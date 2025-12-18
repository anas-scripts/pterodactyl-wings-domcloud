#!/bin/bash
# install.sh - DomCloud Pterodactyl Wings Installer
set -e

echo "==========================================="
echo "Pterodactyl Wings Installer"
echo "DomCloud Rootless Edition"
echo "==========================================="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

success() { echo -e "${GREEN}[✓]${NC} $1"; }
info() { echo -e "${YELLOW}[i]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; }

# Load configuration from DomCloud
if [ -f .env ]; then
    source .env
fi

# Set defaults
PANEL_URL=${PTERODACTYL_PANEL_URL:-https://panel.example.com}
NODE_TOKEN=${PTERODACTYL_NODE_TOKEN:-}
NODE_ID=${PTERODACTYL_NODE_ID:-1}
TIMEZONE=${TZ:-Asia/Riyadh}
DOMAIN=${DOMAIN:-}

# Step 1: Install Rootless Docker
info "Step 1: Installing Rootless Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com/rootless | sh
    export PATH="$HOME/bin:$PATH"
    export DOCKER_HOST="unix:///run/user/$(id -u)/docker.sock"
    
    # Add to .bashrc
    echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
    echo 'export DOCKER_HOST="unix:///run/user/$(id -u)/docker.sock"' >> ~/.bashrc
    source ~/.bashrc
    success "Rootless Docker installed"
else
    success "Docker already installed"
fi

# Step 2: Start Docker daemon
info "Step 2: Starting Docker daemon..."
if ! pgrep -f "dockerd-rootless" > /dev/null; then
    dockerd-rootless.sh --experimental > /dev/null 2>&1 &
    sleep 5
    success "Docker daemon started"
else
    success "Docker daemon already running"
fi

# Step 3: Create directory structure
info "Step 3: Creating directories..."
mkdir -p ~/etc/pterodactyl
mkdir -p ~/var/lib/pterodactyl
mkdir -p ~/var/log/pterodactyl
mkdir -p ~/tmp/pterodactyl
success "Directories created"

# Step 4: Create docker-compose.yml
info "Step 4: Configuring Docker Compose..."
if [ -f docker-compose.example.yml ]; then
    cp -f docker-compose.example.yml docker-compose.yml
    
    # Replace variables
    sed -i "s|\${HOME}|$HOME|g" docker-compose.yml
    sed -i "s|\${UID:-1000}|$(id -u)|g" docker-compose.yml
    sed -i "s|\${GID:-1000}|$(id -g)|g" docker-compose.yml
    sed -i "s|/run/user/\${UID:-1000}/docker.sock|/run/user/$(id -u)/docker.sock|g" docker-compose.yml
    
    success "Docker Compose configured"
fi

# Step 5: Create config.yml
info "Step 5: Creating Wings configuration..."
if [ ! -z "$NODE_TOKEN" ]; then
    cat > ~/etc/pterodactyl/config.yml << EOF
panel: "${PANEL_URL}"
token: "${NODE_TOKEN}"
node: ${NODE_ID}
uuid: "$(cat /proc/sys/kernel/random/uuid 2>/dev/null || echo $(uuidgen))"
remote: "${PANEL_URL}"
ssl:
  enabled: ${DOMAIN:+true}
  cert: ""
  key: ""
upload_limit: 100

docker:
  socket: "/run/user/$(id -u)/docker.sock"
  network:
    name: "bridge"
  network_mode: "bridge"
  container:
    network_mode: "bridge"
  dns:
    - "1.1.1.1"
    - "1.0.0.1"

system:
  data: "$HOME/var/lib/pterodactyl"
  sftp:
    bind_port: 2022
    path: "$HOME/var/lib/pterodactyl/volumes"
  username: "pterodactyl"

allowed_mounts: []
EOF
    success "Configuration created at ~/etc/pterodactyl/config.yml"
else
    cat > ~/etc/pterodactyl/config.yml << EOF
# Pterodactyl Wings Configuration
# Please replace with your actual configuration from Panel

panel: "https://YOUR_PANEL_URL"
token: "YOUR_NODE_TOKEN_HERE"
node: 1

# Get these values from:
# Panel → Nodes → Your Node → Configuration
EOF
    info "Empty configuration created. Please update ~/etc/pterodactyl/config.yml"
fi

# Step 6: Start services
info "Step 6: Starting Pterodactyl Wings..."
docker compose up -d

# Step 7: Verify installation
info "Step 7: Verifying installation..."
sleep 3

if docker compose ps | grep -q "Up"; then
    success "Pterodactyl Wings is running!"
    
    # Get container info
    CONTAINER_ID=$(docker compose ps -q wings)
    PORT=$(docker port $CONTAINER_ID 8080 | cut -d: -f2)
    
    echo ""
    echo "==========================================="
    echo "INSTALLATION SUCCESSFUL!"
    echo "==========================================="
    echo "Wings API: http://127.0.0.1:${PORT:-15196}"
    echo "SFTP Port: 2022"
    echo "Panel URL: ${PANEL_URL}"
    echo "Node ID: ${NODE_ID}"
    echo ""
    echo "Next steps:"
    echo "1. Check status: docker compose ps"
    echo "2. View logs: docker compose logs -f wings"
    echo "3. Test connection: curl http://127.0.0.1:${PORT:-15196}/api/health"
    echo "==========================================="
else
    error "Wings failed to start. Check logs: docker compose logs wings"
    exit 1
fi
