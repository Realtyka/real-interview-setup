#!/bin/bash

# setup-cluster.sh
# Main setup script that orchestrates the installation and cluster creation

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}🚀 Starting Kubernetes Interview Assessment Setup${NC}"
echo "=================================================="

# Check prerequisites
echo -e "\n${YELLOW}📋 Checking prerequisites...${NC}"

# Check if Docker is installed and running
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed. Please install Docker first.${NC}"
    echo "Visit: https://docs.docker.com/get-docker/"
    exit 1
fi

if ! docker info &> /dev/null; then
    echo -e "${RED}❌ Docker is not running. Please start Docker and try again.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Docker is installed and running${NC}"

# Check available memory
echo "🔍 Checking available memory..."
TOTAL_MEM=$(docker system info --format '{{.MemTotal}}' 2>/dev/null || echo "0")
if [ "$TOTAL_MEM" -gt 0 ]; then
    MEM_GB=$((TOTAL_MEM / 1024 / 1024 / 1024))
    echo "💾 Available Docker memory: ${MEM_GB}GB"
    if [ "$MEM_GB" -lt 4 ]; then
        echo -e "${YELLOW}⚠️  Warning: Less than 4GB memory available. Performance may be affected.${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Could not determine available memory${NC}"
fi

# Install kubectl
echo -e "\n${YELLOW}📦 Installing kubectl...${NC}"
if [ -f "$SCRIPT_DIR/install-kubectl.sh" ]; then
    chmod +x "$SCRIPT_DIR/install-kubectl.sh"
    "$SCRIPT_DIR/install-kubectl.sh"
else
    echo -e "${RED}❌ install-kubectl.sh not found${NC}"
    exit 1
fi

# Install kind
echo -e "\n${YELLOW}📦 Installing kind...${NC}"
if [ -f "$SCRIPT_DIR/install-kind.sh" ]; then
    chmod +x "$SCRIPT_DIR/install-kind.sh"
    "$SCRIPT_DIR/install-kind.sh"
else
    echo -e "${RED}❌ install-kind.sh not found${NC}"
    exit 1
fi

# Create kind cluster
echo -e "\n${YELLOW}🏗️  Creating Kubernetes cluster with kind...${NC}"

# Check if cluster already exists
if kind get clusters | grep -q "k8s-interview"; then
    echo -e "${YELLOW}⚠️  Cluster 'k8s-interview' already exists. Deleting it first...${NC}"
    kind delete cluster --name k8s-interview
fi

# Create cluster configuration
CLUSTER_CONFIG=$(mktemp)
cat > "$CLUSTER_CONFIG" << EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: k8s-interview
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
        register-with-taints: "coreservices=true:NoSchedule"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
- role: worker
  kubeadmConfigPatches:
  - |
    kind: JoinConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        register-with-taints: "coreservices=true:NoSchedule"
- role: worker
  kubeadmConfigPatches:
  - |
    kind: JoinConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        register-with-taints: "coreservices=true:NoSchedule"
EOF

echo "📝 Cluster configuration created"

# Create the cluster
echo "🏗️  Creating cluster (this may take a few minutes)..."
kind create cluster --config "$CLUSTER_CONFIG"

# Clean up config file
rm "$CLUSTER_CONFIG"

# Set kubectl context
echo "🔧 Setting kubectl context..."
kubectl cluster-info --context kind-k8s-interview

# Wait for cluster to be ready
echo "⏳ Waiting for cluster to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=300s

# Deploy some basic resources for the assessment
echo -e "\n${YELLOW}📦 Deploying assessment resources...${NC}"

# Create namespace for exercises
kubectl create namespace k8s-interview --dry-run=client -o yaml | kubectl apply -f -

# Create a sample deployment for testing (with toleration)
kubectl create deployment nginx --image=nginx:1.21 --namespace=k8s-interview --dry-run=client -o yaml | kubectl apply -f -

# Add toleration to the nginx deployment
kubectl patch deployment nginx -n k8s-interview -p '{"spec":{"template":{"spec":{"tolerations":[{"key":"coreservices","operator":"Equal","value":"true","effect":"NoSchedule"}]}}}}'

# Create a sample service
kubectl create service clusterip nginx --tcp=80:80 --namespace=k8s-interview --dry-run=client -o yaml | kubectl apply -f -

# Wait for deployment to be ready
kubectl wait --for=condition=available deployment/nginx --namespace=k8s-interview --timeout=120s

# Install nginx ingress controller
echo -e "\n${YELLOW}🌐 Installing nginx ingress controller...${NC}"

# Add ingress-ready label to worker nodes
echo "🏷️  Adding ingress-ready labels to worker nodes..."
kubectl label nodes k8s-interview-worker ingress-ready=true
kubectl label nodes k8s-interview-worker2 ingress-ready=true


# Apply the custom nginx ingress controller manifest with tolerations
kubectl apply -f "$SCRIPT_DIR/ingress-nginx-with-tolerations.yaml"

# Wait for ingress controller to be ready
echo "⏳ Waiting for ingress controller to be ready..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=300s

echo -e "${GREEN}✅ Ingress controller installed and configured${NC}"

# Fix system components for tainted nodes
echo -e "\n${YELLOW}🔧 Configuring system components for tainted nodes...${NC}"

# Add tolerations to CoreDNS
echo "🌐 Adding tolerations to CoreDNS..."
kubectl patch deployment coredns -n kube-system -p '{"spec":{"template":{"spec":{"tolerations":[{"key":"coreservices","operator":"Equal","value":"true","effect":"NoSchedule"}]}}}}'

# Add tolerations to local-path-provisioner
echo "💾 Adding tolerations to local-path-provisioner..."
kubectl patch deployment local-path-provisioner -n local-path-storage -p '{"spec":{"template":{"spec":{"tolerations":[{"key":"coreservices","operator":"Equal","value":"true","effect":"NoSchedule"}]}}}}'

# Wait for system components to be ready
echo "⏳ Waiting for system components to be ready..."
kubectl wait --for=condition=available deployment/coredns --namespace=kube-system --timeout=120s
kubectl wait --for=condition=available deployment/local-path-provisioner --namespace=local-path-storage --timeout=120s

echo -e "${GREEN}✅ System components configured for tainted nodes${NC}"

# Create exercises directory structure
echo -e "\n${YELLOW}📁 Creating exercise directory structure...${NC}"
EXERCISES_DIR="$(dirname "$SCRIPT_DIR")/exercises"
mkdir -p "$EXERCISES_DIR"/{01-basics,02-deployments,03-services,04-configmaps-secrets,05-persistent-volumes,06-networking,07-monitoring,08-troubleshooting}

# Create a sample exercise
cat > "$EXERCISES_DIR/01-basics/README.md" << 'EOF'
# Exercise 1: Kubernetes Basics

## Objective
Get familiar with basic Kubernetes commands and concepts.

## Tasks
1. List all pods in the cluster
2. Describe the nginx deployment
3. Get logs from the nginx pod
4. Scale the nginx deployment to 3 replicas
5. Delete the nginx deployment

## Commands to try
```bash
kubectl get pods -A
kubectl describe deployment nginx -n k8s-interview
kubectl logs -l app=nginx -n k8s-interview
kubectl scale deployment nginx --replicas=3 -n k8s-interview
kubectl delete deployment nginx -n k8s-interview
```

## Verification
- All commands should execute without errors
- You should see 3 nginx pods running after scaling
- The deployment should be deleted successfully
EOF

# Display cluster information
echo -e "\n${GREEN}🎉 Setup completed successfully!${NC}"
echo "=================================================="
echo -e "${BLUE}Cluster Information:${NC}"
echo "  Name: k8s-interview"
echo "  Context: kind-k8s-interview"
echo "  Nodes: 3 (1 control-plane, 2 workers)"
echo "  Taints: All nodes have 'coreservices=true:NoSchedule' taint"
echo "  Ingress: nginx ingress controller installed and configured"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo "1. Run: ./verify-setup.sh to verify everything is working"
echo "2. Start with exercises in the exercises/ directory"
echo "3. Use: kubectl config use-context kind-k8s-interview"
echo ""
echo -e "${BLUE}Useful Commands:${NC}"
echo "  kubectl get nodes"
echo "  kubectl get pods -A"
echo "  kubectl get services -A"
echo "  kubectl get ingress -A"
echo "  kubectl get pods -n ingress-nginx"
echo ""
echo -e "${YELLOW}Happy learning! 🚀${NC}"
