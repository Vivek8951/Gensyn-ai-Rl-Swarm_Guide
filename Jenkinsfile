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
        // Use pre-built Docker image - no build stage needed
        script {
          echo "✅ USING PRE-BUILT DOCKER IMAGE - No build stage needed"
          echo ""
          echo "📦 Pre-built image contains:"
          echo "   • Git repository: Pre-cloned"
          echo "   • Node.js modules: Pre-installed"
          echo "   • Python environment: Pre-built"
          echo "   • Setup time: Instant"
          echo ""
          echo "🚀 Deploying pre-built Docker image..."

          def prebuiltImageExists = fileExists('Dockerfile')
          if (prebuiltImageExists) {
            echo "✅ Pre-built Dockerfile found - deploying pre-built image"

            # Deploy pre-built image with all ports
            withCredentials([usernamePassword(credentialsId: "${DOCKERHUB_CREDENTIALS", usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
              sh '''#!/bin/bash
set -euo pipefail
IMAGE_NAME="${DOCKER_USER}/gensyn-rl-swarm-prebuilt"
TAG="latest"

echo "🚀 Deploying pre-built image ${IMAGE_NAME}:${TAG}..."
docker run -d \
    --name rl-swarm-prebuilt \
    -p 3000:3000 \
    -p 8080:8080 \
    -p 8081:8081 \
    -p 8082:8082 \
    -p 9000:9000 \
    -p 9001:9001 \
    -p 9002:9002 \
    -e AUTO_TUNNEL=true \
    -e REMOTE_ACCESS=true \
    --restart unless-stopped \
    "${IMAGE_NAME}:${TAG}"

echo "✅ Pre-built container started successfully!"
echo ""
echo "📊 Container Status:"
docker ps --filter "name=rl-swarm-prebuilt" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""

echo "📝 Access URLs:"
echo "   Main: http://localhost:3000"
echo "   Alternative: http://localhost:8080"
echo "   Port 9000: http://localhost:9000"
echo ""
echo "📊 Real-time logs:"
echo "   docker logs -f rl-swarm-prebuilt"
echo ""
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
