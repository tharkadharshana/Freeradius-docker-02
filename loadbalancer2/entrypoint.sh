#!/bin/sh
# Fetch configurations from ETCD and start FreeRADIUS

echo "Starting $LB_ID container..."

# Fetch configurations from ETCD
echo "Fetching configurations from ETCD..."
sh /scripts/fetch-configs-from-etcd.sh

if [ $? -ne 0 ]; then
    echo "❌ Failed to fetch configurations from ETCD"
    exit 1
fi

echo "✅ Configurations fetched successfully"

# Create necessary symlinks
echo "Creating symbolic links..."
rm -f /opt/etc/raddb/sites-enabled/status
rm -f /opt/etc/raddb/sites-enabled/default
ln -sf /opt/etc/raddb/sites-available/status /opt/etc/raddb/sites-enabled/status
ln -sf /opt/etc/raddb/sites-available/default /opt/etc/raddb/sites-enabled/default
ln -sf /opt/etc/raddb/sites-available/inner-tunnel /opt/etc/raddb/sites-enabled/inner-tunnel

# Enable proxy site for load balancing
echo "Enabling proxy site for load balancing..."
ln -sf /opt/etc/raddb/sites-available/proxy /opt/etc/raddb/sites-enabled/

# Create ALL necessary module symlinks for the production configuration
echo "Creating module symlinks..."
# Core modules
ln -sf /opt/etc/raddb/mods-available/always /opt/etc/raddb/mods-enabled/
ln -sf /opt/etc/raddb/mods-available/attr_filter /opt/etc/raddb/mods-enabled/
ln -sf /opt/etc/raddb/mods-available/chap /opt/etc/raddb/mods-enabled/
ln -sf /opt/etc/raddb/mods-available/date /opt/etc/raddb/mods-enabled/
ln -sf /opt/etc/raddb/mods-available/detail /opt/etc/raddb/mods-enabled/
ln -sf /opt/etc/raddb/mods-available/detail.log /opt/etc/raddb/mods-enabled/
ln -sf /opt/etc/raddb/mods-available/digest /opt/etc/raddb/mods-enabled/
ln -sf /opt/etc/raddb/mods-available/dynamic_clients /opt/etc/raddb/mods-enabled/
ln -sf /opt/etc/raddb/mods-available/eap /opt/etc/raddb/mods-enabled/
ln -sf /opt/etc/raddb/mods-available/echo /opt/etc/raddb/mods-enabled/
ln -sf /opt/etc/raddb/mods-available/exec /opt/etc/raddb/mods-enabled/
ln -sf /opt/etc/raddb/mods-available/expiration /opt/etc/raddb/mods-enabled/
ln -sf /opt/etc/raddb/mods-available/expr /opt/etc/raddb/mods-enabled/
ln -sf /opt/etc/raddb/mods-available/files /opt/etc/raddb/mods-enabled/
ln -sf /opt/etc/raddb/mods-available/linelog /opt/etc/raddb/mods-enabled/
ln -sf /opt/etc/raddb/mods-available/logintime /opt/etc/raddb/mods-enabled/
ln -sf /opt/etc/raddb/mods-available/mschap /opt/etc/raddb/mods-enabled/
ln -sf /opt/etc/raddb/mods-available/ntlm_auth /opt/etc/raddb/mods-enabled/
ln -sf /opt/etc/raddb/mods-available/pap /opt/etc/raddb/mods-enabled/
ln -sf /opt/etc/raddb/mods-available/passwd /opt/etc/raddb/mods-enabled/
ln -sf /opt/etc/raddb/mods-available/preprocess /opt/etc/raddb/mods-enabled/
ln -sf /opt/etc/raddb/mods-available/proxy_rate_limit /opt/etc/raddb/mods-enabled/
ln -sf /opt/etc/raddb/mods-available/radutmp /opt/etc/raddb/mods-enabled/
ln -sf /opt/etc/raddb/mods-available/realm /opt/etc/raddb/mods-enabled/
ln -sf /opt/etc/raddb/mods-available/replicate /opt/etc/raddb/mods-enabled/
ln -sf /opt/etc/raddb/mods-available/soh /opt/etc/raddb/mods-enabled/
ln -sf /opt/etc/raddb/mods-available/sql /opt/etc/raddb/mods-enabled/
ln -sf /opt/etc/raddb/mods-available/sql_map /opt/etc/raddb/mods-enabled/
ln -sf /opt/etc/raddb/mods-available/sqlcounter /opt/etc/raddb/mods-enabled/
ln -sf /opt/etc/raddb/mods-available/sqlippool /opt/etc/raddb/mods-enabled/
ln -sf /opt/etc/raddb/mods-available/sradutmp /opt/etc/raddb/mods-enabled/
ln -sf /opt/etc/raddb/mods-available/totp /opt/etc/raddb/mods-enabled/
ln -sf /opt/etc/raddb/mods-available/unix /opt/etc/raddb/mods-enabled/
ln -sf /opt/etc/raddb/mods-available/unpack /opt/etc/raddb/mods-enabled/
ln -sf /opt/etc/raddb/mods-available/utf8 /opt/etc/raddb/mods-enabled/

# Find the correct path for radiusd
RADIUSD_PATH=$(which radiusd || echo "/opt/sbin/radiusd")

# Start FreeRADIUS based on DEBUG mode
if [ "${DEBUG_MODE}" = "true" ]; then
    echo "Starting FreeRADIUS in debug mode..."
    exec $RADIUSD_PATH -f -l stdout -XX
else
    echo "Starting FreeRADIUS in production mode..."
    exec $RADIUSD_PATH -f -l stdout
fi
