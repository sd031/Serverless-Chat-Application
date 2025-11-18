# Deployment Guide

## Prerequisites

Before deploying, ensure you have the following installed and configured:

### Required Tools
- **AWS CLI** (v2.x or later)
  ```bash
  aws --version
  ```
- **Terraform** (v1.0 or later)
  ```bash
  terraform version
  ```
- **Node.js** (v18.x or later)
  ```bash
  node --version
  ```
- **npm** (v9.x or later)
  ```bash
  npm --version
  ```

### AWS Configuration

1. **Configure AWS Credentials**
   ```bash
   aws configure
   ```
   Provide:
   - AWS Access Key ID
   - AWS Secret Access Key
   - Default region (e.g., us-east-1)
   - Default output format (json)

2. **Verify Configuration**
   ```bash
   aws sts get-caller-identity
   ```

3. **Required IAM Permissions**
   Your AWS user/role needs permissions for:
   - DynamoDB (create tables, manage streams)
   - Lambda (create functions, manage code)
   - API Gateway (create REST and WebSocket APIs)
   - S3 (create buckets, upload objects)
   - IAM (create roles and policies)
   - CloudWatch Logs (create log groups)

## Deployment Steps

### 1. Clone or Navigate to Project
```bash
cd /Users/sandipdas/aws_chat_project
```

### 2. Review Configuration (Optional)
Edit `terraform/variables.tf` to customize:
- `aws_region` - AWS region for deployment (default: us-east-1)
- `project_name` - Project name prefix (default: serverless-chat)
- `environment` - Environment name (default: dev)

### 3. Run Deployment Script
```bash
./deploy.sh
```

The script will:
1. ✅ Check prerequisites
2. 📦 Build Lambda functions
3. 🏗️ Deploy infrastructure with Terraform
4. ⚛️ Build React frontend
5. ☁️ Upload to S3
6. 🎉 Display URLs

### 4. Review and Confirm
When prompted by Terraform:
```
Do you want to apply these changes? (yes/no):
```
Type `yes` and press Enter.

### 5. Access Your Application
After successful deployment, you'll see:
```
=========================================
Deployment Complete!
=========================================

Your serverless chat application is ready!

Website URL: http://serverless-chat-dev-frontend-xxxxx.s3-website-us-east-1.amazonaws.com
Auth API: https://xxxxxxxxxx.execute-api.us-east-1.amazonaws.com/dev
WebSocket API: wss://xxxxxxxxxx.execute-api.us-east-1.amazonaws.com/dev

Open the Website URL in your browser to start chatting!
```

## Post-Deployment

### Testing the Application

1. **Open the Website URL** in your browser
2. **Sign Up** with a new account
   - Enter username, email, and password
   - Click "Sign Up"
3. **Login** with your credentials
4. **Start Chatting**
   - Type a message and click "Send"
   - Open another browser/incognito window
   - Create another account and see real-time messages

### Verifying Resources

Check deployed resources in AWS Console:

1. **DynamoDB Tables**
   ```bash
   aws dynamodb list-tables
   ```

2. **Lambda Functions**
   ```bash
   aws lambda list-functions --query 'Functions[?contains(FunctionName, `serverless-chat`)].FunctionName'
   ```

3. **API Gateway APIs**
   ```bash
   aws apigateway get-rest-apis
   aws apigatewayv2 get-apis
   ```

4. **S3 Bucket**
   ```bash
   aws s3 ls | grep serverless-chat
   ```

## Troubleshooting

### Deployment Fails

**Issue**: Terraform fails with permission errors
```
Error: creating DynamoDB Table: AccessDeniedException
```
**Solution**: Verify your AWS credentials have sufficient permissions

**Issue**: Lambda function build fails
```
Error: npm install failed
```
**Solution**: Ensure Node.js and npm are installed and accessible

**Issue**: S3 bucket name conflict
```
Error: BucketAlreadyExists
```
**Solution**: S3 bucket names are globally unique. The script uses random suffixes, but if it fails, run cleanup and try again.

### Application Issues

**Issue**: Cannot connect to WebSocket
```
WebSocket connection failed
```
**Solution**: 
- Check browser console for errors
- Verify WebSocket URL in config
- Ensure JWT token is valid (try logging in again)

**Issue**: Messages not appearing
```
Messages sent but not received by other users
```
**Solution**:
- Check DynamoDB Streams are enabled on Messages table
- Verify Stream Processor Lambda is triggered
- Check CloudWatch Logs for errors

**Issue**: Login fails
```
Invalid email or password
```
**Solution**:
- Ensure you signed up first
- Check email is correct
- Password must be at least 6 characters

### Viewing Logs

**Lambda Logs**
```bash
# Signup function
aws logs tail /aws/lambda/serverless-chat-dev-signup --follow

# WebSocket connect
aws logs tail /aws/lambda/serverless-chat-dev-ws-connect --follow

# Stream processor
aws logs tail /aws/lambda/serverless-chat-dev-stream-processor --follow
```

**API Gateway Logs** (if enabled)
```bash
aws logs tail /aws/apigateway/serverless-chat-dev-auth-api --follow
```

## Updating the Application

### Update Lambda Functions
1. Modify Lambda code in `lambda/` directory
2. Run deployment script again:
   ```bash
   ./deploy.sh
   ```
   Terraform will detect changes and update only modified functions.

### Update Frontend
1. Modify React code in `frontend/src/` directory
2. Run deployment script again:
   ```bash
   ./deploy.sh
   ```
   The script will rebuild and upload the new version.

### Update Infrastructure
1. Modify Terraform files in `terraform/` directory
2. Run deployment script again:
   ```bash
   ./deploy.sh
   ```
   Review the plan carefully before applying.

## Cleanup

### Remove All Resources
```bash
./cleanup.sh
```

This will:
1. ⚠️ Warn about resource deletion
2. 🗑️ Empty S3 bucket
3. 💥 Destroy all Terraform resources
4. 🧹 Clean up build artifacts

**Warning**: This action is irreversible. All data will be lost.

### Partial Cleanup

To keep infrastructure but remove frontend:
```bash
aws s3 rm s3://YOUR-BUCKET-NAME/ --recursive
```

To keep data but stop services:
- Disable Lambda functions in AWS Console
- This will stop charges for invocations

## Cost Management

### Estimated Costs

For light usage (< 100 users, < 1000 messages/day):
- **DynamoDB**: ~$0.50/month (on-demand)
- **Lambda**: ~$0.20/month (free tier eligible)
- **API Gateway**: ~$0.30/month
- **S3**: ~$0.10/month
- **CloudWatch Logs**: ~$0.10/month
- **Total**: ~$1.20/month

### Cost Optimization Tips

1. **Use Free Tier**
   - First 12 months include generous free tier
   - Lambda: 1M requests/month free
   - API Gateway: 1M requests/month free
   - DynamoDB: 25 GB storage free

2. **Set Up Billing Alerts**
   ```bash
   aws cloudwatch put-metric-alarm \
     --alarm-name billing-alarm \
     --alarm-description "Alert when charges exceed $10" \
     --metric-name EstimatedCharges \
     --namespace AWS/Billing \
     --statistic Maximum \
     --period 21600 \
     --evaluation-periods 1 \
     --threshold 10 \
     --comparison-operator GreaterThanThreshold
   ```

3. **Monitor Usage**
   - Check AWS Cost Explorer regularly
   - Review CloudWatch metrics
   - Set up budget alerts

4. **Clean Up When Not Needed**
   - Run `./cleanup.sh` when done testing
   - Redeploy when needed (takes ~5 minutes)

## Production Considerations

### Before Going to Production

1. **Change JWT Secret**
   - Update in Lambda environment variables
   - Use AWS Secrets Manager for secure storage

2. **Enable API Gateway Logging**
   - Add CloudWatch log groups
   - Enable execution logging

3. **Add Custom Domain**
   - Register domain in Route53
   - Create SSL certificate in ACM
   - Configure CloudFront distribution

4. **Implement Rate Limiting**
   - Add API Gateway usage plans
   - Set throttle limits per user

5. **Add Monitoring**
   - Set up CloudWatch alarms
   - Configure SNS notifications
   - Add X-Ray tracing

6. **Backup Strategy**
   - Enable DynamoDB point-in-time recovery
   - Set up automated backups
   - Test restore procedures

7. **Security Hardening**
   - Enable AWS WAF
   - Add request validation
   - Implement IP whitelisting if needed
   - Regular security audits

8. **Performance Optimization**
   - Add CloudFront for global distribution
   - Enable DynamoDB auto-scaling
   - Optimize Lambda memory allocation
   - Add caching where appropriate

## Support

For issues or questions:
1. Check CloudWatch Logs for errors
2. Review Terraform state: `cd terraform && terraform show`
3. Verify AWS service quotas
4. Check AWS Service Health Dashboard

## Next Steps

After successful deployment:
1. ✅ Test all features thoroughly
2. 📊 Monitor CloudWatch metrics
3. 💰 Review AWS billing dashboard
4. 🔒 Implement additional security measures
5. 🚀 Consider production enhancements
