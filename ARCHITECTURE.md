# Architecture Overview

## System Architecture

This serverless chat application uses AWS services to provide a scalable, real-time messaging platform.

```
┌─────────────┐
│   Browser   │
│  (React UI) │
└──────┬──────┘
       │
       ├─────────────────────────────────┐
       │                                 │
       │ HTTPS                           │ WebSocket
       │                                 │
       ▼                                 ▼
┌──────────────┐              ┌──────────────────┐
│ API Gateway  │              │  API Gateway     │
│  (REST API)  │              │  (WebSocket API) │
└──────┬───────┘              └────────┬─────────┘
       │                               │
       │                               │
       ▼                               ▼
┌──────────────┐              ┌──────────────────┐
│   Lambda     │              │     Lambda       │
│   - Signup   │              │   - Connect      │
│   - Login    │              │   - Disconnect   │
└──────┬───────┘              │   - SendMessage  │
       │                      │   - GetMessages  │
       │                      └────────┬─────────┘
       │                               │
       ▼                               ▼
┌──────────────────────────────────────────────┐
│              DynamoDB Tables                  │
│  - Users (with EmailIndex)                   │
│  - Messages (with RoomIndex, Streams enabled)│
│  - Connections (with UserIndex, TTL enabled) │
└──────────────┬───────────────────────────────┘
               │
               │ DynamoDB Streams
               │
               ▼
        ┌──────────────┐
        │   Lambda     │
        │   Stream     │
        │  Processor   │
        └──────┬───────┘
               │
               │ Broadcast to
               │ all connections
               │
               ▼
        ┌──────────────┐
        │  WebSocket   │
        │  Connections │
        └──────────────┘
```

## Components

### Frontend (React)
- **Location**: S3 Static Website
- **Features**:
  - User authentication (signup/login)
  - Real-time chat interface
  - WebSocket connection management
  - Message history display
- **Technologies**: React 18, WebSocket API

### Authentication API (REST)
- **Service**: API Gateway REST API
- **Endpoints**:
  - `POST /signup` - User registration
  - `POST /login` - User authentication
- **Backend**: Lambda functions with bcrypt for password hashing
- **Token**: JWT for session management

### WebSocket API
- **Service**: API Gateway WebSocket API
- **Routes**:
  - `$connect` - Authenticate and store connection
  - `$disconnect` - Clean up connection
  - `sendMessage` - Store message in DynamoDB
  - `getMessages` - Retrieve message history
- **Authentication**: JWT token via query parameter

### Database (DynamoDB)

#### Users Table
- **Primary Key**: userId
- **GSI**: EmailIndex (email)
- **Attributes**: userId, email, username, password (hashed), createdAt, updatedAt

#### Messages Table
- **Primary Key**: messageId, timestamp
- **GSI**: RoomIndex (roomId, timestamp)
- **Attributes**: messageId, roomId, userId, username, message, timestamp
- **Streams**: Enabled (NEW_IMAGE)

#### Connections Table
- **Primary Key**: connectionId
- **GSI**: UserIndex (userId)
- **Attributes**: connectionId, userId, username, email, connectedAt, ttl
- **TTL**: Enabled (24 hours)

### Stream Processor (Lambda)
- **Trigger**: DynamoDB Streams on Messages table
- **Function**: Broadcasts new messages to all active WebSocket connections
- **Error Handling**: Removes stale connections (410 status)

## Data Flow

### User Registration
1. User submits signup form
2. Frontend sends POST to `/signup`
3. Lambda validates input
4. Lambda checks for existing user via EmailIndex
5. Lambda hashes password with bcrypt
6. Lambda stores user in DynamoDB
7. Success response returned

### User Login
1. User submits login form
2. Frontend sends POST to `/login`
3. Lambda queries user by email via EmailIndex
4. Lambda verifies password with bcrypt
5. Lambda generates JWT token
6. Token and user data returned
7. Frontend stores token in localStorage

### WebSocket Connection
1. Frontend connects to WebSocket URL with JWT token
2. API Gateway triggers `$connect` Lambda
3. Lambda verifies JWT token
4. Lambda stores connection in Connections table
5. Connection established
6. Frontend requests message history via `getMessages`

### Sending Messages
1. User types and sends message
2. Frontend sends via WebSocket with action `sendMessage`
3. Lambda validates and stores message in Messages table
4. DynamoDB Stream triggers Stream Processor Lambda
5. Stream Processor queries all active connections
6. Stream Processor broadcasts message to all connections
7. All clients receive and display new message

### Disconnection
1. User closes browser or navigates away
2. API Gateway triggers `$disconnect` Lambda
3. Lambda removes connection from Connections table

## Security

### Authentication
- Passwords hashed with bcrypt (10 rounds)
- JWT tokens for session management
- WebSocket connections authenticated via JWT

### Authorization
- Connection table stores user context
- Messages tagged with userId
- Only authenticated users can send messages

### Network
- HTTPS for REST API
- WSS (WebSocket Secure) for real-time communication
- CORS configured for S3 origin

### Data
- DynamoDB encryption at rest (AWS managed)
- IAM roles with least privilege
- No sensitive data in logs

## Scalability

### Serverless Benefits
- **Auto-scaling**: Lambda and API Gateway scale automatically
- **Pay-per-use**: Only pay for actual usage
- **No server management**: Fully managed services

### DynamoDB
- **On-demand pricing**: Automatically scales with traffic
- **Global Secondary Indexes**: Fast queries on email and roomId
- **Streams**: Real-time processing of new messages

### WebSocket Connections
- API Gateway handles up to 10,000 concurrent connections per account
- Connection table with TTL prevents stale connections
- Stream processor broadcasts efficiently

## Cost Optimization

### DynamoDB
- On-demand pricing for variable workload
- TTL automatically removes old connections
- GSI only on required attributes

### Lambda
- Efficient code with minimal dependencies
- Appropriate memory allocation
- Short timeout values

### S3
- Static website hosting (cheapest option)
- CloudFront can be added for global distribution

### API Gateway
- WebSocket connections billed per message
- REST API billed per request
- No idle costs

## Monitoring

### CloudWatch Logs
- All Lambda functions log to CloudWatch
- 7-day retention for cost optimization
- Structured logging for debugging

### Metrics
- Lambda invocations and errors
- API Gateway requests and latency
- DynamoDB read/write capacity
- WebSocket connections and messages

## Future Enhancements

1. **Multiple Chat Rooms**: Add room creation and management
2. **Private Messages**: Direct messaging between users
3. **File Uploads**: S3 integration for media sharing
4. **User Presence**: Online/offline status
5. **Message Reactions**: Emoji reactions to messages
6. **Search**: Full-text search with OpenSearch
7. **Notifications**: SNS for push notifications
8. **Analytics**: User engagement tracking
9. **CDN**: CloudFront for global distribution
10. **Custom Domain**: Route53 and ACM for HTTPS
