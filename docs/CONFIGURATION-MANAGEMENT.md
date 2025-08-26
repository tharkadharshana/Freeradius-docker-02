# 🔧 Configuration Management Guide

## 📋 **Overview**

Your FreeRADIUS Docker system uses **ETCD** for centralized configuration management. This means:
- ✅ **No volume mounts needed**
- ✅ **All configs managed in one place**
- ✅ **Easy to update without rebuilding containers**
- ✅ **Version control friendly**

## 🎯 **How It Works**

1. **Configurations stored in ETCD** (key-value store)
2. **Containers fetch configs at startup** from ETCD
3. **Changes require reloading to ETCD** + container restart
4. **No need to rebuild containers** for config changes

## 📁 **Configuration File Structure**

```
freeradius-docker_reference_only_previous_working_production\configs\
├── radius1\                    # 🖥️ RADIUS Server 1 Configs
│   ├── radiusd.conf           # Main FreeRADIUS configuration
│   ├── clients.conf           # Client definitions (NAS devices)
│   ├── sql.conf              # Database connection settings
│   ├── experimental.conf      # Experimental features
│   ├── templates.conf         # Configuration templates
│   ├── trigger.conf          # Trigger definitions
│   ├── mods-available\       # Available modules
│   ├── mods-config\          # Module-specific configurations
│   ├── sites-available\      # Available sites (authorize, accounting)
│   ├── policy.d\             # Policy definitions
│   └── dict\                 # Dictionary files
├── radius2\                    # 🖥️ RADIUS Server 2 Configs (same structure)
├── radius3\                    # 🖥️ RADIUS Server 3 Configs (same structure)
├── loadbalancer\               # ⚖️ Load Balancer 1 Configs (same structure)
└── loadbalancer2\              # ⚖️ Load Balancer 2 Configs (same structure)
```

## 🔄 **Configuration Change Workflow**

### **Step 1: Edit Configuration File**

```bash
# Example: Edit radius1's main config
notepad "freeradius-docker_reference_only_previous_working_production\configs\radius1\radiusd.conf"

# Example: Edit loadbalancer's clients
notepad "freeradius-docker_reference_only_previous_working_production\configs\loadbalancer\clients.conf"

# Example: Edit any module config
notepad "freeradius-docker_reference_only_previous_working_production\configs\radius1\mods-available\sql"
```

### **Step 2: Reload Configurations to ETCD**

```bash
# Run the PowerShell script to reload all configs
powershell -ExecutionPolicy Bypass -File load-configs-to-etcd.ps1
```

**What this does:**
- Reads all config files from reference directory
- Encodes them in base64
- Stores them in ETCD with proper keys
- Shows progress and any errors

### **Step 3: Restart Container(s)**

```bash
# Restart specific container
docker restart freeradius-radius1

# Or restart multiple containers
docker restart freeradius-radius1 freeradius-radius2

# Or restart all FreeRADIUS containers
docker restart freeradius-radius1 freeradius-radius2 freeradius-radius3 freeradius-loadbalancer1 freeradius-loadbalancer2
```

### **Step 4: Verify Changes**

```bash
# Check container logs
docker logs freeradius-radius1

# Test ETCD connectivity from container
docker exec freeradius-radius1 sh /scripts/test-etcd.sh

# Check if FreeRADIUS started successfully
docker logs freeradius-radius1 | grep "Ready to process requests"
```

## 📝 **Common Configuration Changes**

### **1. Adding New RADIUS Clients**

Edit `clients.conf` in the appropriate service directory:

```conf
# Example: Add new NAS device
client new_nas {
    ipaddr = 192.168.1.100
    secret = your_secret_here
    shortname = new_nas
}
```

### **2. Modifying Database Settings**

Edit `sql.conf` in the appropriate service directory:

```conf
# Example: Change database connection
sql {
    driver = "rlm_sql_mysql"
    server = "host.docker.internal"
    login = "radius_user"
    password = "radius_password"
    radius_db = "radius"
}
```

### **3. Changing Authentication Policies**

Edit files in `policy.d/` directory:

```conf
# Example: Modify authentication policy
policy {
    # Your policy changes here
}
```

### **4. Modifying Sites (Authorize/Accounting)**

Edit files in `sites-available/` directory:

```conf
# Example: Modify default site
authorize {
    # Your authorization logic here
}
```

## 🚨 **Important Notes**

### **Configuration Keys in ETCD**

Configurations are stored in ETCD with keys like:
- `/freeradius/radius1/radiusd.conf`
- `/freeradius/radius1/clients.conf`
- `/freeradius/radius1/mods-available/sql`
- `/freeradius/loadbalancer/clients.conf`

### **File Permissions**

- **Reference files**: Edit with any text editor
- **Container files**: Automatically set by the system
- **ETCD**: Managed automatically

### **Configuration Validation**

- FreeRADIUS validates configs at startup
- Check logs for configuration errors
- Invalid configs will prevent container startup

## 🔍 **Troubleshooting Configuration Issues**

### **1. Configuration Not Applied**

```bash
# Check if config was loaded to ETCD
docker exec freeradius-radius1 sh /scripts/test-etcd.sh

# Verify container is fetching configs
docker logs freeradius-radius1 | grep "Fetching configurations"
```

### **2. Configuration Errors**

```bash
# Check FreeRADIUS startup logs
docker logs freeradius-radius1 | grep -i error

# Check for syntax errors
docker logs freeradius-radius1 | grep -i "syntax error"
```

### **3. Missing Configurations**

```bash
# Verify reference directory structure
dir "freeradius-docker_reference_only_previous_working_production\configs\radius1"

# Check if PowerShell script ran successfully
# Look for "✅ Loaded" messages in output
```

## 📚 **Best Practices**

1. **Always backup** before making changes
2. **Test configurations** in development first
3. **Use version control** for your reference configs
4. **Document changes** you make
5. **Restart containers** after configuration changes
6. **Verify changes** through logs and testing

## 🎯 **Quick Reference Commands**

```bash
# Edit config
notepad "freeradius-docker_reference_only_previous_working_production\configs\radius1\radiusd.conf"

# Reload to ETCD
powershell -ExecutionPolicy Bypass -File load-configs-to-etcd.ps1

# Restart container
docker restart freeradius-radius1

# Check logs
docker logs freeradius-radius1

# Test ETCD
docker exec freeradius-radius1 sh /scripts/test-etcd.sh
```

---

**🎉 You now have complete control over your FreeRADIUS configurations through ETCD!**
