#!/bin/bash

set -e

echo "========================================="
echo "Serverless Chat Application Cleanup"
echo "========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Warning message
echo -e "${RED}WARNING: This will destroy all resources created by Terraform!${NC}"
echo "This includes:"
echo "  - DynamoDB tables and all data"
echo "  - Lambda functions"
echo "  - API Gateway endpoints"
echo "  - S3 bucket and all files"
echo "  - All other AWS resources"
echo ""

read -p "Are you sure you want to continue? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo -e "${YELLOW}Cleanup cancelled${NC}"
    exit 0
fi

echo ""

# Get S3 bucket name before destroying
cd terraform

if [ -f "terraform.tfstate" ]; then
    echo "Emptying S3 bucket..."
    S3_BUCKET=$(terraform output -raw s3_bucket_name 2>/dev/null || echo "")
    
    if [ -n "$S3_BUCKET" ]; then
        echo "  Deleting all objects from ${S3_BUCKET}..."
        aws s3 rm "s3://${S3_BUCKET}/" --recursive --quiet 2>/dev/null || true
        echo -e "  ${GREEN}✓ S3 bucket emptied${NC}"
    fi
fi

echo ""
echo "Destroying infrastructure..."

terraform destroy -auto-approve

cd ..

echo -e "${GREEN}✓ Infrastructure destroyed${NC}"
echo ""

# Clean up build artifacts
echo "Cleaning up build artifacts..."

# Remove Lambda zip files
find lambda -name "*.zip" -type f -delete
find lambda -name "node_modules" -type d -exec rm -rf {} + 2>/dev/null || true

# Remove frontend build
rm -rf frontend/build
rm -rf frontend/node_modules
rm -f frontend/public/config.js

# Remove Terraform files
rm -rf terraform/.terraform
rm -f terraform/tfplan
rm -f terraform/.terraform.lock.hcl

echo -e "${GREEN}✓ Build artifacts cleaned${NC}"
echo ""

echo "========================================="
echo -e "${GREEN}Cleanup Complete!${NC}"
echo "========================================="
echo ""
echo "All AWS resources have been destroyed."
echo "All build artifacts have been removed."
echo ""
