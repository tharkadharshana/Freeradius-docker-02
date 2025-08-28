#!/bin/sh

# Fetch FreeRADIUS configurations from ETCD
# This script is used by containers to get their configs from ETCD

ETCD_ENDPOINT=${ETCD_ENDPOINTS:-"http://etcd:2379"}

# Determine service name - handle both RADIUS servers and load balancers
if [ -n "$RADIUS_SERVER_ID" ]; then
    SERVICE_NAME="$RADIUS_SERVER_ID"
elif [ -n "$LB_ID" ]; then
    # Convert LB_ID to service name format
    case "$LB_ID" in
        "lb1") SERVICE_NAME="loadbalancer" ;;
        "lb2") SERVICE_NAME="loadbalancer2" ;;
        *) SERVICE_NAME="loadbalancer" ;;  # Default fallback
    esac
else
    SERVICE_NAME="radius1"  # Default fallback
fi

CONFIG_DIR="/opt/etc/raddb"

echo "Fetching configurations for $SERVICE_NAME from ETCD at $ETCD_ENDPOINT"

# Function to fetch config file from ETCD
fetch_config_from_etcd() {
    local config_file=$1
    local etcd_key="/freeradius/$SERVICE_NAME/$config_file"
    local config_path="$CONFIG_DIR/$config_file"

    echo "Fetching $etcd_key"

    # Get the config from ETCD
    response=$(curl -s -X POST "$ETCD_ENDPOINT/v3/kv/range" \
        -H "Content-Type: application/json" \
        -d "{\"key\": \"$(echo -n $etcd_key | base64)\"}")

    # Extract the value from response
    value=$(echo "$response" | grep -o '"value":"[^"]*"' | cut -d'"' -f4)

    if [ -n "$value" ]; then
        # Create directory if it doesn't exist
        mkdir -p "$(dirname "$config_path")"

        # Decode and write the config file
        echo "$value" | base64 -d > "$config_path"

        if [ $? -eq 0 ]; then
            echo "✅ Fetched $config_file"
            # Set proper permissions
            chmod 644 "$config_path"
            return 0
        else
            echo "❌ Failed to write $config_file"
            return 1
        fi
    else
        echo "⚠️  Config not found in ETCD: $etcd_key"
        return 1
    fi
}

# Function to fetch all configs for the service
fetch_all_configs() {
    echo "Fetching all configurations for $SERVICE_NAME..."

    # Fetch main config files
    fetch_config_from_etcd "radiusd.conf"
    fetch_config_from_etcd "clients.conf"
    fetch_config_from_etcd "sql.conf"
    fetch_config_from_etcd "proxy.conf"
    fetch_config_from_etcd "experimental.conf"
    fetch_config_from_etcd "templates.conf"
    fetch_config_from_etcd "trigger.conf"

    # Fetch mods-available files - only try a few key ones
    fetch_config_from_etcd "mods-available/sql"
    fetch_config_from_etcd "mods-available/always"
    fetch_config_from_etcd "mods-available/realm"
    fetch_config_from_etcd "mods-available/preprocess"

    # Fetch mods-config files - only try a few key ones
    fetch_config_from_etcd "mods-config/sql/connection"
    fetch_config_from_etcd "mods-config/sql/main"
    fetch_config_from_etcd "mods-config/attr_filter/access_reject"
    fetch_config_from_etcd "mods-config/attr_filter/access_challenge"

    # Fetch policy.d files - only try a few key ones
    fetch_config_from_etcd "policy.d/accounting"
    fetch_config_from_etcd "policy.d/authentication"

    # Fetch sites-available files - only try a few key ones
    fetch_config_from_etcd "sites-available/default"
    fetch_config_from_etcd "sites-available/inner-tunnel"
    fetch_config_from_etcd "sites-available/status"
    fetch_config_from_etcd "sites-available/proxy"

    # Fetch dictionary files
    fetch_config_from_etcd "dict/dictionary"

    echo "Configuration fetching completed for $SERVICE_NAME"
}

# Wait for ETCD to be ready
echo "Waiting for ETCD to be ready..."
until curl -s "$ETCD_ENDPOINT/health" > /dev/null 2>&1; do
    echo "ETCD not ready, waiting..."
    sleep 2
done
echo "ETCD is ready!"

# Fetch all configurations
fetch_all_configs

# Set proper permissions on the config directory
chown -R freerad:freerad "$CONFIG_DIR"
chmod -R 755 "$CONFIG_DIR"

echo "All configurations fetched and permissions set for $SERVICE_NAME"
