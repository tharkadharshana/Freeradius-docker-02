# 🐧 Linux Deployment Guide

## 🎯 **Overview**

This guide covers deploying your FreeRADIUS Docker system on **RedHat/CentOS/RHEL** and other Linux distributions.

## 🚀 **Quick Start (Linux)**

### **1. Prerequisites**

```bash
# Install Docker and Docker Compose
sudo yum install -y docker docker-compose

# Start and enable Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Add your user to docker group (optional, for non-root access)
sudo usermod -aG docker $USER
# Log out and back in for group changes to take effect

# Install required tools
sudo yum install -y curl jq
```

### **2. Clone and Setup**

```bash
# Clone your repository
git clone <your-repo-url>
cd Freeradius-docker

# Make scripts executable
chmod +x setup-complete-system.sh
chmod +x load-configs-to-etcd.sh
chmod +x scripts/*.sh
```

### **3. Deploy the System**

```bash
# Run the complete setup script
./setup-complete-system.sh
```

## 🔧 **Manual Deployment Steps**

If you prefer to run commands manually:

```bash
# Step 1: Stop existing containers
docker-compose -f docker-compose-simple.yml down -v

# Step 2: Build containers
docker-compose -f docker-compose-simple.yml build --no-cache

# Step 3: Start ETCD
docker-compose -f docker-compose-simple.yml up -d etcd

# Step 4: Wait for ETCD (check health)
while ! curl -s http://localhost:2379/health > /dev/null; do
    echo "Waiting for ETCD..."
    sleep 2
done

# Step 5: Load configurations
./load-configs-to-etcd.sh

# Step 6: Start all services
docker-compose -f docker-compose-simple.yml up -d

# Step 7: Check status
docker ps
```

## 📁 **File Structure for Linux**

```
Freeradius-docker/
├── 📚 docs/                                    # Documentation
├── 🔧 scripts/                                 # Essential scripts
│   ├── fetch-configs-from-etcd.sh             # Fetch configs in containers
│   └── test-etcd.sh                           # Test ETCD connectivity
├── 🖥️ radius1/                                # RADIUS Server 1
├── 🖥️ radius2/                                # RADIUS Server 2
├── 🖥️ radius3/                                # RADIUS Server 3
├── ⚖️ loadbalancer/                           # Load Balancer 1
├── ⚖️ loadbalancer2/                          # Load Balancer 2
├── 🔄 failover-router/                        # Failover Router
├── 🐳 docker-compose-simple.yml               # Docker Compose
├── 🐧 setup-complete-system.sh                # Linux setup script
├── 🐧 load-configs-to-etcd.sh                 # Linux config loader
├── 🪟 setup-complete-system.bat               # Windows setup script (backup)
├── 🪟 load-configs-to-etcd.ps1               # Windows config loader (backup)
└── 📖 README.md                               # Main documentation
```

## 🔄 **Configuration Management (Linux)**

### **Change Configurations**

```bash
# 1. Edit configuration files
vim freeradius-docker_reference_only_previous_working_production/configs/radius1/radiusd.conf

# 2. Reload to ETCD
./load-configs-to-etcd.sh

# 3. Restart container
docker restart freeradius-radius1
```

### **Quick Configuration Commands**

```bash
# Edit main config
vim freeradius-docker_reference_only_previous_working_production/configs/radius1/radiusd.conf

# Edit clients
vim freeradius-docker_reference_only_previous_working_production/configs/radius1/clients.conf

# Edit SQL config
vim freeradius-docker_reference_only_previous_working_production/configs/radius1/sql.conf

# Reload all configs
./load-configs-to-etcd.sh

# Restart specific service
docker restart freeradius-radius1

# Check logs
docker logs freeradius-radius1

# Test ETCD
docker exec freeradius-radius1 sh /scripts/test-etcd.sh
```

## 🐧 **Linux-Specific Considerations**

### **1. File Permissions**

```bash
# Ensure scripts are executable
chmod +x *.sh
chmod +x scripts/*.sh

# If using SELinux, you might need to adjust contexts
sudo chcon -t container_file_t *.sh
sudo chcon -t container_file_t scripts/*.sh
```

### **2. Firewall Configuration**

```bash
# Open required ports
sudo firewall-cmd --permanent --add-port=1812/udp
sudo firewall-cmd --permanent --add-port=1813/udp
sudo firewall-cmd --permanent --add-port=2379/tcp
sudo firewall-cmd --permanent --add-port=2380/tcp
sudo firewall-cmd --reload

# Or if using iptables
sudo iptables -A INPUT -p udp --dport 1812 -j ACCEPT
sudo iptables -A INPUT -p udp --dport 1813 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 2379 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 2380 -j ACCEPT
```

### **3. SELinux (if enabled)**

```bash
# Check SELinux status
sestatus

# If SELinux is enforcing, you might need to adjust contexts
sudo chcon -R -t container_file_t ./
sudo chcon -R -t container_file_t scripts/
```

### **4. System Limits**

```bash
# Check and adjust file descriptor limits
ulimit -n

# If needed, increase limits in /etc/security/limits.conf
echo "* soft nofile 65536" | sudo tee -a /etc/security/limits.conf
echo "* hard nofile 65536" | sudo tee -a /etc/security/limits.conf
```

## 📊 **Monitoring & Troubleshooting**

### **System Health Checks**

```bash
# Check container status
docker ps

# Check ETCD health
curl -s http://localhost:2379/health

# Check container logs
docker logs freeradius-radius1

# Test ETCD connectivity from container
docker exec freeradius-radius1 sh /scripts/test-etcd.sh

# Check FreeRADIUS status
docker logs freeradius-radius1 | grep "Ready to process requests"
```

### **Common Linux Issues**

#### **Permission Denied**
```bash
# Make scripts executable
chmod +x *.sh
chmod +x scripts/*.sh
```

#### **Port Already in Use**
```bash
# Check what's using the port
sudo netstat -tulpn | grep :1812

# Stop conflicting service
sudo systemctl stop <service-name>
```

#### **Docker Service Issues**
```bash
# Check Docker service status
sudo systemctl status docker

# Restart Docker if needed
sudo systemctl restart docker
```

## 🚀 **Production Deployment**

### **1. Systemd Service (Optional)**

Create a systemd service for automatic startup:

```bash
sudo tee /etc/systemd/system/freeradius-docker.service > /dev/null <<EOF
[Unit]
Description=FreeRADIUS Docker System
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/path/to/your/Freeradius-docker
ExecStart=/path/to/your/Freeradius-docker/setup-complete-system.sh
ExecStop=/usr/local/bin/docker-compose -f docker-compose-simple.yml down

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable freeradius-docker
sudo systemctl start freeradius-docker
```

### **2. Log Rotation**

```bash
# Create logrotate configuration
sudo tee /etc/logrotate.d/freeradius-docker > /dev/null <<EOF
/path/to/your/Freeradius-docker/logs/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 root root
}
EOF
```

### **3. Backup Script**

```bash
#!/bin/bash
# Create backup script
cat > backup-configs.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/backup/freeradius-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Backup reference configurations
cp -r freeradius-docker_reference_only_previous_working_production "$BACKUP_DIR/"

# Backup ETCD data
docker exec freeradius-etcd etcdctl snapshot save "$BACKUP_DIR/etcd-backup.db"

echo "Backup completed: $BACKUP_DIR"
EOF

chmod +x backup-configs.sh
```

## 🎯 **Quick Reference Commands**

```bash
# Start system
./setup-complete-system.sh

# Change configs
vim freeradius-docker_reference_only_previous_working_production/configs/radius1/radiusd.conf
./load-configs-to-etcd.sh
docker restart freeradius-radius1

# Check status
docker ps
docker logs freeradius-radius1

# Stop system
docker-compose -f docker-compose-simple.yml down

# Backup
./backup-configs.sh
```

---

**🐧 Your FreeRADIUS Docker system is now ready for Linux deployment!**
