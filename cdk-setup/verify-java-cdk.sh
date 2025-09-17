#!/bin/bash

# Java CDK Assessment Verification Script
# This script verifies that the Java CDK environment is properly set up

set -e

echo "🔍 Verifying Java CDK Assessment Environment..."

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

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    echo -n "Testing $test_name... "
    
    if eval "$test_command" &> /dev/null; then
        echo -e "${GREEN}PASS${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}FAIL${NC}"
        ((TESTS_FAILED++))
    fi
}

# Verify Java installation
verify_java() {
    run_test "Java installation" "java -version"
    run_test "Java version (11+)" "[ \$(java -version 2>&1 | head -n 1 | cut -d'\"' -f2 | cut -d'.' -f1) -ge 11 ]"
}

# Verify Maven installation
verify_maven() {
    run_test "Maven installation" "mvn -version"
    run_test "Maven version (3.6+)" "[ \$(mvn -version | head -n 1 | cut -d' ' -f3 | cut -d'.' -f1) -ge 3 ]"
}

# Verify Node.js installation
verify_nodejs() {
    run_test "Node.js installation" "node -version"
    run_test "Node.js version (14+)" "[ \$(node -v | cut -d'v' -f2 | cut -d'.' -f1) -ge 14 ]"
}

# Verify CDK installation
verify_cdk() {
    run_test "CDK installation" "cdk --version"
}

# Verify CDK projects
verify_cdk_projects() {
    for exercise in 1-lambda-function 2-s3-bucket 3-api-gateway 4-dynamodb-table 5-waf-cloudfront 6-s3-advanced; do
        if [ -d "exercises/$exercise" ]; then
            run_test "$exercise CDK project" "[ -f exercises/$exercise/cdk.json ]"
            run_test "$exercise Maven build" "cd exercises/$exercise && mvn clean compile -q && cd ../.."
        else
            print_error "Exercise directory $exercise not found"
            ((TESTS_FAILED++))
        fi
    done
}

# Verify test cases
verify_test_cases() {
    for exercise in 1-lambda-function 2-s3-bucket 3-api-gateway 4-dynamodb-table 5-waf-cloudfront 6-s3-advanced; do
        if [ -f "test-cases/$exercise-test.java" ]; then
            run_test "$exercise test case" "[ -f test-cases/$exercise-test.java ]"
        else
            print_warning "Test case for $exercise not found"
        fi
    done
}

# Verify AWS credentials (optional)
verify_aws_credentials() {
    if aws sts get-caller-identity &> /dev/null; then
        print_status "AWS credentials configured ✓"
        run_test "AWS credentials" "aws sts get-caller-identity"
    else
        print_warning "AWS credentials not configured (optional for testing)"
    fi
}

# Run CDK bootstrap check
verify_cdk_bootstrap() {
    if aws sts get-caller-identity &> /dev/null; then
        if aws cloudformation describe-stacks --stack-name CDKToolkit &> /dev/null; then
            print_status "CDK bootstrap stack found ✓"
        else
            print_warning "CDK bootstrap stack not found. Run 'cdk bootstrap' when ready to deploy."
        fi
    fi
}

# Main verification function
main() {
    print_status "Starting Java CDK Assessment Verification..."
    echo ""
    
    verify_java
    verify_maven
    verify_nodejs
    verify_cdk
    verify_cdk_projects
    verify_test_cases
    verify_aws_credentials
    verify_cdk_bootstrap
    
    echo ""
    print_status "Verification Results:"
    print_status "Tests Passed: $TESTS_PASSED"
    
    if [ $TESTS_FAILED -gt 0 ]; then
        print_error "Tests Failed: $TESTS_FAILED"
        echo ""
        print_error "❌ Verification failed. Please fix the issues above and run again."
        exit 1
    else
        print_status "Tests Failed: $TESTS_FAILED"
        echo ""
        print_status "✅ All verifications passed! Your Java CDK environment is ready."
        echo ""
        print_status "You can now start working on the exercises:"
        print_status "1. Navigate to any exercise directory (e.g., 'cd exercises/1-lambda-function')"
        print_status "2. Run 'mvn test' to see the failing tests"
        print_status "3. Fix the bugs in the code to make tests pass"
        print_status "4. Run 'cdk deploy' to deploy your solution (requires AWS credentials)"
    fi
}

# Run main function
main "$@"
