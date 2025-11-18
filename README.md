# Serverless Chat Application

A real-time serverless chat application built with AWS API Gateway WebSocket APIs, Lambda, DynamoDB, and S3.

## Architecture

- **Frontend**: React-based UI hosted on S3 as a static website
- **API**: API Gateway WebSocket API for real-time communication
- **Backend**: AWS Lambda functions (Node.js)
- **Database**: DynamoDB for user data and chat messages
- **Streams**: DynamoDB Streams for real-time message broadcasting
- **Infrastructure**: Terraform for complete automation

## Features

- User signup and login
- Real-time chat messaging
- WebSocket-based communication
- Serverless architecture for scalability
- Complete infrastructure as code

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.0
- Node.js >= 18.x
- Bash shell

## Quick Start

### 1. Deploy Infrastructure

```bash
./deploy.sh
```

This script will:
- Install dependencies
- Build Lambda functions
- Deploy infrastructure via Terraform
- Build and upload frontend to S3
- Output the website URL

### 2. Access the Application

After deployment, the script will output the S3 website URL. Open it in your browser to access the chat application.

### 3. Cleanup

```bash
./cleanup.sh
```

This will destroy all AWS resources created by Terraform.

## Project Structure

```
.
├── terraform/              # Terraform infrastructure code
│   ├── main.tf            # Main infrastructure
│   ├── variables.tf       # Input variables
│   ├── outputs.tf         # Output values
│   └── lambda.tf          # Lambda configurations
├── lambda/                # Lambda function code
│   ├── auth/              # Authentication handlers
│   ├── websocket/         # WebSocket handlers
│   └── streams/           # DynamoDB stream processor
├── frontend/              # React frontend
│   ├── public/
│   └── src/
├── deploy.sh              # Deployment script
└── cleanup.sh             # Cleanup script
```

## API Endpoints

### REST API (Authentication)
- `POST /signup` - User registration
- `POST /login` - User authentication

### WebSocket API
- `$connect` - Connection handler
- `$disconnect` - Disconnection handler
- `sendMessage` - Send chat message
- `getMessages` - Retrieve message history

## Environment Variables

The deployment script will automatically configure the frontend with the correct API endpoints.

## Security Notes

- Passwords are hashed using bcrypt
- WebSocket connections are authenticated
- CORS is configured for S3 website origin
- All resources are created with least privilege IAM roles

## Cost Estimation

This application uses serverless resources that scale to zero:
- API Gateway: Pay per request
- Lambda: Pay per invocation
- DynamoDB: On-demand pricing
- S3: Storage and request pricing

Estimated cost for light usage: < $1/month

## Troubleshooting

### Deployment fails
- Ensure AWS credentials are configured: `aws configure`
- Check Terraform version: `terraform version`
- Verify region availability for all services

### WebSocket connection fails
- Check browser console for errors
- Verify API Gateway WebSocket URL in frontend config
- Ensure Lambda functions have proper IAM permissions

## License

MIT
