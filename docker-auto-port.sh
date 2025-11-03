#!/bin/bash

# Automatic Port Forwarding Setup INSIDE Docker Container
# This script runs when container starts and shows port forwarding links

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
CONTAINER_NAME="rl-swarm-auto"
MAIN_PORT=3000
ALT_PORTS=(8080 8081 8082 9000 9001 9002)

echo -e "${BLUE}🐳 RL-Swarm Docker Auto Port Forwarding${NC}"
echo "============================================="
echo ""

# Function to get container IP
get_container_ip() {
    ip route get 1.1.1.1 | awk '{print $7}' | head -1
}

# Function to get host IP
get_host_ip() {
    # Try different methods to get host IP
    curl -s ifconfig.me 2>/dev/null || \
    curl -s ipinfo.io/ip 2>/dev/null || \
    curl -s icanhazip.com 2>/dev/null || \
    echo "YOUR_VPS_IP"
}

# Function to check if port is available
check_port() {
    local port=$1
    if netstat -tlnp 2>/dev/null | grep -q ":$port "; then
        return 0  # Port is in use
    else
        return 1  # Port is available
    fi
}

# Function to start simple HTTP servers on alternative ports
start_alt_ports() {
    echo -e "${GREEN}🔗 Starting alternative port servers...${NC}"

    for port in "${ALT_PORTS[@]}"; do
        if ! check_port $port; then
            echo "   Starting server on port $port..."
            # Create a simple proxy using socat or Python
            python3 -c "
import http.server
import socketserver
import urllib.request
from urllib.parse import urlparse

class ProxyHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        try:
            # Forward request to main RL-Swarm
            response = urllib.request.urlopen(f'http://localhost:${MAIN_PORT}{self.path}')
            self.send_response(response.getcode())
            for header, value in response.headers.items():
                self.send_header(header, value)
            self.end_headers()
            self.wfile.write(response.read())
        except Exception as e:
            self.send_error(502, f'Proxy Error: {e}')

    def do_POST(self):
        try:
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)

            req = urllib.request.Request(f'http://localhost:${MAIN_PORT}{self.path}', post_data)
            for header, value in self.headers.items():
                if header.lower() != 'host':
                    req.add_header(header, value)

            response = urllib.request.urlopen(req)
            self.send_response(response.getcode())
            for header, value in response.headers.items():
                self.send_header(header, value)
            self.end_headers()
            self.wfile.write(response.read())
        except Exception as e:
            self.send_error(502, f'Proxy Error: {e}')

with socketserver.TCPServer(('', $port), ProxyHandler) as httpd:
    print(f'Proxy server running on port $port -> localhost:${MAIN_PORT}')
    httpd.serve_forever()
" &
            sleep 1
        else
            echo "   Port $port already in use, skipping..."
        fi
    done

    echo -e "${GREEN}✓ Alternative port servers started${NC}"
}

# Function to start Cloudflare tunnel
start_cloudflare_tunnel() {
    echo -e "${GREEN}🌐 Starting Cloudflare tunnel...${NC}"

    # Check if cloudflared is available
    if command -v cloudflared >/dev/null 2>&1; then
        echo "   Cloudflare tunnel starting..."
        cloudflared tunnel --url http://localhost:${MAIN_PORT} > /tmp/cloudflare.log 2>&1 &
        CLOUDFLARE_PID=$!

        # Wait a moment for tunnel to start
        sleep 10

        # Try to get tunnel URL
        if [ -f /tmp/cloudflare.log ]; then
            TUNNEL_URL=$(grep -o "https://[a-zA-Z0-9.-]*\.trycloudflare\.com" /tmp/cloudflare.log | head -1)
            if [ -n "$TUNNEL_URL" ]; then
                echo "$TUNNEL_URL"
                return 0
            fi
        fi
    else
        echo -e "${YELLOW}⚠️  cloudflared not available, tunnel not started${NC}"
    fi

    return 1
}

# Function to show port forwarding display
show_port_forwarding_display() {
    HOST_IP=$(get_host_ip)
    CONTAINER_IP=$(get_container_ip)

    echo -e "${CYAN}🎉 PORT FORWARDING ACTIVE${NC}"
    echo "=========================="
    echo ""

    echo -e "${YELLOW}📍 Primary Access (Direct):${NC}"
    echo "   Main Interface: http://${HOST_IP}:${MAIN_PORT}"
    echo "   Container IP: http://${CONTAINER_IP}:${MAIN_PORT}"
    echo ""

    echo -e "${YELLOW}🔗 Alternative Ports (Proxy):${NC}"
    for port in "${ALT_PORTS[@]}"; do
        if check_port $port; then
            echo "   Port $port: http://${HOST_IP}:${port} → RL-Swarm"
        fi
    done
    echo ""

    echo -e "${YELLOW}🌐 Cloudflare Tunnel:${NC}"
    TUNNEL_URL=$(start_cloudflare_tunnel)
    if [ -n "$TUNNEL_URL" ]; then
        echo "   🔗 ${GREEN}${TUNNEL_URL}${NC} ${CYAN}(Automatic External Access)${NC}"
        echo ""
        echo -e "${BLUE}💡 ${TUNNEL_URL} works from anywhere in the world!${NC}"
    else
        echo "   Starting tunnel... (check logs for URL)"
    fi
    echo ""

    echo -e "${YELLOW}📋 Quick Access Links:${NC}"
    echo "   Direct: http://${HOST_IP}:${MAIN_PORT}"
    echo "   Web: http://${HOST_IP}:8080"
    echo "   Service 1: http://${HOST_IP}:8081"
    echo "   Service 2: http://${HOST_IP}:8082"
    echo "   Backup 1: http://${HOST_IP}:9000"
    echo "   Backup 2: http://${HOST_IP}:9001"
    echo ""

    echo -e "${GREEN}🚀 All ports forward to the same RL-Swarm instance!${NC}"
    echo ""
}

# Function to start port monitoring
start_port_monitor() {
    echo -e "${BLUE}📊 Starting port monitoring...${NC}"

    # Start monitoring script in background
    (
        while true; do
            sleep 30
            echo "$(date): Port forwarding status check" >> /tmp/port-monitor.log

            # Check if main port is responding
            if curl -s http://localhost:${MAIN_PORT} >/dev/null 2>&1; then
                echo "$(date): Main port ${MAIN_PORT} responding" >> /tmp/port-monitor.log
            else
                echo "$(date): Main port ${MAIN_PORT} not responding" >> /tmp/port-monitor.log
            fi

            # Check alternative ports
            for port in "${ALT_PORTS[@]}"; do
                if check_port $port; then
                    echo "$(date): Alt port $port active" >> /tmp/port-monitor.log
                fi
            done
        done
    ) &

    MONITOR_PID=$!
    echo "   Port monitoring started (PID: $MONITOR_PID)"
}

# Function to create first-run marker
create_first_run_marker() {
    echo "$(date)" > /tmp/rl-swarm-first-run
    echo "First run completed" >> /tmp/rl-swarm-first-run
}

# Function to check if first run
is_first_run() {
    if [ ! -f /tmp/rl-swarm-first-run ]; then
        return 0  # First run
    else
        return 1  # Not first run
    fi
}

# Main execution
main() {
    echo -e "${BLUE}🐳 Initializing RL-Swarm Docker Port Forwarding...${NC}"
    echo ""

    # Show container information
    echo -e "${CYAN}Container Information:${NC}"
    echo "   Container Name: $CONTAINER_NAME"
    echo "   Container ID: $(hostname)"
    echo "   Main Port: $MAIN_PORT"
    echo "   Alternative Ports: ${ALT_PORTS[*]}"
    echo ""

    # Start alternative port servers
    start_alt_ports

    # Start port monitoring
    start_port_monitor

    # Show the port forwarding display
    show_port_forwarding_display

    # Create first-run marker
    if is_first_run; then
        create_first_run_marker
        echo -e "${GREEN}✅ First-time setup completed!${NC}"
    else
        echo -e "${BLUE}🔄 Container restarted - port forwarding active${NC}"
    fi

    echo ""
    echo -e "${CYAN}📝 Logs:${NC}"
    echo "   Port Monitor: tail -f /tmp/port-monitor.log"
    echo "   Cloudflare: tail -f /tmp/cloudflare.log"
    echo ""
    echo -e "${GREEN}🎉 RL-Swarm is ready with automatic port forwarding!${NC}"
    echo ""
}

# Run main function
main "$@"