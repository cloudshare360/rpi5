#!/bin/bash
# =================================================================
# RASPBERRY PI 5 NVMe ISSUES & FIXES - ONE-CLICK INSTALLER
# =================================================================
# Installs all scripts, tools, and monitoring systems
# Sets up proper permissions and systemd services
# =================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="/var/log/nvme-setup"
LOG_FILE="$LOG_DIR/install.log"

print_banner() {
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║        🚀 Raspberry Pi 5 NVMe PCIe Boot Setup Installer       ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
}

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

error_exit() {
    echo -e "${RED}❌ Error: $1${NC}" | tee -a "$LOG_FILE"
    echo -e "${RED}Check the log file for details: $LOG_FILE${NC}"
    exit 1
}

success() {
    echo -e "${GREEN}✅ $1${NC}" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}" | tee -a "$LOG_FILE"
}

info() {
    echo -e "${BLUE}ℹ️  $1${NC}" | tee -a "$LOG_FILE"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        error_exit "This script must be run as root. Use: sudo $0"
    fi
}

check_system() {
    info "Checking system requirements..."
    
    # Check if running on Raspberry Pi 5
    if ! grep -q "Raspberry Pi 5" /proc/cpuinfo 2>/dev/null; then
        warning "Not detected as Raspberry Pi 5, but continuing..."
    else
        success "Running on Raspberry Pi 5"
    fi
    
    # Check for required directories
    if [ ! -d "$REPO_DIR" ]; then
        error_exit "Repository directory not found: $REPO_DIR"
    fi
    
    # Create log directory
    mkdir -p "$LOG_DIR"
    chmod 755 "$LOG_DIR"
    
    # Start logging
    log "=== Starting NVMe PCIe Boot Setup Installation ==="
    log "Repository directory: $REPO_DIR"
    log "System: $(uname -a)"
    log "User: $(whoami)"
    
    success "System check completed"
}

install_dependencies() {
    info "Installing system dependencies..."
    
    # Update package list
    log "Updating package list..."
    apt update || error_exit "Failed to update package list"
    
    # Install required packages
    local packages=(
        "rpi-eeprom"
        "pciutils"
        "nvme-cli"
        "smartmontools"
        "bc"
        "dialog"
        "rsync"
        "tree"
    )
    
    for package in "${packages[@]}"; do
        if dpkg -l | grep -q "^ii.*$package "; then
            log "$package already installed"
        else
            log "Installing $package..."
            apt install -y "$package" || warning "Failed to install $package"
        fi
    done
    
    success "Dependencies installation completed"
}

install_scripts() {
    info "Installing scripts and tools..."
    
    # Create directories in /usr/local/bin
    mkdir -p /usr/local/bin/nvme-tools
    
    # Install main setup script
    if [ -f "$REPO_DIR/scripts/setup/setup-nvme-boot.sh" ]; then
        cp "$REPO_DIR/scripts/setup/setup-nvme-boot.sh" /usr/local/bin/
        chmod +x /usr/local/bin/setup-nvme-boot.sh
        log "Installed setup-nvme-boot.sh"
    fi
    
    # Install monitoring scripts
    for script in "$REPO_DIR/scripts/monitoring/"*.sh; do
        if [ -f "$script" ]; then
            cp "$script" /usr/local/bin/
            chmod +x "/usr/local/bin/$(basename "$script")"
            log "Installed monitoring script: $(basename "$script")"
        fi
    done
    
    # Install repair scripts
    for script in "$REPO_DIR/scripts/repair/"*.sh; do
        if [ -f "$script" ]; then
            cp "$script" /usr/local/bin/
            chmod +x "/usr/local/bin/$(basename "$script")"
            log "Installed repair script: $(basename "$script")"
        fi
    done
    
    # Install diagnostic tools
    for tool in "$REPO_DIR/tools/diagnostic/"*.sh; do
        if [ -f "$tool" ]; then
            cp "$tool" /usr/local/bin/nvme-tools/
            chmod +x "/usr/local/bin/nvme-tools/$(basename "$tool")"
            log "Installed diagnostic tool: $(basename "$tool")"
        fi
    done
    
    # Install analysis tools
    for tool in "$REPO_DIR/tools/analysis/"*.sh; do
        if [ -f "$tool" ]; then
            cp "$tool" /usr/local/bin/nvme-tools/
            chmod +x "/usr/local/bin/nvme-tools/$(basename "$tool")"
            log "Installed analysis tool: $(basename "$tool")"
        fi
    done
    
    # Install recovery tools
    for tool in "$REPO_DIR/tools/recovery/"*.sh; do
        if [ -f "$tool" ]; then
            cp "$tool" /usr/local/bin/nvme-tools/
            chmod +x "/usr/local/bin/nvme-tools/$(basename "$tool")"
            log "Installed recovery tool: $(basename "$tool")"
        fi
    done
    
    # Create convenient symlinks
    ln -sf /usr/local/bin/nvme-tools/boot-status.sh /usr/local/bin/nvme-status
    ln -sf /usr/local/bin/nvme-tools/verify-nvme-setup.sh /usr/local/bin/nvme-verify
    ln -sf /usr/local/bin/nvme-tools/analyze-boot.sh /usr/local/bin/nvme-analyze
    
    success "Scripts and tools installation completed"
}

setup_systemd_services() {
    info "Setting up systemd services..."
    
    # Create boot monitor service
    if [ -f "/usr/local/bin/boot-monitor.sh" ]; then
        cat > /etc/systemd/system/boot-monitor.service << 'EOF'
[Unit]
Description=NVMe Boot Monitor
After=multi-user.target
StartLimitBurst=3
StartLimitIntervalSec=30

[Service]
Type=oneshot
ExecStart=/usr/local/bin/boot-monitor.sh
RemainAfterExit=yes
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
        
        # Enable and start service
        systemctl daemon-reload
        systemctl enable boot-monitor.service
        log "Created and enabled boot-monitor.service"
    fi
    
    success "Systemd services setup completed"
}

setup_log_directories() {
    info "Setting up log directories..."
    
    # Create log directories
    mkdir -p /var/log/boot-monitor
    mkdir -p /var/log/nvme-setup
    mkdir -p /var/log/nvme-repair
    
    # Set proper permissions
    chmod 755 /var/log/boot-monitor
    chmod 755 /var/log/nvme-setup  
    chmod 755 /var/log/nvme-repair
    
    # Create logrotate configuration
    cat > /etc/logrotate.d/nvme-tools << 'EOF'
/var/log/boot-monitor/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    copytruncate
}

/var/log/nvme-setup/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    copytruncate
}

/var/log/nvme-repair/*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    copytruncate
}
EOF
    
    success "Log directories setup completed"
}

create_documentation_links() {
    info "Creating documentation links..."
    
    # Create documentation directory
    mkdir -p /usr/local/share/nvme-tools
    
    # Copy documentation
    if [ -d "$REPO_DIR/docs" ]; then
        cp -r "$REPO_DIR/docs"/* /usr/local/share/nvme-tools/
        log "Copied documentation to /usr/local/share/nvme-tools/"
    fi
    
    # Copy examples
    if [ -d "$REPO_DIR/examples" ]; then
        cp -r "$REPO_DIR/examples" /usr/local/share/nvme-tools/
        log "Copied examples to /usr/local/share/nvme-tools/"
    fi
    
    success "Documentation links created"
}

create_desktop_shortcuts() {
    info "Creating desktop shortcuts (if GUI available)..."
    
    # Check if we have a desktop environment
    if [ -d "/home/pi/Desktop" ] || [ -d "/home/$SUDO_USER/Desktop" 2>/dev/null ]; then
        # Determine desktop directory
        DESKTOP_DIR="/home/pi/Desktop"
        if [ -d "/home/$SUDO_USER/Desktop" ] && [ "$SUDO_USER" != "root" ]; then
            DESKTOP_DIR="/home/$SUDO_USER/Desktop"
        fi
        
        # Create NVMe Status shortcut
        cat > "$DESKTOP_DIR/NVMe Status.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=NVMe Status
Comment=Check NVMe PCIe boot status
Exec=lxterminal -e 'nvme-status; echo "Press Enter to close..."; read'
Icon=utilities-system-monitor
Terminal=false
Categories=System;
EOF
        
        # Create NVMe Verify shortcut
        cat > "$DESKTOP_DIR/NVMe Verify.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=NVMe Verify Setup
Comment=Verify NVMe PCIe boot configuration
Exec=lxterminal -e 'sudo nvme-verify; echo "Press Enter to close..."; read'
Icon=applications-system
Terminal=false
Categories=System;
EOF
        
        # Set proper permissions
        if [ "$SUDO_USER" != "root" ] && [ -n "$SUDO_USER" ]; then
            chown "$SUDO_USER:$SUDO_USER" "$DESKTOP_DIR"/*.desktop 2>/dev/null || true
        fi
        chmod +x "$DESKTOP_DIR"/*.desktop 2>/dev/null || true
        
        success "Desktop shortcuts created"
    else
        info "No desktop environment detected, skipping shortcuts"
    fi
}

setup_path() {
    info "Setting up PATH for tools..."
    
    # Add nvme-tools to PATH for all users
    echo 'export PATH="/usr/local/bin/nvme-tools:$PATH"' > /etc/profile.d/nvme-tools.sh
    chmod +x /etc/profile.d/nvme-tools.sh
    
    success "PATH setup completed"
}

run_verification() {
    info "Running initial verification..."
    
    # Run the verification tool
    if [ -x "/usr/local/bin/nvme-tools/verify-nvme-setup.sh" ]; then
        echo ""
        echo -e "${BLUE}Running NVMe setup verification...${NC}"
        /usr/local/bin/nvme-tools/verify-nvme-setup.sh
        VERIFY_EXIT=$?
        
        if [ $VERIFY_EXIT -eq 0 ]; then
            success "All configurations verified successfully!"
        elif [ $VERIFY_EXIT -eq 1 ]; then
            warning "Minor configuration issues found"
        else
            warning "Configuration issues found - run setup script"
        fi
    fi
}

show_installation_summary() {
    echo ""
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                    🎉 INSTALLATION COMPLETE! 🎉                ║"
    echo "╠════════════════════════════════════════════════════════════════╣"
    echo "║                                                                ║"
    echo "║  📁 Installed Components:                                       ║"
    echo "║  • Setup script: setup-nvme-boot.sh                           ║"
    echo "║  • Monitoring: boot-monitor.sh                                 ║"
    echo "║  • Emergency repair: emergency-nvme-repair.sh                  ║"
    echo "║  • Diagnostic tools in /usr/local/bin/nvme-tools/             ║"
    echo "║  • Systemd services for monitoring                            ║"
    echo "║  • Log rotation configuration                                  ║"
    echo "║                                                                ║"
    echo "║  🔧 Quick Commands:                                            ║"
    echo "║  • Check status: nvme-status                                   ║"
    echo "║  • Verify setup: sudo nvme-verify                             ║"
    echo "║  • Analyze boot: nvme-analyze                                  ║"
    echo "║  • Setup NVMe: sudo setup-nvme-boot.sh                        ║"
    echo "║                                                                ║"
    echo "║  📚 Documentation: /usr/local/share/nvme-tools/               ║"
    echo "║  📊 Logs: /var/log/boot-monitor/, /var/log/nvme-setup/        ║"
    echo "║                                                                ║"
    echo "║  🚀 Next Steps:                                                ║"
    echo "║  1. Run: sudo nvme-verify                                      ║"
    echo "║  2. If needed: sudo setup-nvme-boot.sh                        ║"
    echo "║  3. Connect NVMe and test boot                                 ║"
    echo "║                                                                ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    
    log "Installation completed successfully"
    log "Log file location: $LOG_FILE"
}

main() {
    print_banner
    
    # Check requirements
    check_root
    check_system
    
    # Install components
    install_dependencies
    install_scripts
    setup_systemd_services
    setup_log_directories
    create_documentation_links
    setup_path
    create_desktop_shortcuts
    
    # Run verification
    run_verification
    
    # Show summary
    show_installation_summary
    
    log "=== Installation completed ==="
}

# Run main function
main "$@"