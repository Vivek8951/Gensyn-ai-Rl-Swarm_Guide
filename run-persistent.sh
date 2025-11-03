#!/bin/bash

# RL-Swarm with Persistent Data - No repeated downloads
# Use named volumes to preserve data across container runs

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

CONTAINER_NAME="rl-swarm-persistent"
HOST_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "YOUR_VPS_IP")

echo -e "${BLUE}🚀 RL-Swarm with Persistent Data Volumes${NC}"
echo "=========================================="
echo ""
echo -e "${CYAN}🌐 PERSISTENT ACCESS URLs:${NC}"
echo "============================="
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

# Check if container already exists
if docker ps -a --format 'table {{.Names}}' | grep -q "$CONTAINER_NAME"; then
    echo -e "${GREEN}✅ Existing persistent container found${NC}"
    echo "   • Git repository preserved"
    echo "   • Node.js modules cached"
    echo "   • Virtual environment maintained"
    echo "   • No downloads needed!"
    echo ""

    echo -e "${BLUE}🔄 Starting existing container...${NC}"
    docker start "$CONTAINER_NAME"

    echo -e "${GREEN}✅ Container started with persistent data!${NC}"
else
    echo -e "${YELLOW}📦 First-time setup with persistent volumes...${NC}"
    echo "   • Git repository will be cloned once"
    echo "   • Node.js modules will be cached"
    echo "   • Virtual environment will be preserved"
    echo "   • Future starts will be instant"
    echo ""

    echo -e "${BLUE}🚀 Creating persistent container...${NC}"
    docker run -d \
        --name "$CONTAINER_NAME" \
        -p 3000:3000 \
        -p 8080:8080 \
        -p 8081:8081 \
        -p 8082:8082 \
        -p 9000:9000 \
        -p 9001:9001 \
        -p 9002:9002 \
        -v rl-swarm-repo:/home/rlswarm/rl-swarm \
        -v rl-swarm-node_modules:/home/rlswarm/rl-swarm/node_modules \
        -v rl-swarm-venv:/home/rlswarm/rl-swarm/.venv \
        -v rl-swarm-cache:/home/rlswarm/.cache \
        -e AUTO_TUNNEL=true \
        -e REMOTE_ACCESS=true \
        --restart unless-stopped \
        viveks895/gensyn-rl-swarm

    echo -e "${GREEN}✅ Persistent container created!${NC}"
    echo ""
    echo -e "${YELLOW}⏳ First-time setup in progress...${NC}"
    echo "   This will take 2-3 minutes for the initial setup"
    echo "   Future starts will be instant!"
fi

echo ""
echo -e "${CYAN}📊 Container Status:${NC}"
docker ps --filter "name=$CONTAINER_NAME" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""

echo -e "${BLUE}💾 Persistent Volumes:${NC}"
echo "   • rl-swarm-repo: Git repository cache"
echo "   • rl-swarm-node_modules: Node.js modules cache"
echo "   • rl-swarm-venv: Python virtual environment"
echo "   • rl-swarm-cache: Build cache"
echo ""

echo -e "${BLUE}📝 View Logs:${NC}"
echo "   docker logs -f $CONTAINER_NAME"
echo ""

echo -e "${BLUE}🔄 Management Commands:${NC}"
echo "   • Stop: docker stop $CONTAINER_NAME"
echo "   • Start: docker start $CONTAINER_NAME"
echo "   • Restart: docker restart $CONTAINER_NAME"
echo "   • Remove (data preserved): docker rm $CONTAINER_NAME"
echo "   • Remove all data: docker rm $CONTAINER_NAME && docker volume rm rl-swarm-repo rl-swarm-node_modules rl-swarm-venv rl-swarm-cache"
echo ""

echo -e "${YELLOW}🔗 Access URLs:${NC}"
echo "   ${GREEN}http://${HOST_IP}:3000${NC} - Main Interface"
echo "   ${GREEN}http://${HOST_IP}:8080${NC} - Web Access"
echo "   ${GREEN}http://${HOST_IP}:8081${NC} - Service 1"
echo "   ${GREEN}http://${HOST_IP}:8082${NC} - Service 2"
echo ""

echo -e "${GREEN}🎉 RL-Swarm with persistent data is starting!${NC}"
echo "   📦 First setup: 2-3 minutes (downloads once)"
echo "   🚀 Future starts: 5-10 seconds (instant)"
echo "   📊 Monitor: docker logs -f $CONTAINER_NAME"