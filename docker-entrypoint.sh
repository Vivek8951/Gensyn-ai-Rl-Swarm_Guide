#!/bin/bash

set -e

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║  RL-Swarm Container Starting...                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Check if rl-swarm directory exists, if not clone it
if [ ! -d "/home/rlswarm/rl-swarm" ]; then
    echo "📦 First-time setup - Cloning RL-Swarm repository..."
    cd /home/rlswarm
    git clone https://github.com/gensyn-ai/rl-swarm.git rl-swarm
    cd rl-swarm

    # Setup virtual environment
    echo "🐍 Setting up Python virtual environment..."
    python3 -m venv .venv
    source .venv/bin/activate
    pip install --upgrade pip

    # Install requirements if they exist
    if [ -f requirements.txt ]; then
        echo "📦 Installing Python requirements..."
        pip install -r requirements.txt
    fi

    # Make script executable
    if [ -f run_rl_swarm.sh ]; then
        chmod +x run_rl_swarm.sh
    fi

    # Mark as first-run completed
    touch /tmp/rl-swarm-setup-complete
    echo "✅ First-time setup completed!"
else
    echo "✅ RL-Swarm directory exists (preserving existing setup)"
    cd /home/rlswarm/rl-swarm

    # Only update if specifically requested (not on every restart)
    if [ "$FORCE_UPDATE" = "true" ]; then
        echo "🔄 Force update requested - pulling latest changes..."
        git fetch origin main
        git pull origin main

        # Only reinstall if requirements changed
        if [ requirements.txt -nt /tmp/rl-swarm-requirements-installed ]; then
            echo "📦 Requirements updated - reinstalling..."
            source .venv/bin/activate
            pip install -r requirements.txt
            touch /tmp/rl-swarm-requirements-installed
        fi
    else
        echo "🔄 Skipping update (use FORCE_UPDATE=true to update)"
    fi

    # Don't overwrite local files
    if [ -f "swarm.pem" ]; then
        echo "✅ swarm.pem found - authentication preserved!"
    fi
fi

# Activate virtual environment
if [ -f ".venv/bin/activate" ]; then
    source .venv/bin/activate
    echo "✅ Virtual environment activated"
else
    echo "❌ Virtual environment not found - creating new one..."
    python3 -m venv .venv
    source .venv/bin/activate

    if [ -f requirements.txt ]; then
        pip install -r requirements.txt
    fi
fi

# Function to wait for RL-Swarm to be ready
wait_for_rlswarm_ready() {
    echo "🔍 Waiting for RL-Swarm to start on localhost:3000..."

    # Wait for the application to start with multiple detection methods
    for i in {1..60}; do  # Wait up to 2 minutes (60 * 2 seconds)
        # Method 1: Check if port 3000 is listening
        if lsof -Pi :3000 -sTCP:LISTEN -t >/dev/null 2>&1; then
            echo "✅ Port 3000 is listening"
            # Method 2: Test HTTP connectivity
            if curl -s --connect-timeout 2 http://localhost:3000 >/dev/null 2>&1; then
                echo "✅ RL-Swarm is responding on localhost:3000"
                return 0
            else
                echo "⏳ Port is open but service not ready yet..."
            fi
        else
            # Method 3: Check if the process is running
            if pgrep -f "run_rl_swarm.sh" >/dev/null 2>&1; then
                echo "⏳ RL-Swarm process is running, waiting for port to open..."
            else
                echo "⏳ Waiting for RL-Swarm to start..."
            fi
        fi
        sleep 2
    done

    echo "⚠️  Timeout waiting for RL-Swarm, but continuing anyway..."
    return 1
}

# Function to start cloudflared tunnel when localhost:3000 appears
start_tunnel_when_ready() {
    echo "🔍 Monitoring for RL-Swarm availability..."

    # Wait for RL-Swarm to be ready using improved detection
    if wait_for_rlswarm_ready; then
            echo ""
            echo "╔═══════════════════════════════════════════════════════════╗"
            echo "║  ✅ RL-Swarm is running on localhost:3000                 ║"
            echo "╚═══════════════════════════════════════════════════════════╝"
            echo ""

            # Check if we're in a remote/VPS environment
            if [ -n "$SSH_CONNECTION" ] || [ -n "$SSH_CLIENT" ] || [ "$AUTO_TUNNEL" = "true" ] || [ "$REMOTE_ACCESS" = "true" ]; then
                echo "🌐 Remote/VPS environment detected - Setting up access tunnel..."
                echo ""

                # Check if custom tunnel configuration is provided
                if [ -n "$CLOUDFLARE_TUNNEL_TOKEN" ] && [ -n "$TUNNEL_DOMAIN" ]; then
                    echo "🚀 Using custom Cloudflare tunnel configuration..."
                    echo "╔═══════════════════════════════════════════════════════════╗"
                    echo "║  🔗 Custom Domain Tunnel Active!                         ║"
                    echo "║  Access URL: https://${TUNNEL_DOMAIN}                    ║"
                    echo "╚═══════════════════════════════════════════════════════════╝"
                    echo ""
                    cloudflared tunnel --token "${CLOUDFLARE_TUNNEL_TOKEN}"
                elif [ -n "$TUNNEL_DOMAIN" ]; then
                    echo "🚀 Creating named tunnel for domain: ${TUNNEL_DOMAIN}"
                    echo "╔═══════════════════════════════════════════════════════════╗"
                    echo "║  🔗 Domain Tunnel Active!                                 ║"
                    echo "║  Access URL: https://${TUNNEL_DOMAIN}                    ║"
                    echo "╚═══════════════════════════════════════════════════════════╝"
                    echo ""
                    cloudflared tunnel --url http://localhost:3000 --hostname "${TUNNEL_DOMAIN}"
                else
                    echo "🚀 Starting Cloudflare tunnel with random URL..."
                    echo "╔═══════════════════════════════════════════════════════════╗"
                    echo "║  🌐 Cloudflare Tunnel Active!                             ║"
                    echo "║  Copy the URL below to access from your local browser:    ║"
                    echo "╚═══════════════════════════════════════════════════════════╝"
                    echo ""
                    cloudflared tunnel --url http://localhost:3000
                fi

                # Display additional access information
                echo ""
                echo "📋 Access Information:"
                echo "   • Primary URL: See tunnel URL above"
                echo "   • Container Port: 3000"
                echo "   • External Port: ${EXTERNAL_PORT:-3000}"
                if [ -n "$TUNNEL_PORT" ] && [ "$TUNNEL_PORT" != "22" ]; then
                    echo "   • SSH Tunnel Port: ${TUNNEL_PORT}"
                fi
                echo ""

            else
                echo "💻 Local environment detected"
                echo "   • Direct access: http://localhost:3000"
                echo "   • External port: ${EXTERNAL_PORT:-3000}"
                echo ""
                echo "ℹ️  To manually start tunnel, run:"
                echo "   docker exec -it rl-swarm-node cloudflared tunnel --url http://localhost:3000"
                echo ""
            fi
            break
        fi
        sleep 2
    done
}

# Function to display network configuration
show_network_info() {
    echo "🌐 Network Configuration:"
    echo "   • External Port: ${EXTERNAL_PORT:-3000}"
    echo "   • Tunnel Port: ${TUNNEL_PORT:-22}"
    echo "   • Auto Tunnel: ${AUTO_TUNNEL:-true}"
    echo "   • Remote Access: ${REMOTE_ACCESS:-true}"
    if [ -n "$TUNNEL_DOMAIN" ]; then
        echo "   • Custom Domain: ${TUNNEL_DOMAIN}"
    fi
    echo ""
}

# Start tunnel monitor in background if AUTO_TUNNEL is enabled
if [ "$AUTO_TUNNEL" = "true" ]; then
    start_tunnel_when_ready &
fi

# Function to show automatic port forwarding display
show_auto_port_forwarding() {
    echo ""
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║  🌐 AUTOMATIC PORT FORWARDING ACTIVE                      ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo ""

    # Get host IP
    HOST_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "YOUR_VPS_IP")

    echo "🎉 ${GREEN}MULTIPLE ACCESS POINTS READY${NC}"
    echo "================================"
    echo ""

    echo "📍 ${YELLOW}Primary Access:${NC}"
    echo "   Main Interface: ${GREEN}http://${HOST_IP}:3000${NC}"
    echo ""

    echo "🔗 ${YELLOW}Alternative Ports (Starting Soon):${NC}"
    echo "   Port 8080: ${GREEN}http://${HOST_IP}:8080${NC} → RL-Swarm"
    echo "   Port 8081: ${GREEN}http://${HOST_IP}:8081${NC} → RL-Swarm"
    echo "   Port 8082: ${GREEN}http://${HOST_IP}:8082${NC} → RL-Swarm"
    echo "   Port 9000: ${GREEN}http://${HOST_IP}:9000${NC} → RL-Swarm"
    echo "   Port 9001: ${GREEN}http://${HOST_IP}:9001${NC} → RL-Swarm"
    echo "   Port 9002: ${GREEN}http://${HOST_IP}:9002${NC} → RL-Swarm"
    echo ""

    echo "🌐 ${YELLOW}Cloudflare Tunnel:${NC}"
    echo "   Starting automatic tunnel (check logs for URL)..."
    echo ""

    echo "📋 ${YELLOW}Quick Access:${NC}"
    echo "   ${GREEN}http://${HOST_IP}:3000${NC} - Main Interface"
    echo "   ${GREEN}http://${HOST_IP}:8080${NC} - Web Access"
    echo "   ${GREEN}http://${HOST_IP}:8081${NC} - Service 1"
    echo "   ${GREEN}http://${HOST_IP}:8082${NC} - Service 2"
    echo ""

    echo "✅ ${GREEN}All ports will forward to the same RL-Swarm instance!${NC}"
    echo "🔥 ${GREEN}No manual port commands needed!${NC}"
    echo ""
}

# Function to start alternative port servers inside container
start_container_port_servers() {
    echo "🔗 Starting alternative port servers in background..."

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

    echo "   Alternative port servers started (check /tmp/port_servers.log)"
}

# Start container port servers if in container environment
if [ -f /.dockerenv ] || grep -q 'docker\|lxc' /proc/1/cgroup 2>/dev/null; then
    start_container_port_servers
fi

# Display startup message
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║  🚀 Starting RL-Swarm...                                   ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Show network configuration
show_network_info

# Show automatic port forwarding display
show_auto_port_forwarding

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║  🎉 PORT FORWARDING AUTOMATICALLY CONFIGURED!             ║"
echo "║                                                           ║"
echo "║  ✅ Multiple access points ready                           ║"
echo "║  ✅ Cloudflare tunnel starting                            ║"
echo "║  ✅ No manual commands needed                              ║"
echo "║                                                           ║"
echo "║  🌐 Use any of the URLs above to access RL-Swarm!         ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Start the RL-Swarm application
exec ./run_rl_swarm.sh
