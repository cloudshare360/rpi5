# Docker Setup for Raspberry Pi 5 (ARM64)

This repository contains scripts and documentation for installing, verifying, and managing Docker and Docker Compose on Raspberry Pi 5 with ARM64 architecture.

## 📋 Contents

```
docker-setup/
├── README.md                 # This documentation
├── scripts/
│   ├── install-docker.sh     # Docker installation script
│   ├── verify-docker.sh      # Docker verification script
│   └── uninstall-docker.sh   # Docker removal script
├── examples/
│   ├── hello-world.yml       # Simple test example
│   ├── web-app.yml          # Web application example
│   └── dev-environment.yml  # Development environment
└── docs/
    └── (additional documentation)
```

## 🚀 Quick Start

### Installation

1. **Clone or download this setup**:
   ```bash
   cd ~/docker-setup/scripts
   ```

2. **Make scripts executable**:
   ```bash
   chmod +x *.sh
   ```

3. **Install Docker**:
   ```bash
   ./install-docker.sh
   ```

4. **Verify installation**:
   ```bash
   ./verify-docker.sh
   ```

5. **Log out and log back in** (or restart) to use Docker without sudo.

## 🛠️ Scripts Overview

### `install-docker.sh`
Comprehensive installation script that:
- ✅ Checks system compatibility (ARM64 architecture)
- ✅ Updates system packages
- ✅ Installs Docker using the official Docker installation script
- ✅ Configures Docker Compose (included as plugin)
- ✅ Adds user to docker group
- ✅ Starts and enables Docker service
- ✅ Performs basic verification
- ✅ Provides post-installation instructions

**Usage:**
```bash
./install-docker.sh
```

### `verify-docker.sh`
Comprehensive verification script that runs 10 tests:
- ✅ Docker command existence
- ✅ Docker version check
- ✅ Docker Compose version check
- ✅ Docker service status
- ✅ User docker group membership
- ✅ Docker without sudo test
- ✅ Hello-world container test
- ✅ Docker Compose functionality test
- ✅ Docker images list
- ✅ Docker system information

**Usage:**
```bash
./verify-docker.sh
```

### `uninstall-docker.sh`
Complete removal script that:
- ⚠️ Stops all containers and services
- ⚠️ Removes all Docker data (containers, images, volumes)
- ⚠️ Uninstalls Docker packages
- ⚠️ Removes user from docker group
- ⚠️ Cleans up configuration files
- ⚠️ Removes Docker repository

**Usage:**
```bash
./uninstall-docker.sh
```
**⚠️ WARNING: This will permanently delete all Docker data!**

## 📁 Examples

### Hello World (`hello-world.yml`)
Simple test to verify Docker Compose functionality.
```bash
cd examples
docker compose -f hello-world.yml up
```

### Web Application (`web-app.yml`)
Nginx-based web application example.
```bash
cd examples
mkdir html
echo "<h1>Hello from Docker!</h1>" > html/index.html
docker compose -f web-app.yml up -d
# Visit: http://localhost:8080
```

### Development Environment (`dev-environment.yml`)
Complete development setup with PostgreSQL, Redis, and Adminer.
```bash
cd examples
docker compose -f dev-environment.yml up -d
# Access Adminer: http://localhost:8080
```

## 🖥️ System Requirements

- **Hardware**: Raspberry Pi 5 (8GB model recommended)
- **Architecture**: ARM64 (aarch64)
- **OS**: Debian-based Linux (Raspberry Pi OS)
- **Memory**: 4GB+ RAM (8GB recommended)
- **Storage**: 16GB+ available space (32GB+ recommended)

## 📚 Docker Basics

### Essential Commands

```bash
# Check Docker version
docker --version
docker compose version

# Basic container operations
docker run hello-world                    # Run a test container
docker ps                                 # List running containers
docker ps -a                             # List all containers
docker images                            # List images
docker system info                       # System information

# Docker Compose operations
docker compose up                         # Start services
docker compose up -d                      # Start services in background
docker compose down                       # Stop and remove services
docker compose logs                       # View logs
docker compose ps                         # List compose services
```

### Important Notes

1. **Use `docker compose` (with space)** instead of the deprecated `docker-compose`
2. **Group membership**: You must log out and back in after installation to use Docker without sudo
3. **ARM64 images**: Ensure you use ARM64-compatible images
4. **Resource usage**: Docker can be resource-intensive on Raspberry Pi

## 🔧 Troubleshooting

### Common Issues

#### 1. Permission Denied
```
docker: Got permission denied while trying to connect to the Docker daemon socket
```
**Solution**: 
- Ensure user is in docker group: `groups $USER`
- If not: `sudo usermod -aG docker $USER`
- Log out and log back in

#### 2. Docker Service Not Running
```
Cannot connect to the Docker daemon at unix:///var/run/docker.sock
```
**Solution**:
```bash
sudo systemctl start docker
sudo systemctl enable docker
```

#### 3. Architecture Mismatch
```
The requested image's platform (linux/amd64) does not match the detected host platform
```
**Solution**: Use ARM64-compatible images or specify platform:
```bash
docker run --platform linux/arm64 <image>
```

#### 4. Out of Space
```
No space left on device
```
**Solution**: Clean up Docker resources:
```bash
docker system prune -a          # Remove unused data
docker volume prune             # Remove unused volumes
docker image prune -a           # Remove unused images
```

### Log Files and Debugging

```bash
# Docker service logs
sudo journalctl -u docker.service

# Container logs
docker logs <container-name>

# System resource usage
docker system df
docker stats
```

## 🔒 Security Considerations

### User Permissions
- Adding a user to the `docker` group grants root-equivalent privileges
- For production use, consider rootless Docker mode
- Use Docker secrets for sensitive information

### Network Security
- By default, Docker exposes ports to all interfaces (0.0.0.0)
- Use specific IP bindings for production: `127.0.0.1:8080:80`
- Consider using Docker networks for service isolation

### Rootless Mode
For enhanced security, consider rootless Docker:
```bash
dockerd-rootless-setuptool.sh install
```

## 🚀 Performance Tips

### Raspberry Pi 5 Optimizations

1. **Use Alpine-based images** when possible (smaller, faster)
2. **Limit container resources**:
   ```yaml
   deploy:
     resources:
       limits:
         memory: 512M
         cpus: '0.5'
   ```
3. **Use multi-stage builds** to reduce image size
4. **Enable Docker BuildKit**: `export DOCKER_BUILDKIT=1`

### Storage Optimization

1. **Use volumes instead of bind mounts** for better performance
2. **Clean up regularly**: `docker system prune`
3. **Use .dockerignore** files to reduce build context

## 📖 Additional Resources

### Official Documentation
- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Docker for ARM](https://docs.docker.com/desktop/install/linux-install/)

### Raspberry Pi Specific
- [Docker on Raspberry Pi](https://docs.docker.com/engine/install/debian/)
- [Raspberry Pi Docker Optimization](https://www.docker.com/blog/happy-pi-day-docker-raspberry-pi/)

### ARM64 Images
- [Docker Hub ARM64 Images](https://hub.docker.com/search?architecture=arm64)
- [Multi-architecture Images](https://docs.docker.com/desktop/multi-arch/)

## 🆘 Support

### Getting Help

1. **Run verification script**: `./verify-docker.sh`
2. **Check system logs**: `sudo journalctl -u docker.service`
3. **Check Docker status**: `systemctl status docker`
4. **Test with hello-world**: `docker run hello-world`

### Common Commands for Diagnosis

```bash
# System information
uname -a
lscpu
free -h
df -h

# Docker information
docker version
docker system info
docker system df

# Network information
docker network ls
ss -tulpn | grep docker
```

## 📜 License

This setup is provided as-is for educational and development purposes. Please review and understand each script before execution.

## 🤝 Contributing

Feel free to improve these scripts and documentation. Common improvements:
- Additional verification tests
- More example configurations  
- Enhanced error handling
- Performance optimizations

---

**Last Updated**: $(date +%Y-%m-%d)
**Compatible with**: Raspberry Pi 5 (ARM64), Debian-based systems
**Docker Version Tested**: 28.4.0+
**Docker Compose Version Tested**: v2.39.2+