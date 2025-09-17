# Technical Interview Assessment

This repository contains hands-on exercises designed to assess candidates' practical skills in Kubernetes, Terraform, and Java CDK.

## Available Assessments

### 🚀 Kubernetes Assessment
Hands-on Kubernetes exercises using kind (Kubernetes in Docker) to test practical k8s skills.

### ☁️ Terraform Assessment  
Infrastructure as Code exercises using LocalStack to simulate AWS services without requiring an AWS account.

### ☕ Java CDK Assessment
AWS Cloud Development Kit exercises using Java to test practical CDK and AWS skills with intentional bugs for candidates to identify and fix.

## Prerequisites

- Docker installed on your machine
- Docker Compose installed
- Java 11+ installed (for Java CDK assessment)
- Maven 3.6+ installed (for Java CDK assessment)
- Node.js 14+ installed (for Java CDK assessment)
- Basic understanding of Kubernetes, Terraform, and/or Java CDK concepts
- 4GB+ of available RAM
- macOS, Linux, or Windows with WSL2

## Quick Start

### Kubernetes Assessment
```bash
# Clone and setup
git clone git@github.com:Realtyka/real-interview-setup.git
cd real-interview-setup

# Setup Kubernetes environment
./setup-cluster.sh

# Verify setup
./verify-setup.sh

