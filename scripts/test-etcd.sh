#!/bin/bash

# Test ETCD connectivity and list configurations

ETCD_ENDPOINT=${ETCD_ENDPOINTS:-"http://etcd:2379"}

echo "Testing ETCD connectivity at $ETCD_ENDPOINT"

# Test basic connectivity
echo "Testing basic connectivity..."
if curl -s "$ETCD_ENDPOINT/health" > /dev/null; then
    echo "✅ ETCD is accessible"
else
    echo "❌ ETCD is not accessible"
    exit 1
fi

# List all FreeRADIUS configurations
echo ""
echo "Listing all FreeRADIUS configurations in ETCD:"
echo "=============================================="

# Get all keys under /freeradius
response=$(curl -s -X POST "$ETCD_ENDPOINT/v3/kv/range" \
    -H "Content-Type: application/json" \
    -d "{\"key\": \"$(echo -n /freeradius/ | base64)\", \"range_end\": \"$(echo -n /freeradius/0 | base64)\"}")

# Extract and display keys
echo "$response" | grep -o '"key":"[^"]*"' | cut -d'"' -f4 | while read -r encoded_key; do
    decoded_key=$(echo "$encoded_key" | base64 -d)
    echo "📁 $decoded_key"
done

echo ""
echo "ETCD test completed!"
