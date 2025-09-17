#!/bin/bash

# Terraform Assessment Cleanup Script
# This script cleans up the LocalStack environment and Terraform state

set -e

echo "🧹 Cleaning up Terraform Assessment Environment..."

# Stop and remove Docker containers
echo "🐳 Stopping LocalStack containers..."
docker-compose down

# Remove Docker volumes (optional)
read -p "Do you want to remove LocalStack data volumes? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🗑️  Removing LocalStack data volumes..."
    docker volume prune -f
fi

# Clean up Terraform state files
echo "🧹 Cleaning up Terraform state files..."
find . -name "terraform.tfstate*" -type f -delete
find . -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null || true
find . -name "lambda_function.zip" -type f -delete

# Clean up test results
echo "🧹 Cleaning up test results..."
rm -rf test-results/

echo "✅ Cleanup complete!"
echo ""
echo "💡 To start fresh, run: ./setup-terraform.sh"
