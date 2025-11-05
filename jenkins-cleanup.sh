#!/bin/bash

# Jenkins Container Cleanup Script
# Aggressively cleans up Docker containers and resolves port conflicts

set -e

echo "🧹 JENKINS DOCKER CLEANUP - Starting comprehensive cleanup..."
echo "================================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Function to cleanup containers
cleanup_containers() {
    echo -e "${BLUE}🧹 Cleaning up existing containers...${NC}"

    # Stop all RL-Swarm related containers
    echo -e "${YELLOW}  Stopping RL-Swarm containers...${NC}"
    for container in $(docker ps -a --format "{{.Names}}" 2>/dev/null | grep -E "rl-swarm|gensyn" || true); do
        echo "    Stopping: $container"
        docker stop "$container" 2>/dev/null || true
    done

    # Remove all RL-Swarm related containers
    echo -e "${YELLOW}  Removing RL-Swarm containers...${NC}"
    for container in $(docker ps -a --format "{{.Names}}" 2>/dev/null | grep -E "rl-swarm|gensyn" || true); do
        echo "    Removing: $container"
        docker rm "$container" 2>/dev/null || true
    done

    # Stop any remaining containers using our target ports
    echo -e "${YELLOW}  Checking for containers using target ports...${NC}"
    for port in 3000 8080 8081 8082 9000 9001 9002; do
        container_id=$(docker ps -q --filter "publish=$port" 2>/dev/null || true)
        if [ -n "$container_id" ]; then
            echo "    Stopping container using port $port: $(docker ps --filter "id=$container_id" --format "{{.Names}}")"
            docker stop "$container_id" 2>/dev/null || true
            echo "    Removing container: $(docker ps --filter "id=$container_id" --format "{{.Names}}")"
            docker rm "$container_id" 2>/dev/null || true
        fi
    done

    echo -e "${GREEN}✅ Container cleanup completed${NC}"
}

# Function to cleanup Docker resources
cleanup_docker_resources() {
    echo -e "${BLUE}🧹 Cleaning up Docker resources...${NC}"

    # Prune containers
    echo -e "${YELLOW}  Pruning stopped containers...${NC}"
    docker container prune -f 2>/dev/null || true

    # Prune images
    echo -e "${YELLOW}  Pruning dangling images...${NC}"
    docker image prune -f 2>/dev/null || true

    # Prune networks
    echo -e "${YELLOW}  Pruning unused networks...${NC}"
    docker network prune -f 2>/dev/null || true

    echo -e "${GREEN}✅ Docker resource cleanup completed${NC}"
}

# Function to kill processes using target ports
kill_port_processes() {
    echo -e "${BLUE}🔪 Killing processes using target ports...${NC}"

    for port in 3000 8080 8081 8082 9000 9001 9002; do
        echo -e "${YELLOW}  Checking port $port...${NC}"

        # Find and kill processes using the port
        pids=$(lsof -ti :$port 2>/dev/null || true)
        if [ -n "$pids" ]; then
            for pid in $pids; do
                if [ "$pid" != "$$" ]; then
                    echo "    Killing process $pid using port $port"
                    kill -9 "$pid" 2>/dev/null || true
                fi
            done
        else
            echo -e "${GREEN}    Port $port is free${NC}"
        fi
    done

    echo -e "${GREEN}✅ Port process cleanup completed${NC}"
}

# Function to cleanup iptables rules
cleanup_iptables() {
    echo -e "${BLUE}🔧 Cleaning up iptables rules...${NC}"

    # Remove any existing iptables rules for our ports
    for port in 3000 8080 8081 8082 9000 9001 9002; do
        echo -e "${YELLOW}  Removing iptables rules for port $port...${NC}"
        iptables -t nat -D PREROUTING -p tcp --dport $port -j REDIRECT 2>/dev/null || true
        iptables -t nat -D POSTROUTING -p tcp --dport $port -j MASQUERADE 2>/dev/null || true
    done

    echo -e "${GREEN}✅ iptables cleanup completed${NC}"
}

# Function to cleanup socat processes
cleanup_socat() {
    echo -e "${BLUE}🔌 Cleaning up socat processes...${NC}"

    # Find and kill socat processes
    pids=$(pgrep -f "socat.*:3000" 2>/dev/null || true)
    if [ -n "$pids" ]; then
        for pid in $pids; do
            echo -e "${YELLOW}  Killing socat process $pid...${NC}"
            kill -9 "$pid" 2>/dev/null || true
        done
    else
        echo -e "${GREEN}    No socat processes found${NC}"
    fi

    echo -e "${GREEN}✅ socat cleanup completed${NC}"
}

# Function to verify cleanup
verify_cleanup() {
    echo -e "${BLUE}✅ Verifying cleanup results...${NC}"

    # Check if ports are now free
    local all_free=true
    for port in 3000 8080 8081 8082 9000 9001 9002; do
        if lsof -i :$port >/dev/null 2>&1; then
            echo -e "${RED}    ❌ Port $port is still in use${NC}"
            all_free=false
        else
            echo -e "${GREEN}    ✅ Port $port is free${NC}"
        fi
    done

    if [ "$all_free" = true ]; then
        echo -e "${GREEN}🎉 All target ports are now free!${NC}"
        return 0
    else
        echo -e "${RED}❌ Some ports are still in use${NC}"
        return 1
    fi
}

# Main execution
main() {
    echo "Target ports: 3000, 8080-8082, 9000-9002"
    echo ""

    # Perform all cleanup operations
    cleanup_containers
    cleanup_docker_resources
    kill_port_processes
    cleanup_socat
    cleanup_iptables

    echo ""

    # Verify cleanup was successful
    if verify_cleanup; then
        echo -e "${GREEN}🎉 COMPREHENSIVE CLEANUP COMPLETED SUCCESSFULLY!${NC}"
        echo -e "${GREEN}✅ All target ports are free for Jenkins deployment${NC}"
        exit 0
    else
        echo -e "${RED}❌ CLEANUP INCOMPLETE - Some ports still in use${NC}"
        echo -e "${YELLOW}⚠️  You may need to manually free remaining ports${NC}"
        exit 1
    fi
}

# Run main function
main "$@"