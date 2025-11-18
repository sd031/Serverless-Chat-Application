#!/bin/bash

set -e

echo "========================================="
echo "Serverless Chat Application Deployment"
echo "========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check prerequisites
echo "Checking prerequisites..."

if ! command -v terraform &> /dev/null; then
    echo -e "${RED}Error: Terraform is not installed${NC}"
    exit 1
fi

if ! command -v aws &> /dev/null; then
    echo -e "${RED}Error: AWS CLI is not installed${NC}"
    exit 1
fi

if ! command -v node &> /dev/null; then
    echo -e "${RED}Error: Node.js is not installed${NC}"
    exit 1
fi

if ! command -v npm &> /dev/null; then
    echo -e "${RED}Error: npm is not installed${NC}"
    exit 1
fi

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}Error: AWS credentials are not configured${NC}"
    echo "Please run 'aws configure' to set up your credentials"
    exit 1
fi

echo -e "${GREEN}✓ All prerequisites met${NC}"
echo ""

# Build Lambda functions
echo "Building Lambda functions..."

# Function to build a Lambda function
build_lambda() {
    local dir=$1
    local name=$2
    local parent_dir=$(dirname "$dir")
    
    echo "  Building $name..."
    cd "$dir"
    
    if [ -f "package.json" ]; then
        npm install --production --silent
    fi
    
    # Create zip in parent directory for Terraform
    zip -q -r "../${name}.zip" . -x "*.zip"
    echo -e "  ${GREEN}✓ $name built${NC}"
    cd - > /dev/null
}

# Build auth functions
build_lambda "lambda/auth/signup" "signup"
build_lambda "lambda/auth/login" "login"

# Build websocket functions
build_lambda "lambda/websocket/connect" "connect"
build_lambda "lambda/websocket/disconnect" "disconnect"
build_lambda "lambda/websocket/sendMessage" "sendMessage"
build_lambda "lambda/websocket/getMessages" "getMessages"

# Build stream processor
build_lambda "lambda/streams/processor" "processor"

echo -e "${GREEN}✓ All Lambda functions built${NC}"
echo ""

# Deploy infrastructure with Terraform
echo "Deploying infrastructure with Terraform..."
cd terraform

terraform init -input=false

echo ""
echo "Planning infrastructure changes..."
terraform plan -out=tfplan

echo ""
read -p "Do you want to apply these changes? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo -e "${YELLOW}Deployment cancelled${NC}"
    exit 0
fi

echo ""
echo "Applying infrastructure changes..."
terraform apply tfplan

# Get outputs
AUTH_API_URL=$(terraform output -raw auth_api_url)
WEBSOCKET_URL=$(terraform output -raw websocket_url)
S3_BUCKET=$(terraform output -raw s3_bucket_name)
WEBSITE_URL=$(terraform output -raw website_url)

cd ..

echo -e "${GREEN}✓ Infrastructure deployed${NC}"
echo ""

# Build frontend
echo "Building frontend..."
cd frontend

# Install dependencies
echo "  Installing dependencies..."
npm install --silent

# Create config file with API endpoints
echo "  Configuring API endpoints..."
cat > public/config.js << EOF
window.CONFIG = {
  AUTH_API_URL: '${AUTH_API_URL}',
  WEBSOCKET_URL: '${WEBSOCKET_URL}'
};
EOF

# Update index.html to include config
if ! grep -q "config.js" public/index.html; then
    sed -i.bak 's|</head>|  <script src="%PUBLIC_URL%/config.js"></script>\n  </head>|' public/index.html
    rm public/index.html.bak
fi

# Build
echo "  Building React app..."
npm run build --silent

echo -e "${GREEN}✓ Frontend built${NC}"
echo ""

# Upload to S3
echo "Uploading frontend to S3..."
aws s3 sync build/ "s3://${S3_BUCKET}/" --delete --quiet

echo -e "${GREEN}✓ Frontend uploaded${NC}"
echo ""

cd ..

# Display success message
echo "========================================="
echo -e "${GREEN}Deployment Complete!${NC}"
echo "========================================="
echo ""
echo "Your serverless chat application is ready!"
echo ""
echo -e "${YELLOW}Website URL:${NC} ${WEBSITE_URL}"
echo -e "${YELLOW}Auth API:${NC} ${AUTH_API_URL}"
echo -e "${YELLOW}WebSocket API:${NC} ${WEBSOCKET_URL}"
echo ""
echo "Open the Website URL in your browser to start chatting!"
echo ""
echo "To clean up all resources, run: ./cleanup.sh"
echo ""
