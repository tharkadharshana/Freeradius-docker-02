# Use the official FreeRADIUS Alpine image
FROM freeradius/freeradius-server:latest-alpine

# Install required dependencies for MySQL support, ETCD communication, and RADIUS utilities
RUN apk add --no-cache mariadb-connector-c curl freeradius-utils freeradius-client

# Set up log directory with permissions
RUN mkdir -p /var/log/radius && \
    chmod 755 /var/log/radius

# Create mods-enabled and sites-enabled directories
RUN mkdir -p /opt/etc/raddb/mods-enabled && \
    mkdir -p /opt/etc/raddb/sites-enabled

# Create symbolic links for mods-enabled
RUN ln -sf /opt/etc/raddb/mods-available/chap /opt/etc/raddb/mods-enabled/ && \
    ln -sf /opt/etc/raddb/mods-available/date /opt/etc/raddb/mods-enabled/ && \
    ln -sf /opt/etc/raddb/mods-available/expiration /opt/etc/raddb/mods-enabled/ && \
    ln -sf /opt/etc/raddb/mods-available/linelog /opt/etc/raddb/mods-enabled/ && \
    ln -sf /opt/etc/raddb/mods-available/pap /opt/etc/raddb/mods-enabled/ && \
    ln -sf /opt/etc/raddb/mods-available/preprocess /opt/etc/raddb/mods-enabled/ && \
    ln -sf /opt/etc/raddb/mods-available/realm /opt/etc/raddb/mods-enabled/ && \
    ln -sf /opt/etc/raddb/mods-available/sql /opt/etc/raddb/mods-enabled/ && \
    ln -sf /opt/etc/raddb/mods-available/sql_map /opt/etc/raddb/mods-enabled/ && \
    ln -sf /opt/etc/raddb/mods-available/sqlcounter /opt/etc/raddb/mods-enabled/ && \
    ln -sf /opt/etc/raddb/mods-available/sqlippool /opt/etc/raddb/mods-enabled/ && \
    ln -sf /opt/etc/raddb/mods-available/unix /opt/etc/raddb/mods-enabled/ && \
    ln -sf /opt/etc/raddb/mods-available/utf8 /opt/etc/raddb/mods-enabled/

# Create symbolic links for sites-enabled
RUN ln -sf /opt/etc/raddb/sites-available/default /opt/etc/raddb/sites-enabled/ && \
    ln -sf /opt/etc/raddb/sites-available/inner-tunnel /opt/etc/raddb/sites-enabled/

# Create the freerad user and group
RUN addgroup -S freerad && adduser -S -G freerad freerad

# Copy scripts directory
COPY scripts/ /scripts/
RUN chmod +x /scripts/*.sh

# Copy entrypoint script
COPY loadbalancer2/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Ensure correct permissions
RUN chown -R freerad:freerad /opt/etc/raddb/
RUN chown -R freerad:freerad /var/log/radius/
RUN chown -R freerad:freerad /scripts/

# Expose RADIUS ports
EXPOSE 1812/udp 1813/udp

# Start FreeRADIUS using entrypoint script
ENTRYPOINT ["/entrypoint.sh"]
