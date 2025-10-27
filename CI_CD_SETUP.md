# CI/CD Setup Guide for RL-Swarm

This guide explains how to set up continuous integration and deployment for the RL-Swarm project using GitHub Actions and Jenkins.

## Table of Contents

1. [GitHub Actions Setup](#github-actions-setup)
2. [Jenkins Setup](#jenkins-setup)
3. [Docker Configuration](#docker-configuration)
4. [Testing the Setup](#testing-the-setup)

---

## GitHub Actions Setup

### Prerequisites

- GitHub account with repository access
- Docker Hub account (or GitHub Container Registry)

### Step 1: Configure Repository Secrets

Go to your GitHub repository:
**Settings → Secrets and variables → Actions → Secrets**

Add the following secrets:

| Secret Name | Value | Description |
|------------|-------|-------------|
| `DOCKER_USERNAME` | Your Docker Hub username | Used to push images to Docker Hub |
| `DOCKER_PASSWORD` | Your Docker Hub token/password | Authentication for Docker Hub |

### Step 2: Create Repository Variable

Go to **Settings → Secrets and variables → Actions → Variables**

Create a new variable:

| Variable Name | Initial Value | Description |
|--------------|---------------|-------------|
| `LAST_BUILD_COMMIT` | (empty) | Tracks last built commit from upstream |

### Step 3: Workflow Configuration

The workflow file `.github/workflows/docker-build-push.yml` is configured with:

**Triggers:**
- Schedule: Runs every 6 hours
- Manual: Can be triggered from Actions tab
- Push: Runs on push to main branch

**Features:**
- Checks upstream RL-Swarm repository for changes
- Builds Docker image only when changes detected
- Pushes to Docker Hub and GitHub Container Registry
- Updates build tracking variable
- Creates release tags

### Step 4: Manual Trigger

1. Go to **Actions** tab in your GitHub repository
2. Select "Build and Push Docker Image" workflow
3. Click "Run workflow"
4. Select branch (usually main)
5. Click "Run workflow" button

### Step 5: Verify Build

1. Monitor build progress in Actions tab
2. Check for success status
3. Verify images on Docker Hub or GHCR:
   ```bash
   docker pull yourusername/rl-swarm:latest
   # or
   docker pull ghcr.io/yourusername/rl-swarm:latest
   ```

---

## Jenkins Setup

### Prerequisites

- Jenkins server with Docker installed
- Docker Hub account

### Step 1: Install Required Jenkins Plugins

Install the following plugins:
- Docker Pipeline
- Pipeline
- Git
- Credentials Binding
- HTTP Request

### Step 2: Configure Docker Hub Credentials

1. Go to **Jenkins → Manage Jenkins → Credentials**
2. Click on appropriate domain (usually "Global")
3. Click **Add Credentials**
4. Configure:
   - Kind: Username with password
   - Username: Your Docker Hub username
   - Password: Your Docker Hub token/password
   - ID: `docker-hub-credentials`
   - Description: Docker Hub Access

### Step 3: Create Pipeline Job

1. Go to **Jenkins → New Item**
2. Enter job name (e.g., "rl-swarm-build")
3. Select **Pipeline** and click OK
4. Configure:

**General:**
- Check "GitHub project" and add repository URL

**Build Triggers:**
- Poll SCM: `H */6 * * *` (every 6 hours)
- GitHub hook trigger for GITScm polling (optional)

**Pipeline:**
- Definition: Pipeline script from SCM
- SCM: Git
- Repository URL: Your repository URL
- Branch: `*/main`
- Script Path: `Jenkinsfile`

5. Click **Save**

### Step 4: Run Pipeline

1. Go to job page
2. Click **Build Now**
3. Monitor console output
4. Verify successful build and push

### Step 5: Webhook Setup (Optional)

For automatic builds on repository changes:

1. Go to GitHub repository
2. **Settings → Webhooks → Add webhook**
3. Payload URL: `http://your-jenkins-url/github-webhook/`
4. Content type: application/json
5. Select: "Just the push event"
6. Click **Add webhook**

---

## Docker Configuration

### Dockerfile Overview

The Dockerfile includes:

**System Requirements:**
- Ubuntu 22.04 base image
- Python 3 with virtual environment
- Node.js 20.x and Yarn
- System dependencies: git, curl, wget, screen, lsof, ufw

**User Setup:**
- Non-root user: `rlswarm`
- Sudo access enabled (passwordless)
- Works with both root and sudo commands

**RL-Swarm Setup:**
- Clones from `gensyn-ai/rl-swarm` repository
- Creates Python virtual environment
- Sets up proper permissions
- Exposes port 3000

### Running with Docker

**Build locally:**
```bash
./deploy.sh build
```

**Start container:**
```bash
./deploy.sh up
```

**View logs:**
```bash
./deploy.sh logs
```

**Access web interface:**
Open browser to `http://localhost:3000`

### Running from Registry

**Pull and run:**
```bash
./deploy.sh pull yourusername/rl-swarm:latest
./deploy.sh up
```

**Update to latest:**
```bash
./deploy.sh update yourusername/rl-swarm:latest
```

### Docker Compose

The `docker-compose.yml` includes:
- Port mapping: 3000:3000
- Persistent volumes for data, logs, and pem files
- Automatic restart policy
- Interactive terminal support

---

## Testing the Setup

### Test GitHub Actions

1. Make a commit to main branch
2. Check Actions tab for workflow run
3. Verify successful build
4. Pull image and test:
   ```bash
   docker pull yourusername/rl-swarm:latest
   docker run -p 3000:3000 yourusername/rl-swarm:latest
   ```

### Test Jenkins Pipeline

1. Trigger build manually
2. Check console output for errors
3. Verify image pushed to registry
4. Test deployment:
   ```bash
   ./deploy.sh pull yourusername/rl-swarm:latest
   ./deploy.sh up
   ./deploy.sh logs
   ```

### Verify RL-Swarm Functionality

1. Start container: `./deploy.sh up`
2. Access http://localhost:3000
3. Complete login process
4. Check logs: `./deploy.sh logs`
5. Verify node is running properly

### Test Both Root and Sudo

The Docker image supports both execution contexts:

**Root context (default):**
```bash
docker exec -it rl-swarm-node /bin/bash
python3 --version
```

**Sudo context:**
```bash
docker exec -it rl-swarm-node /bin/bash
sudo apt update
sudo python3 --version
```

---

## Troubleshooting

### GitHub Actions Issues

**Build not triggering:**
- Verify workflow file syntax
- Check schedule cron expression
- Ensure LAST_BUILD_COMMIT variable exists

**Push failing:**
- Verify DOCKER_USERNAME and DOCKER_PASSWORD secrets
- Check Docker Hub credentials validity
- Ensure sufficient Docker Hub storage

### Jenkins Issues

**Build failing:**
- Check Docker daemon is running
- Verify docker-hub-credentials configured
- Review console output for errors

**Credentials not working:**
- Ensure credential ID matches `docker-hub-credentials`
- Verify Docker Hub token has push permissions

### Docker Issues

**Build errors:**
- Check internet connectivity
- Verify base image availability
- Review Dockerfile syntax

**Container not starting:**
- Check port 3000 not already in use
- Review container logs: `./deploy.sh logs`
- Verify volumes are properly mounted

**Permission errors:**
- Container runs as `rlswarm` user
- Use sudo for privileged operations
- Check volume permissions

---

## Deployment Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     GitHub Repository                       │
│  ├── .github/workflows/docker-build-push.yml               │
│  ├── Jenkinsfile                                           │
│  ├── Dockerfile                                            │
│  └── docker-compose.yml                                    │
└────────────┬────────────────────────────────────────────────┘
             │
    ┌────────┴────────┐
    │                 │
    ▼                 ▼
┌─────────┐      ┌─────────┐
│ GitHub  │      │ Jenkins │
│ Actions │      │ Server  │
└────┬────┘      └────┬────┘
     │                │
     │  Monitors      │  Monitors
     │  Upstream      │  Upstream
     │  Changes       │  Changes
     │                │
     ▼                ▼
┌─────────────────────────┐
│  Build Docker Image     │
│  ├── Clone rl-swarm     │
│  ├── Setup environment  │
│  └── Create image       │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│   Push to Registries    │
│  ├── Docker Hub         │
│  └── GitHub Container   │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│   Deploy to VPS/Local   │
│  ├── Pull image         │
│  ├── Start container    │
│  └── Access port 3000   │
└─────────────────────────┘
```

---

## Best Practices

1. **Regular Updates**: The CI/CD checks for updates every 6 hours
2. **Version Tags**: Images are tagged with date and commit hash
3. **Security**: Use Docker secrets/tokens, never commit credentials
4. **Monitoring**: Check logs regularly with `./deploy.sh logs`
5. **Backups**: Persistent volumes store data, logs, and pem files
6. **Testing**: Always test locally before production deployment
7. **Documentation**: Keep this guide updated with changes

---

## Support

- For RL-Swarm issues: https://github.com/gensyn-ai/rl-swarm
- For Docker issues: Check logs with `./deploy.sh logs`
- For CI/CD issues: Review workflow logs in GitHub Actions or Jenkins console

---

**Last Updated:** $(date +%Y-%m-%d)
