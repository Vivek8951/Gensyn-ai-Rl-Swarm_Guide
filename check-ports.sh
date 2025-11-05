#!/bin/bash

# Simple port checking utility for Jenkins
# Returns 0 if all ports are free, 1 if any port is in use

set -e

TARGET_PORTS=(3000 8080 8081 8082 9000 9001 9002)
BLOCKED_PORTS=()

echo "🔍 Checking if target ports are available..."
echo "Target ports: ${TARGET_PORTS[*]}"
echo ""

for port in "${TARGET_PORTS[@]}"; do
    if lsof -i :$port >/dev/null 2>&1; then
        echo "❌ Port $port is BLOCKED"
        BLOCKED_PORTS+=("$port")
    else
        echo "✅ Port $port is available"
    fi
done

echo ""
if [ ${#BLOCKED_PORTS[@]} -eq 0 ]; then
    echo "🎉 All target ports are available!"
    exit 0
else
    echo "❌ Blocked ports: ${BLOCKED_PORTS[*]}"
    exit 1
fi