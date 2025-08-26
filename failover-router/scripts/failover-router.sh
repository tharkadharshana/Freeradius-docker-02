#!/bin/bash

# ============================================================================
# FreeRADIUS Failover Router Script
# Handles smart failover between loadbalancer1 and loadbalancer2
# ============================================================================

# Configuration
PRIMARY_LB="${PRIMARY_LB:-loadbalancer1}"
BACKUP_LB="${BACKUP_LB:-loadbalancer2}"
PRIMARY_LB_PORT="${PRIMARY_LB_PORT:-1812}"
BACKUP_LB_PORT="${BACKUP_LB_PORT:-1812}"
FAILOVER_CHECK_INTERVAL="${FAILOVER_CHECK_INTERVAL:-5}"
FAILOVER_DELAY="${FAILOVER_DELAY:-10}"

# State variables
CURRENT_PRIMARY="$PRIMARY_LB"
LAST_FAILOVER=0

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a /var/log/failover/failover.log
}

# Initialize iptables
init_iptables() {
    log "Initializing iptables for failover routing"
    
    # Clear existing rules
    iptables -t nat -F PREROUTING 2>/dev/null || true
    
    # Set initial routing to primary load balancer
    iptables -t nat -A PREROUTING -p udp --dport 1812 -j DNAT --to-destination "${PRIMARY_LB}:${PRIMARY_LB_PORT}"
    iptables -t nat -A PREROUTING -p udp --dport 1813 -j DNAT --to-destination "${PRIMARY_LB}:${PRIMARY_LB_PORT}"
    
    log "Initial routing set to $PRIMARY_LB"
}

# Check if load balancer is healthy
check_lb_health() {
    local lb="$1"
    local port="$2"
    
    if nc -z "$lb" "$port" 2>/dev/null; then
        return 0  # Healthy
    else
        return 1  # Unhealthy
    fi
}

# Perform failover
perform_failover() {
    local from_lb="$1"
    local to_lb="$2"
    local current_time=$(date +%s)
    
    if [ $((current_time - LAST_FAILOVER)) -lt $FAILOVER_DELAY ]; then
        log "Failover blocked: too soon since last failover"
        return 1
    fi
    
    log "Performing failover from $from_lb to $to_lb"
    
    # Update routing rules
    if [ "$to_lb" = "$PRIMARY_LB" ]; then
        # Route to primary load balancer
        iptables -t nat -D PREROUTING -p udp --dport 1812 -j DNAT --to-destination "${PRIMARY_LB}:${PRIMARY_LB_PORT}" 2>/dev/null || true
        iptables -t nat -D PREROUTING -p udp --dport 1813 -j DNAT --to-destination "${PRIMARY_LB}:${PRIMARY_LB_PORT}" 2>/dev/null || true
        
        iptables -t nat -A PREROUTING -p udp --dport 1812 -j DNAT --to-destination "${PRIMARY_LB}:${PRIMARY_LB_PORT}"
        iptables -t nat -A PREROUTING -p udp --dport 1813 -j DNAT --to-destination "${PRIMARY_LB}:${PRIMARY_LB_PORT}"
        
        CURRENT_PRIMARY="$PRIMARY_LB"
        log "Failover completed: now routing to $PRIMARY_LB"
    else
        # Route to backup load balancer
        iptables -t nat -D PREROUTING -p udp --dport 1812 -j DNAT --to-destination "${PRIMARY_LB}:${PRIMARY_LB_PORT}" 2>/dev/null || true
        iptables -t nat -D PREROUTING -p udp --dport 1813 -j DNAT --to-destination "${PRIMARY_LB}:${PRIMARY_LB_PORT}" 2>/dev/null || true
        
        iptables -t nat -A PREROUTING -p udp --dport 1812 -j DNAT --to-destination "${BACKUP_LB}:${BACKUP_LB_PORT}"
        iptables -t nat -A PREROUTING -p udp --dport 1813 -j DNAT --to-destination "${BACKUP_LB}:${BACKUP_LB_PORT}"
        
        CURRENT_PRIMARY="$BACKUP_LB"
        log "Failover completed: now routing to $BACKUP_LB"
    fi
    
    LAST_FAILOVER=$current_time
}

# Main failover logic
main_failover_logic() {
    local primary_healthy=false
    local backup_healthy=false
    
    # Check primary load balancer health
    if check_lb_health "$PRIMARY_LB" "$PRIMARY_LB_PORT"; then
        primary_healthy=true
        log "Primary load balancer ($PRIMARY_LB) is healthy"
    else
        log "Primary load balancer ($PRIMARY_LB) is unhealthy"
    fi
    
    # Check backup load balancer health
    if check_lb_health "$BACKUP_LB" "$BACKUP_LB_PORT"; then
        backup_healthy=true
        log "Backup load balancer ($BACKUP_LB) is healthy"
    else
        log "Backup load balancer ($BACKUP_LB) is unhealthy"
    fi
    
    # Decision logic
    if [ "$primary_healthy" = true ] && [ "$CURRENT_PRIMARY" != "$PRIMARY_LB" ]; then
        # Primary is healthy and we're not using it - failback
        log "Primary is healthy, performing failback"
        perform_failover "$CURRENT_PRIMARY" "$PRIMARY_LB"
    elif [ "$primary_healthy" = false ] && [ "$CURRENT_PRIMARY" = "$PRIMARY_LB" ] && [ "$backup_healthy" = true ]; then
        # Primary is down, backup is healthy, and we're using primary - failover
        log "Primary is down, backup is healthy, performing failover"
        perform_failover "$PRIMARY_LB" "$BACKUP_LB"
    elif [ "$primary_healthy" = false ] && [ "$backup_healthy" = false ]; then
        log "WARNING: Both load balancers are down!"
    fi
}

# Main loop
main() {
    log "Starting FreeRADIUS Failover Router"
    log "Primary: $PRIMARY_LB:$PRIMARY_LB_PORT"
    log "Backup: $BACKUP_LB:$BACKUP_LB_PORT"
    log "Check interval: ${FAILOVER_CHECK_INTERVAL}s"
    log "Failover delay: ${FAILOVER_DELAY}s"
    
    # Initialize iptables
    init_iptables
    
    # Main loop
    while true; do
        main_failover_logic
        sleep "$FAILOVER_CHECK_INTERVAL"
    done
}

# Handle signals
trap 'log "Received signal, shutting down..."; exit 0' SIGTERM SIGINT

# Start main function
main

