#!/bin/bash

# FreeRADIUS Production Configuration Loader for Linux/RedHat
# This script loads all FreeRADIUS configurations into ETCD v3 from the production config directory

ETCD_HOST="localhost"
ETCD_PORT="2379"
ETCD_BASE_URL="http://${ETCD_HOST}:${ETCD_PORT}"
PRODUCTION_CONFIG_DIR="configs/production"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================"
echo -e "FreeRADIUS Production Configuration Loader for ETCD v3 (Linux)"
echo -e "========================================${NC}"
echo
echo -e "ETCD URL: ${ETCD_BASE_URL}"
echo -e "Production Config Directory: ${PRODUCTION_CONFIG_DIR}"
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

# Function to encode content to base64
encode_base64() {
    local content="$1"
    echo -n "$content" | base64 -w 0
}

# Function to load a single configuration file into ETCD
load_config() {
    local key="$1"
    local file_path="$2"
    
    if [[ -f "$file_path" ]]; then
        local content=$(cat "$file_path")
        if [[ -n "$content" ]]; then
            local base64_key=$(encode_base64 "$key")
            local base64_value=$(encode_base64 "$content")
            
            echo -e "Loading: $key"
            
            local response=$(curl -s -w "%{http_code}" -X POST \
                "${ETCD_BASE_URL}/v3/kv/put" \
                -H "Content-Type: application/json" \
                -d "{
                    \"key\": \"$base64_key\",
                    \"value\": \"$base64_value\"
                }")
            
            local http_code="${response: -3}"
            local response_body="${response%???}"
            
            if [[ "$http_code" == "200" ]]; then
                echo -e "${GREEN}✅ Loaded: $key${NC}"
                return 0
            else
                echo -e "${RED}❌ Failed to load: $key (HTTP $http_code)${NC}"
                return 1
            fi
        else
            echo -e "${YELLOW}⚠️  Empty file: $file_path${NC}"
            return 0
        fi
    else
        echo -e "${YELLOW}⚠️  File not found: $file_path${NC}"
        return 0
    fi
}

# Function to load configurations for a specific service
load_service_configs() {
    local service_name="$1"
    local service_dir="${PRODUCTION_CONFIG_DIR}/${service_name}"
    
    if [[ ! -d "$service_dir" ]]; then
        echo -e "${YELLOW}⚠️  Service directory not found: $service_dir${NC}"
        return 1
    fi
    
    echo -e "${BLUE}📁 Loading configurations for $service_name...${NC}"
    
    # Load main configuration files
    local main_configs=("radiusd.conf" "clients.conf" "sql.conf" "experimental.conf" "templates.conf" "trigger.conf")
    
    for config in "${main_configs[@]}"; do
        local config_path="${service_dir}/${config}"
        local etcd_key="/freeradius/${service_name}/${config}"
        load_config "$etcd_key" "$config_path"
    done
    
    # Load mods-available configurations
    if [[ -d "${service_dir}/mods-available" ]]; then
        echo -e "  📂 Loading mods-available configurations..."
        for config_file in "${service_dir}"/mods-available/*; do
            if [[ -f "$config_file" ]]; then
                local filename=$(basename "$config_file")
                local etcd_key="/freeradius/${service_name}/mods-available/${filename}"
                load_config "$etcd_key" "$config_file"
            fi
        done
    fi
    
    # Load mods-config configurations
    if [[ -d "${service_dir}/mods-config" ]]; then
        echo -e "  📂 Loading mods-config configurations..."
        for config_file in "${service_dir}"/mods-config/*; do
            if [[ -f "$config_file" ]]; then
                local filename=$(basename "$config_file")
                local etcd_key="/freeradius/${service_name}/mods-config/${filename}"
                load_config "$etcd_key" "$config_file"
            fi
        done
    fi
    
    # Load sites-available configurations
    if [[ -d "${service_dir}/sites-available" ]]; then
        echo -e "  📂 Loading sites-available configurations..."
        for config_file in "${service_dir}"/sites-available/*; do
            if [[ -f "$config_file" ]]; then
                local filename=$(basename "$config_file")
                local etcd_key="/freeradius/${service_name}/sites-available/${filename}"
                load_config "$etcd_key" "$config_file"
            fi
        done
    fi
    
    # Load dictionary files
    if [[ -d "${service_dir}/dictionary" ]]; then
        echo -e "  📂 Loading dictionary files..."
        for dict_file in "${service_dir}"/dictionary/*; do
            if [[ -f "$dict_file" ]]; then
                local filename=$(basename "$dict_file")
                local etcd_key="/freeradius/${service_name}/dictionary/${filename}"
                load_config "$etcd_key" "$dict_file"
            fi
        done
    fi
    
    echo -e "${GREEN}✅ Completed loading configurations for $service_name${NC}"
}

# Function to load proxy configurations for load balancers
load_proxy_configs() {
    local service_name="$1"
    local service_dir="${PRODUCTION_CONFIG_DIR}/${service_name}"
    
    if [[ ! -d "$service_dir" ]]; then
        echo -e "${YELLOW}⚠️  Service directory not found: $service_dir${NC}"
        return 1
    fi
    
    echo -e "${BLUE}📁 Loading proxy configurations for $service_name...${NC}"
    
    # Load proxy.conf for load balancers
    local proxy_configs=("proxy.conf" "radiusd.conf" "clients.conf")
    
    for config in "${proxy_configs[@]}"; do
        local config_path="${service_dir}/${config}"
        local etcd_key="/freeradius/${service_name}/${config}"
        load_config "$etcd_key" "$config_path"
    done
    
    # Load sites-available for load balancers
    if [[ -d "${service_dir}/sites-available" ]]; then
        echo -e "  📂 Loading sites-available configurations..."
        for config_file in "${service_dir}"/sites-available/*; do
            if [[ -f "$config_file" ]]; then
                local filename=$(basename "$config_file")
                local etcd_key="/freeradius/${service_name}/sites-available/${filename}"
                load_config "$etcd_key" "$config_file"
            fi
        done
    fi
    
    echo -e "${GREEN}✅ Completed loading proxy configurations for $service_name${NC}"
}

# Main execution
main() {
    echo -e "${YELLOW}Checking ETCD accessibility...${NC}"
    check_etcd
    
    echo
    echo -e "${YELLOW}Starting configuration loading process...${NC}"
    echo
    
    # Load RADIUS server configurations
    local radius_services=("radius1" "radius2" "radius3")
    for service in "${radius_services[@]}"; do
        load_service_configs "$service"
        echo
    done
    
    # Load load balancer configurations
    local lb_services=("loadbalancer" "loadbalancer2")
    for service in "${lb_services[@]}"; do
        load_proxy_configs "$service"
        echo
    done
    
    echo -e "${GREEN}========================================"
    echo -e "🎉 All configurations loaded successfully!"
    echo -e "========================================${NC}"
    echo
    echo -e "${BLUE}Next steps:${NC}"
    echo -e "1. Start your FreeRADIUS containers"
    echo -e "2. Test the Virtual IP: localhost:1812"
    echo -e "3. Monitor logs: docker logs freeradius-keepalived"
    echo
}

# Run main function
main "$@"
