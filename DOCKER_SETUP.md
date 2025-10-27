# 🐳 RL-Swarm Docker Setup & CI/CD Guide

This repository provides Docker containerization and automated CI/CD for the [RL-Swarm project](https://github.com/gensyn-ai/rl-swarm).

## 📋 Prerequisites

- Docker and Docker Compose installed
- (For CI/CD) GitHub account with repository access
- (For CI/CD) Docker Hub account or GitHub Container Registry access

## 🚀 Quick Start

### Option 1: Build and Run Locally

```bash
# Build the Docker image
./deploy.sh build

# Start the container
./deploy.sh up

# Access the login interface at http://localhost:3000
```

### Option 2: Pull from Registry (After CI/CD Setup)

```bash
# Pull the latest image
./deploy.sh pull yourusername/rl-swarm:latest

# Start the container
./deploy.sh up
```

## 🔧 Deployment Commands

The `deploy.sh` script provides convenient commands:

```bash
./deploy.sh build              # Build Docker image locally
./deploy.sh up                 # Start the container
./deploy.sh down               # Stop the container
./deploy.sh logs               # View container logs (live)
./deploy.sh restart            # Restart the container
./deploy.sh pull <image>       # Pull specific Docker image
./deploy.sh update <image>     # Update to latest version
./deploy.sh shell              # Open shell in container
./deploy.sh clean              # Clean up Docker resources
```

## 📦 Docker Image Details

The Docker image includes:
- Ubuntu 22.04 base
- Python 3 with virtual environment
- Node.js 20.x and Yarn
- All system dependencies (curl, wget, git, screen, etc.)
- Pre-cloned RL-Swarm repository
- Exposed port 3000 for web interface

## 🔄 CI/CD Pipeline Setup

The CI/CD pipeline automatically monitors the upstream RL-Swarm repository and builds new Docker images when changes are detected.

### Step 1: Set Up Repository Secrets

In your GitHub repository, go to **Settings → Secrets and variables → Actions** and add:

#### Required Secrets:
- `DOCKER_USERNAME`: Your Docker Hub username
- `DOCKER_PASSWORD`: Your Docker Hub access token/password

#### Optional (for GitHub Container Registry):
The workflow automatically uses `GITHUB_TOKEN` for GHCR.

### Step 2: Create Repository Variable

Go to **Settings → Secrets and variables → Actions → Variables** and create:

- **Name**: `LAST_BUILD_COMMIT`
- **Value**: Leave empty initially (will be auto-populated)

### Step 3: Configure the Workflow

The workflow file `.github/workflows/docker-build-push.yml` is already configured with:

- **Scheduled runs**: Every 6 hours (checks for upstream changes)
- **Manual trigger**: Can be run manually from Actions tab
- **Push trigger**: Runs on push to main branch

#### How it works:

1. **Check Upstream**: Queries the RL-Swarm repository for latest commit
2. **Compare**: Compares with `LAST_BUILD_COMMIT` variable
3. **Build**: If changes detected, builds new Docker image
4. **Push**: Pushes to Docker Hub and GitHub Container Registry
5. **Update**: Updates `LAST_BUILD_COMMIT` variable
6. **Tag**: Creates a release tag for tracking

### Step 4: Verify CI/CD

1. Go to **Actions** tab in your repository
2. Select "Build and Push Docker Image" workflow
3. Click "Run workflow" to trigger manually
4. Monitor the build progress

### Step 5: Pull and Use the Image

After successful build:

```bash
# Pull from Docker Hub
docker pull yourusername/rl-swarm:latest

# Or pull from GitHub Container Registry
docker pull ghcr.io/yourusername/rl-swarm:latest

# Deploy using the script
./deploy.sh update yourusername/rl-swarm:latest
```

## 🔐 VPS Deployment

To deploy on a VPS:

```bash
# SSH into your VPS
ssh username@your-vps-ip

# Clone this repository
git clone https://github.com/yourusername/your-repo.git
cd your-repo

# Pull the Docker image
./deploy.sh pull yourusername/rl-swarm:latest

# Start the container
./deploy.sh up

# Configure firewall
sudo ufw allow 3000/tcp
sudo ufw enable

# Access via http://your-vps-ip:3000
```

## 📊 Monitoring and Logs

```bash
# View live logs
./deploy.sh logs

# Check container status
docker ps

# View container stats
docker stats rl-swarm-node
```

## 🔄 Updating to Latest Version

The CI/CD pipeline automatically builds new images when upstream changes occur. To update your deployment:

```bash
# Pull latest image and restart
./deploy.sh update yourusername/rl-swarm:latest
```

## 🐛 Troubleshooting

### Container not starting?
```bash
# Check logs
./deploy.sh logs

# Restart container
./deploy.sh restart
```

### Need to rebuild locally?
```bash
# Stop container
./deploy.sh down

# Rebuild image
./deploy.sh build

# Start fresh
./deploy.sh up
```

### CI/CD build failing?
- Verify Docker Hub credentials in GitHub secrets
- Check if `LAST_BUILD_COMMIT` variable exists
- Review workflow logs in Actions tab

## 📁 Project Structure

```
.
├── .github/
│   └── workflows/
│       └── docker-build-push.yml    # CI/CD pipeline
├── Dockerfile                        # Docker image definition
├── docker-compose.yml                # Docker Compose configuration
├── deploy.sh                         # Deployment helper script
├── .dockerignore                     # Docker build exclusions
└── DOCKER_SETUP.md                   # This file
```

## 🔗 Useful Links

- [Original RL-Swarm Repository](https://github.com/gensyn-ai/rl-swarm)
- [Docker Hub](https://hub.docker.com/)
- [GitHub Container Registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)

## 📝 Notes

- The container runs the RL-Swarm setup script on startup
- Interactive login is required on first run (access via localhost:3000)
- Data persists in Docker volumes (`swarm-data` and `swarm-logs`)
- The CI/CD pipeline checks for updates every 6 hours by default

## 🤝 Contributing

Feel free to open issues or submit pull requests for improvements to the Docker setup or CI/CD pipeline.

---

**Happy Swarming!** 🐝
