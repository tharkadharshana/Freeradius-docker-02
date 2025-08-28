#!/bin/bash

# FreeRADIUS Docker System Setup for Linux/RedHat
# Complete production setup with Keepalived + Virtual IP + ETCD

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================"
echo -e "FreeRADIUS Docker System Setup (Linux/RedHat)"
echo -e "========================================${NC}"
echo

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker is not running. Please start Docker first.${NC}"
    exit 1
fi

# Check if docker-compose is available (support both v1 and v2)
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE_CMD="docker-compose"
    echo -e "${GREEN}✅ Docker Compose v1 detected${NC}"
elif docker compose &> /dev/null 2>&1; then
    DOCKER_COMPOSE_CMD="docker compose"
    echo -e "${GREEN}✅ Docker Compose v2 detected${NC}"
else
    echo -e "${RED}❌ Docker Compose is not available. Please install it first.${NC}"
    echo -e "${YELLOW}Note: Docker Compose v2 comes with Docker Desktop and newer Docker installations${NC}"
    echo -e "${YELLOW}Debug: Testing docker compose commands...${NC}"
    echo -e "${YELLOW}docker compose: $(docker compose 2>&1 | head -1 || echo 'failed')${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Docker and Docker Compose are available${NC}"
echo

echo -e "${YELLOW}Step 1: Stopping existing containers...${NC}"
$DOCKER_COMPOSE_CMD -f docker-compose-simple.yml down -v

echo
echo -e "${YELLOW}Step 2: Building new containers with ETCD + Keepalived support...${NC}"
$DOCKER_COMPOSE_CMD -f docker-compose-simple.yml build --no-cache

echo
echo -e "${YELLOW}Step 3: Starting ETCD first...${NC}"
$DOCKER_COMPOSE_CMD -f docker-compose-simple.yml up -d etcd

echo
echo -e "${YELLOW}Step 4: Waiting for ETCD to be ready...${NC}"
echo "Waiting for ETCD to be accessible..."
while ! curl -s http://localhost:2379/health > /dev/null 2>&1; do
    echo "ETCD not ready, waiting..."
    sleep 2
done
echo -e "${GREEN}✅ ETCD is ready!${NC}"

echo
echo -e "${YELLOW}Step 5: Loading production configurations into ETCD...${NC}"
bash load-configs-to-etcd-production.sh

echo
echo -e "${YELLOW}Step 6: Starting all FreeRADIUS services...${NC}"
$DOCKER_COMPOSE_CMD -f docker-compose-simple.yml up -d

echo
echo -e "${YELLOW}Step 7: Waiting for services to start and stabilize...${NC}"
sleep 15

echo
echo -e "${YELLOW}Step 8: Checking service status...${NC}"
$DOCKER_COMPOSE_CMD -f docker-compose-simple.yml ps

echo
echo -e "${YELLOW}Step 9: Testing ETCD connectivity from containers...${NC}"
docker exec freeradius-radius1 sh /scripts/test-etcd.sh

echo
echo -e "${YELLOW}Step 10: Testing Virtual IP accessibility...${NC}"
echo "Testing localhost:1812 (Virtual IP managed by Keepalived)..."
if command -v radtest &> /dev/null; then
    radtest test test localhost:1812 0 testing123
else
    echo -e "${YELLOW}⚠️  radtest not available, testing with netcat...${NC}"
    if command -v nc &> /dev/null; then
        echo "test" | nc -u localhost 1812
        echo -e "${GREEN}✅ Port 1812 is accessible${NC}"
    else
        echo -e "${YELLOW}⚠️  netcat not available, skipping port test${NC}"
    fi
fi

echo
echo -e "${GREEN}========================================"
echo -e "🎉 Setup completed successfully!"
echo -e "========================================${NC}"
echo
echo -e "${BLUE}Your FreeRADIUS system is now running with:${NC}"
echo -e "✅ Centralized configuration management via ETCD"
echo -e "✅ High Availability Load Balancers (LoadBalancer1 + LoadBalancer2)"
echo -e "✅ Automatic failover with Keepalived Virtual IP (172.20.0.100)"
echo -e "✅ Single external entry point on ports 1812/1813"
echo -e "✅ All configs managed from configs/production/"
echo
echo -e "${BLUE}To change configurations:${NC}"
echo -e "1. Edit files in configs/production/"
echo -e "2. Run ./load-configs-to-etcd-production.sh to reload"
echo -e "3. Restart containers if needed: $DOCKER_COMPOSE_CMD -f docker-compose-simple.yml restart"
echo
echo -e "${BLUE}To test the system:${NC}"
echo -e "• External access: localhost:1812 (Virtual IP)"
echo -e "• LoadBalancer1 direct: localhost:2812 (if needed)"
echo -e "• LoadBalancer2 direct: localhost:3812 (if needed)"
echo
echo -e "${BLUE}To monitor:${NC}"
echo -e "• Check status: docker ps"
echo -e "• Check logs: docker logs freeradius-keepalived"
echo -e "• Check ETCD: curl http://localhost:2379/health"
echo
echo -e "${GREEN}Press Enter to continue...${NC}"
read
