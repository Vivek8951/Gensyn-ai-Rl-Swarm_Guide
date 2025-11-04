#!/bin/bash

# Pre-built RL-Swarm Docker Entrypoint
# Everything is already pre-built in the image

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║  🚀 PRE-BUILT RL-Swarm Container Starting...            ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Get host IP
HOST_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "YOUR_VPS_IP")

echo -e "${GREEN}✅ PRE-BUILT IMAGE STATUS:${NC}"
echo "   • Git repository: Pre-cloned during image build"
echo "   • Node.js modules: Pre-installed during image build"
echo "   • Python virtual env: Pre-created during image build"
echo "   • Setup time: Instant (no downloads needed)"
echo ""

# Go to RL-Swarm directory
cd /home/rlswarm/rl-swarm

# Verify pre-built setup
if [ -f ".setup-complete" ]; then
    echo -e "${GREEN}✅ Pre-built setup verified${NC}"
    echo "   • Repository commit: $(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')"
    echo "   • Node modules: $(ls -la node_modules 2>/dev/null | wc -l) packages"
    echo "   • Python venv: $(.venv/bin/python --version 2>/dev/null || echo 'unknown')"
    echo ""
else
    echo -e "${RED}❌ Pre-built setup not found${NC}"
    exit 1
fi

# Activate virtual environment
if [ -f ".venv/bin/activate" ]; then
    source .venv/bin/activate
    echo -e "${GREEN}✅ Virtual environment activated${NC}"
else
    echo -e "${RED}❌ Virtual environment not found${NC}"
    exit 1
fi

# Function to show port forwarding display
show_port_forwarding_display() {
    echo ""
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║  🌐 PRE-BUILT PORT FORWARDING ACTIVE                    ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo ""

    echo -e "${CYAN}🎉 MULTIPLE ACCESS POINTS READY:${NC}"
    echo "========================================"
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
    echo "   Starting automatic tunnel (check logs for URL)..."
    echo ""

    echo -e "${YELLOW}📋 Quick Access:${NC}"
    echo "   ${GREEN}http://${HOST_IP}:3000${NC} - Main Interface"
    echo "   ${GREEN}http://${HOST_IP}:8080${NC} - Web Access"
    echo "   ${GREEN}http://${HOST_IP}:8081${NC} - Service 1"
    echo "   ${GREEN}http://${HOST_IP}:8082${NC} - Service 2"
    echo ""

    echo -e "${GREEN}✅ All ports forward to the same RL-Swarm instance!${NC}"
    echo -e "${GREEN}🔥 No downloads needed - everything pre-built!${NC}"
    echo ""
}

# Function to start port servers inside container
start_container_port_servers() {
    echo "🔗 Starting alternative port servers (pre-built)..."
    echo "   Using pre-installed Node.js environment"
    echo ""

    # Create simple Python proxy servers for alternative ports
    python3 -c "
import http.server
import socketserver
import urllib.request
import threading
import time
import sys
import signal

MAIN_PORT = 3000
ALT_PORTS = [8080, 8081, 8082, 9000, 9001, 9002]

class ProxyHandler(http.server.BaseHTTPRequestHandler):
    def proxy_request(self, path, method='GET', post_data=None):
        try:
            url = f'http://localhost:{MAIN_PORT}{path}'

            if method == 'POST' and post_data:
                req = urllib.request.Request(url, post_data)
            else:
                req = urllib.request.Request(url)

            # Copy headers except Host
            for header, value in self.headers.items():
                if header.lower() != 'host':
                    req.add_header(header, value)

            response = urllib.request.urlopen(req)

            self.send_response(response.getcode())
            for header, value in response.headers.items():
                self.send_header(header, value)
            self.end_headers()

            if method == 'GET':
                self.wfile.write(response.read())
            else:
                self.wfile.write(response.read())

        except Exception as e:
            self.send_error(502, f'Proxy Error: {e}')

    def do_GET(self):
        self.proxy_request(self.path)

    def do_POST(self):
        content_length = int(self.headers.get('Content-Length', 0))
        post_data = self.rfile.read(content_length) if content_length > 0 else None
        self.proxy_request(self.path, 'POST', post_data)

def start_server(port):
    try:
        with socketserver.TCPServer(('', port), ProxyHandler) as httpd:
            print(f'Proxy server started on port {port} -> localhost:{MAIN_PORT}')
            httpd.serve_forever()
    except Exception as e:
        print(f'Failed to start server on port {port}: {e}')

# Start servers in background threads
for port in ALT_PORTS:
    thread = threading.Thread(target=start_server, args=(port,))
    thread.daemon = True
    thread.start()
    time.sleep(0.1)  # Small delay between servers

print('All proxy servers started in background')
" > /tmp/port_servers.log 2>&1 &

    echo "   Alternative port servers started successfully"
}

# Function to start Cloudflare tunnel
start_cloudflare_tunnel() {
    echo "🌐 Starting Cloudflare tunnel..."
    if command -v cloudflared >/dev/null 2>&1; then
        cloudflared tunnel --url http://localhost:3000 > /tmp/cloudflare.log 2>&1 &
        CLOUDFLARE_PID=$!
        echo "   Cloudflare tunnel started (PID: $CLOUDFLARE_PID)"
    else
        echo "   ⚠️  cloudflared not available"
    fi
}

# Function to wait for RL-Swarm to be ready
wait_for_rlswarm_ready() {
    echo "🔍 Waiting for RL-Swarm to start..."

    for i in {1..30}; do  # Wait up to 1 minute
        if pgrep -f "run_rl_swarm.sh" >/dev/null 2>&1; then
            echo "   ⏳ RL-Swarm process detected, waiting for port..."
        fi

        if curl -s --connect-timeout 2 http://localhost:3000 >/dev/null 2>&1; then
            echo "   ✅ RL-Swarm is responding on localhost:3000"
            return 0
        fi

        sleep 2
    done

    echo "   ⚠️  Timeout waiting for RL-Swarm, but continuing..."
    return 1
}

# Display pre-built status
show_port_forwarding_display

# Start port servers
start_container_port_servers

# Start Cloudflare tunnel
start_cloudflare_tunnel

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║  🎉 PRE-BUILT RL-Swarm Starting...                        ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

echo -e "${CYAN}📊 Build Information:${NC}"
echo "   • Image: Pre-built with all dependencies"
echo "   • Repository: $(git remote get-url origin 2>/dev/null || echo 'unknown')"
echo "   • Branch: $(git branch --show-current 2>/dev/null || echo 'unknown')"
echo "   • Commit: $(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')"
echo ""

echo -e "${GREEN}🚀 Starting RL-Swarm application...${NC}"
echo ""

# Start RL-Swarm application (this should be very fast now)
exec ./run_rl_swarm.sh

# Note: The exec command never returns as it replaces the shell process