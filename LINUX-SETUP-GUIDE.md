# 🐧 **Linux/RedHat FreeRADIUS Docker Setup Guide**

## 📋 **Overview**

This guide provides complete setup instructions for Linux/RedHat systems to match our Windows production environment. The Linux setup now includes:

- ✅ **Keepalived + Virtual IP** for automatic failover
- ✅ **ETCD v3** for centralized configuration management  
- ✅ **High Availability Load Balancers** with automatic failover
- ✅ **Production configuration directory** (`configs/production/`)
- ✅ **Complete automation scripts** for setup and configuration

## 🔧 **Prerequisites**

### **Required Software**
```bash
# Install Docker (Docker Compose v2 comes with Docker)
sudo yum install -y docker  # RHEL/CentOS
# OR
sudo apt-get install -y docker.io  # Ubuntu/Debian

# For Docker Compose v1 (if needed)
# sudo yum install -y docker-compose  # RHEL/CentOS
# sudo apt-get install -y docker-compose  # Ubuntu/Debian

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add user to docker group (optional)
sudo usermod -aG docker $USER
```

### **Required Tools**
```bash
# Install curl for ETCD health checks
sudo yum install -y curl  # RHEL/CentOS
# OR
sudo apt-get install -y curl  # Ubuntu/Debian

# Install radtest for testing (optional)
sudo yum install -y freeradius-utils  # RHEL/CentOS
# OR
sudo apt-get install -y freeradius-utils  # Ubuntu/Debian
```

## 🚀 **Quick Start (Linux)**

### **1. Clone and Navigate**
```bash
git clone <your-repo-url>
cd freeradius-docker
```

### **2. Make Scripts Executable**
```bash
chmod +x setup-complete-system-linux.sh
chmod +x load-configs-to-etcd-production.sh
```

### **3. Run Complete Setup**
```bash
./setup-complete-system-linux.sh
```

**That's it!** The script will:
- Stop any existing containers
- Build all Docker images
- Start ETCD first
- Load production configurations
- Start all FreeRADIUS services
- Test the Virtual IP setup

## 📁 **Script Comparison: Linux vs Windows**

| Feature | Linux Script | Windows Script | Status |
|---------|--------------|----------------|---------|
| **Complete Setup** | `setup-complete-system-linux.sh` | `setup-complete-system.bat` | ✅ **MATCH** |
| **ETCD Loading** | `load-configs-to-etcd-production.sh` | `load-configs-to-etcd-production.ps1` | ✅ **MATCH** |
| **Production Configs** | Uses `configs/production/` | Uses `configs/production/` | ✅ **MATCH** |
| **Keepalived Support** | ✅ Included | ✅ Included | ✅ **MATCH** |
| **Virtual IP Testing** | ✅ Built-in | ✅ Built-in | ✅ **MATCH** |
| **Error Handling** | ✅ `set -e` | ✅ Try-Catch | ✅ **MATCH** |
| **Color Output** | ✅ ANSI colors | ✅ PowerShell colors | ✅ **MATCH** |

## 🔄 **Configuration Management (Linux)**

### **Update Configurations**
```bash
# 1. Edit files in configs/production/
vim configs/production/radius1/clients.conf

# 2. Reload to ETCD
./load-configs-to-etcd-production.sh

# 3. Restart containers (if needed)
# For Docker Compose v1: docker-compose -f docker-compose-simple.yml restart
# For Docker Compose v2: docker compose -f docker-compose-simple.yml restart
```

### **Check ETCD Contents**
```bash
# List all keys
curl -s "http://localhost:2379/v3/kv/range" \
  -H "Content-Type: application/json" \
  -d '{"key": "", "range_end": ""}' | jq

# Get specific config
curl -s "http://localhost:2379/v3/kv/range" \
  -H "Content-Type: application/json" \
  -d '{"key": "L2ZyZWVyYWRpdXMvcmFkaXVzMS9jbGllbnRzLmNvbmY="}' | jq
```

## 🧪 **Testing (Linux)**

### **Test Virtual IP (Primary Method)**
```bash
# Test the Virtual IP managed by Keepalived
radtest test test localhost:1812 0 testing123

# Alternative with netcat
echo "test" | nc -u localhost 1812
```

### **Test Direct Load Balancers**
```bash
# Test LoadBalancer1 directly (if needed)
radtest test test localhost:2812 0 testing123

# Test LoadBalancer2 directly (if needed)  
radtest test test localhost:3812 0 testing123
```

### **Test Backend RADIUS Servers**
```bash
# Test from within containers
docker exec freeradius-loadbalancer1 radtest test test localhost:1812 0 testing123
docker exec freeradius-radius1 radtest test test localhost:1812 0 testing123
```

## 📊 **Monitoring (Linux)**

### **Check Container Status**
```bash
# All containers
docker ps

# Specific service logs
docker logs freeradius-keepalived
docker logs freeradius-loadbalancer1
docker logs freeradius-radius1
```

### **Check Keepalived Status**
```bash
# Check Virtual IP assignment
docker exec freeradius-keepalived ip addr show eth0

# Check Keepalived logs
docker logs freeradius-keepalived | grep "VIP\|MASTER\|BACKUP"
```

### **Check ETCD Health**
```bash
# Health check
curl -s http://localhost:2379/health

# Version info
curl -s http://localhost:2379/version
```

## 🚨 **Troubleshooting (Linux)**

### **Common Issues**

#### **1. Permission Denied**
```bash
# Fix script permissions
chmod +x *.sh

# Fix Docker permissions
sudo usermod -aG docker $USER
newgrp docker
```

#### **2. Port Already in Use**
```bash
# Check what's using port 1812
sudo netstat -tulpn | grep :1812

# Kill process if needed
sudo kill -9 <PID>
```

#### **3. ETCD Connection Issues**
```bash
# Check if ETCD is running
docker ps | grep etcd

# Check ETCD logs
docker logs freeradius-etcd

# Restart ETCD if needed
# For Docker Compose v1: docker-compose -f docker-compose-simple.yml restart etcd
# For Docker Compose v2: docker compose -f docker-compose-simple.yml restart etcd
```

#### **4. Keepalived Issues**
```bash
# Check Keepalived status
docker exec freeradius-keepalived ps aux | grep keepalived

# Check Virtual IP assignment
docker exec freeradius-keepalived ip addr show

# Restart Keepalived if needed
# For Docker Compose v1: docker-compose -f docker-compose-simple.yml restart keepalived
# For Docker Compose v2: docker compose -f docker-compose-simple.yml restart keepalived
```

## 🔧 **Advanced Configuration (Linux)**

### **Customize Keepalived**
```bash
# Edit Keepalived configuration
vim keepalived/keepalived.conf

# Rebuild and restart
# For Docker Compose v1:
# docker-compose -f docker-compose-simple.yml build keepalived
# docker-compose -f docker-compose-simple.yml restart keepalived
# For Docker Compose v2:
docker compose -f docker-compose-simple.yml build keepalived
docker compose -f docker-compose-simple.yml restart keepalived
```

### **Modify Load Balancer Settings**
```bash
# Edit proxy configuration
vim configs/production/loadbalancer/proxy.conf

# Reload to ETCD
./load-configs-to-etcd-production.sh

# Restart load balancers
# For Docker Compose v1: docker-compose -f docker-compose-simple.yml restart loadbalancer1 loadbalancer2
# For Docker Compose v2: docker compose -f docker-compose-simple.yml restart loadbalancer1 loadbalancer2
```

## 📈 **Performance Tuning (Linux)**

### **Docker Optimizations**
```bash
# Increase Docker daemon limits
sudo tee /etc/docker/daemon.json <<EOF
{
  "default-ulimits": {
    "nofile": {
      "Hard": 64000,
      "Soft": 64000
    }
  }
}
EOF

# Restart Docker
sudo systemctl restart docker
```

### **System Optimizations**
```bash
# Increase file descriptor limits
echo "* soft nofile 65536" | sudo tee -a /etc/security/limits.conf
echo "* hard nofile 65536" | sudo tee -a /etc/security/limits.conf

# Increase network buffer sizes
echo "net.core.rmem_max = 16777216" | sudo tee -a /etc/sysctl.conf
echo "net.core.wmem_max = 16777216" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

## 🎯 **Production Checklist (Linux)**

- [ ] **Docker and Docker Compose** installed and running
- [ ] **Scripts made executable** with `chmod +x`
- [ ] **Production configurations** in `configs/production/`
- [ ] **ETCD accessible** on port 2379
- [ ] **All containers running** and healthy
- [ ] **Virtual IP working** on localhost:1812
- [ ] **Failover tested** by stopping LoadBalancer1
- [ ] **Monitoring configured** (optional)
- [ ] **Backup strategy** in place
- [ ] **Documentation** updated for team

## 🔄 **Maintenance (Linux)**

### **Regular Updates**
```bash
# Pull latest code
git pull origin main

# Rebuild containers
# For Docker Compose v1: docker-compose -f docker-compose-simple.yml build --no-cache
# For Docker Compose v2: docker compose -f docker-compose-simple.yml build --no-cache

# Restart services
# For Docker Compose v1: docker-compose -f docker-compose-simple.yml up -d
# For Docker Compose v2: docker compose -f docker-compose-simple.yml up -d
```

### **Configuration Backups**
```bash
# Backup ETCD data
docker exec freeradius-etcd etcdctl snapshot save /tmp/backup.db

# Backup production configs
tar -czf freeradius-configs-$(date +%Y%m%d).tar.gz configs/production/
```

## 🤝 **Support**

### **Getting Help**
1. **Check logs**: `docker logs <container-name>`
2. **Verify ETCD**: `curl http://localhost:2379/health`
3. **Test connectivity**: Use the testing commands above
4. **Check documentation**: Review this guide and README.md

### **Reporting Issues**
- Include Linux distribution and version
- Provide Docker and Docker Compose versions
- Share relevant logs and error messages
- Describe steps to reproduce the issue

---

## 🎉 **Summary**

**YES, the Linux setup is now COMPLETE and FULLY WORKING like Windows!**

The new Linux scripts provide:
- ✅ **Feature parity** with Windows PowerShell scripts
- ✅ **Production configuration management** via ETCD
- ✅ **Keepalived + Virtual IP** for high availability
- ✅ **Complete automation** from setup to testing
- ✅ **Professional-grade error handling** and monitoring

**To get started on Linux/RedHat:**
```bash
chmod +x *.sh
./setup-complete-system-linux.sh
```

Your FreeRADIUS system will be running with the same high-availability architecture as Windows! 🚀
