#!/bin/bash

# Terraform Assessment Verification Script
# This script verifies that the Terraform testing environment is working correctly

set -e

echo "🔍 Verifying Terraform Assessment Environment..."

# Check if LocalStack is running
if ! curl -s http://localhost:4566/_localstack/health > /dev/null 2>&1; then
    echo "❌ LocalStack is not running. Please run ./setup-terraform.sh first."
    exit 1
fi

echo "✅ LocalStack is running"

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform is not installed"
    exit 1
fi

echo "✅ Terraform is installed"

# Test LocalStack connectivity
echo "🧪 Testing LocalStack connectivity..."

# Test S3 service
if aws --endpoint-url=http://localhost:4566 s3 ls > /dev/null 2>&1; then
    echo "✅ S3 service is accessible"
else
    echo "❌ S3 service is not accessible"
    exit 1
fi

# Test EC2 service
if aws --endpoint-url=http://localhost:4566 ec2 describe-regions --region us-east-1 > /dev/null 2>&1; then
    echo "✅ EC2 service is accessible"
else
    echo "❌ EC2 service is not accessible"
    exit 1
fi

# Test Lambda service
if aws --endpoint-url=http://localhost:4566 lambda list-functions --region us-east-1 > /dev/null 2>&1; then
    echo "✅ Lambda service is accessible"
else
    echo "❌ Lambda service is not accessible"
    exit 1
fi

# Test IAM service
if aws --endpoint-url=http://localhost:4566 iam list-roles --region us-east-1 > /dev/null 2>&1; then
    echo "✅ IAM service is accessible"
else
    echo "❌ IAM service is not accessible"
    exit 1
fi

echo ""
echo "🎉 All services are working correctly!"
echo ""
echo "📋 You can now:"
echo "1. Navigate to any exercise directory (e.g., cd exercises/1-s3-bucket)"
echo "2. Implement your solution in main.tf"
echo "3. Run 'terraform plan' to validate your configuration"
echo "4. Run 'terraform test' to run the test cases"
echo "5. Run 'terraform apply' to create resources in LocalStack"
echo ""
echo "🔧 To test a specific exercise, run:"
echo "   cd exercises/1-s3-bucket"
echo "   terraform test"
