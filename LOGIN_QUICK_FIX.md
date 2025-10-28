# Quick Fix: Modal Login Not Showing

## The Problem
When RL-Swarm prompts for login, the UI doesn't automatically open or show the forwarding port.

## The Solution

### ✅ Quick Fix (2 commands)

```bash
# 1. Start the container
./deploy.sh up

# 2. When you see the login prompt, run:
./deploy.sh login
```

That's it! The login interface will open automatically.

---

## Alternative Methods

### Method 1: Direct Browser Access (Simplest)
```bash
# Just open your browser to:
http://localhost:3000
```

### Method 2: Using login-helper.sh
```bash
./login-helper.sh
```
- Detects local vs VPS automatically
- Sets up cloudflared tunnel if on VPS
- Opens browser automatically if local

### Method 3: Manual Cloudflared (For VPS)
```bash
# In a separate terminal:
docker exec -it rl-swarm-node cloudflared tunnel --url http://localhost:3000

# Copy the URL it shows (like https://xxx.trycloudflare.com)
# Open that URL in your browser
```

---

## Why This Happens

The modal login UI runs on port 3000 inside the container. The port is properly mapped (3000:3000), but you need to manually access it when prompted.

**Docker has already exposed the port** - you just need to know where to access it!

---

## Complete Workflow

```bash
# Terminal 1: Start container
./deploy.sh up

# Watch the logs (optional, in another terminal)
./deploy.sh logs

# When you see "login" prompt, use any of:
./deploy.sh login              # Recommended
./login-helper.sh              # Also good
open http://localhost:3000     # Manual

# Complete login in browser
# Return to terminal - it continues automatically
```

---

## Troubleshooting

### Can't access localhost:3000?

Check if container is running:
```bash
docker ps | grep rl-swarm
```

Check port mapping:
```bash
docker port rl-swarm-node
# Should show: 3000/tcp -> 0.0.0.0:3000
```

Restart container:
```bash
./deploy.sh restart
```

### On VPS and localhost doesn't work?

Use the cloudflared tunnel:
```bash
./login-helper.sh
# OR manually:
docker exec -it rl-swarm-node cloudflared tunnel --url http://localhost:3000
```

### Port 3000 already in use?

Find what's using it:
```bash
sudo lsof -i :3000
```

Kill the process or change the port in docker-compose.yml

---

## Summary

**The fix is simple**: When prompted for login, just run:
```bash
./deploy.sh login
```

Or manually open: **http://localhost:3000**

The cloudflared tunnel is pre-installed for VPS access!
