#!/bin/sh
set -euo pipefail
echo "System Information"
echo "User: $(whoami)"
echo "UID: $(id -u)"
echo "Hostname: $(hostname)"
echo "Kernel: $(uname -r)"
echo "Date: $(date -u +%Y-%m-%dT%H:%M:%S%z)"
echo "Disk Usage"
df -h
echo "Memory Usage"
free -h
echo "Docker Status:"
if docker info > /dev/null 2>&1; then
    echo "Docker is running"
else 
    echo "Docker is not running"
fi
