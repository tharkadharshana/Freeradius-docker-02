#!/bin/bash

# FreeRADIUS Docker System Setup for Linux/RedHat (Legacy Script)
# This script is kept for backward compatibility
# For new installations, use: setup-complete-system-linux.sh

echo "========================================"
echo "FreeRADIUS Docker System Setup (Linux) - LEGACY"
echo "========================================"
echo
echo "⚠️  This is a legacy script. For new installations, use:"
echo "   ./setup-complete-system-linux.sh"
echo

# Check if Docker Compose is available (support both v1 and v2)
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE_CMD="docker-compose"
    echo "✅ Docker Compose v1 detected"
elif docker compose version &> /dev/null; then
    DOCKER_COMPOSE_CMD="docker compose"
    echo "✅ Docker Compose v2 detected"
else
    echo "❌ Docker Compose is not available. Please install it first."
    exit 1
fi

echo "Step 1: Stopping existing containers..."
$DOCKER_COMPOSE_CMD -f docker-compose-simple.yml down -v

echo
echo "Step 2: Building new containers with ETCD support..."
$DOCKER_COMPOSE_CMD -f docker-compose-simple.yml build --no-cache

echo
echo "Step 3: Starting ETCD first..."
$DOCKER_COMPOSE_CMD -f docker-compose-simple.yml up -d etcd

echo
echo "Step 4: Waiting for ETCD to be ready..."
while ! curl -s http://localhost:2379/health > /dev/null 2>&1; do
    echo "ETCD not ready, waiting..."
    sleep 2
done
echo "ETCD is ready!"

echo
echo "Step 5: Loading configurations into ETCD..."
bash load-configs-to-etcd-production.sh

echo
echo "Step 6: Starting all FreeRADIUS services..."
$DOCKER_COMPOSE_CMD -f docker-compose-simple.yml up -d

echo
echo "Step 7: Waiting for services to start..."
sleep 10

echo
echo "Step 8: Checking service status..."
$DOCKER_COMPOSE_CMD -f docker-compose-simple.yml ps

echo
echo "Step 9: Testing ETCD connectivity from containers..."
docker exec freeradius-radius1 sh /scripts/test-etcd.sh

echo
echo "========================================"
echo "Setup completed!"
echo "========================================"
echo
echo "Your FreeRADIUS system is now running with:"
echo "- Centralized configuration management via ETCD"
echo "- Production configurations from configs/production/"
echo "- All configs managed centrally"
echo
echo "To change configurations:"
echo "1. Edit files in configs/production/"
echo "2. Run ./load-configs-to-etcd-production.sh to reload"
echo "3. Restart containers if needed: $DOCKER_COMPOSE_CMD -f docker-compose-simple.yml restart"
echo
echo "Press Enter to continue..."
read
