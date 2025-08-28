#!/bin/bash
# Notification script for when this node becomes BACKUP
# This script runs when LoadBalancer1 becomes standby

# Configuration
LOG_FILE="/var/log/keepalived/notify.log"
RADIUS_SERVICE="freeradius"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - BACKUP: $1" >> "$LOG_FILE"
}

# Main execution
log_message "This node is now BACKUP - LoadBalancer1 is standby"

# Keep RADIUS service running but reduce priority
log_message "LoadBalancer1 is now in standby mode - ready to take over if needed"

# Optional: Send notification to monitoring system
# curl -X POST "http://monitoring-system/api/status" -d "status=backup&node=loadbalancer1"

exit 0


