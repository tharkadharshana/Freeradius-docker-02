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
