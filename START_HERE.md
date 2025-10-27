# 🚀 START HERE - RL-Swarm Docker & CI/CD

Welcome! This repository provides complete Docker containerization and CI/CD automation for the Gensyn RL-Swarm project.

## 📚 Documentation Index

Choose your path based on what you want to do:

### 🎯 Want to Deploy Quickly?
**→ Read: [QUICK_START.md](QUICK_START.md)**
- Get running in 5 minutes
- Local or pre-built image deployment
- Common commands reference

### 🔧 Want to Set Up CI/CD?
**→ Read: [CI_CD_SETUP.md](CI_CD_SETUP.md)**
- Complete GitHub Actions setup
- Complete Jenkins setup
- Step-by-step instructions

### 📦 Want to Understand the Deployment?
**→ Read: [DEPLOYMENT_OVERVIEW.md](DEPLOYMENT_OVERVIEW.md)**
- Architecture overview
- Security features
- Deployment scenarios
- Best practices

### 🐳 Want Docker Details?
**→ Read: [DOCKER_SETUP.md](DOCKER_SETUP.md)**
- Docker image details
- VPS deployment guide
- Monitoring and logs

### 📖 Want Original RL-Swarm Instructions?
**→ Read: [README.md](README.md)**
- Manual setup instructions
- System requirements
- Troubleshooting

### 📋 Want a File Summary?
**→ Read: [FILES_SUMMARY.txt](FILES_SUMMARY.txt)**
- List of all files created
- Quick reference
- Next steps

---

## ⚡ Ultra Quick Start

### Option 1: Build Locally (First Time)
```bash
chmod +x deploy.sh
./deploy.sh build
./deploy.sh up
```
Access: http://localhost:3000

### Option 2: Use Pre-Built Image (After CI/CD)
```bash
./deploy.sh pull yourusername/rl-swarm:latest
./deploy.sh up
```
Access: http://localhost:3000

---

## 🎓 Learning Path

```
1. START_HERE.md (you are here)
   ↓
2. QUICK_START.md (deploy in 5 minutes)
   ↓
3. DEPLOYMENT_OVERVIEW.md (understand what you deployed)
   ↓
4. CI_CD_SETUP.md (automate everything)
   ↓
5. DOCKER_SETUP.md (advanced configuration)
```

---

## ✅ What's Included

- ✓ **Docker Setup**: Complete containerization with multi-user support
- ✓ **GitHub Actions**: Automated CI/CD workflow
- ✓ **Jenkins Pipeline**: Alternative CI/CD solution
- ✓ **Deploy Script**: Easy deployment and management
- ✓ **Documentation**: Comprehensive guides for all scenarios
- ✓ **Security**: Non-root user with sudo access
- ✓ **Persistence**: Volumes for data, logs, and keys

---

## 🎯 Common Tasks

| Task | Command |
|------|---------|
| Start container | `./deploy.sh up` |
| View logs | `./deploy.sh logs` |
| Stop container | `./deploy.sh down` |
| Restart | `./deploy.sh restart` |
| Build locally | `./deploy.sh build` |
| Pull image | `./deploy.sh pull <image>` |
| Shell access | `./deploy.sh shell` |
| Clean up | `./deploy.sh clean` |

---

## 🆘 Need Help?

### Issue → Solution
- Container won't start → `./deploy.sh logs` then `./deploy.sh restart`
- Port 3000 busy → Change port in docker-compose.yml or kill process
- Build fails → Check internet and Docker daemon running
- Login issues → Ensure container running: `docker ps`
- CI/CD fails → Check secrets/credentials in GitHub/Jenkins

### Debug Commands
```bash
./deploy.sh logs          # View container logs
./deploy.sh shell         # Open shell in container
docker ps                 # Check container status
docker images             # List available images
```

---

## 🌟 Key Features

### Docker Image
- Ubuntu 22.04 base
- Python 3 + Node.js 20.x + Yarn
- Non-root user with sudo
- Auto-clones rl-swarm repo
- Port 3000 exposed

### CI/CD
- Monitors upstream changes
- Builds automatically every 6 hours
- Pushes to Docker Hub + GHCR
- Multiple version tags
- Manual trigger support

### Deployment
- Single script for all operations
- Works on VPS, local, cloud
- Persistent data storage
- Easy updates and rollbacks

---

## 📊 Architecture

```
┌─────────────────────┐
│  Upstream Repo      │
│  gensyn-ai/rl-swarm │
└──────────┬──────────┘
           │ monitors
           ▼
┌─────────────────────┐
│  CI/CD Pipeline     │
│  GitHub Actions     │
│  or Jenkins         │
└──────────┬──────────┘
           │ builds
           ▼
┌─────────────────────┐
│  Docker Image       │
│  Ubuntu + Python    │
│  + Node + RL-Swarm  │
└──────────┬──────────┘
           │ push
           ▼
┌─────────────────────┐
│  Registry           │
│  Docker Hub         │
│  GitHub Container   │
└──────────┬──────────┘
           │ pull & run
           ▼
┌─────────────────────┐
│  Your Server        │
│  VPS / Local / Cloud│
└─────────────────────┘
```

---

## 🚦 Status Checks

Before starting, verify:
- [ ] Docker installed: `docker --version`
- [ ] Docker Compose installed: `docker-compose --version`
- [ ] Port 3000 available: `sudo lsof -i :3000`
- [ ] deploy.sh executable: `chmod +x deploy.sh`

---

## 📖 Documentation Quick Links

| Document | Purpose | Read Time |
|----------|---------|-----------|
| **START_HERE.md** | This file | 2 min |
| **QUICK_START.md** | Quick deployment | 5 min |
| **DEPLOYMENT_OVERVIEW.md** | Architecture & features | 10 min |
| **CI_CD_SETUP.md** | CI/CD configuration | 15 min |
| **DOCKER_SETUP.md** | Docker details | 10 min |
| **README.md** | Original instructions | 20 min |
| **FILES_SUMMARY.txt** | File reference | 3 min |

---

## 💡 Pro Tips

1. **First Time Users**: Start with QUICK_START.md
2. **Production**: Set up CI/CD from CI_CD_SETUP.md
3. **Troubleshooting**: Check logs first: `./deploy.sh logs`
4. **Updates**: Use `./deploy.sh update <image>` for zero-downtime
5. **Backups**: Volumes persist data - backup with `docker volume inspect`

---

## 🎬 Next Steps

1. ✅ You're reading START_HERE.md
2. ⏭️ Go to [QUICK_START.md](QUICK_START.md) to deploy
3. 🔧 Set up CI/CD with [CI_CD_SETUP.md](CI_CD_SETUP.md)
4. 📚 Learn more in [DEPLOYMENT_OVERVIEW.md](DEPLOYMENT_OVERVIEW.md)

---

**Ready? Let's deploy! → [QUICK_START.md](QUICK_START.md)** 🚀

---

<div align="center">

Made with ❤️ for the Gensyn Community

[Report Issue](https://github.com/gensyn-ai/rl-swarm) | [Documentation](.) | [Original Repo](https://github.com/gensyn-ai/rl-swarm)

</div>
