#!/bin/bash

# Optimized RL-Swarm with Persistent Caching
# Prevents repeated installations and uses cached dependencies

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}🚀 Optimized RL-Swarm with Persistent Caching${NC}"
echo "================================================="
echo ""

# Get host IP
HOST_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "YOUR_VPS_IP")

echo -e "${CYAN}🌐 OPTIMIZED PORT FORWARDING URLs:${NC}"
echo "=========================================="
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

echo -e "${BLUE}🚀 Starting optimized container...${NC}"
echo ""

# Check if this is first run
if [ ! "$(docker ps -aq -f name=rl-swarm-optimized)" ]; then
    echo -e "${YELLOW}📦 First-time setup detected...${NC}"
    echo "   - Dependencies will be cached for future runs"
    echo "   - Repository will be cloned once"
    echo "   - Virtual environment will be preserved"
    echo ""
else
    echo -e "${GREEN}✅ Using cached dependencies...${NC}"
    echo "   - No repeated installations"
    echo "   - Preserved virtual environment"
    echo "   - Cached packages and dependencies"
    echo ""
fi

# Start the container with optimized configuration
docker-compose -f docker-compose.optimized.yml up -d

echo ""
echo -e "${GREEN}✅ Optimized container started!${NC}"
echo ""

echo -e "${CYAN}📊 Container Status:${NC}"
docker ps --filter "name=rl-swarm-optimized" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""

echo -e "${BLUE}💾 Cache Information:${NC}"
echo "   • Python packages: Cached in pip-cache volume"
echo "   • Yarn packages: Cached in yarn-cache volume"
echo "   • APT packages: Cached in apt-cache volume"
echo "   • Build artifacts: Cached in build-cache volume"
echo ""

echo -e "${BLUE}📝 View Logs:${NC}"
echo "   docker logs -f rl-swarm-optimized"
echo ""

echo -e "${BLUE}🔄 Management Commands:${NC}"
echo "   • Restart: docker-compose -f docker-compose.optimized.yml restart"
echo "   • Stop: docker-compose -f docker-compose.optimized.yml down"
echo "   • Force update: FORCE_UPDATE=true docker-compose -f docker-compose.optimized.yml up -d"
echo "   • Clean cache: docker system prune -f"
echo ""

echo -e "${YELLOW}🔗 Access URLs:${NC}"
echo "   ${GREEN}http://${HOST_IP}:3000${NC} - Main Interface"
echo "   ${GREEN}http://${HOST_IP}:8080${NC} - Web Access"
echo "   ${GREEN}http://${HOST_IP}:8081${NC} - Service 1"
echo "   ${GREEN}http://${HOST_IP}:8082${NC} - Service 2"
echo ""

echo -e "${GREEN}🎉 Optimized RL-Swarm is starting with persistent caching!${NC}"
echo "   📦 First setup will cache all dependencies for future runs"
echo "   🚀 Subsequent starts will be much faster"
echo "   📊 Check logs: docker logs -f rl-swarm-optimized"