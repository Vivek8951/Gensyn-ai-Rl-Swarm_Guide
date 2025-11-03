#!/bin/bash

# Test script for automatic port forwarding
# Verifies that port forwarding works before and after Docker

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🧪 Testing Automatic Port Forwarding${NC}"
echo "======================================"
echo ""

# Test results
TESTS_PASSED=0
TESTS_FAILED=0

# Function to run test
run_test() {
    local test_name="$1"
    local test_command="$2"

    echo -e "${BLUE}Testing: $test_name${NC}"

    if eval "$test_command" >/dev/null 2>&1; then
        echo -e "   ${GREEN}✅ PASSED${NC}"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "   ${RED}❌ FAILED${NC}"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Function to show status
show_status() {
    echo ""
    echo -e "${BLUE}📊 Test Results:${NC}"
    echo "   Passed: $TESTS_PASSED"
    echo "   Failed: $TESTS_FAILED"
    echo ""

    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}🎉 All tests passed! Automatic port forwarding is working.${NC}"
    else
        echo -e "${RED}❌ Some tests failed. Please check the configuration.${NC}"
    fi
}

# Get VPS IP
VPS_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "127.0.0.1")

echo -e "${BLUE}System Information:${NC}"
echo "   IP Address: $VPS_IP"
echo "   Hostname: $(hostname)"
echo "   OS: $(uname -s)"
echo ""

# Test 1: Check if required tools are available
echo -e "${YELLOW}🔧 Checking required tools...${NC}"
run_test "iptables available" "command -v iptables"
run_test "socat available" "command -v socat"
run_test "curl available" "command -c curl"
run_test "netstat available" "command -v netstat"

# Test 2: Check system configuration
echo ""
echo -e "${YELLOW}⚙️  Checking system configuration...${NC}"
run_test "IP forwarding enabled" "cat /proc/sys/net/ipv4/ip_forward | grep -q 1"
run_test "Auto-forward script exists" "test -f /usr/local/bin/rl-swarm-autoforward.sh"
run_test "Start script exists" "test -f /usr/local/bin/start-rl-swarm-auto.sh"

# Test 3: Check services
echo ""
echo -e "${YELLOW}🔍 Checking system services...${NC}"
run_test "Auto-forward service enabled" "systemctl is-enabled rl-swarm-autoforward.service"
run_test "Socat service enabled" "systemctl is-enabled socat-forwarders.service"
run_test "Docker service running" "systemctl is-active docker.service"

# Test 4: Check port forwarding rules
echo ""
echo -e "${YELLOW}🌐 Checking port forwarding rules...${NC}"
run_test "Port 3000 forwarding rule" "iptables -t nat -L PREROUTING | grep -q dpt:3000"
run_test "Port 8080 forwarding rule" "iptables -t nat -L PREROUTING | grep -q dpt:8080"
run_test "Port 80 forwarding rule" "iptables -t nat -L PREROUTING | grep -q dpt:80"

# Test 5: Check if services are listening
echo ""
echo -e "${YELLOW}🔌 Checking listening ports...${NC}"
run_test "Port 3000 is listening" "netstat -tlnp | grep -q :3000"
run_test "Socat processes running" "pgrep -f 'socat.*LISTEN' >/dev/null"

# Test 6: Check Docker containers
echo ""
echo -e "${YELLOW}🐳 Checking Docker containers...${NC}"
run_test "RL-Swarm container exists" "docker ps -a | grep -q rl-swarm"
run_test "RL-Swarm container running" "docker ps | grep -q rl-swarm"

# Test 7: Test connectivity
echo ""
echo -e "${YELLOW}🔗 Testing connectivity...${NC}"
run_test "Local port 3000 reachable" "curl -s http://localhost:3000/health >/dev/null || curl -s http://localhost:3000 >/dev/null"
run_test "External port 3000 reachable" "curl -s http://$VPS_IP:3000/health >/dev/null || curl -s http://$VPS_IP:3000 >/dev/null"

# Test 8: Test log files
echo ""
echo -e "${YELLOW}📝 Checking log files...${NC}"
run_test "Auto-forward log exists" "test -f /var/log/rl-swarm-autoforward.log"
run_test "Startup log exists" "test -f /var/log/rl-swarm-startup.log"

# Show detailed status
echo ""
echo -e "${BLUE}📋 Detailed Status:${NC}"
echo ""

echo -e "${YELLOW}🌐 Active Port Forwards:${NC}"
netstat -tlnp 2>/dev/null | grep -E ":(3000|80|443|808[0-2]|900[0-2])" | while read line; do
    echo "   $line"
done

echo ""
echo -e "${YELLOW}🐳 Docker Containers:${NC}"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "   No Docker containers running"

echo ""
echo -e "${YELLOW}⚙️  Service Status:${NC}"
echo "   Auto-forward: $(systemctl is-active rl-swarm-autoforward.service 2>/dev/null || echo 'inactive')"
echo "   Socat: $(systemctl is-active socat-forwarders.service 2>/dev/null || echo 'inactive')"
echo "   Docker: $(systemctl is-active docker.service 2>/dev/null || echo 'inactive')"

echo ""
echo -e "${YELLOW}📊 Access URLs:${NC}"
echo "   Main: http://$VPS_IP:3000"
echo "   Web: http://$VPS_IP:80"
echo "   Service 1: http://$VPS_IP:8080"
echo "   Service 2: http://$VPS_IP:8081"
echo "   Service 3: http://$VPS_IP:8082"

# Show final status
show_status

# Troubleshooting tips if tests failed
if [ $TESTS_FAILED -gt 0 ]; then
    echo ""
    echo -e "${YELLOW}🔧 Troubleshooting Tips:${NC}"
    echo "   • Check if auto-port-forward.sh was run with sudo"
    echo "   • Verify system reboot after installation"
    echo "   • Check logs: journalctl -u rl-swarm-autoforward -f"
    echo "   • Manual start: systemctl start rl-swarm-autoforward"
    echo "   • Check firewall: ufw status or firewall-cmd --list-all"
    echo ""
    echo -e "${BLUE}Manual fix commands:${NC}"
    echo "   sudo ./auto-port-forward.sh setup"
    echo "   sudo systemctl start rl-swarm-autoforward"
    echo "   sudo rl-swarm-auto"
fi

echo ""
echo -e "${BLUE}📝 Log Files:${NC}"
echo "   Auto-forward: /var/log/rl-swarm-autoforward.log"
echo "   Startup: /var/log/rl-swarm-startup.log"
echo "   System: journalctl -u rl-swarm-auto -f"