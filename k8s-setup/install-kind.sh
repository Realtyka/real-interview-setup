#!/bin/bash

# install-kind.sh
# Script to install kind (Kubernetes in Docker) on macOS, Linux, and Windows (WSL2)

set -e

echo "🔧 Installing kind (Kubernetes in Docker)..."

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

# Check if kind is already installed
if command -v kind &> /dev/null; then
    CURRENT_VERSION=$(kind version | grep "kind version" | cut -d' ' -f3)
    echo "✅ kind is already installed (version: $CURRENT_VERSION)"
    exit 0
fi

# Check if Docker is running
if ! docker info &> /dev/null; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi

echo "✅ Docker is running"

# Get latest kind version
echo "📡 Fetching latest kind version..."
LATEST_VERSION=$(curl -s https://api.github.com/repos/kubernetes-sigs/kind/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
echo "📦 Installing kind version: $LATEST_VERSION"

# Download kind
DOWNLOAD_URL="https://github.com/kubernetes-sigs/kind/releases/download/${LATEST_VERSION}/kind-${OS}-${ARCH}"
TEMP_DIR=$(mktemp -d)

echo "⬇️  Downloading kind from: $DOWNLOAD_URL"
curl -L "$DOWNLOAD_URL" -o "$TEMP_DIR/kind"

# Make executable
chmod +x "$TEMP_DIR/kind"

# Install kind
if [ "$OS" = "windows" ]; then
    # For Windows, we'll assume WSL2 or Git Bash
    INSTALL_PATH="/usr/local/bin/kind"
    sudo mv "$TEMP_DIR/kind" "$INSTALL_PATH"
else
    # For macOS and Linux
    INSTALL_PATH="/usr/local/bin/kind"
    sudo mv "$TEMP_DIR/kind" "$INSTALL_PATH"
fi

# Verify installation
if command -v kind &> /dev/null; then
    INSTALLED_VERSION=$(kind version | grep "kind version" | cut -d' ' -f3)
    echo "✅ kind installed successfully (version: $INSTALLED_VERSION)"
else
    echo "❌ kind installation failed"
    exit 1
fi

# Cleanup
rm -rf "$TEMP_DIR"

echo "🎉 kind installation completed!"
