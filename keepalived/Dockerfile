FROM alpine:3.18

# Install keepalived and required tools
RUN apk add --no-cache \
    keepalived \
    iputils-ping \
    net-tools \
    curl \
    dos2unix \
    netcat-openbsd

# Create log directory
RUN mkdir -p /var/log/keepalived

# Copy configuration and scripts
COPY keepalived.conf /etc/keepalived/keepalived.conf
COPY notify_*.sh /usr/local/bin/
COPY check_radius.sh /usr/local/bin/

# Set permissions
RUN chmod +x /usr/local/bin/*.sh && \
    chmod 644 /etc/keepalived/keepalived.conf && \
    dos2unix /etc/keepalived/keepalived.conf /usr/local/bin/*.sh

# Expose keepalived port
EXPOSE 112

# Start keepalived
CMD ["keepalived", "-n", "-l", "-D"]
