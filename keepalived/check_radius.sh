#!/bin/bash

# Health check script for keepalived
# Checks if RADIUS service is responding on port 1812

RADIUS_HOST="172.20.0.100"
RADIUS_PORT="1812"

# Check if port 1812 is open and responding
if netcat -z -w 2 $RADIUS_HOST $RADIUS_PORT 2>/dev/null; then
    echo "$(date): RADIUS health check PASSED - port $RADIUS_PORT is open on $RADIUS_HOST" >> /var/log/keepalived/health.log
    exit 0
else
    echo "$(date): RADIUS health check FAILED - port $RADIUS_PORT is not accessible on $RADIUS_HOST" >> /var/log/keepalived/health.log
    exit 1
fi
