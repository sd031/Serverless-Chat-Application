# Testing Guide

Comprehensive testing guide for the Serverless Chat Application.

## Table of Contents
1. [Pre-Deployment Testing](#pre-deployment-testing)
2. [Post-Deployment Testing](#post-deployment-testing)
3. [Functional Testing](#functional-testing)
4. [Integration Testing](#integration-testing)
5. [Performance Testing](#performance-testing)
6. [Security Testing](#security-testing)
7. [Troubleshooting](#troubleshooting)

## Pre-Deployment Testing

### Validate Terraform Configuration

```bash
cd terraform
terraform init
terraform validate
terraform fmt -check
```

Expected output:
```
Success! The configuration is valid.
```

### Check Lambda Function Syntax

```bash
# Test Node.js syntax for all Lambda functions
find lambda -name "index.js" -exec node --check {} \;
```

No output means all files are syntactically correct.

### Verify Package.json Files

```bash
# Check all package.json files are valid JSON
find . -name "package.json" -exec node -e "JSON.parse(require('fs').readFileSync('{}'))" \;
```

## Post-Deployment Testing

### Verify AWS Resources

#### Check DynamoDB Tables
```bash
aws dynamodb list-tables --query 'TableNames[?contains(@, `serverless-chat`)]'
```

Expected: 3 tables (users, messages, connections)

#### Check Lambda Functions
```bash
aws lambda list-functions --query 'Functions[?contains(FunctionName, `serverless-chat`)].FunctionName'
```

Expected: 7 functions

#### Check API Gateway
```bash
# REST API
aws apigateway get-rest-apis --query 'items[?contains(name, `serverless-chat`)]'

# WebSocket API
aws apigatewayv2 get-apis --query 'Items[?contains(Name, `serverless-chat`)]'
```

Expected: 1 REST API, 1 WebSocket API

#### Check S3 Bucket
```bash
aws s3 ls | grep serverless-chat
```

Expected: 1 bucket with frontend files

### Verify Terraform Outputs

```bash
cd terraform
terraform output
```

Expected outputs:
- `website_url`
- `auth_api_url`
- `websocket_url`
- `s3_bucket_name`
- `users_table_name`
- `messages_table_name`
- `connections_table_name`

## Functional Testing

### Test 1: User Signup

#### Via UI
1. Open website URL in browser
2. Click "Sign Up" tab
3. Fill in:
   - Username: `testuser1`
   - Email: `test1@example.com`
   - Password: `password123`
4. Click "Sign Up"
5. ✅ Should see success message

#### Via API
```bash
AUTH_API_URL="YOUR_AUTH_API_URL"

curl -X POST "${AUTH_API_URL}/signup" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser2",
    "email": "test2@example.com",
    "password": "password123"
  }'
```

Expected response:
```json
{
  "message": "User created successfully",
  "userId": "...",
  "username": "testuser2",
  "email": "test2@example.com"
}
```

#### Verify in DynamoDB
```bash
aws dynamodb scan \
  --table-name serverless-chat-dev-users \
  --query 'Items[?email.S==`test2@example.com`]'
```

### Test 2: User Login

#### Via UI
1. Switch to "Login" tab
2. Enter email and password
3. Click "Login"
4. ✅ Should redirect to chat interface

#### Via API
```bash
curl -X POST "${AUTH_API_URL}/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test2@example.com",
    "password": "password123"
  }'
```

Expected response:
```json
{
  "message": "Login successful",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "userId": "...",
    "email": "test2@example.com",
    "username": "testuser2"
  }
}
```

Save the token for WebSocket testing.

### Test 3: WebSocket Connection

#### Via Browser Console
```javascript
// Get token from localStorage
const token = localStorage.getItem('token');

// Connect to WebSocket
const ws = new WebSocket(`YOUR_WEBSOCKET_URL?token=${token}`);

ws.onopen = () => console.log('Connected!');
ws.onmessage = (event) => console.log('Message:', event.data);
ws.onerror = (error) => console.error('Error:', error);
```

✅ Should see "Connected!" in console

#### Verify Connection in DynamoDB
```bash
aws dynamodb scan --table-name serverless-chat-dev-connections
```

Should show active connection with your userId.

### Test 4: Send Message

#### Via UI
1. Type message in input box
2. Click "Send" or press Enter
3. ✅ Message should appear in chat

#### Via WebSocket (Browser Console)
```javascript
ws.send(JSON.stringify({
  action: 'sendMessage',
  message: 'Hello from console!',
  roomId: 'general'
}));
```

#### Verify in DynamoDB
```bash
aws dynamodb scan \
  --table-name serverless-chat-dev-messages \
  --query 'Items[?message.S==`Hello from console!`]'
```

### Test 5: Receive Messages (Real-Time)

1. Open website in two different browsers/windows
2. Login with different accounts in each
3. Send message from Browser 1
4. ✅ Message should appear in Browser 2 immediately

### Test 6: Message History

1. Logout and login again
2. ✅ Previous messages should load automatically

#### Via WebSocket
```javascript
ws.send(JSON.stringify({
  action: 'getMessages',
  roomId: 'general',
  limit: 50
}));
```

Should receive messages array.

### Test 7: Logout

1. Click "Logout" button
2. ✅ Should return to login screen
3. ✅ Token should be removed from localStorage

## Integration Testing

### End-to-End User Flow

```bash
#!/bin/bash
# Save as test_e2e.sh

AUTH_API_URL="YOUR_AUTH_API_URL"

echo "1. Testing Signup..."
SIGNUP_RESPONSE=$(curl -s -X POST "${AUTH_API_URL}/signup" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "e2etest",
    "email": "e2e@test.com",
    "password": "testpass123"
  }')
echo "Signup: $SIGNUP_RESPONSE"

echo -e "\n2. Testing Login..."
LOGIN_RESPONSE=$(curl -s -X POST "${AUTH_API_URL}/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "e2e@test.com",
    "password": "testpass123"
  }')
echo "Login: $LOGIN_RESPONSE"

TOKEN=$(echo $LOGIN_RESPONSE | grep -o '"token":"[^"]*' | cut -d'"' -f4)
echo -e "\nToken: $TOKEN"

echo -e "\n3. Testing Invalid Login..."
INVALID_LOGIN=$(curl -s -X POST "${AUTH_API_URL}/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "e2e@test.com",
    "password": "wrongpassword"
  }')
echo "Invalid Login: $INVALID_LOGIN"

echo -e "\n✅ E2E Test Complete"
```

### Lambda Function Testing

#### Test Signup Lambda Directly
```bash
aws lambda invoke \
  --function-name serverless-chat-dev-signup \
  --payload '{"body":"{\"username\":\"lambdatest\",\"email\":\"lambda@test.com\",\"password\":\"test123\"}"}' \
  response.json

cat response.json
```

#### Test Login Lambda Directly
```bash
aws lambda invoke \
  --function-name serverless-chat-dev-login \
  --payload '{"body":"{\"email\":\"lambda@test.com\",\"password\":\"test123\"}"}' \
  response.json

cat response.json
```

### DynamoDB Stream Testing

1. Send a message via UI or API
2. Check Stream Processor logs:
```bash
aws logs tail /aws/lambda/serverless-chat-dev-stream-processor --follow
```

Should see:
- "Stream event:" with new message
- "Message sent to connection" for each active connection

## Performance Testing

### Load Testing with Artillery

Install Artillery:
```bash
npm install -g artillery
```

Create test script `load-test.yml`:
```yaml
config:
  target: "YOUR_AUTH_API_URL"
  phases:
    - duration: 60
      arrivalRate: 10
  
scenarios:
  - name: "Signup and Login"
    flow:
      - post:
          url: "/signup"
          json:
            username: "loadtest{{ $randomNumber() }}"
            email: "load{{ $randomNumber() }}@test.com"
            password: "password123"
      - post:
          url: "/login"
          json:
            email: "load{{ $randomNumber() }}@test.com"
            password: "password123"
```

Run test:
```bash
artillery run load-test.yml
```

### Concurrent WebSocket Connections

Test script `ws-load-test.js`:
```javascript
const WebSocket = require('ws');

const WEBSOCKET_URL = 'YOUR_WEBSOCKET_URL';
const NUM_CONNECTIONS = 100;

async function testConnections() {
  const connections = [];
  
  for (let i = 0; i < NUM_CONNECTIONS; i++) {
    const ws = new WebSocket(`${WEBSOCKET_URL}?token=YOUR_TOKEN`);
    
    ws.on('open', () => {
      console.log(`Connection ${i} opened`);
      ws.send(JSON.stringify({
        action: 'sendMessage',
        message: `Test message ${i}`
      }));
    });
    
    connections.push(ws);
  }
  
  console.log(`Created ${NUM_CONNECTIONS} connections`);
}

testConnections();
```

### Response Time Testing

```bash
# Test signup response time
time curl -X POST "${AUTH_API_URL}/signup" \
  -H "Content-Type: application/json" \
  -d '{"username":"timetest","email":"time@test.com","password":"test123"}'

# Test login response time
time curl -X POST "${AUTH_API_URL}/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"time@test.com","password":"test123"}'
```

Expected: < 500ms for each request

## Security Testing

### Test 1: Password Hashing

```bash
# Create user
curl -X POST "${AUTH_API_URL}/signup" \
  -H "Content-Type: application/json" \
  -d '{"username":"sectest","email":"sec@test.com","password":"mypassword"}'

# Check DynamoDB - password should be hashed
aws dynamodb get-item \
  --table-name serverless-chat-dev-users \
  --key '{"userId":{"S":"USER_ID_HERE"}}'
```

✅ Password should start with `$2a$` (bcrypt hash)

### Test 2: JWT Token Validation

```bash
# Try to connect with invalid token
wscat -c "YOUR_WEBSOCKET_URL?token=invalid_token"
```

✅ Should receive 401 Unauthorized

### Test 3: SQL Injection Protection

```bash
# Try SQL injection in email
curl -X POST "${AUTH_API_URL}/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@test.com OR 1=1","password":"test"}'
```

✅ Should fail gracefully (DynamoDB is NoSQL, not vulnerable to SQL injection)

### Test 4: XSS Protection

1. Try to send message with script tag:
```javascript
ws.send(JSON.stringify({
  action: 'sendMessage',
  message: '<script>alert("XSS")</script>'
}));
```

2. Check if message is displayed as text (not executed)
✅ Should display as plain text

### Test 5: CORS Testing

```bash
# Test CORS headers
curl -X OPTIONS "${AUTH_API_URL}/signup" \
  -H "Origin: http://example.com" \
  -H "Access-Control-Request-Method: POST" \
  -v
```

✅ Should return CORS headers

## Troubleshooting

### Common Issues and Solutions

#### Issue: WebSocket won't connect
```bash
# Check CloudWatch logs
aws logs tail /aws/lambda/serverless-chat-dev-ws-connect --follow

# Verify token is valid
echo $TOKEN | cut -d'.' -f2 | base64 -d
```

#### Issue: Messages not broadcasting
```bash
# Check DynamoDB Streams are enabled
aws dynamodb describe-table \
  --table-name serverless-chat-dev-messages \
  --query 'Table.StreamSpecification'

# Check Stream Processor logs
aws logs tail /aws/lambda/serverless-chat-dev-stream-processor --follow
```

#### Issue: Login fails
```bash
# Check user exists
aws dynamodb scan \
  --table-name serverless-chat-dev-users \
  --filter-expression "email = :email" \
  --expression-attribute-values '{":email":{"S":"YOUR_EMAIL"}}'

# Check Lambda logs
aws logs tail /aws/lambda/serverless-chat-dev-login --follow
```

### Debug Mode

Enable verbose logging in Lambda functions by adding:
```javascript
console.log('Debug:', JSON.stringify(event, null, 2));
```

### Testing Checklist

- [ ] User can signup
- [ ] User can login
- [ ] User cannot login with wrong password
- [ ] User cannot signup with existing email
- [ ] WebSocket connects successfully
- [ ] WebSocket requires valid token
- [ ] Messages are sent successfully
- [ ] Messages are received in real-time
- [ ] Message history loads correctly
- [ ] Multiple users can chat simultaneously
- [ ] Logout works correctly
- [ ] Passwords are hashed in database
- [ ] JWT tokens expire correctly
- [ ] CORS is configured properly
- [ ] Error messages are user-friendly

## Automated Testing Script

Save as `run-tests.sh`:

```bash
#!/bin/bash

echo "==================================="
echo "Serverless Chat - Automated Tests"
echo "==================================="

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Get API URLs from Terraform
cd terraform
AUTH_API_URL=$(terraform output -raw auth_api_url)
WEBSOCKET_URL=$(terraform output -raw websocket_url)
cd ..

echo -e "\nAuth API: $AUTH_API_URL"
echo "WebSocket: $WEBSOCKET_URL"

# Test 1: Signup
echo -e "\n[Test 1] Testing Signup..."
SIGNUP=$(curl -s -X POST "${AUTH_API_URL}/signup" \
  -H "Content-Type: application/json" \
  -d '{"username":"autotest","email":"auto@test.com","password":"test123"}')

if echo $SIGNUP | grep -q "User created successfully"; then
  echo -e "${GREEN}✓ Signup test passed${NC}"
else
  echo -e "${RED}✗ Signup test failed${NC}"
  echo $SIGNUP
fi

# Test 2: Login
echo -e "\n[Test 2] Testing Login..."
LOGIN=$(curl -s -X POST "${AUTH_API_URL}/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"auto@test.com","password":"test123"}')

if echo $LOGIN | grep -q "Login successful"; then
  echo -e "${GREEN}✓ Login test passed${NC}"
else
  echo -e "${RED}✗ Login test failed${NC}"
  echo $LOGIN
fi

# Test 3: Invalid Login
echo -e "\n[Test 3] Testing Invalid Login..."
INVALID=$(curl -s -X POST "${AUTH_API_URL}/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"auto@test.com","password":"wrongpass"}')

if echo $INVALID | grep -q "Invalid"; then
  echo -e "${GREEN}✓ Invalid login test passed${NC}"
else
  echo -e "${RED}✗ Invalid login test failed${NC}"
fi

# Test 4: Duplicate Signup
echo -e "\n[Test 4] Testing Duplicate Signup..."
DUPLICATE=$(curl -s -X POST "${AUTH_API_URL}/signup" \
  -H "Content-Type: application/json" \
  -d '{"username":"autotest","email":"auto@test.com","password":"test123"}')

if echo $DUPLICATE | grep -q "already exists"; then
  echo -e "${GREEN}✓ Duplicate signup test passed${NC}"
else
  echo -e "${RED}✗ Duplicate signup test failed${NC}"
fi

echo -e "\n==================================="
echo "Tests Complete!"
echo "==================================="
```

Make executable and run:
```bash
chmod +x run-tests.sh
./run-tests.sh
```

## Continuous Testing

For production, consider:
- AWS CloudWatch Synthetics for uptime monitoring
- AWS X-Ray for distributed tracing
- Custom CloudWatch alarms for error rates
- Automated testing in CI/CD pipeline

---

**Remember**: Always test in a development environment before deploying to production!
