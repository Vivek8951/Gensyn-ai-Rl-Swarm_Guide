# 🚀 Automatic Port Forwarding - Complete Guide

## ✨ What's New?

The container now **automatically handles port forwarding** and **preserves your swarm.pem** file!

---

## 🎯 Key Features

### 1. **Automatic Port Forwarding**
- Triggers **ONLY** when localhost:3000 is detected
- No manual intervention needed
- Works for both local and VPS environments

### 2. **Persistent swarm.pem**
- First run: Clones rl-swarm and sets up everything
- Subsequent runs: **Preserves swarm.pem** and all data
- Updates code without losing authentication

### 3. **Smart Environment Detection**
- Auto-detects local vs VPS environment
- Local: Shows localhost:3000 URL
- VPS: Auto-starts cloudflared tunnel

---

## 🚀 How to Use

### For Local Machine:

```bash
# First time setup
./deploy.sh build
./deploy.sh up

# Container starts, shows:
# ✅ RL-Swarm is running on localhost:3000
# 💻 Local environment - Access at: http://localhost:3000

# Open browser to http://localhost:3000
```

### For VPS with Auto-Tunnel:

```bash
# Enable auto-tunnel
export AUTO_TUNNEL=true

# Or add to .env file:
echo "AUTO_TUNNEL=true" >> .env

# Start container
./deploy.sh up

# Container automatically:
# 1. Waits for localhost:3000
# 2. Detects VPS environment
# 3. Starts cloudflared tunnel
# 4. Shows tunnel URL like: https://xxx.trycloudflare.com
```

### For VPS without Auto-Tunnel:

```bash
# Start container normally
./deploy.sh up

# When you see "RL-Swarm is running on localhost:3000"
# In another terminal:
./deploy.sh login

# Or manually:
docker exec -it rl-swarm-node cloudflared tunnel --url http://localhost:3000
```

---

## 📦 How It Works

### First Time (Fresh Install):

```
1. Container starts
2. Detects no rl-swarm directory
3. Clones rl-swarm repository
4. Sets up Python venv
5. Installs dependencies
6. Runs run_rl_swarm.sh
7. When localhost:3000 appears → Shows URL or starts tunnel
```

### Subsequent Runs (Using Pre-built Image):

```
1. Container starts
2. Detects existing rl-swarm directory
3. ✅ Preserves swarm.pem file
4. Pulls latest code (doesn't overwrite local files)
5. Uses existing venv
6. Runs run_rl_swarm.sh
7. When localhost:3000 appears → Shows URL or starts tunnel
```

---

## 🔧 Configuration

### Environment Variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `AUTO_TUNNEL` | `false` | Enable automatic cloudflared tunnel on VPS |
| `PYTHONUNBUFFERED` | `1` | Show Python output immediately |
| `PATH` | (set) | Includes venv binaries |

### Setting AUTO_TUNNEL:

**Option 1: Environment variable**
```bash
export AUTO_TUNNEL=true
./deploy.sh up
```

**Option 2: .env file**
```bash
echo "AUTO_TUNNEL=true" >> .env
./deploy.sh up
```

**Option 3: docker-compose**
```bash
AUTO_TUNNEL=true docker-compose up -d
```

---

## 📊 Volume Persistence

### Three volumes for data persistence:

| Volume | Purpose | Preserves |
|--------|---------|-----------|
| `swarm-repo` | Entire rl-swarm directory | **swarm.pem**, config files, code |
| `swarm-data` | Application data | Training data, models |
| `swarm-logs` | Log files | All logs |

### Benefits:

✅ **swarm.pem preserved** - No need to login again
✅ **Fast updates** - Only pulls new code
✅ **Data persists** - Training progress saved
✅ **No reinstallation** - Dependencies cached

---

## 🎬 Complete Workflows

### Workflow 1: Local Development

```bash
# First time
./deploy.sh build
./deploy.sh up

# Wait for message:
# "✅ RL-Swarm is running on localhost:3000"

# Open browser to: http://localhost:3000
# Complete login
# ✅ Done!

# Next time (swarm.pem preserved):
./deploy.sh up
# Already logged in! ✅
```

### Workflow 2: VPS with Auto-Tunnel

```bash
# First time
export AUTO_TUNNEL=true
./deploy.sh build
./deploy.sh up

# Container automatically:
# - Starts application
# - Detects port 3000 is ready
# - Starts cloudflared tunnel
# - Shows: https://xxx.trycloudflare.com

# Copy URL and open in your local browser
# Complete login
# ✅ Done!

# Next time (swarm.pem preserved):
export AUTO_TUNNEL=true
./deploy.sh up
# Already logged in! ✅
# Tunnel starts automatically
```

### Workflow 3: VPS Manual Tunnel

```bash
# Terminal 1: Start container
./deploy.sh up

# Terminal 2: When localhost:3000 appears
./deploy.sh login

# Or manually:
docker exec -it rl-swarm-node cloudflared tunnel --url http://localhost:3000

# Copy tunnel URL
# Open in browser
# Complete login
# ✅ Done!
```

---

## 🔍 Monitoring

### Check if port 3000 is ready:

```bash
# View logs
./deploy.sh logs

# Check for:
# "✅ RL-Swarm is running on localhost:3000"
```

### Check if swarm.pem exists:

```bash
# Inside container
docker exec -it rl-swarm-node ls -la /home/rlswarm/rl-swarm/swarm.pem

# From host
docker exec -it rl-swarm-node cat /home/rlswarm/rl-swarm/swarm.pem
```

### Verify tunnel is running:

```bash
# Check cloudflared process
docker exec -it rl-swarm-node ps aux | grep cloudflared
```

---

## 🐛 Troubleshooting

### Port forwarding not starting?

**Check if port 3000 is listening:**
```bash
docker exec -it rl-swarm-node lsof -i :3000
```

**Check logs:**
```bash
./deploy.sh logs
```

**Restart container:**
```bash
./deploy.sh restart
```

### swarm.pem missing after update?

**Verify volume exists:**
```bash
docker volume ls | grep swarm-repo
```

**Check if file exists:**
```bash
docker exec -it rl-swarm-node ls -la /home/rlswarm/rl-swarm/swarm.pem
```

**Restore from backup:**
```bash
# If you saved swarm.pem locally
docker cp ./swarm.pem rl-swarm-node:/home/rlswarm/rl-swarm/swarm.pem
```

### Auto-tunnel not working?

**Check AUTO_TUNNEL is set:**
```bash
docker exec -it rl-swarm-node env | grep AUTO_TUNNEL
```

**Check if cloudflared is installed:**
```bash
docker exec -it rl-swarm-node cloudflared --version
```

**Manually start tunnel:**
```bash
docker exec -it rl-swarm-node cloudflared tunnel --url http://localhost:3000
```

---

## 📋 Comparison

### Before vs After:

| Feature | Before | After |
|---------|--------|-------|
| Port forwarding | Manual setup | ✅ Automatic |
| Trigger point | Anytime | ✅ Only when port 3000 ready |
| swarm.pem | Lost on update | ✅ Preserved |
| Re-installation | Full reinstall | ✅ Smart update |
| Login required | Every time | ✅ Once (persisted) |
| Environment detection | Manual | ✅ Automatic |

---

## 💡 Best Practices

1. **Use AUTO_TUNNEL on VPS**
   ```bash
   export AUTO_TUNNEL=true
   ```

2. **Backup swarm.pem**
   ```bash
   docker cp rl-swarm-node:/home/rlswarm/rl-swarm/swarm.pem ./swarm.pem.backup
   ```

3. **Monitor logs during first run**
   ```bash
   ./deploy.sh logs
   ```

4. **Use volumes for persistence**
   - Already configured in docker-compose.yml ✅

5. **Keep container running**
   - Restart policy: `unless-stopped` ✅

---

## 🎯 Summary

### What You Need to Know:

✅ **Port forwarding is automatic** - Triggers when localhost:3000 is ready
✅ **swarm.pem is preserved** - No need to login again
✅ **Smart environment detection** - Works locally and on VPS
✅ **No reinstallation** - Fast updates without losing data
✅ **Multiple workflows** - Choose what works for you

### Simple Commands:

```bash
# Local
./deploy.sh up
# Open: http://localhost:3000

# VPS with auto-tunnel
export AUTO_TUNNEL=true
./deploy.sh up
# Use cloudflare URL

# VPS manual
./deploy.sh up
./deploy.sh login
# Use cloudflare URL
```

---

## 🔗 Related Documentation

- [QUICK_START.md](QUICK_START.md) - Quick deployment
- [LOGIN_FIX_COMPLETE.md](LOGIN_FIX_COMPLETE.md) - Login solutions
- [DOCKER_SETUP.md](DOCKER_SETUP.md) - Docker details
- [CI_CD_SETUP.md](CI_CD_SETUP.md) - Automation setup

---

**Everything works automatically now!** 🎉
