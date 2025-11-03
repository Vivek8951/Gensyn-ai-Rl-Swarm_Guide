#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default port configuration
DEFAULT_RL_SWARM_PORT=3000
DEFAULT_WEB_PORT=80
DEFAULT_HTTPS_PORT=443
DEFAULT_SERVICE_PORT_1=8080
DEFAULT_SERVICE_PORT_2=8081
DEFAULT_SERVICE_PORT_3=8082
DEFAULT_ALT_PORT_1=9000
DEFAULT_ALT_PORT_2=9001
DEFAULT_ALT_PORT_3=9002
DEFAULT_SSH_TUNNEL_PORT=2223

echo -e "${BLUE}🌐 RL-Swarm Port Manager for VPS/Cloud Instances${NC}"
echo "======================================================"
echo ""

# Function to show usage
show_usage() {
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  setup               Setup multi-port environment"
    echo "  start               Start all port forwarding services"
    echo "  stop                Stop all services"
    echo "  status              Show port status"
    echo "  forward <port>      Forward specific port to RL-Swarm"
    echo "  tunnel <host:port>  Create SSH tunnel to remote service"
    echo "  list                List all active forwards and tunnels"
    echo "  config              Show current configuration"
    echo "  ssl                 Generate self-signed SSL certificates"
    echo "  cleanup             Clean up port forwarding rules"
    echo ""
    echo "Examples:"
    echo "  $0 setup                           # Setup multi-port environment"
    echo "  $0 forward 9999                    # Forward port 9999 to RL-Swarm"
    echo "  $0 tunnel database.example.com:5432 # Tunnel to remote database"
    echo "  $0 status                          # Show all port status"
    echo ""
}

# Function to create environment file for multi-port setup
setup_multiport() {
    echo -e "${GREEN}🔧 Setting up multi-port environment...${NC}"

    # Get VPS IP
    VPS_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "YOUR_VPS_IP")

    # Create multi-port environment file
    cat > .env.multiport << EOF
# Multi-Port RL-Swarm Configuration for VPS
# Generated on $(date)

# Main RL-Swarm port
RL_SWARM_PORT=${1:-$DEFAULT_RL_SWARM_PORT}

# Web server ports
WEB_PORT=${2:-$DEFAULT_WEB_PORT}
HTTPS_PORT=${3:-$DEFAULT_HTTPS_PORT}

# Additional service ports
SERVICE_PORT_1=${4:-$DEFAULT_SERVICE_PORT_1}
SERVICE_PORT_2=${5:-$DEFAULT_SERVICE_PORT_2}
SERVICE_PORT_3=${6:-$DEFAULT_SERVICE_PORT_3}

# Alternative access ports
ALT_PORT_1=${7:-$DEFAULT_ALT_PORT_1}
ALT_PORT_2=${8:-$DEFAULT_ALT_PORT_2}
ALT_PORT_3=${9:-$DEFAULT_ALT_PORT_3}

# SSH tunnel configuration
SSH_TUNNEL_PORT=${10:-$DEFAULT_SSH_TUNNEL_PORT}
SSH_FORWARD_HOST=${SSH_FORWARD_HOST:-}
SSH_FORWARD_PORT=${SSH_FORWARD_PORT:-}
SSH_USER=${SSH_USER:-root}

# Tunnel settings
AUTO_TUNNEL=true
REMOTE_ACCESS=true
TUNNEL_DOMAIN=${TUNNEL_DOMAIN:-}
CLOUDFLARE_TUNNEL_TOKEN=${CLOUDFLARE_TUNNEL_TOKEN:-}

# VPS Information
VPS_IP=${VPS_IP}
EOF

    echo -e "${GREEN}✓ Created .env.multiport configuration${NC}"
    echo ""
    echo -e "${YELLOW}📋 Port Configuration:${NC}"
    echo "   RL-Swarm Interface: http://${VPS_IP}:${1:-$DEFAULT_RL_SWARM_PORT}"
    echo "   Web Interface: http://${VPS_IP}:${2:-$DEFAULT_WEB_PORT}"
    echo "   Service 1: http://${VPS_IP}:${4:-$DEFAULT_SERVICE_PORT_1}"
    echo "   Service 2: http://${VPS_IP}:${5:-$DEFAULT_SERVICE_PORT_2}"
    echo "   Service 3: http://${VPS_IP}:${6:-$DEFAULT_SERVICE_PORT_3}"
    echo "   Alternative 1: http://${VPS_IP}:${7:-$DEFAULT_ALT_PORT_1}"
    echo "   Alternative 2: http://${VPS_IP}:${8:-$DEFAULT_ALT_PORT_2}"
    echo "   Alternative 3: http://${VPS_IP}:${9:-$DEFAULT_ALT_PORT_3}"
    echo "   SSH Tunnel: ${VPS_IP}:${10:-$DEFAULT_SSH_TUNNEL_PORT}"
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo "  1. Copy environment: cp .env.multiport .env"
    echo "  2. Start services: $0 start"
    echo "  3. Check status: $0 status"
    echo ""
}

# Function to start multi-port services
start_services() {
    echo -e "${GREEN}🚀 Starting multi-port services...${NC}"

    if [ ! -f ".env" ]; then
        echo -e "${RED}❌ Error: .env file not found. Run '$0 setup' first.${NC}"
        exit 1
    fi

    # Use multi-port docker-compose file
    docker-compose -f docker-compose.ports.yml up -d

    echo -e "${GREEN}✓ Services started successfully${NC}"
    echo ""
    echo -e "${BLUE}🔗 Access URLs:${NC}"
    show_access_urls
}

# Function to stop services
stop_services() {
    echo -e "${YELLOW}🛑 Stopping multi-port services...${NC}"

    docker-compose -f docker-compose.ports.yml down

    echo -e "${GREEN}✓ Services stopped${NC}"
}

# Function to show port status
show_status() {
    echo -e "${BLUE}📊 Port Status Report${NC}"
    echo "====================="
    echo ""

    # Check if containers are running
    if docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -q "rl-swarm"; then
        echo -e "${GREEN}🟢 RL-Swarm Services Running:${NC}"
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep rl-swarm
        echo ""
    else
        echo -e "${RED}🔴 RL-Swarm Services Not Running${NC}"
        echo ""
    fi

    # Show port usage
    echo -e "${BLUE}🔌 Port Usage:${NC}"
    netstat -tlnp 2>/dev/null | grep -E ":(3000|80|443|8080|8081|8082|9000|9001|9002|222[0-9])" || echo "No active ports found"
    echo ""

    # Show access URLs if environment exists
    if [ -f ".env" ]; then
        show_access_urls
    fi
}

# Function to show access URLs
show_access_urls() {
    if [ ! -f ".env" ]; then
        return
    fi

    source .env
    VPS_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "YOUR_VPS_IP")

    echo -e "${BLUE}🌐 Access URLs:${NC}"
    echo "   Main RL-Swarm: http://${VPS_IP}:${RL_SWARM_PORT:-3000}"
    echo "   Web Interface: http://${VPS_IP}:${WEB_PORT:-80}"
    [ -n "${HTTPS_PORT:-}" ] && echo "   HTTPS Interface: https://${VPS_IP}:${HTTPS_PORT:-443}"
    [ -n "${SERVICE_PORT_1:-}" ] && echo "   Service 1: http://${VPS_IP}:${SERVICE_PORT_1}"
    [ -n "${SERVICE_PORT_2:-}" ] && echo "   Service 2: http://${VPS_IP}:${SERVICE_PORT_2}"
    [ -n "${SERVICE_PORT_3:-}" ] && echo "   Service 3: http://${VPS_IP}:${SERVICE_PORT_3}"
    [ -n "${ALT_PORT_1:-}" ] && echo "   Alternative 1: http://${VPS_IP}:${ALT_PORT_1}"
    [ -n "${ALT_PORT_2:-}" ] && echo "   Alternative 2: http://${VPS_IP}:${ALT_PORT_2}"
    [ -n "${ALT_PORT_3:-}" ] && echo "   Alternative 3: http://${VPS_IP}:${ALT_PORT_3}"
    [ -n "${SSH_TUNNEL_PORT:-}" ] && echo "   SSH Tunnel: ssh -p ${SSH_TUNNEL_PORT} user@${VPS_IP}"
    echo ""
}

# Function to forward specific port
forward_port() {
    local port=$1
    if [ -z "$port" ]; then
        echo -e "${RED}❌ Error: Please specify a port to forward${NC}"
        echo "Usage: $0 forward <port>"
        return 1
    fi

    echo -e "${GREEN}🔗 Forwarding port ${port} to RL-Swarm...${NC}"

    # Create a simple socat forwarder
    docker run -d --name port-forward-${port} \
        --network container:rl-swarm-node \
        alpine/socat \
        socat TCP4-LISTEN:${port},fork,reuseaddr TCP4:localhost:3000

    echo -e "${GREEN}✓ Port ${port} forwarded to RL-Swarm${NC}"
    echo "   Access at: http://$(curl -s ifconfig.me 2>/dev/null || echo 'YOUR_VPS_IP'):${port}"
}

# Function to create SSH tunnel
create_ssh_tunnel() {
    local target=$1
    if [ -z "$target" ]; then
        echo -e "${RED}❌ Error: Please specify target host:port${NC}"
        echo "Usage: $0 tunnel <host:port>"
        return 1
    fi

    local host=$(echo "$target" | cut -d':' -f1)
    local remote_port=$(echo "$target" | cut -d':' -f2)
    local local_port=${2:-2223}

    echo -e "${GREEN}🔐 Creating SSH tunnel to ${target}...${NC}"

    # Create SSH tunnel container
    docker run -d --name ssh-tunnel-${local_port} \
        -p ${local_port}:${local_port} \
        -e SSH_HOST="$host" \
        -e SSH_REMOTE_PORT="$remote_port" \
        -e SSH_LOCAL_PORT="$local_port" \
        alpine:latest \
        sh -c "
        apk add --no-cache openssh-client socat &&
        while true; do
            socat TCP4-LISTEN:${local_port},fork,reuseaddr EXEC:'ssh -W \${SSH_HOST}:\${SSH_REMOTE_PORT} \${SSH_HOST}'
            sleep 5
        done
        "

    echo -e "${GREEN}✓ SSH tunnel created${NC}"
    echo "   Local access: localhost:${local_port} -> ${target}"
}

# Function to generate SSL certificates
generate_ssl() {
    echo -e "${GREEN}🔒 Generating SSL certificates...${NC}"

    mkdir -p ssl

    # Generate private key
    openssl genrsa -out ssl/key.pem 2048

    # Generate certificate
    openssl req -new -x509 -key ssl/key.pem -out ssl/cert.pem -days 365 \
        -subj "/C=US/ST=State/L=City/O=Organization/CN=$(curl -s ifconfig.me 2>/dev/null || echo 'localhost')"

    echo -e "${GREEN}✓ SSL certificates generated in ssl/ directory${NC}"
    echo "   Key: ssl/key.pem"
    echo "   Cert: ssl/cert.pem"
}

# Function to cleanup
cleanup() {
    echo -e "${YELLOW}🧹 Cleaning up port forwarding...${NC}"

    # Stop and remove port forwarding containers
    docker ps --filter "name=port-forward-" --format "{{.Names}}" | xargs -r docker stop
    docker ps --filter "name=port-forward-" --format "{{.Names}}" | xargs -r docker rm

    # Stop and remove SSH tunnel containers
    docker ps --filter "name=ssh-tunnel-" --format "{{.Names}}" | xargs -r docker stop
    docker ps --filter "name=ssh-tunnel-" --format "{{.Names}}" | xargs -r docker rm

    # Stop main services
    docker-compose -f docker-compose.ports.yml down

    echo -e "${GREEN}✓ Cleanup completed${NC}"
}

# Function to show configuration
show_config() {
    echo -e "${BLUE}⚙️ Current Configuration${NC}"
    echo "=========================="
    echo ""

    if [ -f ".env" ]; then
        echo -e "${GREEN}Environment variables:${NC}"
        cat .env | grep -E "PORT|HOST|DOMAIN|TUNNEL" | sort
        echo ""
    else
        echo -e "${YELLOW}No .env file found${NC}"
    fi

    if [ -f "docker-compose.ports.yml" ]; then
        echo -e "${GREEN}Docker Compose services:${NC}"
        docker-compose -f docker-compose.ports.yml config --services
        echo ""
    fi
}

# Main command handling
case "$1" in
    setup)
        setup_multiport "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9" "${10}"
        ;;
    start)
        start_services
        ;;
    stop)
        stop_services
        ;;
    status)
        show_status
        ;;
    forward)
        forward_port "$2"
        ;;
    tunnel)
        create_ssh_tunnel "$2" "$3"
        ;;
    list)
        echo -e "${BLUE}📋 Active Port Forwards:${NC}"
        docker ps --filter "name=port-forward-" --format "table {{.Names}}\t{{.Ports}}"
        echo ""
        echo -e "${BLUE}🔐 Active SSH Tunnels:${NC}"
        docker ps --filter "name=ssh-tunnel-" --format "table {{.Names}}\t{{.Ports}}"
        ;;
    config)
        show_config
        ;;
    ssl)
        generate_ssl
        ;;
    cleanup)
        cleanup
        ;;
    *)
        show_usage
        exit 1
        ;;
esac