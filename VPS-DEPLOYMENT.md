# RL-Swarm VPS/Cloud Deployment Guide

This guide explains how to deploy RL-Swarm on VPS and cloud instances with automatic port forwarding and tunneling capabilities.

## 🌐 VPS/Cloud Features

- **Automatic Cloudflare Tunnel**: Remote access without opening ports
- **Flexible Port Configuration**: Customize external and tunnel ports
- **Custom Domain Support**: Use your own domain with tunnels
- **Environment Detection**: Automatic VPS vs local environment detection
- **SSH Tunnel Support**: Optional SSH tunnel port forwarding

## 🚀 Quick VPS Setup

### 1. Basic VPS Deployment

```bash
# Setup VPS environment
./deploy.sh vps

# Apply configuration
cp .env.vps .env

# Start with automatic tunnel
./deploy.sh up

# Get tunnel URL from logs
./deploy.sh logs
```

### 2. Custom Port Configuration

```bash
# VPS with custom external port (8080) and SSH tunnel (2222)
./deploy.sh vps 8080 2222

# Apply configuration
cp .env.vps .env

# Start container
./deploy.sh up
```

## 🔧 Port Forwarding Options

### Method 1: Cloudflare Tunnel (Recommended)

**Features:**
- No need to open firewall ports
- Automatic HTTPS
- Random or custom domain URLs
- Works behind NAT/firewalls

**Setup:**
```bash
# Automatic tunnel (default)
export AUTO_TUNNEL=true
./deploy.sh up

# Custom domain tunnel
export TUNNEL_DOMAIN=your-domain.com
export CLOUDFLARE_TUNNEL_TOKEN=your-token
./deploy.sh up
```

### Method 2: Direct Port Access

**Features:**
- Direct IP access
- Custom external ports
- Requires firewall configuration

**Setup:**
```bash
# Custom external port
export EXTERNAL_PORT=8080
export AUTO_TUNNEL=false
./deploy.sh up

# Access at: http://YOUR_VPS_IP:8080
```

### Method 3: SSH Tunneling

**Features:**
- Secure SSH tunnel
- Local port forwarding
- Additional SSH access port

**Setup:**
```bash
# Configure SSH tunnel port
export TUNNEL_PORT=2222
./deploy.sh up

# Create SSH tunnel from local machine
ssh -L 3000:localhost:3000 -p 2222 user@your-vps-ip
```

## 📋 Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `EXTERNAL_PORT` | `3000` | External port for direct access |
| `AUTO_TUNNEL` | `true` | Enable automatic Cloudflare tunnel |
| `REMOTE_ACCESS` | `true` | Enable remote/VPS features |
| `TUNNEL_PORT` | `22` | Optional SSH tunnel port |
| `TUNNEL_DOMAIN` | - | Custom domain for tunnel |
| `CLOUDFLARE_TUNNEL_TOKEN` | - | Cloudflare tunnel token |

## 🛠️ Deployment Commands

### Basic Commands
```bash
./deploy.sh vps              # Create VPS environment
./deploy.sh up               # Start container
./deploy.sh down             # Stop container
./deploy.sh logs             # View logs
./deploy.sh restart          # Restart container
```

### Tunnel Management
```bash
./deploy.sh tunnel status    # Check tunnel status
./deploy.sh tunnel start     # Start manual tunnel
./deploy.sh tunnel stop      # Stop tunnel
```

### Server Information
```bash
./deploy.sh ip               # Show server IP and URLs
./deploy.sh login            # Get access information
```

## 🔍 Access URLs

After deployment, you can access RL-Swarm through multiple methods:

### 1. Cloudflare Tunnel (Automatic)
```bash
# Get tunnel URL from logs
./deploy.sh logs | grep "https://"
```

### 2. Direct IP Access
```bash
# Get server IP
./deploy.sh ip

# Access format: http://VPS_IP:EXTERNAL_PORT
```

### 3. Local Container Access
```bash
# Inside VPS
http://localhost:3000
```

## 🌍 Custom Domain Setup

### Option 1: Cloudflare Tunnel Token
```bash
# Create environment with custom domain
cat > .env << EOF
EXTERNAL_PORT=3000
AUTO_TUNNEL=true
TUNNEL_DOMAIN=rl-swarm.yourdomain.com
CLOUDFLARE_TUNNEL_TOKEN=your-cloudflare-token
EOF

./deploy.sh up
```

### Option 2: Named Tunnel
```bash
# Configure named tunnel
export TUNNEL_DOMAIN=rl-swarm.yourdomain.com
./deploy.sh up
```

## 🔒 Firewall Configuration

If using direct port access (not tunnel), configure your firewall:

### UFW (Ubuntu)
```bash
# Allow custom port
sudo ufw allow 8080/tcp
sudo ufw reload
```

### iptables
```bash
# Allow port 8080
sudo iptables -A INPUT -p tcp --dport 8080 -j ACCEPT
```

## 📱 Mobile/Remote Access

### From Mobile Device
1. Use the Cloudflare tunnel URL from logs
2. Or access via `http://VPS_IP:EXTERNAL_PORT`
3. Login with your RL-Swarm credentials

### SSH Tunnel for Local Development
```bash
# Create SSH tunnel from local machine
ssh -L 3000:localhost:3000 user@your-vps-ip

# Access locally at http://localhost:3000
```

## 🐛 Troubleshooting

### Tunnel Not Working
```bash
# Check tunnel status
./deploy.sh tunnel status

# View container logs
./deploy.sh logs

# Restart tunnel
./deploy.sh tunnel stop
./deploy.sh tunnel start
```

### Port Access Issues
```bash
# Check if port is open
sudo netstat -tlnp | grep :3000

# Check firewall
sudo ufw status

# Test local access
curl http://localhost:3000
```

### Container Issues
```bash
# View container logs
./deploy.sh logs

# Access container shell
./deploy.sh shell

# Restart container
./deploy.sh restart
```

## 📊 Monitoring

### Check Container Status
```bash
docker ps | grep rl-swarm
docker stats rl-swarm-node
```

### Monitor Resources
```bash
# Memory and CPU usage
docker stats --no-stream

# Disk usage
docker system df
```

## 🔄 Updates

### Update RL-Swarm
```bash
# Pull latest image
./deploy.sh pull yourusername/rl-swarm:latest

# Update running container
./deploy.sh update yourusername/rl-swarm:latest
```

## 🌐 Network Architecture

```
Internet
    │
    ├─ Cloudflare Tunnel (Recommended)
    │   └─ https://random-domain.trycloudflare.com
    │
    ├─ Direct IP Access
    │   └─ http://VPS_IP:EXTERNAL_PORT
    │
    └─ SSH Tunnel
        └─ ssh -L 3000:localhost:3000 user@vps
            └─ http://localhost:3000 (local)
```

## 📞 Support

For issues with:
- **Tunnel**: Check `./deploy.sh tunnel status`
- **Ports**: Verify firewall settings
- **Container**: Review `./deploy.sh logs`
- **Access**: Use `./deploy.sh ip` for configuration

---

**Note**: Cloudflare tunnels are recommended for VPS deployment as they don't require opening firewall ports and provide automatic HTTPS.