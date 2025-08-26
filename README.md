# 🚀 FreeRADIUS Docker System with ETCD Configuration Management

A production-ready, enterprise-grade FreeRADIUS Docker environment featuring centralized configuration management via ETCD, load balancing, failover capabilities, and external MySQL integration.

## 🏗️ **System Architecture**

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Client        │    │   Client        │    │   Client        │
│   Requests      │    │   Requests      │    │   Requests      │
└─────────┬───────┘    └─────────┬───────┘    └─────────┬───────┘
          │                      │                      │
          └──────────────────────┼──────────────────────┘
                                 │
                    ┌─────────────▼─────────────┐
                    │    Failover Router       │
                    │   (Primary: 1812/1813)   │
                    │   (Backup: 3812/3813)    │
                    └─────────────┬─────────────┘
                                  │
                    ┌─────────────▼─────────────┐
                    │   Load Balancer 1        │
                    │   (Ports: 2812/2813)     │
                    └─────────────┬─────────────┘
                                  │
                    ┌─────────────▼─────────────┐
                    │   Load Balancer 2        │
                    │   (Ports: 3812/3813)     │
                    └─────────────┬─────────────┘
                                  │
          ┌───────────────────────┼───────────────────────┐
          │                       │                       │
    ┌─────▼─────┐         ┌───────▼──────┐         ┌─────▼─────┐
    │  RADIUS1  │         │   RADIUS2   │         │  RADIUS3  │
    │ (Backend) │         │  (Backend)  │         │ (Backend) │
    └───────────┘         └─────────────┘         └───────────┘
          │                       │                       │
          └───────────────────────┼───────────────────────┘
                                  │
                    ┌─────────────▼─────────────┐
                    │      External MySQL       │
                    │      (Host Machine)      │
                    └───────────────────────────┘
```

## 🎯 **Key Features**

- ✅ **Centralized Configuration Management** via ETCD
- ✅ **No Volume Mounts** - All configs managed through ETCD
- ✅ **Load Balancing** with failover capabilities
- ✅ **External MySQL Integration** (no MySQL in containers)
- ✅ **Production-Ready** FreeRADIUS Alpine containers
- ✅ **Health Monitoring** and automatic failover
- ✅ **Windows-Friendly** setup and testing

## 🚀 **Quick Start**

1. **Clone and navigate to the project:**
   ```bash
   cd Freeradius-docker
   ```

2. **Start the complete system:**
   ```bash
   .\setup-complete-system.bat
   ```

3. **System will automatically:**
   - Build all containers
   - Start ETCD
   - Load configurations
   - Start all FreeRADIUS services

## 📁 **Project Structure**

```
Freeradius-docker/
├── docs/                           # 📚 Documentation
├── scripts/                        # 🔧 Essential scripts
│   ├── fetch-configs-from-etcd.sh # Fetch configs in containers
│   └── test-etcd.sh               # Test ETCD connectivity
├── radius1/                        # 🖥️ RADIUS Server 1
├── radius2/                        # 🖥️ RADIUS Server 2
├── radius3/                        # 🖥️ RADIUS Server 3
├── loadbalancer/                   # ⚖️ Load Balancer 1
├── loadbalancer2/                  # ⚖️ Load Balancer 2
├── failover-router/                # 🔄 Failover Router
├── docker-compose-simple.yml       # 🐳 Docker Compose
├── load-configs-to-etcd.ps1       # 📥 Load configs to ETCD
└── setup-complete-system.bat      # 🚀 Complete system setup
```

## 🔧 **Configuration Management**

All configurations are managed through ETCD. To change any configuration:

1. **Edit** the file in `freeradius-docker_reference_only_previous_working_production\configs\`
2. **Reload** configurations: `powershell -ExecutionPolicy Bypass -File load-configs-to-etcd.ps1`
3. **Restart** the specific container

See [Configuration Management Guide](docs/CONFIGURATION-MANAGEMENT.md) for detailed instructions.

## 📊 **Ports and Services**

| Service | Ports | Description |
|---------|-------|-------------|
| **Failover Router** | 1812-1813/UDP | Primary entry point for RADIUS traffic |
| **Load Balancer 1** | 2812-2813/UDP | Primary load balancer |
| **Load Balancer 2** | 3812-3813/UDP | Backup load balancer |
| **ETCD** | 2379-2380/TCP | Configuration management |
| **RADIUS Backends** | Internal | Backend RADIUS servers |

## 🆘 **Troubleshooting**

- **Container Issues**: Check logs with `docker logs <container-name>`
- **Configuration Issues**: Verify ETCD contents with `docker exec <container> sh /scripts/test-etcd.sh`
- **Network Issues**: Ensure ports are not blocked by firewall

## 📚 **Documentation**

- [📖 Configuration Management](docs/CONFIGURATION-MANAGEMENT.md) - How to modify configurations
- [❓ FAQ & Troubleshooting](docs/FAQ-TROUBLESHOOTING.md) - Common issues and solutions
- [🏗️ Architecture Details](docs/ARCHITECTURE-DETAILS.md) - Technical implementation details

## 🤝 **Support**

For issues or questions:
1. Check the [FAQ](docs/FAQ-TROUBLESHOOTING.md)
2. Review container logs
3. Verify ETCD connectivity

---

**🎉 Your FreeRADIUS Docker system is now production-ready with centralized configuration management!**
