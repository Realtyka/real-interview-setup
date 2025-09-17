#!/bin/bash

# Java CDK Assessment Cleanup Script
# This script cleans up the Java CDK environment after assessment

set -e

echo "🧹 Cleaning up Java CDK Assessment Environment..."

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

# Check if AWS credentials are configured
check_aws_credentials() {
    if aws sts get-caller-identity &> /dev/null; then
        print_status "AWS credentials found ✓"
        return 0
    else
        print_warning "AWS credentials not configured. Skipping AWS cleanup."
        return 1
    fi
}

# Destroy CDK stacks
destroy_cdk_stacks() {
    print_status "Destroying CDK stacks..."
    
    for exercise in 1-lambda-function 2-s3-bucket 3-api-gateway 4-dynamodb-table; do
        if [ -d "exercises/$exercise" ]; then
            print_status "Destroying $exercise stack..."
            cd "exercises/$exercise"
            
            if cdk list &> /dev/null; then
                cdk destroy --force --all 2>/dev/null || print_warning "Failed to destroy $exercise stack"
            else
                print_warning "No CDK stacks found for $exercise"
            fi
            
            cd ../..
        fi
    done
}

# Clean up CDK bootstrap stack
cleanup_bootstrap() {
    print_status "Checking CDK bootstrap stack..."
    
    if aws cloudformation describe-stacks --stack-name CDKToolkit &> /dev/null; then
        print_warning "CDK bootstrap stack found. This is shared across CDK projects."
        print_warning "Only destroy it if you're sure no other CDK projects are using it."
        read -p "Do you want to destroy the CDK bootstrap stack? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_status "Destroying CDK bootstrap stack..."
            aws cloudformation delete-stack --stack-name CDKToolkit
            print_status "CDK bootstrap stack deletion initiated ✓"
        else
            print_status "Skipping CDK bootstrap stack cleanup"
        fi
    else
        print_status "No CDK bootstrap stack found ✓"
    fi
}

# Clean up local files
cleanup_local_files() {
    print_status "Cleaning up local files..."
    
    # Remove target directories
    for exercise in 1-lambda-function 2-s3-bucket 3-api-gateway 4-dynamodb-table; do
        if [ -d "exercises/$exercise/target" ]; then
            rm -rf "exercises/$exercise/target"
            print_status "Removed $exercise/target directory ✓"
        fi
    done
    
    # Remove test results
    if [ -d "test-results" ]; then
        rm -rf test-results
        print_status "Removed test-results directory ✓"
    fi
    
    # Remove CDK output files
    find . -name "cdk.out" -type d -exec rm -rf {} + 2>/dev/null || true
    print_status "Removed CDK output directories ✓"
}

# Main cleanup function
main() {
    print_status "Starting Java CDK Assessment Cleanup..."
    
    if check_aws_credentials; then
        destroy_cdk_stacks
        cleanup_bootstrap
    fi
    
    cleanup_local_files
    
    print_status "✅ Java CDK Assessment cleanup completed!"
    print_status ""
    print_status "Cleanup summary:"
    print_status "- CDK stacks destroyed (if AWS credentials were available)"
    print_status "- Local build artifacts removed"
    print_status "- Test results cleaned up"
    print_status ""
    print_warning "Note: CDK bootstrap stack may still exist if other projects are using it."
}

# Run main function
main "$@"
