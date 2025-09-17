#!/bin/bash

# Start LocalStack for Java CDK Assessment
echo "🚀 Starting LocalStack for Java CDK Assessment..."

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    print_warning "Docker is not running. Please start Docker first."
    exit 1
fi

# Start LocalStack
print_status "Starting LocalStack container..."
docker-compose up -d

# Wait for LocalStack to be ready
print_status "Waiting for LocalStack to be ready..."
max_attempts=30
attempt=1

while [ $attempt -le $max_attempts ]; do
    if curl -s http://localhost:4566/_localstack/health > /dev/null 2>&1; then
        print_status "LocalStack is ready! ✓"
        break
    fi
    
    if [ $attempt -eq $max_attempts ]; then
        print_warning "LocalStack failed to start within expected time"
        exit 1
    fi
    
    print_status "Attempt $attempt/$max_attempts - waiting for LocalStack..."
    sleep 2
    ((attempt++))
done

# Set environment variables for LocalStack
export AWS_ENDPOINT_URL=http://localhost:4566
export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test

print_status "LocalStack environment variables set:"
print_status "  AWS_ENDPOINT_URL=$AWS_ENDPOINT_URL"
print_status "  AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION"
print_status "  AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID"

print_status ""
print_status "✅ LocalStack is ready for Java CDK Assessment!"
print_status ""
print_status "Next steps:"
print_status "1. Run './setup-java-cdk.sh' to set up the assessment"
print_status "2. Navigate to any exercise directory"
print_status "3. Run 'mvn test' to run tests against LocalStack"
print_status ""
print_status "To stop LocalStack: ./stop-localstack.sh"
