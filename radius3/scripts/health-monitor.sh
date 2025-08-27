#!/bin/bash

# ============================================================================
# Health Monitor Script for FreeRADIUS radius3
# Basic health monitoring for testing
# ============================================================================

LOG_FILE="/var/log/radius/health-monitor.log"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Check FreeRADIUS process
check_radius_process() {
    if pgrep -f "radiusd" > /dev/null; then
        log "✓ FreeRADIUS process is running"
        return 0
    else
        log "✗ FreeRADIUS process is not running"
        return 1
    fi
}

# Check RADIUS port
check_radius_port() {
    if netstat -tuln | grep -q ":1812 "; then
        log "✓ Port 1812 is listening"
        return 0
    else
        log "✗ Port 1812 is not listening"
        return 1
    fi
}

# Check MySQL connectivity
check_mysql_connectivity() {
    if mysql -h "${EXTERNAL_MYSQL_HOST:-host.docker.internal}" \
             -u "${EXTERNAL_MYSQL_USER:-radius}" \
             -p"${EXTERNAL_MYSQL_PASSWORD:-RadiusPass123!}" \
             -P "${EXTERNAL_MYSQL_PORT:-3306}" \
             -e "SELECT 1;" > /dev/null 2>&1; then
        log "✓ MySQL connection is working"
        return 0
    else
        log "✗ MySQL connection failed"
        return 1
    fi
}

# Main health check
main_health_check() {
    log "Starting health check for radius3..."
    
    local overall_health=true
    
    check_radius_process || overall_health=false
    check_radius_port || overall_health=false
    check_mysql_connectivity || overall_health=false
    
    if [ "$overall_health" = true ]; then
        log "✓ All health checks passed"
    else
        log "✗ Some health checks failed"
    fi
    
    log "Health check completed"
}

# Main loop
main() {
    log "Health Monitor started for radius3"
    
    while true; do
        main_health_check
        sleep 60  # Check every minute
    done
}

# Handle signals
trap 'log "Health monitor stopped"; exit 0' SIGTERM SIGINT

# Start main function
main


