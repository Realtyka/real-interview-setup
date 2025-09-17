#!/bin/bash

# Terraform Assessment Setup Script
# This script sets up the LocalStack environment for Terraform testing

set -e

echo "🚀 Setting up Terraform Assessment Environment..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check if Docker Compose is available
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose and try again."
    exit 1
fi

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform is not installed. Please install Terraform and try again."
    exit 1
fi

echo "✅ Prerequisites check passed"

# Create necessary directories
mkdir -p ~/.ssh
mkdir -p test-results

# Generate SSH key if it doesn't exist
if [ ! -f ~/.ssh/id_rsa ]; then
    echo "🔑 Generating SSH key pair..."
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N "" -C "terraform-test@example.com"
fi

# Start LocalStack
echo "🐳 Starting LocalStack..."
docker-compose up -d localstack

# Wait for LocalStack to be ready
echo "⏳ Waiting for LocalStack to be ready..."
timeout=120
counter=0
while ! curl -s http://localhost:4566/_localstack/health > /dev/null 2>&1; do
    if [ $counter -eq $timeout ]; then
        echo "❌ LocalStack failed to start within $timeout seconds"
        echo "🔍 Checking LocalStack logs..."
        docker-compose logs localstack | tail -20
        exit 1
    fi
    if [ $((counter % 10)) -eq 0 ]; then
        echo "  Still waiting... ($counter/$timeout seconds)"
    fi
    sleep 1
    counter=$((counter + 1))
done

echo "✅ LocalStack is ready!"

# Initialize Terraform in each exercise directory
echo "🔧 Initializing Terraform configurations..."

for exercise in exercises/*/; do
    if [ -d "$exercise" ] && [ -f "$exercise/main.tf" ]; then
        echo "  Initializing $(basename "$exercise")..."
        cd "$exercise"
        terraform init -upgrade
        cd - > /dev/null
    fi
done

echo "✅ Setup complete!"
echo ""
echo "📋 Next steps:"
echo "1. Navigate to any exercise directory (e.g., cd exercises/1-s3-bucket)"
echo "2. Implement your solution in main.tf"
echo "3. Run 'terraform plan' to validate your configuration"
echo "4. Run 'terraform test' to run the test cases"
echo "5. Run 'terraform apply' to create resources in LocalStack"
echo ""
echo "🔍 To verify your setup, run: ./verify-terraform.sh"
