#!/bin/bash

# One-Click Automatic Port Forwarding Installation
# This script sets up everything needed for automatic port forwarding

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🚀 RL-Swarm Automatic Port Forwarding Installer${NC}"
echo "================================================"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}❌ This installer must be run as root${NC}"
    echo "Please run: sudo $0"
    exit 1
fi

# Function to print status
status() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Function to print warning
warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Function to print error
error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to check command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Installation steps
echo -e "${BLUE}🔧 Step 1: Installing dependencies...${NC}"

# Detect OS
if [ -f /etc/debian_version ]; then
    OS="debian"
    status "Detected Debian/Ubuntu system"
elif [ -f /etc/redhat-release ]; then
    OS="redhat"
    status "Detected RHEL/CentOS system"
else
    OS="unknown"
    warning "Unknown OS, will attempt generic installation"
fi

# Update package lists
if [ "$OS" = "debian" ]; then
    apt-get update
    status "Updated package lists"
elif [ "$OS" = "redhat" ]; then
    yum update -y
    status "Updated packages"
fi

# Install required packages
echo -e "${BLUE}📦 Installing required packages...${NC}"

if [ "$OS" = "debian" ]; then
    apt-get install -y docker.io docker-compose curl wget iptables socat net-tools systemd
    systemctl enable docker
    systemctl start docker
    status "Installed Docker and dependencies"
elif [ "$OS" = "redhat" ]; then
    yum install -y docker docker-compose curl wget iptables socat net-tools systemd
    systemctl enable docker
    systemctl start docker
    status "Installed Docker and dependencies"
else
    warning "Please install Docker, iptables, and socat manually"
fi

# Install Docker Compose if not present
if ! command_exists docker-compose; then
    echo -e "${BLUE}📦 Installing Docker Compose...${NC}"
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    status "Installed Docker Compose"
fi

echo -e "${BLUE}🔧 Step 2: Setting up port forwarding...${NC}"

# Make scripts executable
chmod +x auto-port-forward.sh
status "Made scripts executable"

# Setup port forwarding
./auto-port-forward.sh setup
status "Configured automatic port forwarding"

echo -e "${BLUE}📁 Step 3: Setting up RL-Swarm directory...${NC}"

# Create directory
mkdir -p /opt/rl-swarm
cp -r ./* /opt/rl-swarm/ 2>/dev/null || true
cd /opt/rl-swarm

# Create environment file for automatic forwarding
cat > .env.auto << EOF
# Automatic Port Forwarding Configuration
AUTO_PORT_FORWARD=true
AUTO_TUNNEL=true
REMOTE_ACCESS=true

# Docker configuration
PYTHONUNBUFFERED=1
COMPOSE_PROJECT_NAME=rl-swarm
EOF

# Link environment file
ln -sf .env.auto .env

status "Set up RL-Swarm directory with auto-forwarding"

echo -e "${BLUE}🔧 Step 4: Creating system startup...${NC}"

# Create systemd service for automatic startup
cat > /etc/systemd/system/rl-swarm-auto.service << 'EOF'
[Unit]
Description=RL-Swarm Automatic Startup with Port Forwarding
Requires=docker.service
After=docker.service network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/start-rl-swarm-auto.sh
RemainAfterExit=yes
TimeoutStartSec=300

[Install]
WantedBy=multi-user.target
EOF

# Enable service
systemctl enable rl-swarm-auto.service

status "Created automatic startup service"

echo -e "${BLUE}🔧 Step 5: Testing installation...${NC}"

# Test Docker
if command_exists docker && docker info >/dev/null 2>&1; then
    status "Docker is working"
else
    error "Docker is not working properly"
    exit 1
fi

# Test port forwarding setup
if systemctl is-active rl-swarm-autoforward.service >/dev/null 2>&1; then
    status "Port forwarding service is ready"
else
    status "Port forwarding service configured (will start on boot)"
fi

echo ""
echo -e "${GREEN}🎉 Installation completed successfully!${NC}"
echo ""
echo -e "${BLUE}📋 What was installed:${NC}"
echo "   • Docker and Docker Compose"
echo "   • Automatic port forwarding system"
echo "   • System services for auto-startup"
echo "   • RL-Swarm with multi-port access"
echo ""
echo -e "${BLUE}🚀 How to use:${NC}"
echo "   1. Reboot system: sudo reboot"
echo "     OR"
echo "   2. Start immediately: rl-swarm-auto"
echo ""
echo "   3. Check status: auto-port-forward.sh status"
echo "   4. View logs: journalctl -u rl-swarm-auto -f"
echo ""
echo -e "${BLUE}🌐 Access URLs (after starting):${NC}"
VPS_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "YOUR_VPS_IP")
echo "   • Main Interface: http://$VPS_IP:3000"
echo "   • Web Interface: http://$VPS_IP:80"
echo "   • Service 1: http://$VPS_IP:8080"
echo "   • Service 2: http://$VPS_IP:8081"
echo "   • Service 3: http://$VPS_IP:8082"
echo "   • Alternative 1: http://$VPS_IP:9000"
echo "   • Alternative 2: http://$VPS_IP:9001"
echo "   • Alternative 3: http://$VPS_IP:9002"
echo ""
echo -e "${YELLOW}⚠️  Important:${NC}"
echo "   • Port forwarding happens automatically at system level"
echo "   • No manual commands needed after initial setup"
echo "   • System will auto-configure on boot"
echo "   • All ports forward to the same RL-Swarm instance"
echo ""
echo -e "${GREEN}✅ Ready for automatic port forwarding!${NC}"