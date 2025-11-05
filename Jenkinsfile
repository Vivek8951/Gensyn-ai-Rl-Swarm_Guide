pipeline {
  agent any

  environment {
    DOCKERHUB_CREDENTIALS = 'dockerhub-credentials'
  }

  options {
    // keep build logs readable and fail fast on errors in sh blocks
    skipStagesAfterUnstable()
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Prepare Python env') {
      steps {
        // create a virtualenv if python3 is available and install requirements if present
        sh '''#!/bin/bash
set -euo pipefail

echo ">>> Checking for python3..."
if command -v python3 >/dev/null 2>&1; then
  echo "python3 found: $(python3 --version)"
  echo "Creating virtualenv .venv"
  python3 -m venv .venv
  . .venv/bin/activate
  if [ -f requirements.txt ]; then
    echo "Installing requirements.txt"
    pip install --upgrade pip
    pip install -r requirements.txt || true
  else
    echo "No requirements.txt found, skipping pip install"
  fi
else
  echo "python3 not found on agent, skipping virtualenv setup"
fi
'''
      }
    }

    stage('Build / Package') {
      steps {
        // Build pre-built Docker image and deploy
        script {
          echo "🏗️  BUILDING PRE-BUILT DOCKER IMAGE"
          echo "========================================"
          echo ""
          echo "📦 Pre-building all components during image creation:"
          echo "   • Git repository: Pre-cloned during build"
          echo "   • Node.js modules: Pre-installed during build"
          echo "   • Python environment: Pre-created during build"
          echo "   • Setup time: Instant (no downloads needed)"
          echo ""

          def prebuiltImageExists = fileExists('Dockerfile')
          if (prebuiltImageExists) {
            echo "✅ Pre-built Dockerfile found - building and deploying pre-built image"

            // Build pre-built image and deploy with all ports
            withCredentials([usernamePassword(credentialsId: "${DOCKERHUB_CREDENTIALS}", usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
              sh '''#!/bin/bash
set -euo pipefail
IMAGE_NAME="${DOCKER_USER}/gensyn-rl-swarm-prebuilt"
TAG="latest"

echo "🏗️  Building pre-built Docker image ${IMAGE_NAME}:${TAG}..."
echo "This will pre-install all dependencies during Docker build..."

# Build the pre-built Docker image
if docker build -t "${IMAGE_NAME}:${TAG}" .; then
    echo "✅ Pre-built Docker image built successfully!"
    echo ""
    echo "📦 Pre-built components:"
    echo "   • Git repository: Pre-cloned"
    echo "   • Node.js modules: Pre-installed"
    echo "   • Python environment: Pre-created"
    echo "   • Setup time: Instant"
    echo ""
else
    echo "❌ Docker build failed!"
    exit 1
fi

echo "🚀 Deploying pre-built image ${IMAGE_NAME}:${TAG}..."

# AGGRESSIVE CONTAINER CLEANUP - Stop ALL RL-Swarm related containers
echo "🧹 Cleaning up existing RL-Swarm containers..."
for container in $(docker ps -a --format "{{.Names}}" 2>/dev/null | grep -E "rl-swarm|gensyn" || true); do
    echo "Stopping container: $container"
    docker stop "$container" 2>/dev/null || true
    echo "Removing container: $container"
    docker rm "$container" 2>/dev/null || true
done

# Force cleanup of any dangling containers
echo "🧹 Cleaning up dangling containers..."
docker container prune -f 2>/dev/null || true

# Try to free up ports if still in use
echo "🔧 Checking for port conflicts on 3000, 8080-8082, 9000-9002..."
for port in 3000 8080 8081 8082 9000 9001 9002; do
    if lsof -i :$port >/dev/null 2>&1; then
        echo "⚠️  Port $port is still in use, trying to free it..."
        pkill -f ":$port" 2>/dev/null || true
        sleep 2
    fi
done

# Deploy the new container with unique name and retry logic
CONTAINER_NAME="rl-swarm-prebuilt-$(date +%s)"
MAX_RETRIES=3
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    echo "🚀 Attempting deployment (Attempt $((RETRY_COUNT + 1))..."

    if docker run -d \
        --name "${CONTAINER_NAME}" \
        -p 3000:3000 \
        -p 8080:8080 \
        -p 8081:8081 \
        -p 8082:8082 \
        -p 9000:9000 \
        -p 9001:9001 \
        -p 9002:9002 \
        -e AUTO_TUNNEL=true \
        -e REMOTE_ACCESS=true \
        -e PREBUILT=true \
        --restart unless-stopped \
        "${IMAGE_NAME}:${TAG}"; then

        echo "✅ Container deployed successfully!"
        break
    else
        echo "❌ Deployment attempt failed, cleaning up..."
        docker stop "${CONTAINER_NAME}" 2>/dev/null || true
        docker rm "${CONTAINER_NAME}" 2>/dev/null || true
        RETRY_COUNT=$((RETRY_COUNT + 1))
        if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
            echo "⏳ Waiting 5 seconds before retry..."
            sleep 5
        fi
    fi
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo "❌ All deployment attempts failed!"
    echo "🔍 Debugging port usage:"
    for port in 3000 8080 8081 8082 9000 9001 9002; do
        echo "Port $port: $(lsof -i :$port 2>/dev/null || echo 'Free')"
    done
    exit 1
fi

echo "✅ Pre-built container started successfully!"
echo ""
echo "📊 Container Status:"
docker ps --filter "name=${CONTAINER_NAME}" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""

echo "🔥 Pushing pre-built image to Docker Hub..."
if docker push "${IMAGE_NAME}:${TAG}"; then
    echo "✅ Pre-built image pushed successfully to Docker Hub!"
    echo "✅ Image available: ${IMAGE_NAME}:${TAG}"
else
    echo "⚠️  Docker push failed, but container is running locally"
    echo "   • Container continues to work locally"
    echo "   • Push credentials may need verification"
fi

echo ""
echo "📝 Access URLs:"
echo "   Main: http://localhost:3000"
echo "   Alternative: http://localhost:8080"
echo "   Port 9000: http://localhost:9000"
echo ""
echo "📊 Real-time logs:"
echo "   docker logs -f ${CONTAINER_NAME}"
echo ""
echo "🎉 PRE-BUILT DEPLOYMENT COMPLETE! 🚀"
echo "✅ All dependencies pre-installed - instant access!"
'''
            }
          } else {
            echo "❌ Dockerfile not found - cannot deploy pre-built image"
            error "Pre-built Dockerfile not found. Cannot continue."
          }
        }
      }
    }

    stage('Run rl-swarm (attempt non-interactive)') {
      steps {
        // Attempt to prepare and start run_rl_swarm.sh non-interactively.
        // WARNING: run_rl_swarm.sh requires interactive login via the web UI in many cases.
        // This attempts a background start and saves logs; it may still require human interaction.
        sh '''#!/bin/bash
set -euo pipefail

if [ -f run_rl_swarm.sh ]; then
  chmod +x run_rl_swarm.sh

  # Activate venv if created
  if [ -f .venv/bin/activate ]; then
    . .venv/bin/activate
  fi

  echo "Attempting non-interactive start of run_rl_swarm.sh. Output will go to rl_swarm.log"
  # Known prompts (from README): login via UI, "Would you like to push models... [y/N]" -> N,
  # press Enter to accept default model, and "Would you like your model to participate... [Y/n]" -> Y
  # We provide a conservative sequence of answers. Adjust as needed.
  printf '\\nN\\n\\nY\\n' | nohup ./run_rl_swarm.sh > rl_swarm.log 2>&1 &
  sleep 2
  echo "rl-swarm start command issued (background). Tail of rl_swarm.log:"
  tail -n +1 rl_swarm.log | sed -n '1,200p' || true
else
  echo "run_rl_swarm.sh not found — skipping start"
fi
'''
      }
    }

    stage('Smoke tests') {
      steps {
        // Run a few non-interactive checks if available
        sh '''#!/bin/bash
set -euo pipefail

echo "Checking for a basic executable or help output"
if [ -f run_rl_swarm.sh ]; then
  ./run_rl_swarm.sh --help > /dev/null 2>&1 || echo "run_rl_swarm.sh --help not supported; skipping"
else
  echo "No run_rl_swarm.sh present to check"
fi
'''
      }
    }
  }

  post {
    always {
      // Safely show a small snippet of the logs for debugging. Quote parentheses to avoid shell issues.
      echo 'Post-build: collecting logs and cleaning workspace'
      sh 'echo "last lines of rl_swarm.log (if exists):"'
      sh '''#!/bin/bash
set +e
if [ -f rl_swarm.log ]; then
  tail -n 200 rl_swarm.log || true
else
  echo "No rl_swarm.log found."
fi
'''
    }
    success {
      echo 'Build pipeline finished: SUCCESS'
    }
    failure {
      echo 'Build pipeline finished: FAILURE'
    }
  }
}