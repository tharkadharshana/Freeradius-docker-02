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
# DO NOT enable default site for load balancers - it binds to 1812/1813
# ln -sf /opt/etc/raddb/sites-available/default /opt/etc/raddb/sites-enabled/default
ln -sf /opt/etc/raddb/sites-available/inner-tunnel /opt/etc/raddb/sites-enabled/inner-tunnel

# Enable proxy site for load balancing
echo "Enabling proxy site for load balancing..."
ln -sf /opt/etc/raddb/sites-available/proxy /opt/etc/raddb/sites-enabled/

# Create minimal module symlinks for the production configuration
echo "Creating module symlinks..."
# Only essential modules that we know exist
ln -sf /opt/etc/raddb/mods-available/preprocess /opt/etc/raddb/mods-enabled/
ln -sf /opt/etc/raddb/mods-available/files /opt/etc/raddb/mods-enabled/
ln -sf /opt/etc/raddb/mods-available/suffix /opt/etc/raddb/mods-enabled/
ln -sf /opt/etc/raddb/mods-available/sql /opt/etc/raddb/mods-enabled/

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
