#!/bin/bash

# Docker Installation Script for Raspberry Pi 5 (ARM64)
# Author: Auto-generated Docker Setup
# Date: $(date +%Y-%m-%d)
# Compatible with: Debian-based systems on ARM64 architecture

set -euo pipefail  # Exit on error, undefined variables, pipe failures

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1" >&2
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO:${NC} $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        error "This script should not be run as root. Please run as a regular user."
        exit 1
    fi
}

# Check system architecture
check_architecture() {
    local arch=$(uname -m)
    if [[ "$arch" != "aarch64" ]]; then
        error "This script is designed for ARM64 (aarch64) architecture. Detected: $arch"
        exit 1
    fi
    log "Architecture check passed: $arch"
}

# Check if Docker is already installed
check_existing_docker() {
    if command -v docker &> /dev/null; then
        warn "Docker is already installed:"
        docker --version
        read -p "Do you want to continue and potentially reinstall? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            info "Installation cancelled by user"
            exit 0
        fi
    fi
}

# Update system packages
update_system() {
    log "Updating system packages..."
    if ! sudo apt update; then
        error "Failed to update package lists"
        exit 1
    fi
    log "System packages updated successfully"
}

# Install prerequisites
install_prerequisites() {
    log "Installing prerequisites..."
    local packages=("ca-certificates" "curl" "gnupg" "lsb-release")
    
    for package in "${packages[@]}"; do
        if ! dpkg -l | grep -q "^ii.*$package"; then
            info "Installing $package..."
            sudo apt install -y "$package"
        else
            info "$package is already installed"
        fi
    done
    log "Prerequisites installation completed"
}

# Download and run Docker installation script
install_docker() {
    log "Downloading Docker installation script..."
    
    # Download the script
    if ! curl -fsSL https://get.docker.com -o /tmp/get-docker.sh; then
        error "Failed to download Docker installation script"
        exit 1
    fi
    
    log "Running Docker installation script..."
    if ! sudo sh /tmp/get-docker.sh; then
        error "Docker installation failed"
        rm -f /tmp/get-docker.sh
        exit 1
    fi
    
    # Clean up
    rm -f /tmp/get-docker.sh
    log "Docker installation completed"
}

# Add user to docker group
configure_user_permissions() {
    log "Adding user to docker group..."
    sudo usermod -aG docker "$USER"
    log "User added to docker group. You may need to log out and back in for this to take effect."
}

# Start and enable Docker service
configure_docker_service() {
    log "Starting and enabling Docker service..."
    
    if ! sudo systemctl start docker; then
        error "Failed to start Docker service"
        exit 1
    fi
    
    if ! sudo systemctl enable docker; then
        error "Failed to enable Docker service"
        exit 1
    fi
    
    log "Docker service configured successfully"
}

# Verify installation
verify_installation() {
    log "Verifying Docker installation..."
    
    # Check Docker version
    if ! docker --version; then
        error "Docker installation verification failed"
        exit 1
    fi
    
    # Check Docker Compose version
    if ! docker compose version; then
        error "Docker Compose verification failed"
        exit 1
    fi
    
    # Test Docker with hello-world
    log "Testing Docker with hello-world container..."
    if ! sudo docker run --rm hello-world > /dev/null 2>&1; then
        warn "Docker hello-world test failed, but Docker appears to be installed"
    else
        log "Docker hello-world test successful"
    fi
    
    log "Docker installation verification completed"
}

# Display post-installation information
show_post_install_info() {
    echo
    echo "================================================================="
    echo -e "${GREEN}Docker Installation Completed Successfully!${NC}"
    echo "================================================================="
    echo
    echo "Installed versions:"
    docker --version
    docker compose version
    echo
    echo "Important Notes:"
    echo "1. You have been added to the 'docker' group"
    echo "2. Log out and log back in (or restart) to use Docker without sudo"
    echo "3. Docker service is enabled and will start automatically on boot"
    echo "4. Use 'docker compose' (with space) instead of 'docker-compose'"
    echo
    echo "To verify your installation, run:"
    echo "  ./verify-docker.sh"
    echo
    echo "To test Docker without logging out, use sudo temporarily:"
    echo "  sudo docker run hello-world"
    echo
    echo "================================================================="
}

# Main installation function
main() {
    log "Starting Docker installation for Raspberry Pi 5 (ARM64)"
    
    check_root
    check_architecture
    check_existing_docker
    update_system
    install_prerequisites
    install_docker
    configure_user_permissions
    configure_docker_service
    verify_installation
    show_post_install_info
    
    log "Installation script completed successfully"
}

# Handle script interruption
trap 'error "Installation interrupted"; exit 1' INT TERM

# Run main function
main "$@"