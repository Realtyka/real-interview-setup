#!/bin/bash

# verify-setup.sh
# Script to verify that the Kubernetes cluster setup is working correctly

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 Verifying Kubernetes Interview Assessment Setup${NC}"
echo "======================================================"

# Check if kubectl is installed
echo -e "\n${YELLOW}1. Checking kubectl installation...${NC}"
if command -v kubectl &> /dev/null; then
    KUBECTL_VERSION=$(kubectl version --client --short 2>/dev/null | cut -d' ' -f3 | cut -d'v' -f2)
    echo -e "${GREEN}✅ kubectl is installed (version: $KUBECTL_VERSION)${NC}"
else
    echo -e "${RED}❌ kubectl is not installed${NC}"
    exit 1
fi

# Check if kind is installed
echo -e "\n${YELLOW}2. Checking kind installation...${NC}"
if command -v kind &> /dev/null; then
    KIND_VERSION=$(kind version | grep "kind version" | cut -d' ' -f3)
    echo -e "${GREEN}✅ kind is installed (version: $KIND_VERSION)${NC}"
else
    echo -e "${RED}❌ kind is not installed${NC}"
    exit 1
fi

# Check if Docker is running
echo -e "\n${YELLOW}3. Checking Docker status...${NC}"
if docker info &> /dev/null; then
    echo -e "${GREEN}✅ Docker is running${NC}"
else
    echo -e "${RED}❌ Docker is not running${NC}"
    exit 1
fi

# Check if cluster exists
echo -e "\n${YELLOW}4. Checking Kubernetes cluster...${NC}"
if kind get clusters | grep -q "k8s-interview"; then
    echo -e "${GREEN}✅ Cluster 'k8s-interview' exists${NC}"
else
    echo -e "${RED}❌ Cluster 'k8s-interview' not found${NC}"
    echo "Run ./setup-cluster.sh first"
    exit 1
fi

# Set kubectl context
echo -e "\n${YELLOW}5. Setting kubectl context...${NC}"
kubectl config use-context kind-k8s-interview
echo -e "${GREEN}✅ Context set to kind-k8s-interview${NC}"

# Check cluster connectivity
echo -e "\n${YELLOW}6. Testing cluster connectivity...${NC}"
if kubectl cluster-info &> /dev/null; then
    echo -e "${GREEN}✅ Cluster is accessible${NC}"
else
    echo -e "${RED}❌ Cannot connect to cluster${NC}"
    exit 1
fi

# Check nodes
echo -e "\n${YELLOW}7. Checking cluster nodes...${NC}"
NODE_COUNT=$(kubectl get nodes --no-headers | wc -l)
if [ "$NODE_COUNT" -eq 3 ]; then
    echo -e "${GREEN}✅ All 3 nodes are present${NC}"
    kubectl get nodes
else
    echo -e "${RED}❌ Expected 3 nodes, found $NODE_COUNT${NC}"
    kubectl get nodes
fi

# Check if nodes are ready
echo -e "\n${YELLOW}8. Checking node status...${NC}"
READY_NODES=$(kubectl get nodes --no-headers | grep "Ready" | wc -l)
if [ "$READY_NODES" -eq 3 ]; then
    echo -e "${GREEN}✅ All nodes are in Ready state${NC}"
else
    echo -e "${YELLOW}⚠️  Only $READY_NODES out of 3 nodes are ready${NC}"
    kubectl get nodes
fi

# Check system pods
echo -e "\n${YELLOW}9. Checking system pods...${NC}"
SYSTEM_PODS=$(kubectl get pods -n kube-system --no-headers | wc -l)
if [ "$SYSTEM_PODS" -gt 0 ]; then
    echo -e "${GREEN}✅ System pods are running ($SYSTEM_PODS pods)${NC}"
else
    echo -e "${RED}❌ No system pods found${NC}"
fi

# Check assessment namespace
echo -e "\n${YELLOW}10. Checking assessment namespace...${NC}"
if kubectl get namespace k8s-interview &> /dev/null; then
    echo -e "${GREEN}✅ Assessment namespace exists${NC}"
    
    # Check nginx deployment
    if kubectl get deployment nginx -n k8s-interview &> /dev/null; then
        echo -e "${GREEN}✅ Sample nginx deployment exists${NC}"
        
        # Check if deployment is ready
        READY_REPLICAS=$(kubectl get deployment nginx -n k8s-interview -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
        DESIRED_REPLICAS=$(kubectl get deployment nginx -n k8s-interview -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "0")
        
        if [ "$READY_REPLICAS" -eq "$DESIRED_REPLICAS" ] && [ "$DESIRED_REPLICAS" -gt 0 ]; then
            echo -e "${GREEN}✅ nginx deployment is ready ($READY_REPLICAS/$DESIRED_REPLICAS replicas)${NC}"
        else
            echo -e "${YELLOW}⚠️  nginx deployment is not ready ($READY_REPLICAS/$DESIRED_REPLICAS replicas)${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Sample nginx deployment not found${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Assessment namespace not found${NC}"
fi

# Test basic kubectl commands
echo -e "\n${YELLOW}11. Testing basic kubectl commands...${NC}"

# Test get pods
if kubectl get pods -A &> /dev/null; then
    echo -e "${GREEN}✅ 'kubectl get pods -A' works${NC}"
else
    echo -e "${RED}❌ 'kubectl get pods -A' failed${NC}"
fi

# Test get services
if kubectl get services -A &> /dev/null; then
    echo -e "${GREEN}✅ 'kubectl get services -A' works${NC}"
else
    echo -e "${RED}❌ 'kubectl get services -A' failed${NC}"
fi

# Test get nodes
if kubectl get nodes &> /dev/null; then
    echo -e "${GREEN}✅ 'kubectl get nodes' works${NC}"
else
    echo -e "${RED}❌ 'kubectl get nodes' failed${NC}"
fi

# Display cluster information
echo -e "\n${BLUE}📊 Cluster Information:${NC}"
echo "========================"
kubectl cluster-info
echo ""
echo -e "${BLUE}📋 Node Status:${NC}"
kubectl get nodes -o wide
echo ""
echo -e "${BLUE}📦 Pods in k8s-interview namespace:${NC}"
kubectl get pods -n k8s-interview -o wide
echo ""

echo -e "\n${BLUE}🏷️  Node Taints:${NC}"
kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.taints}{"\n"}{end}' | column -t
echo ""


# Summary
echo -e "\n${GREEN}🎉 Verification completed!${NC}"
echo "======================================================"

if [ "$READY_NODES" -eq 3 ] && [ "$SYSTEM_PODS" -gt 0 ]; then
    echo -e "${GREEN}✅ All checks passed! Your Kubernetes cluster is ready for the assessment.${NC}"
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo "1. Navigate to the exercises/ directory"
    echo "2. Start with 01-basics/README.md"
    echo "3. Use 'kubectl config use-context kind-k8s-interview' to ensure you're using the right cluster"
    echo ""
    echo -e "${BLUE}Useful commands:${NC}"
    echo "  kubectl get pods -A"
    echo "  kubectl get services -A"
    echo "  kubectl get nodes"
    echo "  kubectl describe <resource> <name>"
    echo ""
    echo -e "${YELLOW}Happy learning! 🚀${NC}"
else
    echo -e "${YELLOW}⚠️  Some checks failed. Please review the output above and run ./setup-cluster.sh again if needed.${NC}"
    exit 1
fi
