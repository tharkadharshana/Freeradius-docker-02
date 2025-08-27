# FreeRADIUS Docker - High Availability Load Balancing System

## 🚀 **Project Overview**

A production-ready, high-availability FreeRADIUS system with intelligent load balancing, failover routing, and centralized configuration management using Docker containers.

## 🏗️ **System Architecture**

```
                    [Internet/External Clients]
                           │
                    [Failover Router]
                    Ports: 1812-1813
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
   [LoadBalancer1]   [LoadBalancer2]   [LoadBalancer3]
   Ports: 2812-2813  Ports: 3812-3813  Ports: 4812-4813
        │                  │                  │
        └──────────────────┼──────────────────┘
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
    [RADIUS1]         [RADIUS2]         [RADIUS3]
   Ports: 1812-1813  Ports: 1812-1813  Ports: 1812-1813
        │                  │                  │
        └──────────────────┼──────────────────┘
                           │
                    [External MySQL Database]
                    (Your local MySQL Workbench)
```

## ✨ **Key Features**

- **🔀 High Availability Load Balancing**: Multiple load balancers with smart failover
- **🔄 Intelligent Failover Routing**: Automatic failover between load balancers
- **📊 Centralized Configuration**: ETCD-based configuration management
- **🐳 Docker Containerization**: Easy deployment and scaling
- **🔒 Production Security**: BlastRADIUS protection and security hardening
- **📈 Monitoring Ready**: Graylog and Zabbix integration ready
- **🌐 External Database**: Uses your existing MySQL infrastructure

## 🛠️ **Technology Stack**

- **FreeRADIUS**: Latest stable version with production configurations
- **Docker**: Container orchestration and management
- **ETCD**: Distributed key-value store for configuration management
- **MySQL**: External database integration
- **HAProxy**: Load balancing and health checking
- **Failover Router**: Intelligent routing and failover management

## 📁 **Project Structure**

```
Freeradius-docker/
├── configs/                          # Configuration files
│   ├── production/                   # Production configurations
│   │   ├── loadbalancer/            # LoadBalancer configurations
│   │   ├── radius1/                 # RADIUS1 configurations
│   │   ├── radius2/                 # RADIUS2 configurations
│   │   └── radius3/                 # RADIUS3 configurations
│   └── template config/              # Template configurations
├── loadbalancer/                     # LoadBalancer1 container
├── loadbalancer2/                    # LoadBalancer2 container
├── radius1/                          # RADIUS1 container
├── radius2/                          # RADIUS2 container
├── radius3/                          # RADIUS3 container
├── failover-router/                  # Failover routing logic
├── scripts/                          # Utility and setup scripts
├── docs/                             # Documentation
├── docker-compose-simple.yml         # Main Docker Compose file
└── README.md                         # This file
```

## 🚀 **Quick Start**

### **Prerequisites**
- Docker and Docker Compose installed
- External MySQL database accessible
- Ports 1812-1813, 2812-2813, 3812-3813 available

### **1. Clone the Repository**
```bash
git clone https://github.com/tharkadharshana/Freeradius-docker-02.git
cd Freeradius-docker-02
```

### **2. Configure External MySQL**
Update the environment variables in `docker-compose-simple.yml`:
```yaml
environment:
  - EXTERNAL_MYSQL_HOST=your-mysql-host
  - EXTERNAL_MYSQL_PORT=3306
```

### **3. Start the System**
```bash
docker-compose -f docker-compose-simple.yml up -d
```

### **4. Load Configurations to ETCD**
```bash
# Windows PowerShell
powershell -ExecutionPolicy Bypass -File scripts/load-configs-to-etcd-production.ps1

# Linux/Mac
./scripts/load-configs-to-etcd-production.sh
```

### **5. Verify System Status**
```bash
docker ps
docker logs freeradius-loadbalancer1
```

## 🔧 **Configuration Management**

### **ETCD Integration**
All configurations are managed through ETCD:
- **LoadBalancer Configs**: `/freeradius/loadbalancer/*`
- **RADIUS Server Configs**: `/freeradius/radius1/*`, `/freeradius/radius2/*`, `/freeradius/radius3/*`

### **Configuration Updates**
```bash
# Reload configurations to ETCD
powershell -ExecutionPolicy Bypass -File scripts/load-configs-to-etcd-production.ps1

# Restart containers to pick up new configs
docker-compose -f docker-compose-simple.yml restart
```

## 📊 **Port Configuration**

| Service | External Ports | Internal Ports | Purpose |
|---------|----------------|----------------|---------|
| Failover Router | 1812-1813 | 1812-1813 | Primary client access |
| LoadBalancer1 | 2812-2813 | 1814-1815 | Secondary load balancer |
| LoadBalancer2 | 3812-3813 | 1812-1813 | Primary load balancer |
| RADIUS Servers | N/A | 1812-1813 | Backend authentication |

## 🔍 **Health Checks**

### **Container Health Status**
```bash
# Check all container statuses
docker ps

# Check specific container logs
docker logs freeradius-loadbalancer1
docker logs freeradius-loadbalancer2
docker logs freeradius-radius1
```

### **RADIUS Service Testing**
```bash
# Test LoadBalancer1
docker exec freeradius-loadbalancer1 radtest test test localhost:1814 0 testing123

# Test LoadBalancer2
docker exec freeradius-loadbalancer2 radtest test test localhost:1812 0 testing123
```

## 🚨 **Troubleshooting**

### **Common Issues**

1. **Port Conflicts**
   - Ensure ports 1812-1813, 2812-2813, 3812-3813 are available
   - Check for other RADIUS services running

2. **Configuration Loading Issues**
   - Verify ETCD is running: `docker ps | grep etcd`
   - Check configuration files exist in `configs/production/`

3. **Module Loading Errors**
   - Ensure all required modules are in `mods-available/`
   - Check module symlinks in `mods-enabled/`

### **Debug Mode**
Enable debug mode for troubleshooting:
```yaml
environment:
  - DEBUG_MODE=true
```

## 📈 **Monitoring and Logging**

### **Log Locations**
- **LoadBalancer Logs**: `/var/log/radius/` in containers
- **RADIUS Server Logs**: `/var/log/radius/` in containers
- **ETCD Logs**: Container logs

### **Integration Ready**
- **Graylog**: Centralized logging (configuration ready)
- **Zabbix**: Monitoring and alerting (configuration ready)
- **Prometheus**: Metrics collection (configuration ready)

## 🔒 **Security Features**

- **BlastRADIUS Protection**: Built-in security hardening
- **Message Authenticator**: Enhanced packet security
- **Proxy State Validation**: Load balancer security
- **Client Secret Management**: Secure client authentication

## 🤝 **Contributing**

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 **License**

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 **Support**

- **Issues**: Report bugs and feature requests via GitHub Issues
- **Documentation**: Check the `docs/` directory for detailed guides
- **Community**: Join FreeRADIUS community discussions

## 🎯 **Roadmap**

- [x] High Availability Load Balancing
- [x] ETCD Configuration Management
- [x] Failover Routing
- [x] Production Security Hardening
- [ ] Advanced Monitoring Dashboard
- [ ] Kubernetes Deployment
- [ ] Multi-Region Support
- [ ] Automated Testing Suite

---

**Built with ❤️ for production FreeRADIUS deployments**
