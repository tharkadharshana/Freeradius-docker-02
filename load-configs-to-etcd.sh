#!/bin/bash

# FreeRADIUS Configuration Loader for Linux
# This script loads all FreeRADIUS configurations into ETCD

ETCD_HOST="localhost"
ETCD_PORT="2379"
ETCD_BASE_URL="http://${ETCD_HOST}:${ETCD_PORT}"
REFERENCE_DIR="freeradius-docker_reference_only_previous_working_production/configs"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🚀 Loading FreeRADIUS configurations into ETCD..."
echo "ETCD URL: ${ETCD_BASE_URL}"
echo "Reference Directory: ${REFERENCE_DIR}"
echo

# Function to check if ETCD is accessible
check_etcd() {
    if ! curl -s "${ETCD_BASE_URL}/health" > /dev/null; then
        echo -e "${RED}❌ ETCD is not accessible at ${ETCD_BASE_URL}${NC}"
        echo "Please ensure ETCD is running and accessible"
        exit 1
    fi
    echo -e "${GREEN}✅ ETCD is accessible${NC}"
}

# Function to load a single configuration file
load_config() {
    local service_name="$1"
    local config_path="$2"
    local etcd_key="$3"
    
    if [[ -f "$config_path" ]]; then
        # Read file content and encode in base64
        local content=$(cat "$config_path" | base64 -w 0)
        
        # Store in ETCD
        local response=$(curl -s -w "%{http_code}" -X PUT \
            "${ETCD_BASE_URL}/v3/kv/put" \
            -H "Content-Type: application/json" \
            -d "{
                \"key\": \"$(echo -n "$etcd_key" | base64 -w 0)\",
                \"value\": \"$content\"
            }")
        
        local http_code="${response: -3}"
        local response_body="${response%???}"
        
        if [[ "$http_code" == "200" ]]; then
            echo -e "${GREEN}✅ Loaded: $etcd_key${NC}"
            return 0
        else
            echo -e "${RED}❌ Failed to load: $etcd_key (HTTP $http_code)${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}⚠️  File not found: $config_path${NC}"
        return 1
    fi
}

# Function to load configurations for a service
load_service_configs() {
    local service_name="$1"
    local service_dir="${REFERENCE_DIR}/${service_name}"
    
    if [[ ! -d "$service_dir" ]]; then
        echo -e "${YELLOW}⚠️  Service directory not found: $service_dir${NC}"
        return 1
    fi
    
    echo "📁 Loading configurations for $service_name..."
    
    # Load main configuration files
    local main_configs=("radiusd.conf" "clients.conf" "sql.conf" "experimental.conf" "templates.conf" "trigger.conf")
    
    for config in "${main_configs[@]}"; do
        local config_path="${service_dir}/${config}"
        local etcd_key="/freeradius/${service_name}/${config}"
        load_config "$service_name" "$config_path" "$etcd_key"
    done
    
    # Load mods-available configurations
    if [[ -d "${service_dir}/mods-available" ]]; then
        echo "  📂 Loading mods-available configurations..."
        for config_file in "${service_dir}"/mods-available/*; do
            if [[ -f "$config_file" ]]; then
                local filename=$(basename "$config_file")
                local etcd_key="/freeradius/${service_name}/mods-available/${filename}"
                load_config "$service_name" "$config_file" "$etcd_key"
            fi
        done
    fi
    
    # Load mods-config configurations
    if [[ -d "${service_dir}/mods-config" ]]; then
        echo "  📂 Loading mods-config configurations..."
        for config_file in "${service_dir}"/mods-config/**/*; do
            if [[ -f "$config_file" ]]; then
                local relative_path="${config_file#$service_dir/}"
                local etcd_key="/freeradius/${service_name}/${relative_path}"
                load_config "$service_name" "$config_file" "$etcd_key"
            fi
        done
    fi
    
    # Load sites-available configurations
    if [[ -d "${service_dir}/sites-available" ]]; then
        echo "  📂 Loading sites-available configurations..."
        for config_file in "${service_dir}"/sites-available/*; do
            if [[ -f "$config_file" ]]; then
                local filename=$(basename "$config_file")
                local etcd_key="/freeradius/${service_name}/sites-available/${filename}"
                load_config "$service_name" "$config_file" "$etcd_key"
            fi
        done
    fi
    
    # Load policy.d configurations
    if [[ -d "${service_dir}/policy.d" ]]; then
        echo "  📂 Loading policy.d configurations..."
        for config_file in "${service_dir}"/policy.d/*; do
            if [[ -f "$config_file" ]]; then
                local filename=$(basename "$config_file")
                local etcd_key="/freeradius/${service_name}/policy.d/${filename}"
                load_config "$service_name" "$config_file" "$etcd_key"
            fi
        done
    fi
    
    # Load dictionary files
    if [[ -d "${service_dir}/dict" ]]; then
        echo "  📂 Loading dictionary files..."
        for dict_file in "${service_dir}"/dict/*; do
            if [[ -f "$dict_file" ]]; then
                local filename=$(basename "$dict_file")
                local etcd_key="/freeradius/${service_name}/dict/${filename}"
                load_config "$service_name" "$dict_file" "$etcd_key"
            fi
        done
    fi
    
    echo "✅ Completed loading configurations for $service_name"
    echo
}

# Main execution
main() {
    echo "🔍 Checking ETCD accessibility..."
    check_etcd
    
    echo "📂 Checking reference directory..."
    if [[ ! -d "$REFERENCE_DIR" ]]; then
        echo -e "${RED}❌ Reference directory not found: $REFERENCE_DIR${NC}"
        echo "Please ensure the reference directory exists and contains configurations"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Reference directory found${NC}"
    echo
    
    # Load configurations for each service
    local services=("radius1" "radius2" "radius3" "loadbalancer" "loadbalancer2")
    
    for service in "${services[@]}"; do
        load_service_configs "$service"
    done
    
    echo "🎉 All configurations loaded successfully!"
    echo
    
    # Show summary of loaded configurations
    echo "📊 Summary of loaded configurations:"
    local total_keys=$(curl -s "${ETCD_BASE_URL}/v3/kv/range" \
        -H "Content-Type: application/json" \
        -d '{"key": "/freeradius/", "range_end": "/freeradius/0"}' | \
        jq '.kvs | length' 2>/dev/null || echo "0")
    
    echo "Total configuration keys in ETCD: $total_keys"
    echo
    
    echo "🔧 Next steps:"
    echo "1. Start your FreeRADIUS containers"
    echo "2. Containers will automatically fetch configurations from ETCD"
    echo "3. Check container logs to verify successful configuration loading"
}

# Run main function
main "$@"
