#!/bin/bash

# Docker Uninstall Script for Raspberry Pi 5 (ARM64)
# Author: Auto-generated Docker Setup
# Date: $(date +%Y-%m-%d)
# Purpose: Completely remove Docker and Docker Compose from the system

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
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

# Confirm uninstallation
confirm_uninstall() {
    echo
    echo "================================================================="
    echo "Docker Uninstallation Script"
    echo "================================================================="
    echo "This script will:"
    echo "• Stop all running Docker containers"
    echo "• Remove all Docker images, containers, and volumes"
    echo "• Uninstall Docker and Docker Compose"
    echo "• Remove Docker configuration files"
    echo "• Remove user from docker group"
    echo "• Clean up Docker repositories and keys"
    echo
    warn "This action is IRREVERSIBLE!"
    warn "All Docker data will be permanently lost!"
    echo
    
    read -p "Are you sure you want to continue? (Type 'yes' to confirm): " -r
    if [[ ! $REPLY == "yes" ]]; then
        info "Uninstallation cancelled by user"
        exit 0
    fi
    
    read -p "Last chance - type 'DELETE EVERYTHING' to proceed: " -r
    if [[ ! $REPLY == "DELETE EVERYTHING" ]]; then
        info "Uninstallation cancelled by user"
        exit 0
    fi
}

# Stop all Docker containers and services
stop_docker_services() {
    log "Stopping Docker services and containers..."
    
    if command -v docker &> /dev/null; then
        # Stop all running containers
        if sudo docker ps -q | wc -l | grep -q "^0$"; then
            info "No running containers to stop"
        else
            info "Stopping all running containers..."
            sudo docker stop $(sudo docker ps -q) 2>/dev/null || true
        fi
        
        # Remove all containers
        if sudo docker ps -aq | wc -l | grep -q "^0$"; then
            info "No containers to remove"
        else
            info "Removing all containers..."
            sudo docker rm $(sudo docker ps -aq) 2>/dev/null || true
        fi
        
        # Remove all images
        if sudo docker images -q | wc -l | grep -q "^0$"; then
            info "No images to remove"
        else
            info "Removing all Docker images..."
            sudo docker rmi -f $(sudo docker images -q) 2>/dev/null || true
        fi
        
        # Remove all volumes
        if sudo docker volume ls -q | wc -l | grep -q "^0$"; then
            info "No volumes to remove"
        else
            info "Removing all Docker volumes..."
            sudo docker volume rm $(sudo docker volume ls -q) 2>/dev/null || true
        fi
        
        # Remove all networks (except defaults)
        info "Removing custom Docker networks..."
        sudo docker network ls --filter type=custom -q | xargs -r sudo docker network rm 2>/dev/null || true
    else
        info "Docker command not found, skipping container cleanup"
    fi
    
    # Stop Docker service
    if systemctl is-active docker &> /dev/null; then
        info "Stopping Docker service..."
        sudo systemctl stop docker 2>/dev/null || true
        sudo systemctl disable docker 2>/dev/null || true
    else
        info "Docker service not running"
    fi
    
    # Stop containerd service
    if systemctl is-active containerd &> /dev/null; then
        info "Stopping containerd service..."
        sudo systemctl stop containerd 2>/dev/null || true
        sudo systemctl disable containerd 2>/dev/null || true
    fi
}

# Remove Docker packages
remove_docker_packages() {
    log "Removing Docker packages..."
    
    local docker_packages=(
        "docker-ce"
        "docker-ce-cli" 
        "containerd.io"
        "docker-compose-plugin"
        "docker-ce-rootless-extras"
        "docker-buildx-plugin"
        "docker-model-plugin"
    )
    
    for package in "${docker_packages[@]}"; do
        if dpkg -l | grep -q "^ii.*$package"; then
            info "Removing package: $package"
            sudo apt remove --purge -y "$package" 2>/dev/null || warn "Failed to remove $package"
        else
            info "Package $package not installed"
        fi
    done
    
    # Remove any remaining docker packages
    info "Removing any remaining Docker packages..."
    sudo apt autoremove -y 2>/dev/null || true
    
    log "Docker packages removal completed"
}

# Remove user from docker group
remove_user_from_docker_group() {
    log "Removing user from docker group..."
    
    if groups "$USER" | grep -q docker; then
        info "Removing user $USER from docker group..."
        sudo deluser "$USER" docker 2>/dev/null || warn "Failed to remove user from docker group"
        info "User removed from docker group (changes take effect after logout)"
    else
        info "User $USER is not in docker group"
    fi
}

# Remove Docker directories and files
remove_docker_files() {
    log "Removing Docker directories and configuration files..."
    
    local docker_dirs=(
        "/var/lib/docker"
        "/var/lib/containerd"
        "/etc/docker"
        "/var/run/docker.sock"
        "/var/run/docker"
        "$HOME/.docker"
    )
    
    for dir in "${docker_dirs[@]}"; do
        if [[ -e "$dir" ]]; then
            info "Removing: $dir"
            sudo rm -rf "$dir" 2>/dev/null || warn "Failed to remove $dir"
        else
            info "Directory/file not found: $dir"
        fi
    done
    
    # Remove Docker systemd files
    local systemd_files=(
        "/etc/systemd/system/docker.service.d"
        "/lib/systemd/system/docker.service"
        "/lib/systemd/system/docker.socket"
        "/lib/systemd/system/containerd.service"
    )
    
    for file in "${systemd_files[@]}"; do
        if [[ -e "$file" ]]; then
            info "Removing systemd file: $file"
            sudo rm -rf "$file" 2>/dev/null || warn "Failed to remove $file"
        fi
    done
    
    # Reload systemd
    sudo systemctl daemon-reload 2>/dev/null || true
}

# Remove Docker repository and GPG keys
remove_docker_repository() {
    log "Removing Docker repository and GPG keys..."
    
    # Remove Docker repository
    local repo_files=(
        "/etc/apt/sources.list.d/docker.list"
        "/etc/apt/keyrings/docker.asc"
        "/etc/apt/keyrings/docker.gpg"
    )
    
    for file in "${repo_files[@]}"; do
        if [[ -e "$file" ]]; then
            info "Removing repository file: $file"
            sudo rm -f "$file" 2>/dev/null || warn "Failed to remove $file"
        fi
    done
    
    # Update package lists
    info "Updating package lists..."
    sudo apt update 2>/dev/null || warn "Failed to update package lists"
}

# Clean up system
cleanup_system() {
    log "Performing system cleanup..."
    
    # Remove unused packages
    info "Removing unused packages..."
    sudo apt autoremove -y 2>/dev/null || true
    
    # Clean package cache
    info "Cleaning package cache..."
    sudo apt autoclean 2>/dev/null || true
    
    log "System cleanup completed"
}

# Verify removal
verify_removal() {
    log "Verifying Docker removal..."
    
    local issues_found=0
    
    # Check if Docker command still exists
    if command -v docker &> /dev/null; then
        warn "Docker command still found at: $(which docker)"
        issues_found=$((issues_found + 1))
    else
        info "Docker command successfully removed"
    fi
    
    # Check if Docker service exists
    if systemctl list-unit-files | grep -q docker; then
        warn "Docker service files still present"
        issues_found=$((issues_found + 1))
    else
        info "Docker service files successfully removed"
    fi
    
    # Check if user is still in docker group
    if groups "$USER" | grep -q docker; then
        warn "User $USER still in docker group (restart required)"
        issues_found=$((issues_found + 1))
    else
        info "User successfully removed from docker group"
    fi
    
    # Check for Docker directories
    if [[ -d "/var/lib/docker" ]]; then
        warn "Docker data directory still exists: /var/lib/docker"
        issues_found=$((issues_found + 1))
    else
        info "Docker data directories successfully removed"
    fi
    
    if [[ $issues_found -eq 0 ]]; then
        log "Docker removal verification successful"
        return 0
    else
        warn "Found $issues_found issues during verification"
        return 1
    fi
}

# Display post-uninstall information
show_post_uninstall_info() {
    echo
    echo "================================================================="
    echo -e "${GREEN}Docker Uninstallation Completed!${NC}"
    echo "================================================================="
    echo
    echo "What was removed:"
    echo "• All Docker containers, images, and volumes"
    echo "• Docker CE and Docker Compose"
    echo "• All Docker configuration files"
    echo "• Docker repository and GPG keys"
    echo "• User removed from docker group"
    echo
    echo "Important Notes:"
    echo "1. You may need to log out and back in to complete group changes"
    echo "2. All Docker data has been permanently deleted"
    echo "3. To reinstall Docker, run: ./install-docker.sh"
    echo
    echo "If you encounter any issues:"
    echo "• Restart your system to ensure all changes take effect"
    echo "• Check for any remaining Docker processes: ps aux | grep docker"
    echo "• Manually remove any remaining files if needed"
    echo
    echo "================================================================="
}

# Main uninstallation function
main() {
    log "Starting Docker uninstallation for Raspberry Pi 5 (ARM64)"
    
    check_root
    confirm_uninstall
    stop_docker_services
    remove_docker_packages
    remove_user_from_docker_group
    remove_docker_files
    remove_docker_repository
    cleanup_system
    verify_removal
    show_post_uninstall_info
    
    log "Uninstallation script completed"
}

# Handle script interruption
trap 'error "Uninstallation interrupted"; exit 1' INT TERM

# Run main function
main "$@"