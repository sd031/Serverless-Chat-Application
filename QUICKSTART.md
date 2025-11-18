# Quick Start Guide

Get your serverless chat application running in 5 minutes!

## Prerequisites Check

Run these commands to verify you have everything installed:

```bash
# Check AWS CLI
aws --version
# Expected: aws-cli/2.x.x or higher

# Check Terraform
terraform version
# Expected: Terraform v1.x.x or higher

# Check Node.js
node --version
# Expected: v18.x.x or higher

# Check npm
npm --version
# Expected: 9.x.x or higher

# Check AWS credentials
aws sts get-caller-identity
# Should show your AWS account details
```

If any command fails, install the missing tool:
- **AWS CLI**: https://aws.amazon.com/cli/
- **Terraform**: https://www.terraform.io/downloads
- **Node.js**: https://nodejs.org/

## Deploy in 3 Steps

### Step 1: Navigate to Project
```bash
cd /Users/sandipdas/aws_chat_project
```

### Step 2: Run Deploy Script
```bash
./deploy.sh
```

### Step 3: Confirm Deployment
When prompted, type `yes` and press Enter.

## What Happens During Deployment?

```
✓ Checking prerequisites
✓ Building Lambda functions (7 functions)
✓ Deploying infrastructure (DynamoDB, Lambda, API Gateway, S3)
✓ Building React frontend
✓ Uploading to S3
✓ Done! Your URLs are displayed
```

**Time**: ~5-7 minutes

## Using the Application

### 1. Open the Website
Copy the Website URL from the deployment output and open it in your browser.

### 2. Create an Account
- Click "Sign Up" tab
- Enter username, email, and password
- Click "Sign Up" button
- Switch to "Login" tab

### 3. Login
- Enter your email and password
- Click "Login" button

### 4. Start Chatting
- Type a message in the input box
- Click "Send" or press Enter
- Your message appears in the chat!

### 5. Test Real-Time (Optional)
- Open another browser window (or incognito mode)
- Create a different account
- Login with the new account
- Send messages from both windows
- See messages appear in real-time! 🎉

## Cleanup

When you're done testing:

```bash
./cleanup.sh
```

Type `yes` to confirm. This removes all AWS resources and stops any charges.

## Troubleshooting

### "Command not found" errors
Install the missing tool (see Prerequisites Check above)

### "Access Denied" errors
Run `aws configure` and enter your AWS credentials

### "Bucket already exists" errors
Run `./cleanup.sh` first, then try deploying again

### WebSocket won't connect
- Make sure you're logged in
- Check browser console for errors
- Try refreshing the page

### Messages not appearing
- Wait a few seconds (DynamoDB Streams have slight delay)
- Check CloudWatch Logs for errors
- Verify DynamoDB tables exist in AWS Console

## What's Next?

- Read [ARCHITECTURE.md](ARCHITECTURE.md) to understand how it works
- Read [DEPLOYMENT.md](DEPLOYMENT.md) for detailed deployment guide
- Customize the UI in `frontend/src/components/`
- Add features like rooms, private messages, etc.

## Cost

For testing/development with light usage:
- **Estimated cost**: < $1/month
- **Free tier eligible**: Yes (first 12 months)
- **Remember**: Run `./cleanup.sh` when done to avoid charges

## Support

If you encounter issues:

1. **Check Logs**
   ```bash
   # View Lambda logs
   aws logs tail /aws/lambda/serverless-chat-dev-signup --follow
   ```

2. **Verify Resources**
   ```bash
   # List DynamoDB tables
   aws dynamodb list-tables
   
   # List Lambda functions
   aws lambda list-functions
   ```

3. **Common Fixes**
   - Refresh browser
   - Clear browser cache
   - Re-login
   - Run cleanup and redeploy

## Features

✅ User signup and login  
✅ Real-time messaging  
✅ Message history  
✅ Multiple concurrent users  
✅ Auto-scaling  
✅ Serverless (no servers to manage)  
✅ Production-ready architecture  

Enjoy your serverless chat application! 🚀
