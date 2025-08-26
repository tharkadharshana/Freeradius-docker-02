#!/bin/bash

# ============================================================================
# Health Monitor Script for FreeRADIUS Load Balancer
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

# Check backend RADIUS servers
check_backend_servers() {
    local servers=("radius1" "radius2" "radius3")
    local healthy_count=0
    
    for server in "${servers[@]}"; do
        if ping -c 1 "$server" > /dev/null 2>&1; then
            log "✓ Backend server $server is reachable"
            ((healthy_count++))
        else
            log "✗ Backend server $server is not reachable"
        fi
    done
    
    if [ $healthy_count -gt 0 ]; then
        log "✓ $healthy_count out of ${#servers[@]} backend servers are healthy"
        return 0
    else
        log "✗ No backend servers are healthy"
        return 1
    fi
}

# Main health check
main_health_check() {
    log "Starting health check for load balancer..."
    
    local overall_health=true
    
    check_radius_process || overall_health=false
    check_radius_port || overall_health=false
    check_backend_servers || overall_health=false
    
    if [ "$overall_health" = true ]; then
        log "✓ All health checks passed"
    else
        log "✗ Some health checks failed"
    fi
    
    log "Health check completed"
}

# Main loop
main() {
    log "Health Monitor started for load balancer"
    
    while true; do
        main_health_check
        sleep 60  # Check every minute
    done
}

# Handle signals
trap 'log "Health monitor stopped"; exit 0' SIGTERM SIGINT

# Start main function
main

