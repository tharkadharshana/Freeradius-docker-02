# ============================================================================
# FreeRADIUS Failover Router Dockerfile
# Handles smart failover between loadbalancer1 and loadbalancer2
# ============================================================================

FROM alpine:3.18

# Install required packages
RUN apk add --no-cache \
    iptables \
    iproute2 \
    netcat-openbsd \
    curl \
    bash \
    supervisor

# Create necessary directories
RUN mkdir -p /var/log/failover \
    && mkdir -p /etc/supervisor.d \
    && mkdir -p /scripts

# Copy scripts
COPY scripts/ /scripts/
COPY supervisord.conf /etc/supervisor.d/

# Make scripts executable
RUN chmod +x /scripts/*.sh

# Create log directory
RUN mkdir -p /var/log/failover

# Expose ports
EXPOSE 1812/udp 1813/udp

# Start supervisor
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor.d/supervisord.conf"]

