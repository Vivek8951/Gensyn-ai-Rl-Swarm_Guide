# Self-Contained Automatic Port Forwarding

**🎯 Run Docker ONCE - Get instant port forwarding links - No setup needed!**

## 🚀 What This Does

When you run the Docker container, it **automatically**:
1. Shows you all port forwarding URLs immediately
2. Starts alternative port servers inside the container
3. Creates Cloudflare tunnel for external access
4. Displays multiple access points to the same RL-Swarm

**No git clone, no manual commands, no setup!**

## 🎯 Quick Start - One Command

```bash
# Run this single command
./run-auto-port.sh
```

That's it! The script will:
- Show you all the access URLs immediately
- Start the Docker container
- Handle all port forwarding automatically

## 🌐 Instant Access URLs

When you run the script, you'll immediately see:

```
🌐 PORT FORWARDING URLs (Ready when container starts):
================================================================

📍 Primary Access:
   Main Interface: http://YOUR_VPS_IP:3000

🔗 Alternative Ports:
   Port 8080: http://YOUR_VPS_IP:8080 → RL-Swarm
   Port 8081: http://YOUR_VPS_IP:8081 → RL-Swarm
   Port 8082: http://YOUR_VPS_IP:8082 → RL-Swarm
   Port 9000: http://YOUR_VPS_IP:9000 → RL-Swarm
   Port 9001: http://YOUR_VPS_IP:9001 → RL-Swarm
   Port 9002: http://YOUR_VPS_IP:9002 → RL-Swarm
```

All these ports work **automatically** without any configuration!

## 🔧 What Happens Automatically

### Inside the Container
1. **Port Display** - Shows all access URLs immediately
2. **Proxy Servers** - Starts Python proxy servers on ports 8080-9002
3. **Cloudflare Tunnel** - Creates external access tunnel
4. **Port Forwarding** - All alternative ports proxy to main port 3000

### Outside the Container
1. **Docker Mapping** - Maps container ports to host ports
2. **Firewall Access** - Ports accessible from external IP
3. **Multiple Entry Points** - Same RL-Swarm on all ports

## 📋 Access Methods

### Method 1: Direct Port Access
```bash
http://your-vps-ip:3000  # Main RL-Swarm
http://your-vps-ip:8080  # Same RL-Swarm
http://your-vps-ip:8081  # Same RL-Swarm
# ... and more ports
```

### Method 2: Cloudflare Tunnel
```bash
# Check container logs for tunnel URL
docker logs -f rl-swarm-self-contained

# Look for: https://random-words.trycloudflare.com
```

### Method 3: Development Testing
```bash
# Multiple developers can use different ports simultaneously
# Developer 1: http://vps-ip:3000
# Developer 2: http://vps-ip:8080
# Developer 3: http://vps-ip:8081
```

## 🛠️ How It Works

### Docker Container Setup
```yaml
# docker-compose.self-contained.yml
services:
  rl-swarm:
    ports:
      - "3000:3000"    # Main port
      - "8080:8080"    # Alternative ports
      - "8081:8081"
      - "8082:8082"
      - "9000:9000"
      - "9001:9001"
      - "9002:9002"
```

### Container Internal Proxies
```python
# Python proxy servers run inside container
# Port 8080 → Proxy to localhost:3000
# Port 8081 → Proxy to localhost:3000
# etc...
```

### Automatic Display
```bash
# docker-entrypoint.sh shows URLs immediately
show_auto_port_forwarding() {
    echo "http://YOUR_VPS_IP:3000 - Main Interface"
    echo "http://YOUR_VPS_IP:8080 - Web Access"
    # ... all URLs displayed
}
```

## 🎯 Use Cases

### Use Case 1: Quick VPS Deployment
```bash
# On your VPS, just run:
./run-auto-port.sh

# Immediately get all access URLs
# No setup, no configuration, no git clone needed
```

### Use Case 2: Development Team
```bash
# Team coordinator runs:
./run-auto-port.sh

# Shares different ports with team members:
# Developer 1: http://vps-ip:3000
# Developer 2: http://vps-ip:8080
# Developer 3: http://vps-ip:8081
```

### Use Case 3: Testing Different Configurations
```bash
# Test same RL-Swarm with different access methods:
http://vps-ip:3000  # Direct access
http://vps-ip:8080  # Through proxy
https://tunnel-url  # Through Cloudflare
```

## 📊 Monitoring

### Check Container Status
```bash
docker ps --filter "name=rl-swarm-self-contained"
```

### View Port Forwarding Logs
```bash
# See all container output including port URLs
docker logs -f rl-swarm-self-contained

# Check port server logs
docker exec rl-swarm-self-contained cat /tmp/port_servers.log
```

### Test Port Access
```bash
# Test main port
curl http://localhost:3000

# Test alternative ports
curl http://localhost:8080
curl http://localhost:8081
```

## 🔍 Troubleshooting

### Port Not Accessible
```bash
# Check if container is running
docker ps | grep rl-swarm-self-contained

# Check container logs
docker logs rl-swarm-self-contained

# Restart container
./run-auto-port.sh
```

### Cloudflare Tunnel Not Working
```bash
# Check if cloudflared is running in container
docker exec rl-swarm-self-contained pgrep cloudflared

# Check tunnel logs
docker exec rl-swarm-self-contained cat /tmp/cloudflare.log
```

### Alternative Ports Not Working
```bash
# Check if proxy servers are running
docker exec rl-swarm-self-contained ps aux | grep python

# Check proxy logs
docker exec rl-swarm-self-contained cat /tmp/port_servers.log
```

## 🛡️ Security Notes

### Port Exposure
- All mapped ports are accessible from external IP
- Consider firewall rules if only local access needed
- Container runs proxy servers internally

### Access Control
```bash
# Optional: Limit access to specific IPs
sudo ufw allow from YOUR_IP to any port 3000
sudo ufw allow from YOUR_IP to any port 8080
```

## 📈 Performance

### Resource Usage
- **Memory**: ~100MB additional for proxy servers
- **CPU**: Minimal overhead for proxy forwarding
- **Network**: All requests go to same RL-Swarm instance

### Benefits
- **Zero Configuration** - Works out of the box
- **Multiple Access Points** - 7 different ports available
- **Automatic Setup** - No manual commands needed
- **Self-Contained** - Everything inside Docker container

## 🔄 Stopping and Restarting

### Stop Services
```bash
docker-compose -f docker-compose.self-contained.yml down
```

### Restart Services
```bash
./run-auto-port.sh
```

### Clean Restart
```bash
docker-compose -f docker-compose.self-contained.yml down
docker system prune -f
./run-auto-port.sh
```

## 🎉 Key Advantages

✅ **True Zero-Configuration** - Run one command, get all URLs immediately
✅ **Self-Contained** - Everything happens inside Docker container
✅ **Multiple Access Points** - 7 different ports automatically available
✅ **No Git Clone Needed** - Docker image contains everything
✅ **Instant URL Display** - See all access URLs before container fully starts
✅ **Automatic Port Forwarding** - No manual setup required
✅ **Cloudflare Tunnel** - External access without opening ports

---

**Usage**: `./run-auto-port.sh`
**Access**: All URLs shown immediately when you run the script
**Monitoring**: `docker logs -f rl-swarm-self-contained`

Perfect for quick VPS deployment without any setup! 🚀