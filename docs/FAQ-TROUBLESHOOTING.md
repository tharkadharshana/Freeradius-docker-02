# ❓ FAQ & Troubleshooting Guide

## 🔥 **Common Issues & Solutions**

### **1. Containers Keep Restarting**

**Problem**: Containers show "Restarting" status
```
CONTAINER_NAME    Restarting (1) 2 seconds ago
```

**Solution**:
```bash
# Check container logs
docker logs <container-name>

# Common causes:
# - Script execution errors (fixed with shebang change)
# - Configuration errors
# - ETCD connectivity issues
```

**Prevention**: Always check logs after making changes

---

### **2. "Script Not Found" Errors**

**Problem**: 
```
/entrypoint.sh: line 8: /scripts/fetch-configs-from-etcd.sh: not found
```

**Solution**: ✅ **FIXED** - Scripts now use `sh /scripts/fetch-configs-from-etcd.sh`

**Root Cause**: Alpine containers use `sh` not `bash`

---

### **3. ETCD Connection Issues**

**Problem**: Containers can't connect to ETCD
```
ETCD not ready, waiting...
ETCD not ready, waiting...
```

**Solution**:
```bash
# Check if ETCD is running
docker ps | grep etcd

# Verify ETCD health
curl -s http://localhost:2379/health

# Restart ETCD if needed
docker restart freeradius-etcd
```

---

### **4. Configuration Not Applied**

**Problem**: Changes made but not reflected in containers

**Solution**:
```bash
# 1. Verify config was loaded to ETCD
docker exec <container> sh /scripts/test-etcd.sh

# 2. Check if container fetched configs
docker logs <container> | grep "Fetching configurations"

# 3. Restart container to pick up new configs
docker restart <container>
```

---

### **5. PowerShell Script Errors**

**Problem**: `load-configs-to-etcd.ps1` fails with errors

**Solution**:
```bash
# Run with proper execution policy
powershell -ExecutionPolicy Bypass -File load-configs-to-etcd.ps1

# Check for "Method Not Allowed" errors (some files may not load)
# This is normal for default FreeRADIUS configs
```

---

### **6. Port Already in Use**

**Problem**: 
```
Error response from daemon: driver failed programming external connectivity on endpoint
```

**Solution**:
```bash
# Check what's using the port
netstat -an | findstr :1812

# Stop conflicting services
# Or change ports in docker-compose-simple.yml
```

---

### **7. Container Build Failures**

**Problem**: Docker build fails with package errors

**Solution**:
```bash
# Retry build (network issues are common)
docker-compose -f docker-compose-simple.yml build --no-cache

# Check internet connectivity
# Ensure Docker Desktop is running
```

---

### **8. FreeRADIUS Won't Start**

**Problem**: Container starts but FreeRADIUS fails

**Solution**:
```bash
# Check FreeRADIUS logs
docker logs <container> | grep -i error

# Common issues:
# - Invalid configuration syntax
# - Missing required modules
# - Database connection issues
```

---

## ❓ **Frequently Asked Questions**

### **Q: How do I change a configuration?**

**A**: 
1. Edit file in `freeradius-docker_reference_only_previous_working_production\configs\`
2. Run `powershell -ExecutionPolicy Bypass -File load-configs-to-etcd.ps1`
3. Restart the container: `docker restart <container-name>`

---

### **Q: Do I need to rebuild containers for config changes?**

**A**: **NO!** That's the beauty of ETCD! Just reload configs and restart containers.

---

### **Q: Why are some containers showing "unhealthy"?**

**A**: Usually due to missing configurations or health check failures. Check logs and ensure all required configs are loaded.

---

### **Q: Can I use different ports?**

**A**: Yes! Edit `docker-compose-simple.yml` and change the port mappings.

---

### **Q: How do I add more RADIUS servers?**

**A**: 
1. Copy `radius1/` directory to `radius4/`
2. Update `docker-compose-simple.yml`
3. Add to PowerShell script
4. Rebuild and deploy

---

### **Q: What if ETCD goes down?**

**A**: Containers will fail to start. ETCD is critical - ensure it's running and healthy.

---

### **Q: How do I backup configurations?**

**A**: Backup the entire `freeradius-docker_reference_only_previous_working_production\configs\` directory.

---

### **Q: Can I use a different database?**

**A**: Yes! Edit `sql.conf` files and ensure the database driver is available in the container.

---

### **Q: How do I monitor the system?**

**A**: 
```bash
# Check container status
docker ps

# Monitor logs
docker logs -f <container-name>

# Check ETCD health
curl -s http://localhost:2379/health
```

---

### **Q: What's the difference between loadbalancer1 and loadbalancer2?**

**A**: 
- **loadbalancer1**: Primary load balancer (ports 2812/2813)
- **loadbalancer2**: Backup load balancer (ports 3812/3813)
- **failover-router**: Routes traffic between them

---

### **Q: How do I test RADIUS authentication?**

**A**: 
```bash
# From Windows (if you have RADIUS client tools)
echo "User-Name = test, User-Password = test" | radclient -x localhost:1812 auth testing123

# Or use online RADIUS testing tools
# Or test from another machine on the network
```

---

## 🚨 **Emergency Procedures**

### **System Won't Start**

```bash
# 1. Stop everything
docker-compose -f docker-compose-simple.yml down

# 2. Check ETCD
docker run --rm -it quay.io/coreos/etcd:v3.5.9 etcdctl endpoint health

# 3. Start fresh
docker-compose -f docker-compose-simple.yml up -d
```

### **Configuration Corrupted**

```bash
# 1. Restore from backup
# 2. Reload to ETCD
powershell -ExecutionPolicy Bypass -File load-configs-to-etcd.ps1

# 3. Restart containers
docker restart freeradius-radius1 freeradius-radius2 freeradius-radius3
```

### **Database Connection Lost**

```bash
# 1. Check MySQL service on host
# 2. Verify network connectivity
# 3. Check sql.conf settings
# 4. Restart containers
```

---

## 📊 **Health Check Commands**

```bash
# Overall system health
docker ps

# ETCD health
curl -s http://localhost:2379/health

# Container logs
docker logs <container-name>

# ETCD contents
docker exec <container> sh /scripts/test-etcd.sh

# FreeRADIUS status
docker logs <container> | grep "Ready to process requests"
```

---

## 🎯 **Prevention Tips**

1. **Always backup** before making changes
2. **Test configurations** in development first
3. **Monitor logs** after changes
4. **Use version control** for configurations
5. **Document changes** you make
6. **Test failover** regularly
7. **Keep ETCD healthy** and monitored

---

**💡 Remember: Most issues can be solved by checking logs and following the configuration workflow!**
