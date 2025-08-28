#!/bin/bash
# Notification script for when this node becomes MASTER
# This script runs when LoadBalancer1 takes over as primary

# Configuration
LOG_FILE="/var/log/keepalived/notify.log"
RADIUS_SERVICE="freeradius"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - MASTER: $1" >> "$LOG_FILE"
}

# Main execution
log_message "This node is now MASTER - LoadBalancer1 is active"

# Ensure RADIUS service is running and healthy
if systemctl is-active --quiet "$RADIUS_SERVICE"; then
    log_message "RADIUS service is already running"
else
    log_message "Starting RADIUS service"
    systemctl start "$RADIUS_SERVICE"
fi

# Log the transition
log_message "Failover completed - LoadBalancer1 is now handling traffic on ports 1812/1813"

# Optional: Send notification to monitoring system
# curl -X POST "http://monitoring-system/api/status" -d "status=master&node=loadbalancer1"

exit 0


