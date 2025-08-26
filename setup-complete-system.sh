#!/bin/bash

echo "========================================"
echo "FreeRADIUS Docker System Setup (Linux)"
echo "========================================"
echo

echo "Step 1: Stopping existing containers..."
docker-compose -f docker-compose-simple.yml down -v

echo
echo "Step 2: Building new containers with ETCD support..."
docker-compose -f docker-compose-simple.yml build --no-cache

echo
echo "Step 3: Starting ETCD first..."
docker-compose -f docker-compose-simple.yml up -d etcd

echo
echo "Step 4: Waiting for ETCD to be ready..."
while ! curl -s http://localhost:2379/health > /dev/null 2>&1; do
    echo "ETCD not ready, waiting..."
    sleep 2
done
echo "ETCD is ready!"

echo
echo "Step 5: Loading configurations into ETCD..."
bash load-configs-to-etcd.sh

echo
echo "Step 6: Starting all FreeRADIUS services..."
docker-compose -f docker-compose-simple.yml up -d

echo
echo "Step 7: Waiting for services to start..."
sleep 10

echo
echo "Step 8: Checking service status..."
docker ps

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
echo "- No volume mounts needed"
echo "- All configs managed centrally"
echo
echo "To change configurations:"
echo "1. Edit files in freeradius-docker_reference_only_previous_working_production/configs/"
echo "2. Run ./load-configs-to-etcd.sh to reload"
echo "3. Restart containers if needed"
echo
echo "Press Enter to continue..."
read
