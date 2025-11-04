#!/bin/bash

# Run Pre-built RL-Swarm Docker Container
# Instant startup - no downloads needed

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
DOCKER_USER="${DOCKER_USER:-viveks895}"
IMAGE_NAME="${DOCKER_USER}/gensyn-rl-swarm-prebuilt"
TAG="${TAG:-latest}"
CONTAINER_NAME="rl-swarm-prebuilt"

# Get host IP
HOST_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "YOUR_VPS_IP")

echo -e "${BLUE}🚀 Running Pre-built RL-Swarm Container${NC}"
echo "========================================"
echo ""

echo -e "${CYAN}📦 PRE-BUILT STATUS:${NC}"
echo "   • Git repository: Pre-cloned in Docker image"
echo "   • Node.js modules: Pre-installed in Docker image"
echo "   • Python environment: Pre-built in Docker image"
echo "   • Startup time: Instant (no downloads)"
echo ""

echo -e "${CYAN}🌐 ACCESS URLS:${NC}"
echo "========================"
echo ""

echo -e "${YELLOW}📍 Primary Access:${NC}"
echo "   Main Interface: ${GREEN}http://${HOST_IP}:3000${NC}"
echo ""

echo -e "${YELLOW}🔗 Alternative Ports:${NC}"
echo "   Port 8080: ${GREEN}http://${HOST_IP}:8080${NC} → RL-Swarm"
echo "   Port 8081: ${GREEN}http://${HOST_IP}:8081${NC} → RL-Swarm"
echo "   Port 8082: ${GREEN}http://${HOST_IP}:8082${NC} → RL-Swarm"
echo "   Port 9000: ${GREEN}http://${HOST_IP}:9000${NC} → RL-Swarm"
echo "   Port 9001: ${GREEN}http://${HOST_IP}:9001${NC} → RL-Swarm"
echo "   Port 9002: ${GREEN}http://${HOST_IP}:9002${NC} → RL-Swarm"
echo ""

echo -e "${BLUE}🚀 Starting pre-built container...${NC}"
echo ""

# Pull the latest pre-built image
echo "📥 Pulling pre-built image: ${IMAGE_NAME}:${TAG}"
docker pull "${IMAGE_NAME}:${TAG}"

# Check if container already exists
if docker ps -a --format 'table {{.Names}}' | grep -q "$CONTAINER_NAME"; then
    echo -e "${GREEN}✅ Existing container found - stopping and removing...${NC}"
    docker stop "$CONTAINER_NAME" 2>/dev/null || true
    docker rm "$CONTAINER_NAME" 2>/dev/null || true
fi

# Run the pre-built container
echo "🚀 Starting new container..."
docker run -d \
    --name "$CONTAINER_NAME" \
    -p 3000:3000 \
    -p 8080:8080 \
    -p 8081:8081 \
    -p 8082:8082 \
    -p 9000:9000 \
    -p 9001:9001 \
    -p 9002:9002 \
    -e AUTO_TUNNEL=true \
    -e REMOTE_ACCESS=true \
    --restart unless-stopped \
    "${IMAGE_NAME}:${TAG}"

echo ""
echo -e "${GREEN}✅ Pre-built container started successfully!${NC}"
echo ""

# Wait a moment for startup
echo "⏳ Waiting for RL-Swarm to start..."
sleep 5

# Show container status
echo -e "${CYAN}📊 Container Status:${NC}"
docker ps --filter "name=$CONTAINER_NAME" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""

# Show logs
echo -e "${CYAN}📝 Container Logs (last 20 lines):${NC}"
docker logs --tail 20 "$CONTAINER_NAME"
echo ""

echo -e "${BLUE}🔍 Verifying RL-Swarm startup...${NC}"
sleep 10

# Check if RL-Swarm is responding
if curl -s http://localhost:3000 >/dev/null 2>&1; then
    echo -e "${GREEN}✅ RL-Swarm is responding on port 3000${NC}"
else
    echo -e "${YELLOW}⏳ RL-Swarm still starting... (this is normal for first-time setup)${NC}"
fi

echo ""
echo -e "${BLUE}🔄 Management Commands:${NC}"
echo "   • View logs: docker logs -f $CONTAINER_NAME"
echo "   • Stop: docker stop $CONTAINER_NAME"
echo "   • Start: docker start $CONTAINER_NAME"
echo "   • Restart: docker restart $CONTAINER_NAME"
echo "   • Remove: docker rm $CONTAINER_NAME"
echo ""

echo -e "${BLUE}📝 View Real-time Logs:${NC}"
echo "   docker logs -f $CONTAINER_NAME"
echo ""

echo -e "${YELLOW}🔗 Access URLs:${NC}"
echo "   ${GREEN}http://${HOST_IP}:3000${NC} - Main Interface"
echo "   ${GREEN}http://${HOST_IP}:8080${NC} - Web Access"
echo "   ${GREEN}http://${HOST_IP}:8081${NC} - Service 1"
echo "   ${GREEN}http://${HOST_IP}:8082${NC} - Service 2"
echo "   ${GREEN}http://${HOST_IP}:9000${NC} - Alternative 1"
echo "   ${GREEN}http://${HOST_IP}:9001}${NC} - Alternative 2"
echo "   ${GREEN}http://${HOST_IP}:9002}${NC} - Alternative 3"
echo ""

echo -e "${GREEN}🎉 PRE-BUILT RL-SWARM IS RUNNING!${NC}"
echo -e "${GREEN}   ⚡ Instant startup (no downloads needed!)${NC}"
echo -e "${GREEN}   📦 All dependencies pre-built in image${NC}"
echo -e "${GREEN}   🚀 Multiple access points ready${NC}"
echo ""
echo -e "${CYAN}💡 Check container logs for Cloudflare tunnel URL:${NC}"
echo "   docker logs -f $CONTAINER_NAME | grep 'https://'"
echo ""