#!/bin/bash

# Stop LocalStack for Java CDK Assessment
echo "🛑 Stopping LocalStack for Java CDK Assessment..."

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

# Stop LocalStack
print_status "Stopping LocalStack container..."
docker-compose down

# Clean up volumes if requested
if [ "$1" = "--clean" ]; then
    print_status "Cleaning up LocalStack volumes..."
    docker-compose down -v
    print_status "LocalStack volumes cleaned ✓"
fi

print_status "✅ LocalStack stopped successfully!"
print_status ""
print_status "To start LocalStack again: ./start-localstack.sh"
