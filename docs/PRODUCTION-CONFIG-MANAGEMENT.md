# FreeRADIUS Production Configuration Management Guide

## 🎯 **Overview**

This guide explains how to manage FreeRADIUS configurations in production using ETCD for centralized configuration management. **NO MORE REFERENCE DIRECTORY USAGE** - everything is now properly managed from the production config directory.

## 📁 **Configuration Directory Structure**

```
configs/production/           # PRODUCTION CONFIGURATIONS (NOT REFERENCE!)
├── radius1/                 # Radius1 server configurations
├── radius2/                 # Radius2 server configurations  
├── radius3/                 # Radius3 server configurations
├── loadbalancer/            # LoadBalancer1 configurations
└── loadbalancer2/           # LoadBalancer2 configurations
```

## 🔧 **How to Modify Configurations**

### **Step 1: Edit Production Configuration Files**

**⚠️ IMPORTANT: NEVER edit the reference directory!**

Edit files directly in the production config directory:
```bash
# Edit Radius1 configurations
notepad configs/production/radius1/clients.conf
notepad configs/production/radius1/radiusd.conf
notepad configs/production/radius1/sql.conf

# Edit Radius2 configurations
notepad configs/production/radius2/clients.conf
notepad configs/production/radius2/radiusd.conf

# Edit LoadBalancer configurations
notepad configs/production/loadbalancer/clients.conf
notepad configs/production/loadbalancer/radiusd.conf
```

### **Step 2: Reload Configurations into ETCD**

After editing, run the production configuration loader:
```powershell
# Load all production configurations into ETCD
powershell -ExecutionPolicy Bypass -File scripts/load-configs-to-etcd-production.ps1
```

### **Step 3: Restart Containers**

Restart the containers to pick up new configurations:
```bash
# Restart specific services
docker-compose -f docker-compose-simple.yml restart radius1
docker-compose -f docker-compose-simple.yml restart radius2
docker-compose -f docker-compose-simple.yml restart radius3
docker-compose -f docker-compose-simple.yml restart loadbalancer1
docker-compose -f docker-compose-simple.yml restart loadbalancer2

# Or restart all at once
docker-compose -f docker-compose-simple.yml restart
```

## 📋 **Complete Configuration Management Workflow**

### **🔍 Check Current Configurations**

**View configurations inside running containers:**
```bash
# Check Radius1 configurations
docker exec freeradius-radius1 cat /opt/etc/raddb/clients.conf
docker exec freeradius-radius1 cat /opt/etc/raddb/radiusd.conf
docker exec freeradius-radius1 cat /opt/etc/raddb/sql.conf

# Check Radius2 configurations  
docker exec freeradius-radius2 cat /opt/etc/raddb/clients.conf
docker exec freeradius-radius2 cat /opt/etc/raddb/radiusd.conf

# Check LoadBalancer1 configurations
docker exec freeradius-loadbalancer1 cat /opt/etc/raddb/clients.conf
docker exec freeradius-loadbalancer1 cat /opt/etc/raddb/radiusd.conf
```

**View configurations in production directory:**
```bash
# View production configs
Get-Content "configs\production\radius1\clients.conf"
Get-Content "configs\production\radius2\clients.conf"
Get-Content "configs\production\loadbalancer\clients.conf"
```

### **✏️ Modify Configurations**

1. **Edit the production config files directly**
2. **Save your changes**
3. **Run the production config loader script**
4. **Restart the affected containers**

### **🔄 Reload and Restart**

```powershell
# 1. Load configurations into ETCD
powershell -ExecutionPolicy Bypass -File scripts/load-configs-to-etcd-production.ps1

# 2. Restart containers
docker-compose -f docker-compose-simple.yml restart radius1 radius2 radius3 loadbalancer1 loadbalancer2

# 3. Wait for containers to initialize
Start-Sleep 30

# 4. Check status
docker ps
```

## 🚨 **Important Notes**

### **❌ What NOT to do:**
- **NEVER edit files in `freeradius-docker_reference_only_previous_working_production/`**
- **NEVER use the old reference-based scripts**
- **NEVER manually edit files inside running containers**

### **✅ What TO do:**
- **ALWAYS edit files in `configs/production/`**
- **ALWAYS use `scripts/load-configs-to-etcd-production.ps1`**
- **ALWAYS restart containers after configuration changes**
- **ALWAYS verify ETCD has the new configurations**

## 🔍 **Verification Commands**

### **Check ETCD Contents:**
```bash
# List all FreeRADIUS configurations in ETCD
docker exec freeradius-etcd etcdctl get --prefix /freeradius

# Check specific service configurations
docker exec freeradius-etcd etcdctl get --prefix /freeradius/radius1
docker exec freeradius-etcd etcdctl get --prefix /freeradius/loadbalancer
```

### **Check Container Status:**
```bash
# Check all containers
docker ps

# Check specific container logs
docker logs freeradius-radius1 --tail 20
docker logs freeradius-loadbalancer1 --tail 20
```

### **Test Configuration Loading:**
```bash
# Test if containers can fetch configs from ETCD
docker exec freeradius-radius1 sh /scripts/test-etcd.sh
```

## 🆘 **Troubleshooting**

### **Configuration Not Loading:**
1. Check if ETCD is running: `docker ps | grep etcd`
2. Verify ETCD has configs: `docker exec freeradius-etcd etcdctl get --prefix /freeradius`
3. Check container logs: `docker logs freeradius-radius1 --tail 20`
4. Ensure you're using the production config loader script

### **Container Not Starting:**
1. Check container logs: `docker logs freeradius-radius1`
2. Verify ETCD connectivity from container
3. Check if all required config files exist in production directory

### **Health Checks Failing:**
1. This is normal for test environments
2. Health checks use test credentials that don't exist in production
3. Focus on container logs showing "Ready to process requests"

## 📚 **Quick Reference Commands**

```bash
# Edit configs
notepad configs/production/radius1/clients.conf

# Reload to ETCD
powershell -ExecutionPolicy Bypass -File scripts/load-configs-to-etcd-production.ps1

# Restart containers
docker-compose -f docker-compose-simple.yml restart

# Check status
docker ps

# View logs
docker logs freeradius-radius1 --tail 20

# Verify ETCD
docker exec freeradius-etcd etcdctl get --prefix /freeradius
```

## 🎯 **Summary**

- **Source**: `configs/production/` (NOT reference directory!)
- **Storage**: ETCD (centralized, no volume mounts)
- **Loading**: `scripts/load-configs-to-etcd-production.ps1`
- **Activation**: Restart containers
- **Verification**: Check ETCD contents and container logs

This system provides centralized, version-controlled configuration management with zero-downtime updates through ETCD.
