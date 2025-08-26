#!/bin/bash

# ============================================================================
# Health Monitor Script for FreeRADIUS Failover Router
# Monitors system health and reports status
# ============================================================================

LOG_FILE="/var/log/failover/health-monitor.log"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Check iptables rules
check_iptables() {
    log "Checking iptables rules..."
    
    local rules_count=$(iptables -t nat -L PREROUTING --line-numbers | grep -c "1812\|1813" || echo "0")
    log "Active routing rules: $rules_count"
    
    if [ "$rules_count" -eq 0 ]; then
        log "WARNING: No active routing rules found!"
        return 1
    fi
    
    return 0
}

# Check network connectivity
check_network() {
    log "Checking network connectivity..."
    
    # Check primary load balancer
    if ping -c 1 loadbalancer1 >/dev/null 2>&1; then
        log "✓ Primary load balancer (loadbalancer1) is reachable"
    else
        log "✗ Primary load balancer (loadbalancer1) is not reachable"
    fi
    
    # Check backup load balancer
    if ping -c 1 loadbalancer2 >/dev/null 2>&1; then
        log "✓ Backup load balancer (loadbalancer2) is reachable"
    else
        log "✗ Backup load balancer (loadbalancer2) is not reachable"
    fi
}

# Check port availability
check_ports() {
    log "Checking port availability..."
    
    # Check if our ports are listening
    if netstat -tuln | grep -q ":1812 "; then
        log "✓ Port 1812 is listening"
    else
        log "✗ Port 1812 is not listening"
    fi
    
    if netstat -tuln | grep -q ":1813 "; then
        log "✓ Port 1813 is listening"
    else
        log "✗ Port 1813 is not listening"
    fi
}

# Check system resources
check_resources() {
    log "Checking system resources..."
    
    # Check disk space
    local disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ "$disk_usage" -lt 80 ]; then
        log "✓ Disk usage: ${disk_usage}%"
    else
        log "⚠ Disk usage: ${disk_usage}% (high)"
    fi
    
    # Check memory
    local mem_usage=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
    log "Memory usage: ${mem_usage}%"
    
    # Check CPU load
    local cpu_load=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    log "CPU load: $cpu_load"
}

# Main health check
main_health_check() {
    log "Starting health check..."
    
    check_iptables
    check_network
    check_ports
    check_resources
    
    log "Health check completed"
}

# Main loop
main() {
    log "Health Monitor started"
    
    while true; do
        main_health_check
        sleep 60  # Check every minute
    done
}

# Handle signals
trap 'log "Health monitor stopped"; exit 0' SIGTERM SIGINT

# Start main function
main

