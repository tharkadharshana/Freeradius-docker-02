# 🏗️ Architecture Details

## 🎯 **System Overview**

Your FreeRADIUS Docker system is designed as a **production-ready, enterprise-grade** RADIUS infrastructure with the following key architectural principles:

- **Centralized Configuration Management** via ETCD
- **High Availability** with failover capabilities
- **Load Balancing** across multiple RADIUS backends
- **External Database Integration** (no database in containers)
- **Containerized Services** for easy deployment and scaling

## 🏛️ **Detailed Architecture**

### **1. Network Architecture**

```
Internet/Client Network
         │
         ▼
┌─────────────────────────────────────────────────────────────┐
│                    Failover Router                         │
│              (Primary: 1812/1813 UDP)                     │
│              (Backup: 3812/3813 UDP)                      │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                 Load Balancer Layer                        │
│  ┌─────────────────┐    ┌─────────────────┐               │
│  │ Load Balancer 1 │    │ Load Balancer 2 │               │
│  │ (2812/2813 UDP) │    │ (3812/3813 UDP) │               │
│  └─────────────────┘    └─────────────────┘               │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                RADIUS Backend Layer                        │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐                    │
│  │RADIUS 1 │  │RADIUS 2 │  │RADIUS 3 │                    │
│  │(Backend)│  │(Backend)│  │(Backend)│                    │
│  └─────────┘  └─────────┘  └─────────┘                    │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                External Database Layer                      │
│              MySQL/PostgreSQL on Host                      │
│              (host.docker.internal)                        │
└─────────────────────────────────────────────────────────────┘
```

### **2. Container Architecture**

#### **Failover Router Container**
- **Image**: Alpine Linux 3.18
- **Purpose**: Intelligent UDP traffic routing and failover
- **Technology**: iptables + custom routing logic
- **Ports**: 1812-1813/UDP (external)
- **Failover Logic**: Primary → Backup → Primary (automatic)

#### **Load Balancer Containers**
- **Image**: FreeRADIUS Alpine
- **Purpose**: Distribute RADIUS requests across backend servers
- **Load Balancing**: Round-robin distribution
- **Health Checks**: Built-in FreeRADIUS health monitoring

#### **RADIUS Backend Containers**
- **Image**: FreeRADIUS Alpine
- **Purpose**: Process RADIUS authentication/accounting requests
- **Configuration**: Fetched from ETCD at startup
- **Database**: External MySQL via `host.docker.internal`

#### **ETCD Container**
- **Image**: CoreOS ETCD v3.5.9
- **Purpose**: Centralized configuration storage
- **API**: HTTP/2 REST API
- **Persistence**: Docker volume for data storage

### **3. Configuration Management Architecture**

```
Reference Configs (Host)     ETCD (Container)     Container Configs
┌─────────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│ freeradius-docker_ │    │                 │    │                 │
│ reference_only_... │───▶│  ETCD Store     │───▶│ /opt/etc/raddb │
│ configs/           │    │                 │    │                 │
│ ├── radius1/       │    │ Key-Value Pairs │    │ Fetched at      │
│ ├── radius2/       │    │ Base64 Encoded  │    │ Container       │
│ ├── radius3/       │    │                 │    │ Startup        │
│ ├── loadbalancer/  │    │                 │    │                 │
│ └── loadbalancer2/ │    │                 │    │                 │
└─────────────────────┘    └─────────────────┘    └─────────────────┘
```

#### **Configuration Flow**
1. **Edit** configuration files in reference directory
2. **Load** configurations into ETCD via PowerShell script
3. **Fetch** configurations from ETCD at container startup
4. **Apply** configurations and start FreeRADIUS

## 🔧 **Technical Implementation Details**

### **1. ETCD Integration**

#### **Key Structure**
```
/freeradius/
├── radius1/
│   ├── radiusd.conf
│   ├── clients.conf
│   ├── sql.conf
│   ├── mods-available/
│   ├── sites-available/
│   └── policy.d/
├── radius2/ (same structure)
├── radius3/ (same structure)
├── loadbalancer/ (same structure)
└── loadbalancer2/ (same structure)
```

#### **Data Encoding**
- **Keys**: UTF-8 encoded, then base64
- **Values**: File content encoded in base64
- **API**: ETCD v3 HTTP API

### **2. Container Startup Process**

```bash
# 1. Container starts
# 2. Entrypoint script runs
# 3. Fetch configurations from ETCD
# 4. Write configs to /opt/etc/raddb
# 5. Set proper permissions
# 6. Create symbolic links
# 7. Start FreeRADIUS
# 8. Health check passes
```

### **3. Failover Logic**

#### **Primary Path**
```
Client → Failover Router (1812/1813) → Load Balancer 1 → RADIUS Backends
```

#### **Failover Path**
```
Client → Failover Router (1812/1813) → Load Balancer 2 → RADIUS Backends
```

#### **Automatic Failback**
- Primary load balancer health is continuously monitored
- Automatic failback when primary becomes healthy
- No manual intervention required

### **4. Load Balancing Algorithm**

- **Distribution**: Round-robin across available backends
- **Health Checking**: Continuous monitoring of backend health
- **Failover**: Automatic removal of unhealthy backends
- **Recovery**: Automatic re-addition when healthy

## 🚀 **Performance & Scalability**

### **1. Horizontal Scaling**

#### **Adding More RADIUS Servers**
1. Copy `radius1/` directory to `radius4/`
2. Update `docker-compose-simple.yml`
3. Add to PowerShell configuration script
4. Rebuild and deploy

#### **Adding More Load Balancers**
1. Copy `loadbalancer/` directory to `loadbalancer3/`
2. Update failover router configuration
3. Update PowerShell script
4. Deploy new load balancer

### **2. Resource Optimization**

#### **Container Resources**
- **Memory**: Optimized for Alpine Linux
- **CPU**: Shared across containers
- **Storage**: Minimal (configs in ETCD)
- **Network**: Optimized UDP handling

#### **ETCD Performance**
- **Concurrent Reads**: Multiple containers can fetch simultaneously
- **Write Performance**: Bulk configuration loading
- **Storage**: Efficient key-value storage
- **Backup**: Easy backup and restore

### **3. Monitoring & Observability**

#### **Health Checks**
- **Container Level**: Docker health checks
- **Application Level**: FreeRADIUS status monitoring
- **Network Level**: ETCD connectivity monitoring

#### **Logging**
- **Container Logs**: Docker logs for each service
- **Application Logs**: FreeRADIUS logs
- **System Logs**: ETCD and routing logs

## 🔒 **Security Considerations**

### **1. Network Security**

#### **Port Exposure**
- **External**: Only failover router ports (1812-1813)
- **Internal**: Load balancer and backend ports
- **Management**: ETCD ports (2379-2380)

#### **Firewall Rules**
- **UDP 1812-1813**: RADIUS authentication
- **UDP 1813**: RADIUS accounting
- **TCP 2379-2380**: ETCD management

### **2. Configuration Security**

#### **ETCD Security**
- **Access Control**: Local access only
- **Encryption**: Base64 encoding (not encryption)
- **Backup**: Regular configuration backups

#### **FreeRADIUS Security**
- **Client Secrets**: Managed in clients.conf
- **Database Credentials**: In sql.conf
- **Module Security**: Controlled access to modules

### **3. Container Security**

#### **Image Security**
- **Base Images**: Official FreeRADIUS Alpine
- **Updates**: Regular base image updates
- **Vulnerabilities**: Minimal attack surface

#### **Runtime Security**
- **User**: Non-root freerad user
- **Permissions**: Minimal required permissions
- **Isolation**: Docker network isolation

## 🔄 **Deployment & Operations**

### **1. Deployment Process**

#### **Initial Deployment**
1. **Build**: `docker-compose build --no-cache`
2. **Start ETCD**: `docker-compose up -d etcd`
3. **Load Configs**: PowerShell script execution
4. **Start Services**: `docker-compose up -d`

#### **Configuration Updates**
1. **Edit**: Modify reference configurations
2. **Reload**: Execute PowerShell script
3. **Restart**: Restart affected containers
4. **Verify**: Check logs and health

### **2. Backup & Recovery**

#### **Configuration Backup**
```bash
# Backup reference configurations
xcopy "freeradius-docker_reference_only_previous_working_production\configs" "backup\configs" /E /I

# Backup ETCD data
docker exec freeradius-etcd etcdctl snapshot save backup.etcd
```

#### **System Recovery**
1. **Stop Services**: `docker-compose down`
2. **Restore Configs**: Copy from backup
3. **Restart ETCD**: `docker-compose up -d etcd`
4. **Reload Configs**: PowerShell script
5. **Start Services**: `docker-compose up -d`

### **3. Maintenance Operations**

#### **Regular Maintenance**
- **Log Rotation**: Monitor log file sizes
- **Health Checks**: Regular health monitoring
- **Updates**: Base image updates
- **Backups**: Regular configuration backups

#### **Emergency Procedures**
- **Service Failure**: Check logs and restart
- **Configuration Issues**: Verify ETCD contents
- **Network Issues**: Check port availability
- **Database Issues**: Verify external MySQL connectivity

## 📊 **Monitoring & Metrics**

### **1. Key Metrics**

#### **Performance Metrics**
- **Response Time**: RADIUS request processing time
- **Throughput**: Requests per second
- **Error Rate**: Failed authentication attempts
- **Availability**: Service uptime percentage

#### **Resource Metrics**
- **Container Health**: Docker health status
- **ETCD Performance**: Configuration fetch times
- **Network Latency**: Load balancer response times
- **Database Performance**: Query response times

### **2. Alerting**

#### **Critical Alerts**
- **Service Down**: Container not responding
- **ETCD Failure**: Configuration service unavailable
- **High Error Rate**: Authentication failures
- **Database Issues**: Connection problems

#### **Warning Alerts**
- **High Latency**: Slow response times
- **Resource Usage**: High memory/CPU usage
- **Configuration Issues**: Invalid configurations
- **Health Check Warnings**: Degraded performance

---

**🏗️ This architecture provides a robust, scalable, and maintainable FreeRADIUS infrastructure suitable for production environments!**
