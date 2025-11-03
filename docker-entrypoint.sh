#!/bin/bash

set -e

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║  RL-Swarm Container Starting...                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Check if rl-swarm directory exists, if not clone it
if [ ! -d "/home/rlswarm/rl-swarm" ]; then
    echo "📦 Cloning RL-Swarm repository..."
    cd /home/rlswarm
    git clone https://github.com/gensyn-ai/rl-swarm.git rl-swarm
    cd rl-swarm

    # Setup virtual environment
    echo "🐍 Setting up Python virtual environment..."
    python3 -m venv .venv
    source .venv/bin/activate
    pip install --upgrade pip

    # Make script executable
    if [ -f run_rl_swarm.sh ]; then
        chmod +x run_rl_swarm.sh
    fi
else
    echo "✅ RL-Swarm directory exists (preserving swarm.pem)"
    cd /home/rlswarm/rl-swarm

    # Update the repository but preserve local files
    echo "🔄 Pulling latest changes from repository..."
    git fetch origin main
    # Don't overwrite local changes, just inform
    if [ -f "swarm.pem" ]; then
        echo "✅ swarm.pem found - authentication preserved!"
    fi
fi

# Activate virtual environment
source .venv/bin/activate

# Function to start cloudflared tunnel when localhost:3000 appears
start_tunnel_when_ready() {
    echo "🔍 Monitoring for localhost:3000..."

    # Wait for the application to start
    while true; do
        # Check if port 3000 is listening
        if lsof -Pi :3000 -sTCP:LISTEN -t >/dev/null 2>&1; then
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

# Display startup message
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║  🚀 Starting RL-Swarm...                                   ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Show network configuration
show_network_info

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║  📍 Access Information                                      ║"
echo "║                                                           ║"
echo "║  • Local: http://localhost:3000                           ║"
echo "║  • External: http://YOUR_VPS_IP:${EXTERNAL_PORT:-3000}    ║"
echo "║                                                           ║"
echo "║  💡 Tip: Run './deploy.sh login' to auto-open browser     ║"
echo "║  🌐 For remote access, tunnel will start automatically    ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Start the RL-Swarm application
exec ./run_rl_swarm.sh
