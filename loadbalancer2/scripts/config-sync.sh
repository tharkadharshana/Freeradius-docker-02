#!/bin/bash

# ============================================================================
# Config Sync Script for FreeRADIUS Load Balancer 2
# Basic configuration synchronization for testing
# ============================================================================

LOG_FILE="/var/log/radius/config-sync.log"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Check if ETCD is available
check_etcd() {
    if curl -s "${ETCD_ENDPOINTS:-http://etcd:2379}/health" > /dev/null 2>&1; then
        log "✓ ETCD is available"
        return 0
    else
        log "✗ ETCD is not available"
        return 1
    fi
}

# Sync configuration from ETCD
sync_config() {
    local config_key="$1"
    local config_path="$2"
    
    log "Syncing $config_key to $config_path"
    
    # Get config from etcd
    local config_content
    config_content=$(curl -s "${ETCD_ENDPOINTS:-http://etcd:2379}/v3/kv/range" \
        -H "Content-Type: application/json" \
        -d "{\"key\": \"$(echo -n "$config_key" | base64)\"}" | \
        jq -r '.kvs[0].value' | base64 -d 2>/dev/null || echo "")
    
    if [ -n "$config_content" ]; then
        echo "$config_content" > "$config_path"
        log "✓ Successfully synced $config_key"
        return 0
    else
        log "✗ Failed to sync $config_key"
        return 1
    fi
}

# Main sync function
main_sync() {
    log "Starting configuration synchronization for load balancer 2..."
    
    if ! check_etcd; then
        log "ETCD not available, skipping sync"
        return 1
    fi
    
    local configs_synced=0
    
    # Sync main configurations
    sync_config "freeradius/loadbalancer2/radiusd.conf" "/etc/raddb/radiusd.conf" && ((configs_synced++))
    sync_config "freeradius/loadbalancer2/proxy.conf" "/etc/raddb/proxy.conf" && ((configs_synced++))
    sync_config "freeradius/loadbalancer2/clients.conf" "/etc/raddb/clients.conf" && ((configs_synced++))
    
    log "Configuration sync completed: $configs_synced configs synced"
    
    # Reload FreeRADIUS if configs changed
    if [ $configs_synced -gt 0 ]; then
        log "Configurations changed, reloading FreeRADIUS..."
        if [ -f /var/run/radiusd/radiusd.pid ]; then
            kill -HUP $(cat /var/run/radiusd/radiusd.pid) 2>/dev/null && \
            log "✓ FreeRADIUS reloaded successfully" || \
            log "✗ Failed to reload FreeRADIUS"
        else
            log "FreeRADIUS PID file not found, skipping reload"
        fi
    fi
}

# Main loop
main() {
    log "Config Sync started for load balancer 2"
    
    # Initial sync
    main_sync
    
    # Continuous sync loop
    while true; do
        sleep 300  # Sync every 5 minutes
        main_sync
    done
}

# Handle signals
trap 'log "Config sync stopped"; exit 0' SIGTERM SIGINT

# Start main function
main


