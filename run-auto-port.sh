#!/bin/bash

# Self-Contained RL-Swarm with Automatic Port Forwarding
# Run this script to start Docker with immediate port forwarding display

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}🐳 RL-Swarm Self-Contained Auto Port Forwarding${NC}"
echo "=================================================="
echo ""

# Get host IP
HOST_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "YOUR_VPS_IP")

echo -e "${CYAN}🌐 PORT FORWARDING URLs (Ready when container starts):${NC}"
echo "================================================================"
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

echo -e "${YELLOW}🌐 Cloudflare Tunnel:${NC}"
echo "   Will start automatically (check container logs for URL)"
echo ""

echo -e "${BLUE}🚀 Starting Docker container...${NC}"
echo ""

# Start the container
docker-compose -f docker-compose.self-contained.yml up -d

echo ""
echo -e "${GREEN}✅ Container started!${NC}"
echo ""

echo -e "${CYAN}📊 Container Status:${NC}"
docker ps --filter "name=rl-swarm-self-contained" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""

echo -e "${BLUE}📝 View Logs:${NC}"
echo "   docker logs -f rl-swarm-self-contained"
echo ""

echo -e "${BLUE}🔗 Access URLs:${NC}"
echo "   ${GREEN}http://${HOST_IP}:3000${NC} - Main Interface"
echo "   ${GREEN}http://${HOST_IP}:8080${NC} - Web Access"
echo "   ${GREEN}http://${HOST_IP}:8081${NC} - Service 1"
echo "   ${GREEN}http://${HOST_IP}:8082${NC} - Service 2"
echo ""

echo -e "${YELLOW}💡 Tips:${NC}"
echo "   • All ports forward to the same RL-Swarm instance"
echo "   • Cloudflare tunnel URL will appear in container logs"
echo "   • Container automatically sets up port forwarding"
echo "   • No manual commands needed!"
echo ""

echo -e "${GREEN}🎉 RL-Swarm is starting with automatic port forwarding!${NC}"
echo "   Check logs: docker logs -f rl-swarm-self-contained"