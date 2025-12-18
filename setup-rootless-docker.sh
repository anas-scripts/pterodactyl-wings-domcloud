#!/bin/bash
# setup-rootless-docker.sh
set -e

echo "Setting up Rootless Docker for DomCloud..."

# Check if already installed
if command -v docker &> /dev/null && docker info 2>/dev/null | grep -q "Rootless: true"; then
    echo "✓ Rootless Docker already installed and running"
    exit 0
fi

# Install dependencies
if [ -f /etc/debian_version ]; then
    sudo apt-get update
    sudo apt-get install -y uidmap dbus-user-session
elif [ -f /etc/redhat-release ]; then
    sudo yum install -y shadow-utils
fi

# Install Rootless Docker
curl -fsSL https://get.docker.com/rootless | sh

# Set environment variables
export PATH="$HOME/bin:$PATH"
export DOCKER_HOST="unix:///run/user/$(id -u)/docker.sock"
export XDG_RUNTIME_DIR="/run/user/$(id -u)"

# Make permanent
cat >> ~/.bashrc << EOF
# Rootless Docker
export PATH="\$HOME/bin:\$PATH"
export DOCKER_HOST="unix:///run/user/\$(id -u)/docker.sock"
export XDG_RUNTIME_DIR="/run/user/\$(id -u)"
EOF

# Start Docker daemon
systemctl --user start docker
systemctl --user enable docker

# Verify
if docker info 2>/dev/null | grep -q "Rootless: true"; then
    echo "✓ Rootless Docker installed successfully"
else
    echo "⚠ Docker installed but not running. Starting manually..."
    dockerd-rootless.sh --experimental &
    sleep 5
    docker info | grep "Rootless"
fi
