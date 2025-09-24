# Quick Usage Guide

## Installation Steps

1. **Navigate to the setup directory**:
   ```bash
   cd ~/docker-setup/scripts
   ```

2. **Install Docker**:
   ```bash
   ./install-docker.sh
   ```

3. **Verify installation**:
   ```bash
   ./verify-docker.sh
   ```

4. **Log out and log back in** for group permissions to take effect.

## Testing Examples

### Basic Test
```bash
cd ~/docker-setup/examples
docker compose -f hello-world.yml up
```

### Web Application Test  
```bash
cd ~/docker-setup/examples
mkdir html
echo "<h1>Hello from Docker on Raspberry Pi 5!</h1>" > html/index.html
docker compose -f web-app.yml up -d
# Visit: http://your-pi-ip:8080
```

### Development Environment
```bash
cd ~/docker-setup/examples  
docker compose -f dev-environment.yml up -d
# Access database admin: http://your-pi-ip:8080
# Database: postgres, User: devuser, Pass: devpass123
```

## Common Commands

```bash
# Check versions
docker --version
docker compose version

# System status
docker system info
docker system df

# Clean up (if needed)
docker system prune
docker volume prune

# View running containers
docker ps
```

## Troubleshooting

If you encounter permission issues:
```bash
# Check if user is in docker group
groups $USER

# If not, add user to docker group
sudo usermod -aG docker $USER
# Then log out and log back in
```

If Docker service isn't running:
```bash
sudo systemctl start docker
sudo systemctl enable docker
```

## Removal

To completely remove Docker:
```bash
cd ~/docker-setup/scripts
./uninstall-docker.sh
```
⚠️ **Warning**: This will delete all Docker data permanently!

---

For detailed documentation, see `README.md`.