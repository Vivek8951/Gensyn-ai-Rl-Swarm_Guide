#!/bin/bash

set -e

echo "======================================"
echo "  RL-Swarm Docker Deployment Script  "
echo "======================================"
echo ""

if [ "$1" == "build" ]; then
    echo "Building Docker image..."
    docker build -t rl-swarm:latest .
    echo "✓ Image built successfully!"

elif [ "$1" == "up" ]; then
    echo "Starting RL-Swarm container..."
    docker-compose up -d
    echo "✓ Container started!"
    echo ""
    echo "Access the login at: http://localhost:3000"
    echo "View logs with: docker logs -f rl-swarm-node"

elif [ "$1" == "down" ]; then
    echo "Stopping RL-Swarm container..."
    docker-compose down
    echo "✓ Container stopped!"

elif [ "$1" == "logs" ]; then
    echo "Showing container logs (Ctrl+C to exit)..."
    docker logs -f rl-swarm-node

elif [ "$1" == "restart" ]; then
    echo "Restarting RL-Swarm container..."
    docker-compose restart
    echo "✓ Container restarted!"

elif [ "$1" == "pull" ]; then
    echo "Pulling latest Docker image..."
    if [ -z "$2" ]; then
        echo "Error: Please specify Docker image (e.g., username/rl-swarm:latest)"
        exit 1
    fi
    docker pull "$2"
    echo "✓ Image pulled successfully!"

elif [ "$1" == "update" ]; then
    echo "Updating to latest version..."
    if [ -z "$2" ]; then
        echo "Error: Please specify Docker image (e.g., username/rl-swarm:latest)"
        exit 1
    fi
    docker pull "$2"
    docker-compose down
    docker tag "$2" rl-swarm:latest
    docker-compose up -d
    echo "✓ Updated to latest version!"

elif [ "$1" == "shell" ]; then
    echo "Opening shell in container..."
    docker exec -it rl-swarm-node /bin/bash

elif [ "$1" == "clean" ]; then
    echo "Cleaning up Docker resources..."
    read -p "This will remove stopped containers and unused images. Continue? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker-compose down
        docker system prune -f
        echo "✓ Cleanup complete!"
    else
        echo "Cleanup cancelled."
    fi

elif [ "$1" == "login" ]; then
    echo "Opening login interface..."
    if [ -f ./login-helper.sh ]; then
        ./login-helper.sh
    else
        # Check if we're on a VPS/remote server
        if [ -n "$SSH_CONNECTION" ] || [ -n "$SSH_CLIENT" ]; then
            EXTERNAL_PORT=${EXTERNAL_PORT:-3000}
            VPS_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "YOUR_VPS_IP")
            echo "🌐 Remote/VPS environment detected"
            echo "   Local access: http://localhost:${EXTERNAL_PORT}"
            echo "   External access: http://${VPS_IP}:${EXTERNAL_PORT}"
            echo ""
            echo "🔗 Check container logs for Cloudflare tunnel URL:"
            echo "   ./deploy.sh logs"
            echo ""
        else
            echo "Login helper not found. Opening browser to http://localhost:3000"
            if command -v xdg-open > /dev/null; then
                xdg-open http://localhost:3000
            elif command -v open > /dev/null; then
                open http://localhost:3000
            else
                echo "Please open http://localhost:3000 in your browser"
            fi
        fi
    fi

elif [ "$1" == "vps" ]; then
    echo "🌐 VPS/Cloud Deployment Setup"
    echo "================================"
    echo ""
    echo "Setting up environment for VPS deployment..."

    # Create environment file for VPS
    cat > .env.vps << EOF
# VPS/Cloud Instance Configuration
EXTERNAL_PORT=${2:-3000}
AUTO_TUNNEL=true
REMOTE_ACCESS=true
TUNNEL_PORT=${3:-22}

# Optional: Custom domain tunnel (uncomment and configure)
# TUNNEL_DOMAIN=your-domain.com
# CLOUDFLARE_TUNNEL_TOKEN=your-token-here

# Docker configuration
PYTHONUNBUFFERED=1
EOF

    echo "✓ Created .env.vps configuration file"
    echo ""
    echo "📋 VPS Deployment Commands:"
    echo "   1. Copy environment: cp .env.vps .env"
    echo "   2. Start container: ./deploy.sh up"
    echo "   3. View logs: ./deploy.sh logs"
    echo "   4. Get tunnel URL: ./deploy.sh logs"
    echo ""
    echo "🔧 Optional Configuration:"
    echo "   • Edit .env to customize ports and tunnel settings"
    echo "   • Set custom domain with TUNNEL_DOMAIN"
    echo "   • Use Cloudflare token for persistent tunnels"
    echo ""

elif [ "$1" == "multiport" ]; then
    echo "🔌 Multi-Port VPS Deployment"
    echo "============================"
    echo ""
    echo "Setting up multi-port environment for VPS..."

    if [ -f "./port-manager.sh" ]; then
        ./port-manager.sh setup "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9" "${10}"
    else
        echo "❌ Error: port-manager.sh not found"
        exit 1
    fi

elif [ "$1" == "ports" ]; then
    echo "🔌 Port Management"
    echo "=================="
    echo ""

    if [ -f "./port-manager.sh" ]; then
        if [ -z "$2" ]; then
            ./port-manager.sh status
        else
            ./port-manager.sh "$2" "$3" "$4"
        fi
    else
        echo "❌ Error: port-manager.sh not found"
        echo "Run './deploy.sh multiport' to set up port management first"
        exit 1
    fi

elif [ "$1" == "forward" ]; then
    echo "🔗 Port Forwarding"
    echo "=================="
    echo ""

    if [ -f "./port-manager.sh" ]; then
        ./port-manager.sh forward "$2"
    else
        echo "❌ Error: port-manager.sh not found"
        echo "Run './deploy.sh multiport' to set up port management first"
        exit 1
    fi

elif [ "$1" == "start-multi" ]; then
    echo "🚀 Starting Multi-Port Services"
    echo "==============================="
    echo ""

    if [ -f "./port-manager.sh" ]; then
        ./port-manager.sh start
    else
        echo "❌ Error: port-manager.sh not found"
        exit 1
    fi

elif [ "$1" == "stop-multi" ]; then
    echo "🛑 Stopping Multi-Port Services"
    echo "=============================="
    echo ""

    if [ -f "./port-manager.sh" ]; then
        ./port-manager.sh stop
    else
        echo "❌ Error: port-manager.sh not found"
        exit 1
    fi

elif [ "$1" == "tunnel" ]; then
    echo "🔗 Cloudflare Tunnel Management"
    echo "==============================="
    echo ""
    if [ "$2" = "status" ]; then
        echo "Checking tunnel status..."
        docker exec rl-swarm-node pgrep -f cloudflared > /dev/null 2>&1 && echo "✓ Tunnel is running" || echo "✗ Tunnel is not running"
    elif [ "$2" = "start" ]; then
        echo "Starting manual tunnel..."
        docker exec -it rl-swarm-node cloudflared tunnel --url http://localhost:3000
    elif [ "$2" = "stop" ]; then
        echo "Stopping tunnel..."
        docker exec rl-swarm-node pkill -f cloudflared || echo "No tunnel process found"
    else
        echo "Usage: ./deploy.sh tunnel [status|start|stop]"
        echo ""
        echo "Commands:"
        echo "  status    Check if tunnel is running"
        echo "  start     Start manual tunnel"
        echo "  stop      Stop running tunnel"
    fi

elif [ "$1" == "ip" ]; then
    echo "🌐 Server IP Information"
    echo "======================="
    echo ""
    VPS_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "Could not determine")
    echo "External IP: ${VPS_IP}"
    echo "Local access: http://localhost:${EXTERNAL_PORT:-3000}"
    echo "External access: http://${VPS_IP}:${EXTERNAL_PORT:-3000}"
    echo ""

else
    echo "Usage: ./deploy.sh [command]"
    echo ""
    echo "Commands:"
    echo "  build              Build the Docker image locally"
    echo "  up                 Start the container"
    echo "  down               Stop the container"
    echo "  logs               View container logs"
    echo "  restart            Restart the container"
    echo "  pull <image>       Pull a specific Docker image"
    echo "  update <image>     Update to latest version from registry"
    echo "  shell              Open a shell in the running container"
    echo "  login              Open the login interface (port 3000)"
    echo "  vps [port] [ssh]   Setup VPS environment (default: 3000, 22)"
    echo "  tunnel [cmd]       Manage Cloudflare tunnels"
    echo "  ip                 Show server IP and access URLs"
    echo "  clean              Clean up Docker resources"
    echo ""
    echo "Examples:"
    echo "  ./deploy.sh build"
    echo "  ./deploy.sh up"
    echo "  ./deploy.sh vps 8080 2222    # VPS setup with custom ports"
    echo "  ./deploy.sh tunnel status    # Check tunnel status"
    echo "  ./deploy.sh ip                # Get server IP"
    echo "  ./deploy.sh pull yourusername/rl-swarm:latest"
    echo "  ./deploy.sh update yourusername/rl-swarm:latest"
    echo ""
    echo "VPS/Cloud Setup:"
    echo "  1. ./deploy.sh vps          # Create VPS environment file"
    echo "  2. cp .env.vps .env         # Apply VPS configuration"
    echo "  3. ./deploy.sh up           # Start with tunnel support"
    echo "  4. ./deploy.sh logs         # Get tunnel URL"
    exit 1
fi
