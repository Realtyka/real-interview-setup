#!/bin/bash

# Java CDK Assessment Setup Script
# This script sets up the Java CDK environment for the technical assessment

# Don't exit on error - we expect tests to fail initially

echo "🚀 Setting up Java CDK Assessment Environment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Java is installed
check_java() {
    print_status "Checking Java installation..."
    if command -v java &> /dev/null; then
        JAVA_VERSION=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2 | cut -d'.' -f1)
        if [ "$JAVA_VERSION" -ge 11 ]; then
            print_status "Java $JAVA_VERSION found ✓"
        else
            print_error "Java 11 or higher is required. Found version $JAVA_VERSION"
            exit 1
        fi
    else
        print_error "Java is not installed. Please install Java 11 or higher."
        exit 1
    fi
}

# Check if Maven is installed
check_maven() {
    print_status "Checking Maven installation..."
    if command -v mvn &> /dev/null; then
        MAVEN_VERSION=$(mvn -version | head -n 1 | cut -d' ' -f3)
        print_status "Maven $MAVEN_VERSION found ✓"
    else
        print_error "Maven is not installed. Please install Maven 3.6 or higher."
        exit 1
    fi
}

# Check if Node.js is installed (required for CDK)
check_nodejs() {
    print_status "Checking Node.js installation..."
    if command -v node &> /dev/null; then
        NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
        if [ "$NODE_VERSION" -ge 14 ]; then
            print_status "Node.js $NODE_VERSION found ✓"
        else
            print_error "Node.js 14 or higher is required. Found version $NODE_VERSION"
            exit 1
        fi
    else
        print_error "Node.js is not installed. Please install Node.js 14 or higher."
        exit 1
    fi
}

# Install AWS CDK
install_cdk() {
    print_status "Installing AWS CDK..."
    if command -v cdk &> /dev/null; then
        CDK_VERSION=$(cdk --version | cut -d' ' -f1)
        print_status "CDK $CDK_VERSION already installed ✓"
    else
        print_status "Installing CDK globally..."
        npm install -g aws-cdk@latest
        print_status "CDK installed successfully ✓"
    fi
}

# Initialize CDK projects
init_cdk_projects() {
    print_status "Initializing CDK projects..."
    
    for exercise in 1-lambda-function 2-s3-bucket 3-api-gateway 4-dynamodb-table; do
        if [ -d "exercises/$exercise" ]; then
            print_status "Initializing $exercise..."
            cd "exercises/$exercise"
            
            # Initialize CDK if not already done
            if [ ! -f "cdk.json" ]; then
                cdk init app --language java --name "$exercise" --generate-only
            fi
            
            # Install dependencies (tests may fail initially - this is expected)
            print_status "Installing dependencies for $exercise..."
            if mvn clean install -q; then
                print_status "$exercise dependencies installed successfully ✓"
            else
                print_warning "$exercise dependencies installed but tests failed (this is expected for buggy code) ✓"
            fi
            
            cd ../..
            print_status "$exercise initialized ✓"
        fi
    done
}

# Create test results directory
create_test_dirs() {
    print_status "Creating test directories..."
    mkdir -p test-results
    print_status "Test directories created ✓"
}

# Main setup function
main() {
    print_status "Starting Java CDK Assessment Setup..."
    
    check_java
    check_maven
    check_nodejs
    install_cdk
    init_cdk_projects
    create_test_dirs
    
    print_status "✅ Java CDK Assessment setup completed successfully!"
    print_status ""
    print_status "Next steps:"
    print_status "1. Start LocalStack: './start-localstack.sh' (recommended for local testing)"
    print_status "2. Or configure AWS credentials for real AWS deployment"
    print_status "3. Run './verify-java-cdk.sh' to verify your setup"
    print_status "4. Navigate to any exercise directory (e.g., 'cd exercises/1-lambda-function')"
    print_status "5. Run 'mvn test' to run the test cases"
    print_status "6. Fix the bugs in the code to make tests pass"
    print_status ""
    print_warning "Note: Tests are expected to fail initially - this is part of the assessment!"
    print_warning "The code contains intentional bugs that you need to identify and fix."
    print_warning ""
    print_status "LocalStack Option (Recommended):"
    print_status "  - No AWS credentials needed"
    print_status "  - No AWS costs"
    print_status "  - Fast local testing"
    print_status "  - Run './start-localstack.sh' to begin"
    print_status ""
    print_warning "AWS Option:"
    print_warning "  - Run 'aws configure' or set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY"
    print_warning "  - May incur AWS costs"
}

# Run main function
main "$@"
