# RL-Swarm Deployment Overview

## 📦 What's Included

This repository provides a complete Docker containerization and CI/CD automation solution for the [Gensyn RL-Swarm](https://github.com/gensyn-ai/rl-swarm) project.

### Key Features

✅ **Docker Containerization**
- Ubuntu 22.04 base with all dependencies
- Non-root user with sudo access
- Persistent volumes for data, logs, and keys
- Port 3000 exposed for web interface

✅ **GitHub Actions CI/CD**
- Automated builds on upstream changes
- Pushes to Docker Hub + GitHub Container Registry
- Scheduled checks every 6 hours
- Manual trigger support

✅ **Jenkins Pipeline**
- Monitors upstream repository
- Builds only when changes detected
- Automated testing and deployment
- Tracks build history

✅ **Easy Deployment**
- Single script for all operations
- Works on VPS, local, and cloud
- Automated setup and configuration
- Comprehensive logging

---

## 🎯 Quick Links

| Document | Purpose |
|----------|---------|
| **QUICK_START.md** | Get running in 5 minutes |
| **CI_CD_SETUP.md** | Complete CI/CD configuration |
| **DOCKER_SETUP.md** | Docker deployment details |
| **README.md** | Original RL-Swarm instructions |

---

## 🚀 Get Started in 3 Steps

### 1. Local Testing (No CI/CD Required)

```bash
chmod +x deploy.sh
./deploy.sh build
./deploy.sh up
```

Access http://localhost:3000

### 2. Set Up CI/CD (Optional but Recommended)

**GitHub Actions:**
```
1. Add DOCKER_USERNAME and DOCKER_PASSWORD secrets
2. Create LAST_BUILD_COMMIT variable
3. Trigger workflow from Actions tab
```

**Jenkins:**
```
1. Add docker-hub-credentials
2. Create pipeline job pointing to Jenkinsfile
3. Click "Build Now"
```

### 3. Deploy Pre-Built Image

```bash
./deploy.sh pull yourusername/rl-swarm:latest
./deploy.sh up
./deploy.sh logs
```

---

## 📁 Repository Structure

```
.
├── .github/
│   └── workflows/
│       └── docker-build-push.yml    # GitHub Actions workflow
├── Dockerfile                        # Multi-user Docker image
├── docker-compose.yml                # Container orchestration
├── Jenkinsfile                       # Jenkins pipeline
├── deploy.sh                         # Deployment helper script
├── .dockerignore                     # Build exclusions
├── CI_CD_SETUP.md                    # Complete CI/CD guide
├── QUICK_START.md                    # Quick reference
├── DOCKER_SETUP.md                   # Docker details
├── DEPLOYMENT_OVERVIEW.md            # This file
└── README.md                         # Original RL-Swarm guide
```

---

## 🔄 Automated Workflow

```
┌─────────────────────────────────────────┐
│  Upstream: gensyn-ai/rl-swarm          │
│  Changes detected in main branch        │
└─────────────┬───────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│  CI/CD Triggers (Every 6 hours)        │
│  ├── GitHub Actions                     │
│  └── Jenkins Pipeline                   │
└─────────────┬───────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│  Build Process                          │
│  ├── Clone rl-swarm repository          │
│  ├── Install dependencies               │
│  ├── Create Python venv                 │
│  ├── Configure permissions              │
│  └── Build Docker image                 │
└─────────────┬───────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│  Test & Validate                        │
│  ├── Verify Python version              │
│  ├── Verify Node.js version             │
│  └── Verify Yarn version                │
└─────────────┬───────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│  Push to Registries                     │
│  ├── Docker Hub                         │
│  └── GitHub Container Registry          │
└─────────────┬───────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│  Tag & Version                          │
│  ├── latest                             │
│  ├── YYYYMMDD                           │
│  └── YYYYMMDD-commit                    │
└─────────────┬───────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│  Ready for Deployment                   │
│  ├── VPS / Cloud servers                │
│  ├── Local development                  │
│  └── Production environments            │
└─────────────────────────────────────────┘
```

---

## 🐳 Docker Configuration

### Base Image
- **OS**: Ubuntu 22.04 LTS
- **Python**: 3.x with venv
- **Node.js**: 20.x LTS
- **Package Manager**: Yarn

### User Configuration
- **User**: `rlswarm` (non-root)
- **Sudo**: Enabled (passwordless)
- **Home**: `/home/rlswarm`
- **Workdir**: `/home/rlswarm/rl-swarm`

### Volumes
```yaml
swarm-data: Application data
swarm-logs: Log files
swarm-pem: SSH/PEM keys
```

### Environment
```bash
PYTHONUNBUFFERED=1
PATH=/home/rlswarm/rl-swarm/.venv/bin:$PATH
```

---

## 🎮 Deploy Script Commands

### Build & Run
```bash
./deploy.sh build              # Build image locally
./deploy.sh up                 # Start container
./deploy.sh down               # Stop container
./deploy.sh restart            # Restart container
```

### Image Management
```bash
./deploy.sh pull <image>       # Pull from registry
./deploy.sh update <image>     # Pull and restart
```

### Debugging
```bash
./deploy.sh logs               # View live logs
./deploy.sh shell              # Open container shell
./deploy.sh clean              # Clean resources
```

---

## 🔐 Security Features

### Container Security
- Runs as non-root user by default
- Sudo access for privileged operations
- No hardcoded credentials
- Isolated network namespace

### CI/CD Security
- GitHub secrets for credentials
- Jenkins credential binding
- Automated secret rotation support
- No credentials in logs

### Volume Security
- Persistent storage for keys
- Isolated from host filesystem
- Proper permission management

---

## 📊 CI/CD Features

### GitHub Actions
- **Trigger**: Schedule, Manual, Push
- **Check**: Upstream changes every 6 hours
- **Build**: Only when changes detected
- **Push**: Docker Hub + GHCR
- **Tag**: Multiple versioning schemes

### Jenkins
- **Monitoring**: Upstream repository
- **Testing**: Automated validation
- **Deployment**: Automated push
- **Tracking**: Build commit history

---

## 🌍 Deployment Scenarios

### Local Development
```bash
./deploy.sh build
./deploy.sh up
# Access http://localhost:3000
```

### VPS Server
```bash
ssh user@vps
git clone <repo>
./deploy.sh pull username/rl-swarm:latest
./deploy.sh up
sudo ufw allow 3000/tcp
# Access http://vps-ip:3000
```

### Cloud Platform (AWS/GCP/Azure)
```bash
# Pull image
docker pull username/rl-swarm:latest

# Run with cloud-specific configs
docker run -d \
  -p 3000:3000 \
  -v data:/home/rlswarm/rl-swarm/data \
  username/rl-swarm:latest
```

### Kubernetes
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: rl-swarm
spec:
  replicas: 1
  template:
    spec:
      containers:
      - name: rl-swarm
        image: username/rl-swarm:latest
        ports:
        - containerPort: 3000
```

---

## 🔍 Monitoring & Logging

### Container Logs
```bash
# Live logs
./deploy.sh logs

# Last 100 lines
docker logs --tail 100 rl-swarm-node

# Since 1 hour ago
docker logs --since 1h rl-swarm-node
```

### Container Stats
```bash
# Real-time stats
docker stats rl-swarm-node

# Container details
docker inspect rl-swarm-node
```

### Health Checks
```bash
# Container status
docker ps | grep rl-swarm

# Port accessibility
curl http://localhost:3000

# Container shell
./deploy.sh shell
```

---

## 🐛 Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| Port 3000 in use | Change port in docker-compose.yml or kill process |
| Container won't start | Check logs: `./deploy.sh logs` |
| Build fails | Check internet connection and Docker daemon |
| Login issues | Ensure container running and access localhost:3000 |
| CI/CD fails | Verify secrets/credentials configured correctly |

### Debug Commands
```bash
# Check container status
docker ps -a

# View all logs
docker logs rl-swarm-node

# Restart container
./deploy.sh restart

# Rebuild from scratch
./deploy.sh down
./deploy.sh build
./deploy.sh up

# Shell access
./deploy.sh shell
```

---

## 📈 Performance Tips

1. **Use Pre-built Images**: Faster than building locally
2. **Volume Mounts**: Persist data across restarts
3. **Resource Limits**: Set in docker-compose.yml if needed
4. **Network Mode**: Use host network for better performance
5. **Multi-stage Builds**: Consider for production

---

## 🔄 Update Process

### Automatic (CI/CD)
- Checks every 6 hours
- Builds on upstream changes
- Pushes new images automatically

### Manual Update
```bash
# Pull latest
./deploy.sh update username/rl-swarm:latest

# Or rebuild
git pull
./deploy.sh down
./deploy.sh build
./deploy.sh up
```

---

## 🤝 Contributing

### Docker Improvements
- Optimize build time
- Reduce image size
- Add health checks
- Improve security

### CI/CD Enhancements
- Add more tests
- Improve notifications
- Add deployment stages
- Enhance monitoring

---

## 📚 Additional Resources

- [RL-Swarm Repository](https://github.com/gensyn-ai/rl-swarm)
- [Docker Documentation](https://docs.docker.com/)
- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [Jenkins Pipeline Docs](https://www.jenkins.io/doc/book/pipeline/)

---

## 📝 Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2024 | Initial Docker setup |
| 2.0 | 2024 | Added CI/CD automation |
| 2.1 | 2024 | Multi-user support (root + sudo) |

---

## 💡 Best Practices

1. ✅ Use CI/CD for consistent builds
2. ✅ Tag images with versions
3. ✅ Monitor logs regularly
4. ✅ Backup volumes periodically
5. ✅ Test locally before production
6. ✅ Use secrets for credentials
7. ✅ Document custom changes
8. ✅ Keep dependencies updated

---

## 🎓 Learning Path

1. **Beginner**: Use pre-built images with deploy.sh
2. **Intermediate**: Understand Dockerfile and docker-compose
3. **Advanced**: Set up CI/CD pipelines
4. **Expert**: Customize builds and optimize performance

---

## 🌟 Features Comparison

| Feature | Manual Setup | Docker | Docker + CI/CD |
|---------|--------------|--------|----------------|
| Setup Time | 30+ min | 10 min | 5 min |
| Consistency | Variable | High | Very High |
| Updates | Manual | Manual | Automatic |
| Rollback | Difficult | Easy | Very Easy |
| Scalability | Low | Medium | High |
| Monitoring | Manual | Built-in | Automated |

---

## 📞 Support & Help

- **Documentation**: Check QUICK_START.md and CI_CD_SETUP.md
- **Logs**: Run `./deploy.sh logs` for troubleshooting
- **Shell**: Run `./deploy.sh shell` for interactive debugging
- **Issues**: Check GitHub Actions or Jenkins logs

---

**Ready to Deploy? Start with QUICK_START.md!** 🚀
