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
            if [ -n "$SSH_CONNECTION" ] || [ -n "$SSH_CLIENT" ] || [ "$AUTO_TUNNEL" = "true" ]; then
                echo "🌐 Remote environment detected - Starting cloudflared tunnel..."
                echo ""
                echo "╔═══════════════════════════════════════════════════════════╗"
                echo "║  🚀 Cloudflare Tunnel Active!                             ║"
                echo "║  Copy the URL below to access from your local browser:    ║"
                echo "╚═══════════════════════════════════════════════════════════╝"
                echo ""

                # Start cloudflared in foreground
                cloudflared tunnel --url http://localhost:3000
            else
                echo "💻 Local environment - Access at: http://localhost:3000"
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

# Start tunnel monitor in background if AUTO_TUNNEL is enabled
if [ "$AUTO_TUNNEL" = "true" ]; then
    start_tunnel_when_ready &
fi

# Display startup message
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║  🚀 Starting RL-Swarm...                                   ║"
echo "║                                                           ║"
echo "║  📍 Login will be available at: http://localhost:3000     ║"
echo "║                                                           ║"
echo "║  💡 Tip: Run './deploy.sh login' to auto-open browser     ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Start the RL-Swarm application
exec ./run_rl_swarm.sh
