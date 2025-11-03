#!/bin/bash

# Automatic Port Forwarding Setup for RL-Swarm VPS
# This script configures port forwarding BEFORE Docker containers start

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DEFAULT_PORTS=(3000 8080 8081 8082 9000 9001 9002 80 443)
FORWARD_TARGET="127.0.0.1"  # Forward to localhost
FORWARD_METHOD="iptables"    # Use iptables for forwarding

echo -e "${BLUE}🔧 Automatic Port Forwarding Setup${NC}"
echo "========================================"
echo ""

# Function to check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}❌ This script must be run as root for port forwarding${NC}"
        echo "Please run: sudo $0"
        exit 1
    fi
}

# Function to detect system type
detect_system() {
    if [ -f /etc/debian_version ]; then
        echo "debian"
    elif [ -f /etc/redhat-release ]; then
        echo "redhat"
    elif command -v systemctl >/dev/null 2>&1; then
        echo "systemd"
    else
        echo "unknown"
    fi
}

# Function to install required packages
install_dependencies() {
    echo -e "${GREEN}📦 Installing dependencies...${NC}"

    SYSTEM_TYPE=$(detect_system)

    case $SYSTEM_TYPE in
        "debian"|"ubuntu")
            apt-get update
            apt-get install -y iptables-persistent netfilter-persistent socat
            ;;
        "redhat"|"centos")
            yum update -y
            yum install -y iptables-services socat
            systemctl enable iptables
            ;;
        *)
            echo -e "${YELLOW}⚠️  Unknown system type, please install iptables and socat manually${NC}"
            ;;
    esac
}

# Function to configure iptables for port forwarding
setup_iptables_forwarding() {
    echo -e "${GREEN}🌐 Setting up iptables port forwarding...${NC}"

    # Enable IP forwarding
    echo 1 > /proc/sys/net/ipv4/ip_forward

    # Make IP forwarding persistent
    if ! grep -q "net.ipv4.ip_forward=1" /etc/sysctl.conf; then
        echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
    fi

    # Clear existing rules for our ports
    for port in "${DEFAULT_PORTS[@]}"; do
        iptables -t nat -D PREROUTING -p tcp --dport $port -j DNAT --to-destination $FORWARD_TARGET:$port 2>/dev/null || true
        iptables -t nat -D POSTROUTING -p tcp --dport $port -j MASQUERADE 2>/dev/null || true
        iptables -D FORWARD -p tcp -d $FORWARD_TARGET --dport $port -j ACCEPT 2>/dev/null || true
    done

    # Add new forwarding rules
    for port in "${DEFAULT_PORTS[@]}"; do
        echo "   Forwarding port $port -> $FORWARD_TARGET:$port"

        # NAT rule for port forwarding
        iptables -t nat -A PREROUTING -p tcp --dport $port -j DNAT --to-destination $FORWARD_TARGET:$port

        # MASQUERADE rule for return traffic
        iptables -t nat -A POSTROUTING -p tcp --dport $port -j MASQUERADE

        # FORWARD rule to allow traffic
        iptables -A FORWARD -p tcp -d $FORWARD_TARGET --dport $port -j ACCEPT
    done

    # Save iptables rules
    SYSTEM_TYPE=$(detect_system)
    case $SYSTEM_TYPE in
        "debian"|"ubuntu")
            iptables-save > /etc/iptables/rules.v4 2>/dev/null || iptables-save > /etc/iptables.rules
            ;;
        "redhat"|"centos")
            service iptables save 2>/dev/null || iptables-save > /etc/sysconfig/iptables
            ;;
        *)
            echo -e "${YELLOW}⚠️  Please save iptables rules manually for your system${NC}"
            ;;
    esac

    echo -e "${GREEN}✓ iptables forwarding configured${NC}"
}

# Function to setup socat port forwarders
setup_socat_forwarders() {
    echo -e "${GREEN}🔗 Setting up socat port forwarders...${NC}"

    # Create socat configuration directory
    mkdir -p /etc/socat

    # Create systemd service for socat forwarders
    cat > /etc/systemd/system/socat-forwarders.service << 'EOF'
[Unit]
Description=Socat Port Forwarders for RL-Swarm
After=network.target

[Service]
Type=forking
ExecStart=/usr/local/bin/start-socat-forwarders.sh
ExecStop=/usr/bin/pkill -f "socat.*LISTEN"
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    # Create socat startup script
    cat > /usr/local/bin/start-socat-forwarders.sh << 'EOF'
#!/bin/bash

# Socat Port Forwarders for RL-Swarm
FORWARD_TARGET="127.0.0.1"
PORTS=(3000 8080 8081 8082 9000 9001 9002)

echo "Starting socat port forwarders..."

for port in "${PORTS[@]}"; do
    # Kill any existing socat process for this port
    pkill -f "socat.*LISTEN.*$port" 2>/dev/null || true

    # Start socat for this port
    socat TCP4-LISTEN:$port,fork,reuseaddr TCP4:$FORWARD_TARGET:$port &
    echo "Started socat for port $port"
done

echo "All socat forwarders started"
EOF

    chmod +x /usr/local/bin/start-socat-forwarders.sh

    # Enable and start the service
    systemctl enable socat-forwarders
    systemctl start socat-forwarders

    echo -e "${GREEN}✓ socat forwarders configured${NC}"
}

# Function to create systemd service for automatic port setup
create_autoport_service() {
    echo -e "${GREEN}⚙️  Creating automatic port setup service...${NC}"

    cat > /etc/systemd/system/rl-swarm-autoforward.service << EOF
[Unit]
Description=RL-Swarm Automatic Port Forwarding Setup
Before=docker.service
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/rl-swarm-autoforward.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
WantedBy=docker.service
EOF

    # Create the auto-forward script
    cat > /usr/local/bin/rl-swarm-autoforward.sh << 'EOF'
#!/bin/bash

# RL-Swarm Automatic Port Forwarding
# This runs before Docker starts

LOG_FILE="/var/log/rl-swarm-autoforward.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

log "Starting automatic port forwarding setup"

# Enable IP forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward
log "Enabled IP forwarding"

# Wait for network to be ready
sleep 5

# Start socat forwarders if they exist
if [ -f /usr/local/bin/start-socat-forwarders.sh ]; then
    /usr/local/bin/start-socat-forwarders.sh
    log "Started socat forwarders"
fi

log "Port forwarding setup completed"
EOF

    chmod +x /usr/local/bin/rl-swarm-autoforward.sh

    # Enable the service
    systemctl enable rl-swarm-autoforward.service

    echo -e "${GREEN}✓ Auto-forward service created${NC}"
}

# Function to setup firewall rules
setup_firewall() {
    echo -e "${GREEN}🔥 Configuring firewall...${NC}"

    # Check if UFW is available (Ubuntu/Debian)
    if command -v ufw >/dev/null 2>&1; then
        echo "Configuring UFW firewall..."

        # Allow our ports
        for port in "${DEFAULT_PORTS[@]}"; do
            ufw allow $port/tcp 2>/dev/null || echo "Could not add UFW rule for port $port"
        done

        # Enable UFW if not already enabled
        ufw --force enable 2>/dev/null || echo "UFW already enabled or could not enable"

    # Check if firewalld is available (RHEL/CentOS)
    elif command -v firewall-cmd >/dev/null 2>&1; then
        echo "Configuring firewalld..."

        # Add ports to firewalld
        for port in "${DEFAULT_PORTS[@]}"; do
            firewall-cmd --permanent --add-port=$port/tcp 2>/dev/null || echo "Could not add firewalld rule for port $port"
        done

        firewall-cmd --reload 2>/dev/null || echo "Could not reload firewalld"

    # Basic iptables fallback
    else
        echo "Configuring basic iptables rules..."

        for port in "${DEFAULT_PORTS[@]}"; do
            iptables -A INPUT -p tcp --dport $port -j ACCEPT 2>/dev/null || echo "Could not add iptables rule for port $port"
        done
    fi

    echo -e "${GREEN}✓ Firewall configured${NC}"
}

# Function to create automatic startup script
create_autostart_script() {
    echo -e "${GREEN}🚀 Creating automatic startup script...${NC}"

    cat > /usr/local/bin/start-rl-swarm-auto.sh << 'EOF'
#!/bin/bash

# Automatic RL-Swarm Startup with Port Forwarding
RL_SWARM_DIR="/opt/rl-swarm"
LOG_FILE="/var/log/rl-swarm-startup.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log "Starting RL-Swarm automatic startup"

# Check if directory exists
if [ ! -d "$RL_SWARM_DIR" ]; then
    log "Creating RL-Swarm directory"
    mkdir -p "$RL_SWARM_DIR"
    cp -r /root/rl-swarm/* "$RL_SWARM_DIR/" 2>/dev/null || log "Could not copy files"
fi

cd "$RL_SWARM_DIR"

# Start port forwarding (runs before Docker)
log "Starting port forwarding"
systemctl start rl-swarm-autoforward.service 2>/dev/null || log "Could not start auto-forward service"

# Wait for port forwarding to be ready
sleep 10

# Start Docker services
log "Starting Docker services"
if [ -f "docker-compose.ports.yml" ]; then
    docker-compose -f docker-compose.ports.yml up -d
else
    docker-compose up -d
fi

log "RL-Swarm startup completed"

# Show status
echo ""
echo "🎉 RL-Swarm started with automatic port forwarding!"
echo "📋 Access URLs:"
echo "   Main: http://$(curl -s ifconfig.me 2>/dev/null || echo 'YOUR_VPS_IP'):3000"
echo "   Web: http://$(curl -s ifconfig.me 2>/dev/null || echo 'YOUR_VPS_IP'):80"
echo "   Services: http://$(curl -s ifconfig.me 2>/dev/null || echo 'YOUR_VPS_IP'):8080-8082"
echo ""
echo "📊 Check status: ./auto-port-forward.sh status"
echo "📝 View logs: tail -f /var/log/rl-swarm-startup.log"
EOF

    chmod +x /usr/local/bin/start-rl-swarm-auto.sh

    # Create symlink for easy access
    ln -sf /usr/local/bin/start-rl-swarm-auto.sh /usr/local/bin/rl-swarm-auto

    echo -e "${GREEN}✓ Auto-startup script created${NC}"
}

# Function to show status
show_status() {
    echo -e "${BLUE}📊 Port Forwarding Status${NC}"
    echo "=========================="
    echo ""

    echo -e "${YELLOW}🔌 Active Port Forwards:${NC}"
    netstat -tlnp 2>/dev/null | grep -E ":(3000|80|443|808[0-2]|900[0-2])" | while read line; do
        echo "   $line"
    done

    echo ""
    echo -e "${YELLOW}🔥 Firewall Status:${NC}"
    if command -v ufw >/dev/null 2>&1; then
        ufw status verbose | head -10
    elif command -v firewall-cmd >/dev/null 2>&1; then
        firewall-cmd --list-all | head -10
    else
        iptables -L -n | head -10
    fi

    echo ""
    echo -e "${YELLOW}⚙️  Service Status:${NC}"
    systemctl is-active rl-swarm-autoforward.service 2>/dev/null && echo "   Auto-forward: ✅ Active" || echo "   Auto-forward: ❌ Inactive"
    systemctl is-active socat-forwarders.service 2>/dev/null && echo "   Socat: ✅ Active" || echo "   Socat: ❌ Inactive"
    systemctl is-active docker.service 2>/dev/null && echo "   Docker: ✅ Active" || echo "   Docker: ❌ Inactive"

    echo ""
    echo -e "${YELLOW}🌐 Access URLs:${NC}"
    VPS_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "YOUR_VPS_IP")
    echo "   Main: http://$VPS_IP:3000"
    echo "   Web: http://$VPS_IP:80"
    echo "   Service 1: http://$VPS_IP:8080"
    echo "   Service 2: http://$VPS_IP:8081"
    echo "   Service 3: http://$VPS_IP:8082"
}

# Function to cleanup
cleanup() {
    echo -e "${YELLOW}🧹 Cleaning up port forwarding...${NC}"

    # Stop services
    systemctl stop rl-swarm-autoforward.service 2>/dev/null || true
    systemctl stop socat-forwarders.service 2>/dev/null || true

    # Remove iptables rules
    for port in "${DEFAULT_PORTS[@]}"; do
        iptables -t nat -D PREROUTING -p tcp --dport $port -j DNAT --to-destination $FORWARD_TARGET:$port 2>/dev/null || true
        iptables -t nat -D POSTROUTING -p tcp --dport $port -j MASQUERADE 2>/dev/null || true
        iptables -D FORWARD -p tcp -d $FORWARD_TARGET --dport $port -j ACCEPT 2>/dev/null || true
    done

    # Kill socat processes
    pkill -f "socat.*LISTEN" 2>/dev/null || true

    echo -e "${GREEN}✓ Cleanup completed${NC}"
}

# Main execution
main() {
    case "${1:-setup}" in
        "setup")
            check_root
            echo -e "${BLUE}🚀 Setting up automatic port forwarding...${NC}"
            install_dependencies
            setup_iptables_forwarding
            setup_socat_forwarders
            create_autoport_service
            setup_firewall
            create_autostart_script

            echo ""
            echo -e "${GREEN}🎉 Automatic port forwarding setup completed!${NC}"
            echo ""
            echo -e "${BLUE}Next steps:${NC}"
            echo "   1. Reboot system: sudo reboot"
            echo "   2. Or start immediately: rl-swarm-auto"
            echo "   3. Check status: $0 status"
            echo ""
            ;;
        "status")
            show_status
            ;;
        "start")
            echo -e "${GREEN}🚀 Starting RL-Swarm with auto port forwarding...${NC}"
            /usr/local/bin/start-rl-swarm-auto.sh
            ;;
        "stop")
            echo -e "${YELLOW}🛑 Stopping RL-Swarm services...${NC}"
            systemctl stop rl-swarm-autoforward.service 2>/dev/null || true
            systemctl stop socat-forwarders.service 2>/dev/null || true
            ;;
        "restart")
            echo -e "${YELLOW}🔄 Restarting RL-Swarm services...${NC}"
            $0 stop
            sleep 5
            $0 start
            ;;
        "cleanup")
            check_root
            cleanup
            ;;
        "help"|"-h"|"--help")
            echo "Usage: $0 [command]"
            echo ""
            echo "Commands:"
            echo "  setup     Setup automatic port forwarding (requires root)"
            echo "  status    Show port forwarding status"
            echo "  start     Start RL-Swarm with auto port forwarding"
            echo "  stop      Stop RL-Swarm services"
            echo "  restart   Restart RL-Swarm services"
            echo "  cleanup   Clean up port forwarding rules (requires root)"
            echo "  help      Show this help"
            ;;
        *)
            echo -e "${RED}❌ Unknown command: $1${NC}"
            echo "Use '$0 help' for available commands"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"