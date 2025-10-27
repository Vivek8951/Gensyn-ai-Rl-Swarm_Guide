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
    echo "  clean              Clean up Docker resources"
    echo ""
    echo "Examples:"
    echo "  ./deploy.sh build"
    echo "  ./deploy.sh up"
    echo "  ./deploy.sh pull yourusername/rl-swarm:latest"
    echo "  ./deploy.sh update yourusername/rl-swarm:latest"
    exit 1
fi
