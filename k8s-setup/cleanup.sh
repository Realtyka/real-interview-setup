#!/bin/bash

# cleanup.sh
# Script to clean up the Kubernetes cluster and resources

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧹 Cleaning up Kubernetes Interview Assessment${NC}"
echo "=============================================="

# Check if kind cluster exists
echo -e "\n${YELLOW}1. Checking for existing cluster...${NC}"
if kind get clusters | grep -q "k8s-interview"; then
    echo -e "${YELLOW}Found cluster 'k8s-interview'. Deleting...${NC}"
    kind delete cluster --name k8s-interview
    echo -e "${GREEN}✅ Cluster deleted successfully${NC}"
else
    echo -e "${GREEN}✅ No cluster found to delete${NC}"
fi

# Check for any remaining kind clusters
echo -e "\n${YELLOW}2. Checking for other kind clusters...${NC}"
REMAINING_CLUSTERS=$(kind get clusters 2>/dev/null | wc -l)
if [ "$REMAINING_CLUSTERS" -gt 0 ]; then
    echo -e "${YELLOW}Found $REMAINING_CLUSTERS other kind cluster(s):${NC}"
    kind get clusters
    echo -e "${YELLOW}These clusters were not created by this assessment and will be left running.${NC}"
else
    echo -e "${GREEN}✅ No other kind clusters found${NC}"
fi

# Clean up Docker resources (optional)
echo -e "\n${YELLOW}3. Cleaning up Docker resources...${NC}"
echo "This will remove unused Docker images and containers."
read -p "Do you want to clean up Docker resources? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Cleaning up unused Docker resources..."
    docker system prune -f
    echo -e "${GREEN}✅ Docker cleanup completed${NC}"
else
    echo -e "${YELLOW}⚠️  Skipping Docker cleanup${NC}"
fi

# Reset kubectl context
echo -e "\n${YELLOW}4. Resetting kubectl context...${NC}"
if kubectl config get-contexts | grep -q "kind-k8s-interview"; then
    kubectl config delete-context kind-k8s-interview 2>/dev/null || true
    echo -e "${GREEN}✅ Removed kind-k8s-interview context${NC}"
else
    echo -e "${GREEN}✅ Context already removed${NC}"
fi

# Display current kubectl context
CURRENT_CONTEXT=$(kubectl config current-context 2>/dev/null || echo "none")
echo -e "${BLUE}Current kubectl context: $CURRENT_CONTEXT${NC}"

echo -e "\n${GREEN}🎉 Cleanup completed!${NC}"
echo "=============================================="
echo -e "${BLUE}Summary:${NC}"
echo "✅ Kubernetes cluster deleted"
echo "✅ kubectl context removed"
echo "✅ Docker resources cleaned (if requested)"
echo ""
echo -e "${YELLOW}Note:${NC} Docker and kubectl installations remain on your system."
echo "To completely remove them, you'll need to uninstall them manually."
echo ""
echo -e "${BLUE}To start fresh:${NC}"
echo "Run: ./setup-cluster.sh"
