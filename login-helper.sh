#!/bin/bash

echo "╔══════════════════════════════════════════════════════════╗"
echo "║         RL-Swarm Login Helper                            ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# Check if container is running
if ! docker ps | grep -q rl-swarm-node; then
    echo "❌ Container is not running!"
    echo ""
    echo "Start it with: ./deploy.sh up"
    exit 1
fi

echo "✅ Container is running"
echo ""

# Check if running locally or remotely
if [ -n "$SSH_CONNECTION" ] || [ -n "$SSH_CLIENT" ]; then
    echo "🌐 Remote/VPS environment detected"
    echo "   Setting up cloudflared tunnel for remote access..."
    echo ""

    # Check if cloudflared is installed in container
    if ! docker exec rl-swarm-node which cloudflared > /dev/null 2>&1; then
        echo "📦 Installing cloudflared in container..."
        docker exec rl-swarm-node bash -c "
            wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb 2>/dev/null &&
            sudo dpkg -i cloudflared-linux-amd64.deb > /dev/null 2>&1 &&
            rm cloudflared-linux-amd64.deb
        " 2>/dev/null

        if [ $? -eq 0 ]; then
            echo "✅ cloudflared installed successfully"
        else
            echo "❌ Failed to install cloudflared"
            echo "   Try manually: docker exec -it rl-swarm-node bash"
            exit 1
        fi
    else
        echo "✅ cloudflared already installed"
    fi

    echo ""
    echo "🚀 Starting tunnel to http://localhost:3000..."
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Copy the URL below and open it in your browser:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "⚠️  Press Ctrl+C when done with login"
    echo ""

    docker exec -it rl-swarm-node cloudflared tunnel --url http://localhost:3000
else
    echo "💻 Local environment detected"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Open your browser to:"
    echo "  👉 http://localhost:3000"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Check if port is accessible
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 > /dev/null 2>&1; then
        echo "✅ Login UI is accessible at http://localhost:3000"
    else
        echo "⚠️  Login UI might not be ready yet"
        echo "   Check container logs: ./deploy.sh logs"
    fi

    echo ""
    echo "Attempting to open browser automatically..."

    # Try to open browser automatically
    if command -v xdg-open > /dev/null 2>&1; then
        xdg-open http://localhost:3000 2>/dev/null &
        echo "✅ Browser opened (Linux)"
    elif command -v open > /dev/null 2>&1; then
        open http://localhost:3000 2>/dev/null &
        echo "✅ Browser opened (macOS)"
    elif command -v start > /dev/null 2>&1; then
        start http://localhost:3000 2>/dev/null &
        echo "✅ Browser opened (Windows)"
    else
        echo "⚠️  Couldn't open browser automatically"
        echo "   Please open http://localhost:3000 manually"
    fi

    echo ""
    echo "📋 Quick Commands:"
    echo "   View logs:    ./deploy.sh logs"
    echo "   Restart:      ./deploy.sh restart"
    echo "   Stop:         ./deploy.sh down"
fi

echo ""
