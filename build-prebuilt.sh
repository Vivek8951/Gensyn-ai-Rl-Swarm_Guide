#!/bin/bash

# Build and Push Pre-built RL-Swarm Docker Image
# Everything is pre-built during Docker image creation

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}🏗️  Building Pre-built RL-Swarm Docker Image${NC}"
echo "=========================================="
echo ""

# Configuration
DOCKER_USER="${DOCKER_USER:-viveks895}"
IMAGE_NAME="${DOCKER_USER}/gensyn-rl-swarm-prebuilt"
TAG="${TAG:-latest}"

echo -e "${CYAN}📋 Build Configuration:${NC}"
echo "   • Docker User: ${DOCKER_USER}"
echo "   • Image Name: ${IMAGE_NAME}"
echo "   • Tag: ${TAG}"
echo ""

echo -e "${YELLOW}🔧 Pre-built Components:${NC}"
echo "   • Git repository: Pre-cloned during build"
echo "   • Node.js modules: Pre-installed during build"
echo "   • Python virtual env: Pre-created during build"
echo "   • Setup time: Instant (no downloads needed)"
echo ""

echo -e "${BLUE}🏗️  Building Docker image...${NC}"
echo ""

# Build the pre-built Docker image
if ! docker build -f Dockerfile.prebuilt -t "${IMAGE_NAME}:${TAG}" .; then
    echo -e "${RED}❌ Docker build failed!${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Docker image built successfully!${NC}"
echo ""

# Verify the image
echo -e "${BLUE}📊 Image Information:${NC}"
docker images "${IMAGE_NAME}:${TAG}"
echo ""

echo -e "${CYAN}🔍 Verifying Pre-built Components:${NC}"
echo ""

# Check if repository is pre-cloned
echo "   📦 Git repository:"
REPO_COMMIT=$(docker run --rm "${IMAGE_NAME}:${TAG}" git -C /home/rlswarm/rl-swarm rev-parse --short HEAD 2>/dev/null || echo "unknown")
echo "      Commit: ${REPO_COMMIT}"

# Check if node_modules is pre-installed
echo "   📦 Node.js modules:"
NODE_MODULES_COUNT=$(docker run --rm "${IMAGE_NAME}:${TAG}" bash -c "cd /home/rlswarm/rl-swarm && ls node_modules 2>/dev/null | wc -l" 2>/dev/null || echo "0")
echo "      Packages: ${NODE_MODULES_COUNT}"

# Check if virtual environment is pre-built
echo "   🐍 Python environment:"
PYTHON_VERSION=$(docker run --rm "${IMAGE_NAME}:${TAG}" bash -c "source /home/rlswarm/rl-swarm/.venv/bin/activate && python --version" 2>/dev/null || echo "unknown")
echo "      Version: ${PYTHON_VERSION}"

echo ""

echo -e "${GREEN}✅ All pre-built components verified!${NC}"
echo ""

# Login to Docker Hub (if credentials are available)
if [ -n "${DOCKER_PASS}" ] && [ -n "${DOCKER_USER}" ]; then
    echo -e "${BLUE}🔐 Logging into Docker Hub...${NC}"
    echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
    echo -e "${GREEN}✅ Logged into Docker Hub${NC}"
    echo ""

    # Push the image
    echo -e "${BLUE}📤 Pushing Docker image...${NC}"
    if docker push "${IMAGE_NAME}:${TAG}"; then
        echo -e "${GREEN}✅ Docker image pushed successfully!${NC}"
        echo ""
        echo -e "${CYAN}🎉 PRE-BUILT IMAGE READY FOR USE!${NC}"
        echo "====================================="
        echo ""
        echo -e "${YELLOW}🚀 Quick Start Commands:${NC}"
        echo ""
        echo "Pull and run:"
        echo "   docker pull ${IMAGE_NAME}:${TAG}"
        echo "   docker run -d -p 3000:3000 ${IMAGE_NAME}:${TAG}"
        echo ""
        echo "Or use the provided run script:"
        echo "   ./run-prebuilt.sh"
        echo ""
        echo -e "${YELLOW}🌐 Access URLs:${NC}"
        echo "   • Main: http://your-vps-ip:3000"
        echo "   • Alternative: http://your-vps-ip:8080"
        echo "   • Instant startup (no downloads)!"
        echo ""
    else
        echo -e "${RED}❌ Failed to push Docker image${NC}"
        docker logout
        exit 1
    fi

    # Logout
    docker logout
else
    echo -e "${YELLOW}⚠️  Docker credentials not provided${NC}"
    echo "   • Image built locally"
    echo "   • To push: DOCKER_USER=youruser DOCKER_PASS=yourpass ./build-prebuilt.sh"
    echo ""
    echo -e "${CYAN}🎉 PRE-BUILT IMAGE READY LOCALLY!${NC}"
    echo "====================================="
    echo ""
    echo -e "${YELLOW}🚀 Test Locally:${NC}"
    echo "   docker run -d -p 3000:3000 ${IMAGE_NAME}:${TAG}"
    echo ""
    echo -e "${YELLOW}🌐 Access:${NC}"
    echo "   http://localhost:3000"
    echo ""
fi

echo -e "${GREEN}✅ Pre-built Docker build completed!${NC}"
echo -e "${GREEN}   💾 All dependencies pre-built into image${NC}"
echo -e "${GREEN}   🚀 Instant startup for users${NC}"
echo -e "${GREEN}   📦 No downloads needed when running${NC}"
echo ""