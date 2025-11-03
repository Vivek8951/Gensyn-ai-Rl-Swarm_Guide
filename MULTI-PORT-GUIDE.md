# RL-Swarm Multi-Port Forwarding Guide

This comprehensive guide explains how to set up advanced port forwarding for RL-Swarm on VPS and cloud instances, supporting multiple services, reverse proxy, and SSH tunneling.

## 🌐 Overview

The multi-port system provides:
- **Multiple Access Points**: 10+ different ports for RL-Swarm access
- **Reverse Proxy**: Nginx-based load balancing and SSL termination
- **SSH Tunneling**: Secure tunneling to remote services
- **Dynamic Forwarding**: Add/remove port forwards on demand
- **SSL Support**: HTTPS with custom or self-signed certificates
- **Service Segregation**: Different ports for different use cases

## 🚀 Quick Start

### Basic Multi-Port Setup
```bash
# Setup multi-port environment
./deploy.sh multiport

# Apply configuration
cp .env.multiport .env

# Start all services
./deploy.sh start-multi

# Check port status
./deploy.sh ports
```

### Custom Port Configuration
```bash
# Custom ports: RL-Swarm(3000), Web(80), HTTPS(443), Services(8080,8081,8082)
./deploy.sh multiport 3000 80 443 8080 8081 8082

# Apply and start
cp .env.multiport .env
./deploy.sh start-multi
```

## 📋 Available Ports

### Primary Access Ports
| Port | Purpose | Description |
|------|---------|-------------|
| `3000` | RL-Swarm Main | Direct RL-Swarm interface |
| `80` | Web Interface | Nginx reverse proxy |
| `443` | HTTPS Interface | Secure SSL access |

### Service Ports
| Port | Purpose | Description |
|------|---------|-------------|
| `8080` | Service 1 | Additional service access |
| `8081` | Service 2 | Additional service access |
| `8082` | Service 3 | Additional service access |

### Alternative Ports
| Port | Purpose | Description |
|------|---------|-------------|
| `9000` | Alternative 1 | Backup access port |
| `9001` | Alternative 2 | Backup access port |
| `9002` | Alternative 3 | Backup access port |

### Tunnel Ports
| Port | Purpose | Description |
|------|---------|-------------|
| `2222` | Container SSH | Direct SSH to container |
| `2223` | SSH Tunnel | SSH tunnel to remote services |

## 🔧 Configuration Options

### Environment Variables
```bash
# Main Configuration
RL_SWARM_PORT=3000          # Main RL-Swarm port
WEB_PORT=80                 # Nginx web interface
HTTPS_PORT=443              # SSL/HTTPS interface

# Service Ports
SERVICE_PORT_1=8080         # Additional service 1
SERVICE_PORT_2=8081         # Additional service 2
SERVICE_PORT_3=8082         # Additional service 3

# Alternative Access
ALT_PORT_1=9000             # Alternative port 1
ALT_PORT_2=9001             # Alternative port 2
ALT_PORT_3=9002             # Alternative port 3

# SSH Configuration
SSH_TUNNEL_PORT=2223        # SSH tunnel port
SSH_FORWARD_HOST=           # Remote host for tunneling
SSH_FORWARD_PORT=           # Remote port for tunneling
SSH_USER=root               # SSH user for tunneling

# Tunnel Configuration
AUTO_TUNNEL=true            # Enable Cloudflare tunnel
REMOTE_ACCESS=true          # Enable remote features
TUNNEL_DOMAIN=              # Custom tunnel domain
CLOUDFLARE_TUNNEL_TOKEN=    # Cloudflare tunnel token
```

## 🛠️ Port Management Commands

### Port Manager Script
```bash
# Direct access to port manager
./port-manager.sh [command]
```

### Port Management via deploy.sh
```bash
# Setup multi-port environment
./deploy.sh multiport [port1] [port2] [...]

# Start/stop multi-port services
./deploy.sh start-multi
./deploy.sh stop-multi

# Port management
./deploy.sh ports status    # Show port status
./deploy.sh ports list      # List active forwards
./deploy.sh ports config    # Show configuration

# Dynamic port forwarding
./deploy.sh forward 9999    # Forward port 9999 to RL-Swarm

# SSH tunneling
./port-manager.sh tunnel database.example.com:5432
```

## 🔌 Dynamic Port Forwarding

### Add Port Forward
```bash
# Forward specific port to RL-Swarm
./deploy.sh forward 9999

# Access RL-Swarm on port 9999
http://your-vps-ip:9999
```

### SSH Tunnel to Remote Service
```bash
# Create tunnel to remote database
./port-manager.sh tunnel database.example.com:5432

# Access remote database locally
localhost:2223 -> database.example.com:5432
```

### List Active Forwards
```bash
# Show all active port forwards
./deploy.sh ports list
```

## 🌐 Access Methods

### Method 1: Direct Port Access
```bash
# Multiple access points to the same RL-Swarm instance
http://your-vps-ip:3000    # Main RL-Swarm
http://your-vps-ip:8080    # Service port 1
http://your-vps-ip:8081    # Service port 2
http://your-vps-ip:8082    # Service port 3
http://your-vps-ip:9000    # Alternative 1
http://your-vps-ip:9001    # Alternative 2
http://your-vps-ip:9002    # Alternative 3
```

### Method 2: Reverse Proxy
```bash
# Nginx reverse proxy with load balancing
http://your-vps-ip:80      # Main web interface
https://your-vps-ip:443    # Secure SSL interface
```

### Method 3: Cloudflare Tunnel
```bash
# Automatic tunnel from container logs
./deploy.sh logs | grep "https://"
```

## 🔒 SSL Configuration

### Self-Signed Certificate
```bash
# Generate SSL certificates
./port-manager.sh ssl

# Certificates stored in ssl/
#   ssl/key.pem    # Private key
#   ssl/cert.pem   # Certificate
```

### Custom SSL Certificate
```bash
# Place your certificates in ssl/ directory
cp your-cert.pem ssl/cert.pem
cp your-key.pem ssl/key.pem

# Restart services
./deploy.sh stop-multi
./deploy.sh start-multi
```

## 🏗️ Architecture

```
Internet
    │
    ├─ Direct Port Access (Multiple Ports)
    │   ├─ :3000  → RL-Swarm (Main)
    │   ├─ :8080  → RL-Swarm (Service 1)
    │   ├─ :8081  → RL-Swarm (Service 2)
    │   ├─ :8082  → RL-Swarm (Service 3)
    │   ├─ :9000  → RL-Swarm (Alternative 1)
    │   ├─ :9001  → RL-Swarm (Alternative 2)
    │   └─ :9002  → RL-Swarm (Alternative 3)
    │
    ├─ Nginx Reverse Proxy
    │   ├─ :80    → Nginx → RL-Swarm
    │   └─ :443   → Nginx (SSL) → RL-Swarm
    │
    ├─ SSH Tunnels
    │   ├─ :2222  → Container SSH
    │   └─ :2223  → SSH Tunnel → Remote Services
    │
    └─ Cloudflare Tunnel
        └─ https://random.trycloudflare.com → RL-Swarm
```

## 📱 Use Cases

### Use Case 1: Development Team Access
```bash
# Setup multiple ports for different team members
./deploy.sh multiport 3000 8080 8081 8082

# Team members access:
# Developer 1: http://vps-ip:3000
# Developer 2: http://vps-ip:8080
# Developer 3: http://vps-ip:8081
# Testing:     http://vps-ip:8082
```

### Use Case 2: Production with Load Balancing
```bash
# Setup reverse proxy with SSL
./deploy.sh multiport 3000 80 443
./port-manager.sh ssl

# Access:
# Users:      https://vps-ip
# Admin:      http://vps-ip:3000
# Monitoring: http://vps-ip:8080
```

### Use Case 3: Database Tunneling
```bash
# Create tunnel to remote database
./port-manager.sh tunnel production-db.company.com:5432

# Access database locally:
psql -h localhost -p 2223 -U postgres
```

### Use Case 4: A/B Testing
```bash
# Forward additional ports for testing
./deploy.sh forward 9001    # Test version 1
./deploy.sh forward 9002    # Test version 2

# Access different versions:
# Production: http://vps-ip:3000
# Test 1:     http://vps-ip:9001
# Test 2:     http://vps-ip:9002
```

## 🔍 Monitoring and Troubleshooting

### Check Port Status
```bash
# Overall port status
./deploy.sh ports status

# Detailed container information
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Network connections
netstat -tlnp | grep -E ":(3000|80|443|808[0-2]|900[0-2]|222[0-9])"
```

### Service Logs
```bash
# RL-Swarm logs
docker logs -f rl-swarm-node

# Nginx proxy logs
docker logs -f rl-swarm-proxy

# Port forwarder logs
docker logs -f rl-swarm-forwarder

# SSH tunnel logs
docker logs -f rl-swarm-ssh-tunnel
```

### Common Issues

#### Port Already in Use
```bash
# Check what's using the port
sudo lsof -i :8080

# Stop conflicting service
sudo systemctl stop nginx

# Or use different port
./deploy.sh multiport 3000 8081 8082 8083
```

#### SSL Certificate Issues
```bash
# Regenerate certificates
./port-manager.sh ssl

# Check certificate files
ls -la ssl/
openssl x509 -in ssl/cert.pem -text -noout
```

#### Tunnel Not Working
```bash
# Check tunnel status
./deploy.sh tunnel status

# Restart tunnel services
./deploy.sh stop-multi
./deploy.sh start-multi
```

## 🔧 Advanced Configuration

### Custom Nginx Configuration
```bash
# Edit nginx.conf for custom rules
nano nginx.conf

# Add custom location blocks
location /custom/ {
    proxy_pass http://rl_swarm_backend/custom/;
    # Custom headers, auth, etc.
}
```

### Environment-Specific Configs
```bash
# Development environment
cat > .env.dev << EOF
RL_SWARM_PORT=3000
WEB_PORT=8080
AUTO_TUNNEL=false
EOF

# Production environment
cat > .env.prod << EOF
RL_SWARM_PORT=3000
WEB_PORT=80
HTTPS_PORT=443
AUTO_TUNNEL=true
TUNNEL_DOMAIN=rl-swarm.company.com
EOF
```

### Backup and Restore
```bash
# Backup configuration
cp .env .env.backup.$(date +%Y%m%d)
tar -czf ssl-backup.tar.gz ssl/

# Restore configuration
cp .env.backup.20231201 .env
tar -xzf ssl-backup.tar.gz
```

## 📊 Performance Considerations

### Resource Usage
- **Memory**: ~200MB for all containers
- **CPU**: Minimal under normal load
- **Network**: Multiple connections share same RL-Swarm instance

### Optimization Tips
```bash
# Limit log sizes
echo "{\"log-driver\":\"json-file\",\"log-opts\":{\"max-size\":\"10m\",\"max-file\":\"3\"}}" > /etc/docker/daemon.json

# Optimize Nginx for high concurrency
# Edit nginx.conf: increase worker_connections

# Monitor resource usage
docker stats rl-swarm-node rl-swarm-proxy rl-swarm-forwarder
```

## 🚀 Production Deployment

### Security Hardening
```bash
# Use custom SSL certificates
./port-manager.sh ssl
# Replace with production certificates

# Configure firewall
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 3000/tcp
sudo ufw enable

# Remove unnecessary services
docker-compose -f docker-compose.ports.yml down
docker image prune -f
```

### High Availability
```bash
# Multiple RL-Swarm instances (advanced)
# Edit docker-compose.ports.yml to add upstream servers

upstream rl_swarm_backend {
    server rl-swarm-1:3000;
    server rl-swarm-2:3000;
    server rl-swarm-3:3000;
}
```

---

**Support**: For issues with multi-port setup, use `./deploy.sh ports status` to diagnose problems.