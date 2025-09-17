#!/bin/bash

# install-kubectl.sh
# Script to install kubectl on macOS, Linux, and Windows (WSL2)

set -e

echo "🔧 Installing kubectl..."

# Detect OS
OS=""
ARCH=""
case "$(uname -s)" in
    Darwin*)
        OS="darwin"
        ;;
    Linux*)
        OS="linux"
        ;;
    CYGWIN*|MINGW32*|MSYS*|MINGW*)
        OS="windows"
        ;;
    *)
        echo "❌ Unsupported operating system: $(uname -s)"
        exit 1
        ;;
esac

# Detect architecture
case "$(uname -m)" in
    x86_64)
        ARCH="amd64"
        ;;
    arm64|aarch64)
        ARCH="arm64"
        ;;
    *)
        echo "❌ Unsupported architecture: $(uname -m)"
        exit 1
        ;;
esac

# Check if kubectl is already installed
if command -v kubectl &> /dev/null; then
    CURRENT_VERSION=$(kubectl version --client --short 2>/dev/null | cut -d' ' -f3 | cut -d'v' -f2)
    echo "✅ kubectl is already installed (version: $CURRENT_VERSION)"
    
    # Check if version is recent enough (1.20+)
    if [[ "$CURRENT_VERSION" =~ ^[0-9]+\.[0-9]+ ]]; then
        MAJOR=$(echo $CURRENT_VERSION | cut -d'.' -f1)
        MINOR=$(echo $CURRENT_VERSION | cut -d'.' -f2)
        if [ "$MAJOR" -gt 1 ] || ([ "$MAJOR" -eq 1 ] && [ "$MINOR" -ge 20 ]); then
            echo "✅ kubectl version is compatible"
            exit 0
        fi
    fi
    echo "⚠️  kubectl version may be outdated, continuing with installation..."
fi

# Get latest stable version
echo "📡 Fetching latest kubectl version..."
LATEST_VERSION=$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)
echo "📦 Installing kubectl version: $LATEST_VERSION"

# Download kubectl
DOWNLOAD_URL="https://storage.googleapis.com/kubernetes-release/release/${LATEST_VERSION}/bin/${OS}/${ARCH}/kubectl"
TEMP_DIR=$(mktemp -d)

echo "⬇️  Downloading kubectl from: $DOWNLOAD_URL"
curl -L "$DOWNLOAD_URL" -o "$TEMP_DIR/kubectl"

# Make executable
chmod +x "$TEMP_DIR/kubectl"

# Install kubectl
if [ "$OS" = "windows" ]; then
    # For Windows, we'll assume WSL2 or Git Bash
    INSTALL_PATH="/usr/local/bin/kubectl"
    sudo mv "$TEMP_DIR/kubectl" "$INSTALL_PATH"
else
    # For macOS and Linux
    INSTALL_PATH="/usr/local/bin/kubectl"
    sudo mv "$TEMP_DIR/kubectl" "$INSTALL_PATH"
fi

# Verify installation
if command -v kubectl &> /dev/null; then
    INSTALLED_VERSION=$(kubectl version --client --short 2>/dev/null | cut -d' ' -f3 | cut -d'v' -f2)
    echo "✅ kubectl installed successfully (version: $INSTALLED_VERSION)"
else
    echo "❌ kubectl installation failed"
    exit 1
fi

# Cleanup
rm -rf "$TEMP_DIR"

echo "🎉 kubectl installation completed!"
