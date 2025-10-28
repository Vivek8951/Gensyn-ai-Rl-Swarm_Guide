# Modal Login UI Fix - Port Forwarding Guide

## Problem
When running RL-Swarm in Docker, the modal login UI doesn't open automatically and the forwarding port isn't showing for login at http://localhost:3000.

## Solutions

### Solution 1: Direct Port Access (Recommended for Docker)

When the container prompts for login, the modal UI is already accessible at:

```
http://localhost:3000
```

**Steps:**
1. Start the container:
   ```bash
   ./deploy.sh up
   ```

2. Watch the logs:
   ```bash
   ./deploy.sh logs
   ```

3. When you see the login prompt, open your browser to:
   ```
   http://localhost:3000
   ```

4. Complete the login in the browser

5. Return to the terminal - the process will continue automatically

---

### Solution 2: Using Cloudflared Tunnel (For VPS/Remote Access)

If you're running on a VPS and need to access the login from your local machine:

**Step 1: Install cloudflared in the container**
```bash
docker exec -it rl-swarm-node bash
```

Inside the container:
```bash
wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared-linux-amd64.deb
cloudflared --version
```

**Step 2: Start the tunnel (in a separate terminal)**
```bash
docker exec -it rl-swarm-node cloudflared tunnel --url http://localhost:3000
```

**Step 3: Access the provided URL**
The cloudflared command will output a URL like:
```
https://xxxxxxxx.trycloudflare.com
```

Open this URL in your browser to access the login interface.

---

### Solution 3: Update Dockerfile to Include Cloudflared

Update the Dockerfile to include cloudflared by default:

```dockerfile
# Add after the system dependencies installation
RUN wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb && \
    dpkg -i cloudflared-linux-amd64.deb && \
    rm cloudflared-linux-amd64.deb
```

---

### Solution 4: Docker Compose with Multiple Services

Create a separate service for the tunnel:

```yaml
version: '3.8'

services:
  rl-swarm:
    # ... existing config ...

  cloudflared:
    image: cloudflare/cloudflared:latest
    command: tunnel --url http://rl-swarm:3000
    depends_on:
      - rl-swarm
    restart: unless-stopped
```

---

## Quick Fix Commands

### For Local Docker (localhost access):
```bash
# Start container
./deploy.sh up

# In another terminal, check logs
./deploy.sh logs

# When login prompt appears, open browser:
open http://localhost:3000  # macOS
xdg-open http://localhost:3000  # Linux
start http://localhost:3000  # Windows
```

### For VPS/Remote Access:
```bash
# Terminal 1: Run the container
./deploy.sh up

# Terminal 2: SSH to VPS and start tunnel
ssh user@your-vps
docker exec -it rl-swarm-node cloudflared tunnel --url http://localhost:3000

# Copy the provided URL and open in your local browser
```

---

## Troubleshooting

### Issue: Port 3000 not accessible

**Check if container is running:**
```bash
docker ps | grep rl-swarm
```

**Check port mapping:**
```bash
docker port rl-swarm-node
```

Should show: `3000/tcp -> 0.0.0.0:3000`

**Check firewall (if on VPS):**
```bash
sudo ufw status
sudo ufw allow 3000/tcp
```

### Issue: Can't install cloudflared in container

**Option 1: Install during build**
Rebuild the image with cloudflared included (see Solution 3 above).

**Option 2: Use host cloudflared**
Install cloudflared on your host machine and tunnel to the container:
```bash
cloudflared tunnel --url http://localhost:3000
```

### Issue: Login page loads but doesn't work

**Check container logs:**
```bash
./deploy.sh logs
```

**Ensure all services are running:**
```bash
docker exec -it rl-swarm-node ps aux | grep -E "node|python"
```

**Restart the container:**
```bash
./deploy.sh restart
```

---

## Alternative: Pre-configure Authentication

If you've already logged in once, you can copy the authentication files:

```bash
# From host, save the swarm.pem file
docker cp rl-swarm-node:/home/rlswarm/rl-swarm/swarm.pem ./swarm.pem

# In future deployments, copy it back
docker cp ./swarm.pem rl-swarm-node:/home/rlswarm/rl-swarm/swarm.pem
```

This is already configured with the `swarm-pem` volume in docker-compose.yml.

---

## Automatic Solution Script

Save this as `login-helper.sh`:

```bash
#!/bin/bash

echo "RL-Swarm Login Helper"
echo "===================="
echo ""

# Check if container is running
if ! docker ps | grep -q rl-swarm-node; then
    echo "❌ Container is not running. Start it with: ./deploy.sh up"
    exit 1
fi

echo "✅ Container is running"
echo ""

# Check if running locally or remotely
if [ -n "$SSH_CONNECTION" ] || [ -n "$SSH_CLIENT" ]; then
    echo "🌐 Remote/VPS detected - Setting up cloudflared tunnel..."
    echo ""

    # Check if cloudflared is installed
    if ! docker exec rl-swarm-node which cloudflared > /dev/null 2>&1; then
        echo "📦 Installing cloudflared in container..."
        docker exec rl-swarm-node bash -c "
            wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb &&
            sudo dpkg -i cloudflared-linux-amd64.deb &&
            rm cloudflared-linux-amd64.deb
        "
    fi

    echo "🚀 Starting tunnel..."
    echo "⚠️  Press Ctrl+C when done with login"
    echo ""
    docker exec -it rl-swarm-node cloudflared tunnel --url http://localhost:3000
else
    echo "💻 Local environment detected"
    echo ""
    echo "🌐 Open your browser to: http://localhost:3000"
    echo ""
    echo "For macOS: open http://localhost:3000"
    echo "For Linux: xdg-open http://localhost:3000"
    echo ""

    # Try to open browser automatically
    if command -v xdg-open > /dev/null; then
        xdg-open http://localhost:3000 2>/dev/null
    elif command -v open > /dev/null; then
        open http://localhost:3000 2>/dev/null
    fi
fi
```

Make it executable:
```bash
chmod +x login-helper.sh
```

Usage:
```bash
./login-helper.sh
```

---

## Recommended Workflow

### First Time Setup:

1. Start container:
   ```bash
   ./deploy.sh up
   ```

2. Monitor logs in another terminal:
   ```bash
   ./deploy.sh logs
   ```

3. When login prompt appears, access UI:
   - **Local**: http://localhost:3000
   - **VPS**: Use login-helper.sh or cloudflared tunnel

4. Complete login in browser

5. The container will automatically continue after successful login

### Subsequent Runs:

The `swarm.pem` file is persisted in the volume, so you may not need to login again unless:
- You delete the volumes
- The authentication expires
- You want to switch accounts

---

## Testing the Fix

```bash
# 1. Start container
./deploy.sh up

# 2. Test port accessibility
curl http://localhost:3000

# Expected: HTML response from Next.js app

# 3. Check logs for login prompt
./deploy.sh logs | grep -i "login\|3000"

# 4. Open browser
open http://localhost:3000  # or use login-helper.sh
```

---

## Summary

The modal login issue occurs because:
1. The Next.js UI runs on port 3000 inside the container
2. Port is properly mapped (3000:3000) in docker-compose
3. You need to manually access http://localhost:3000 when prompted
4. For VPS, use cloudflared tunnel to access remotely

**Quick Solution:**
- **Local**: Open http://localhost:3000 when prompted
- **VPS**: Run `./login-helper.sh` or use cloudflared tunnel

The login UI is accessible - you just need to know where to look!
