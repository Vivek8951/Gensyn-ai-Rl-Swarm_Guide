# Quick Start Guide - RL-Swarm Docker & CI/CD

## What's Been Set Up

This repository now includes complete Docker containerization and CI/CD automation for the RL-Swarm project.

### Files Added

```
.github/workflows/docker-build-push.yml  - GitHub Actions workflow
Jenkinsfile                              - Jenkins pipeline configuration
Dockerfile                               - Updated with sudo support
docker-compose.yml                       - Updated volume mappings
.dockerignore                            - Build exclusions
CI_CD_SETUP.md                          - Complete setup guide
QUICK_START.md                          - This file
```

---

## 🚀 Quick Start (Local Development)

### Option 1: Build and Run Locally

```bash
# Make deploy script executable
chmod +x deploy.sh

# Build the Docker image
./deploy.sh build

# Start the container
./deploy.sh up

# View logs
./deploy.sh logs

# Access http://localhost:3000 for login
```

### Option 2: Use Pre-built Image (After CI/CD Setup)

```bash
# Pull from Docker Hub
./deploy.sh pull yourusername/rl-swarm:latest

# Start container
./deploy.sh up

# View logs
./deploy.sh logs
```

---

## 🔄 CI/CD Setup (5 Minutes)

### GitHub Actions

1. **Add Secrets** (Settings → Secrets → Actions):
   - `DOCKER_USERNAME`: Your Docker Hub username
   - `DOCKER_PASSWORD`: Your Docker Hub token

2. **Add Variable** (Settings → Variables → Actions):
   - `LAST_BUILD_COMMIT`: Leave empty

3. **Trigger Build** (Actions tab):
   - Click "Build and Push Docker Image"
   - Click "Run workflow"

4. **Wait for Build** (~10-15 minutes first time)

5. **Use Image**:
   ```bash
   ./deploy.sh pull yourusername/rl-swarm:latest
   ./deploy.sh up
   ```

### Jenkins Setup

1. **Add Docker Hub Credentials**:
   - ID: `docker-hub-credentials`
   - Type: Username with password

2. **Create Pipeline Job**:
   - New Item → Pipeline
   - SCM: Git
   - Script Path: `Jenkinsfile`
   - Build Triggers: Poll SCM `H */6 * * *`

3. **Run Build**:
   - Click "Build Now"
   - Monitor console output

---

## 📋 Deploy Script Commands

```bash
./deploy.sh build              # Build Docker image locally
./deploy.sh up                 # Start container
./deploy.sh down               # Stop container
./deploy.sh logs               # View live logs
./deploy.sh restart            # Restart container
./deploy.sh pull <image>       # Pull specific image
./deploy.sh update <image>     # Update and restart
./deploy.sh shell              # Open container shell
./deploy.sh clean              # Clean Docker resources
```

---

## 🐳 Docker Features

### User Configuration

The Docker image runs as non-root user `rlswarm` but has sudo access:

```bash
# Both work:
docker exec -it rl-swarm-node python3 --version
docker exec -it rl-swarm-node sudo apt update
```

### Persistent Volumes

- `swarm-data`: Application data
- `swarm-logs`: Log files
- `swarm-pem`: Key files (swarm.pem)

### Port Mapping

- Host: `3000` → Container: `3000`
- Access: http://localhost:3000

---

## 🔍 How It Works

### Automated Build Process

1. **Monitor Upstream**: Checks `gensyn-ai/rl-swarm` every 6 hours
2. **Detect Changes**: Compares commits
3. **Build Image**: Only if changes detected
4. **Push to Registry**: Docker Hub + GitHub Container Registry
5. **Tag Version**: Date + commit hash

### Dockerfile Steps

1. Base: Ubuntu 22.04
2. Install: Python, Node.js, Yarn, system tools
3. Create: Non-root user with sudo access
4. Clone: RL-Swarm repository
5. Setup: Python virtual environment
6. Expose: Port 3000
7. Run: `./run_rl_swarm.sh`

---

## 🚨 Troubleshooting

### Container Won't Start

```bash
# Check logs
./deploy.sh logs

# Restart
./deploy.sh restart

# Rebuild
./deploy.sh down
./deploy.sh build
./deploy.sh up
```

### Port 3000 Already in Use

```bash
# Find process using port 3000
sudo lsof -i :3000

# Kill the process or change docker-compose.yml port mapping to "3001:3000"
```

### Login Issues

1. Ensure container is running: `docker ps`
2. Check logs: `./deploy.sh logs`
3. Access http://localhost:3000
4. Follow on-screen instructions

### CI/CD Build Failing

**GitHub Actions:**
- Check secrets are correctly set
- Verify LAST_BUILD_COMMIT variable exists
- Review workflow logs in Actions tab

**Jenkins:**
- Verify Docker daemon is running
- Check docker-hub-credentials configuration
- Review console output

---

## 📖 Full Documentation

For complete details, see:
- **CI_CD_SETUP.md** - Complete CI/CD setup guide
- **DOCKER_SETUP.md** - Docker deployment guide
- **README.md** - Original RL-Swarm setup instructions

---

## 🎯 Next Steps

1. **Set up CI/CD** (GitHub Actions or Jenkins)
2. **Configure secrets** (Docker Hub credentials)
3. **Trigger first build** (Manual or automatic)
4. **Deploy to VPS/server** using pre-built images
5. **Set up monitoring** for logs and health checks

---

## 📊 Build Status

After CI/CD setup, your images will be available at:

- **Docker Hub**: `docker pull yourusername/rl-swarm:latest`
- **GHCR**: `docker pull ghcr.io/yourusername/rl-swarm:latest`

Images are automatically tagged with:
- `latest` - Most recent build
- `YYYYMMDD` - Daily build
- `YYYYMMDD-<sha>` - Specific commit

---

## 🔐 VPS Deployment

```bash
# SSH to VPS
ssh user@your-vps

# Clone this repo
git clone https://github.com/yourusername/your-repo.git
cd your-repo

# Pull and run
./deploy.sh pull yourusername/rl-swarm:latest
./deploy.sh up

# Configure firewall
sudo ufw allow 3000/tcp
sudo ufw enable

# Access via http://your-vps-ip:3000
```

---

## ✅ Verification Checklist

- [ ] Docker and Docker Compose installed
- [ ] Repository cloned locally
- [ ] deploy.sh is executable (`chmod +x deploy.sh`)
- [ ] Can build locally (`./deploy.sh build`)
- [ ] Can start container (`./deploy.sh up`)
- [ ] Can access http://localhost:3000
- [ ] GitHub Actions secrets configured
- [ ] First CI/CD build successful
- [ ] Can pull pre-built image
- [ ] Container runs with both root and sudo

---

**Need Help?**
- GitHub Actions logs: Repository → Actions tab
- Jenkins logs: Job → Console Output
- Container logs: `./deploy.sh logs`
- Shell access: `./deploy.sh shell`

---

**Happy Swarming!** 🐝
