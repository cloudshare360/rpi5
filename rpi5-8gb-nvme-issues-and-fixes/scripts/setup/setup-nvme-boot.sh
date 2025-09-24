#!/bin/bash
# Raspberry Pi 5 NVMe PCIe Boot Setup Script
# 
# This script automates the complete setup of NVMe boot via PCIe FFC connector
# Based on solutions for all documented issues in nvme-issues-solutions.md
#
# Author: AI Assistant
# Created: 2025-09-16
# Version: 1.0
# Compatible: Raspberry Pi 5, Debian-based OS

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration variables
PCIE_GEN="1"  # PCIe generation (1, 2, or 3)
LOG_DIR="/var/log/boot-monitor"
BACKUP_DIR="/home/${SUDO_USER:-$USER}/nvme-boot-backups/$(date +%Y%m%d_%H%M%S)"

# Function definitions
print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}🚀 Raspberry Pi 5 NVMe PCIe Boot Setup${NC}"
    echo -e "${BLUE}================================${NC}"
    echo ""
}

print_step() {
    echo -e "${YELLOW}[STEP] $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

check_requirements() {
    print_step "Checking system requirements"
    
    # Check if running on Raspberry Pi 5
    if ! grep -q "Raspberry Pi 5" /proc/cpuinfo 2>/dev/null; then
        print_error "This script is designed for Raspberry Pi 5 only"
        exit 1
    fi
    
    # Check if running as root or with sudo
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run with sudo privileges"
        echo "Usage: sudo $0"
        exit 1
    fi
    
    # Check for required commands
    local required_commands=("rpi-eeprom-config" "systemctl" "tune2fs" "vcgencmd")
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            print_error "Required command '$cmd' not found"
            exit 1
        fi
    done
    
    print_success "System requirements check passed"
}

create_backups() {
    print_step "Creating configuration backups"
    
    # Create backup directory
    mkdir -p "$BACKUP_DIR"
    chown ${SUDO_USER:-$USER}:${SUDO_USER:-$USER} "$BACKUP_DIR" -R
    
    # Backup critical files
    cp /boot/firmware/config.txt "$BACKUP_DIR/config.txt.backup" 2>/dev/null || true
    cp /boot/firmware/cmdline.txt "$BACKUP_DIR/cmdline.txt.backup" 2>/dev/null || true
    rpi-eeprom-config > "$BACKUP_DIR/eeprom-config.backup" 2>/dev/null || true
    
    print_success "Backups created in $BACKUP_DIR"
}

update_system() {
    print_step "Updating system packages and firmware"
    
    # Update package lists and upgrade system
    apt update
    apt upgrade -y
    
    # Update firmware specifically
    apt install -y rpi-eeprom
    
    print_success "System updated successfully"
}

configure_pcie() {
    print_step "Configuring PCIe settings in config.txt"
    
    # Check if PCIe is already configured
    if grep -q "dtparam=pciex1" /boot/firmware/config.txt; then
        print_warning "PCIe already configured in config.txt"
    else
        # Add PCIe configuration
        cat >> /boot/firmware/config.txt << EOF

# NVMe PCIe Boot Configuration - Added by setup script
# Enable PCIe
dtparam=pciex1

# PCIe boot configuration - Enable PCIe Gen $PCIE_GEN speed
dtparam=pciex1_gen=$PCIE_GEN
EOF
        print_success "PCIe configuration added to config.txt"
    fi
    
    # Verify configuration
    if tail -10 /boot/firmware/config.txt | grep -q "pciex1"; then
        print_success "PCIe configuration verified"
    else
        print_error "Failed to configure PCIe"
        exit 1
    fi
}

configure_eeprom() {
    print_step "Configuring EEPROM bootloader settings"
    
    # Create temporary EEPROM config file
    local temp_config=$(mktemp)
    
    # Get current EEPROM config
    rpi-eeprom-config > "$temp_config"
    
    # Update/add NVMe boot settings
    if grep -q "NVME_CONTROLLER" "$temp_config"; then
        sed -i 's/NVME_CONTROLLER=.*/NVME_CONTROLLER=1/' "$temp_config"
    else
        echo "NVME_CONTROLLER=1" >> "$temp_config"
    fi
    
    if grep -q "NVME_BOOT" "$temp_config"; then
        sed -i 's/NVME_BOOT=.*/NVME_BOOT=1/' "$temp_config"
    else
        echo "NVME_BOOT=1" >> "$temp_config"
    fi
    
    if grep -q "PCIE_PROBE_RETRIES" "$temp_config"; then
        sed -i 's/PCIE_PROBE_RETRIES=.*/PCIE_PROBE_RETRIES=10/' "$temp_config"
    else
        echo "PCIE_PROBE_RETRIES=10" >> "$temp_config"
    fi
    
    if grep -q "BOOT_ORDER" "$temp_config"; then
        sed -i 's/BOOT_ORDER=.*/BOOT_ORDER=0xf461/' "$temp_config"
    else
        echo "BOOT_ORDER=0xf461" >> "$temp_config"
    fi
    
    # Apply EEPROM configuration
    rpi-eeprom-config --apply "$temp_config"
    rm "$temp_config"
    
    print_success "EEPROM configuration updated"
}

setup_filesystem_repair() {
    print_step "Configuring enhanced filesystem repair and hardware stability"
    
    # Enhanced kernel command line parameters
    local cmdline_params="fsck.repair=yes fsck.mode=force elevator=none"
    cmdline_params="$cmdline_params nvme.poll_queues=1 nvme.write_queues=1 nvme.io_timeout=60"
    cmdline_params="$cmdline_params pci=realloc,hpiosize=16M,hpmmiosize=512M"
    
    if ! grep -q "fsck.repair=yes" /boot/firmware/cmdline.txt; then
        # Add enhanced parameters to cmdline.txt
        sed -i "s/$/ $cmdline_params/" /boot/firmware/cmdline.txt
        print_success "Added enhanced filesystem repair and stability parameters"
    else
        print_warning "Filesystem repair already configured"
    fi
    
    # Configure system-level stability enhancements
    cat >> /etc/sysctl.conf << 'EOF'
# NVMe stability enhancements
vm.swappiness=10
vm.vfs_cache_pressure=50
vm.dirty_ratio=5
vm.dirty_background_ratio=2
EOF
    
    # Create emergency repair script
    cat > /usr/local/bin/emergency-nvme-repair.sh << 'EOF'
#!/bin/bash
echo "EMERGENCY NVMe Repair Script"
echo "Attempting automated repair..."
echo "Device detection..."
lsblk -f

# Try to identify the NVMe device
NVME_DEV="/dev/nvme0n1p2"
if [ ! -b "$NVME_DEV" ]; then
    NVME_DEV="/dev/sda2"  # Fallback to USB adapter
fi

echo "Using device: $NVME_DEV"

# Force unmount
umount "$NVME_DEV" 2>/dev/null

# Comprehensive repair sequence
echo "Running comprehensive filesystem check..."
fsck.ext4 -f -y -v -C 0 "$NVME_DEV"
if [ $? -ne 0 ]; then
    echo "Standard repair failed, trying backup superblock..."
    e2fsck -f -y -v -C 0 -b 32768 "$NVME_DEV"
    if [ $? -ne 0 ]; then
        echo "Backup superblock repair failed, trying alternative..."
        e2fsck -f -y -v -C 0 -b 98304 "$NVME_DEV"
    fi
fi

# Check for bad blocks if repair completed
if [ $? -eq 0 ]; then
    echo "Running bad block check..."
    e2fsck -f -y -v -c -C 0 "$NVME_DEV"
fi

echo "Repair sequence completed. Check output above for results."
echo "If repairs failed, hardware issues may be present."
EOF
    chmod +x /usr/local/bin/emergency-nvme-repair.sh
    
    # Create health monitoring script
    cat > /usr/local/bin/nvme-health-check.sh << 'EOF'
#!/bin/bash
LOG_FILE="/var/log/nvme-health.log"
echo "$(date): NVMe Health Check" >> "$LOG_FILE"

# Check SMART status
if command -v smartctl >/dev/null 2>&1; then
    SMART_STATUS=$(smartctl -H /dev/nvme0n1 2>/dev/null | grep "SMART overall-health" || echo "SMART check failed")
    echo "$SMART_STATUS" >> "$LOG_FILE"
    
    # Check temperature
    TEMP=$(smartctl -A /dev/nvme0n1 2>/dev/null | grep -i "Temperature" | head -1 || echo "Temperature check failed")
    echo "$TEMP" >> "$LOG_FILE"
fi

# Check filesystem (read-only)
if [ -b "/dev/nvme0n1p2" ]; then
    FS_STATUS=$(fsck.ext4 -f -n /dev/nvme0n1p2 2>&1 | tail -3)
else
    FS_STATUS=$(fsck.ext4 -f -n /dev/sda2 2>&1 | tail -3)
fi
echo "Filesystem status: $FS_STATUS" >> "$LOG_FILE"
EOF
    chmod +x /usr/local/bin/nvme-health-check.sh
    
    # Create corruption response script
    cat > /usr/local/bin/corruption-response.sh << 'EOF'
#!/bin/bash
echo "FILESYSTEM CORRUPTION DETECTED - EMERGENCY RESPONSE"
echo "1. System will be set to read-only mode"
mount -o remount,ro / 2>/dev/null

echo "2. Creating system state snapshot"
dmesg > /tmp/corruption-dmesg.log 2>/dev/null
journalctl > /tmp/corruption-journal.log 2>/dev/null
if command -v smartctl >/dev/null 2>&1; then
    smartctl -a /dev/nvme0n1 > /tmp/corruption-smart.log 2>/dev/null
fi

echo "3. Emergency logs saved to /tmp/corruption-*.log"
echo "4. REBOOT FROM USB/SD IMMEDIATELY TO PERFORM REPAIR"
echo "5. Run: /usr/local/bin/emergency-nvme-repair.sh"
EOF
    chmod +x /usr/local/bin/corruption-response.sh
    
    # Create simple force fsck script
    cat > /usr/local/bin/force-fsck.sh << 'EOF'
#!/bin/bash
# Force filesystem check on next boot
echo "Scheduling filesystem check on next boot..."
tune2fs -c 1 /dev/sda2 2>/dev/null || tune2fs -c 1 /dev/nvme0n1p2 2>/dev/null || echo "Could not set mount count"
touch /forcefsck
echo "Filesystem check scheduled. Reboot to execute."
EOF
    chmod +x /usr/local/bin/force-fsck.sh
    
    # Install essential monitoring tools
    apt install -y smartmontools sysstat e2fsprogs 2>/dev/null || print_warning "Could not install monitoring tools"
    
    print_success "Enhanced filesystem repair and monitoring system configured"
}

install_monitoring_system() {
    print_step "Installing boot monitoring system"
    
    # Create log directory
    mkdir -p "$LOG_DIR"
    
    # Install main boot monitor script
    cat > /usr/local/bin/boot-monitor.sh << 'EOF'
#!/bin/bash
# Boot Monitor Script - Logs comprehensive boot information for analysis
# Auto-generated by setup-nvme-boot.sh

LOG_DIR="/var/log/boot-monitor"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
BOOT_LOG="$LOG_DIR/boot_${TIMESTAMP}.log"

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Function to log with timestamp
log_with_timestamp() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$BOOT_LOG"
}

# Function to log command output with header
log_command() {
    local cmd="$1"
    local desc="$2"
    
    log_with_timestamp "=== $desc ==="
    log_with_timestamp "Command: $cmd"
    echo "" >> "$BOOT_LOG"
    
    if eval "$cmd" >> "$BOOT_LOG" 2>&1; then
        log_with_timestamp "✅ Command completed successfully"
    else
        log_with_timestamp "❌ Command failed with exit code: $?"
    fi
    
    echo "" >> "$BOOT_LOG"
    echo "----------------------------------------" >> "$BOOT_LOG"
    echo "" >> "$BOOT_LOG"
}

# Start logging
log_with_timestamp "🚀 Boot Monitor Script Started"
log_with_timestamp "Boot ID: $TIMESTAMP"
log_with_timestamp "Hostname: $(hostname)"
log_with_timestamp "Kernel: $(uname -r)"

# System Information
log_command "uname -a" "System Information"
log_command "uptime" "System Uptime"

# Hardware Detection
log_command "lsblk -f" "Block Devices with Filesystems"
log_command "lspci -v" "PCI Devices (Verbose)"

# Storage Information
log_command "fdisk -l" "Disk Partitions"
log_command "mount | grep -E '(sda|nvme)'" "Storage Mounts"

# PCIe and NVMe Specific
log_command "ls -la /dev/nvme*" "NVMe Device Files"
log_command "ls -la /dev/sd*" "SCSI/SATA Device Files"
log_command "dmesg | grep -i pcie" "PCIe Related Kernel Messages"
log_command "dmesg | grep -i nvme" "NVMe Related Kernel Messages"

# Filesystem Health
log_command "dmesg | grep -i ext4" "EXT4 Filesystem Messages"
log_command "dmesg | grep -i error" "Error Messages in Kernel Log"

# Boot Configuration
log_command "cat /boot/firmware/config.txt" "Boot Configuration"
log_command "rpi-eeprom-config" "EEPROM Configuration"

# Final Kernel Messages
log_command "dmesg | tail -50" "Last 50 Kernel Messages"

# Boot completion
log_with_timestamp "📊 Boot Monitor Script Completed"

# Create a symlink to latest log
ln -sf "$BOOT_LOG" "$LOG_DIR/latest.log"
chmod 644 "$BOOT_LOG" "$LOG_DIR/latest.log"
EOF

    chmod +x /usr/local/bin/boot-monitor.sh
    
    # Create systemd service
    cat > /etc/systemd/system/boot-monitor.service << 'EOF'
[Unit]
Description=Boot Monitor - Log system information at boot
After=multi-user.target
Wants=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/boot-monitor.sh
User=root
StandardOutput=journal
StandardError=journal
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

    # Enable and start the service
    systemctl daemon-reload
    systemctl enable boot-monitor.service
    
    print_success "Boot monitoring system installed"
}

create_analysis_tools() {
    print_step "Creating analysis tools"
    
    local user_home="/home/${SUDO_USER:-$USER}"
    
    # Create quick status script
    cat > "$user_home/boot-status.sh" << 'EOF'
#!/bin/bash
# Quick Boot Status - Instant overview

LOG_FILE="/var/log/boot-monitor/latest.log"
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "🔍 QUICK BOOT STATUS"
echo "==================="

if [[ ! -f "$LOG_FILE" ]]; then
    echo -e "${RED}❌ No boot log available${NC}"
    echo "Run: sudo systemctl start boot-monitor.service"
    exit 1
fi

echo -e "${GREEN}✅ Boot log available${NC}"
echo "Log time: $(stat -c %y "$LOG_FILE" | cut -d. -f1)"
echo ""

# Check storage
if grep -q "nvme" "$LOG_FILE"; then
    echo -e "${GREEN}✅ NVMe detected${NC}"
elif grep -q "sda" "$LOG_FILE"; then
    echo -e "${YELLOW}⚠️ Using USB/SATA (sda)${NC}"
else
    echo -e "${RED}❌ No storage detected${NC}"
fi

# Check errors
ERROR_COUNT=$(grep -ic "error\|fail" "$LOG_FILE" 2>/dev/null || echo 0)
if [[ $ERROR_COUNT -gt 0 ]]; then
    echo -e "${YELLOW}⚠️ $ERROR_COUNT errors/failures found${NC}"
else
    echo -e "${GREEN}✅ No critical errors${NC}"
fi

# PCIe status
if grep -qi "pcie" "$LOG_FILE"; then
    echo -e "${GREEN}✅ PCIe active${NC}"
else
    echo -e "${YELLOW}⚠️ No PCIe activity${NC}"
fi

# Filesystem health
if grep -qi "ext4.*error\|journal.*abort" "$LOG_FILE"; then
    echo -e "${RED}❌ Filesystem errors detected${NC}"
else
    echo -e "${GREEN}✅ Filesystem healthy${NC}"
fi
EOF

    # Create verification script
    cat > "$user_home/verify-nvme-setup.sh" << 'EOF'
#!/bin/bash
# NVMe Setup Verification Script

echo "🔍 NVMe PCIe Boot Configuration Verification"
echo "==========================================="
echo ""

# Check PCIe configuration
echo "📋 PCIe Configuration:"
if grep -q "dtparam=pciex1" /boot/firmware/config.txt; then
    echo "✅ PCIe enabled in config.txt"
    grep "pciex1" /boot/firmware/config.txt
else
    echo "❌ PCIe not configured in config.txt"
fi
echo ""

# Check EEPROM configuration
echo "📋 EEPROM Boot Configuration:"
if rpi-eeprom-config | grep -q "NVME_CONTROLLER=1"; then
    echo "✅ NVMe controller enabled"
    rpi-eeprom-config | grep -E "(NVME|PCIE|BOOT_ORDER)"
else
    echo "❌ NVMe not configured in EEPROM"
fi
echo ""

# Check filesystem repair
echo "📋 Filesystem Auto-repair:"
if grep -q "fsck.repair=yes" /boot/firmware/cmdline.txt; then
    echo "✅ Automatic filesystem repair enabled"
else
    echo "❌ Filesystem auto-repair not configured"
fi
echo ""

# Check monitoring service
echo "📋 Boot Monitoring Service:"
if systemctl is-enabled boot-monitor.service &>/dev/null; then
    echo "✅ Boot monitor service enabled"
else
    echo "❌ Boot monitor service not enabled"
fi
echo ""

# Check current storage
echo "📋 Current Storage Configuration:"
lsblk -f | head -10
echo ""

echo "🎯 Setup Status Summary:"
ISSUES=0

if ! grep -q "dtparam=pciex1" /boot/firmware/config.txt; then
    echo "❌ PCIe not enabled"
    ((ISSUES++))
fi

if ! rpi-eeprom-config | grep -q "NVME_CONTROLLER=1"; then
    echo "❌ EEPROM not configured for NVMe boot"
    ((ISSUES++))
fi

if ! systemctl is-enabled boot-monitor.service &>/dev/null; then
    echo "❌ Boot monitoring not enabled"
    ((ISSUES++))
fi

if [[ $ISSUES -eq 0 ]]; then
    echo "✅ All configurations are correct - ready for PCIe boot test!"
else
    echo "⚠️ Found $ISSUES configuration issues that need attention"
fi
EOF

    chmod +x "$user_home/boot-status.sh" "$user_home/verify-nvme-setup.sh"
    chown ${SUDO_USER:-$USER}:${SUDO_USER:-$USER} "$user_home/boot-status.sh" "$user_home/verify-nvme-setup.sh"
    
    print_success "Analysis tools created"
}

create_documentation() {
    print_step "Creating setup documentation"
    
    local user_home="/home/${SUDO_USER:-$USER}"
    
    cat > "$user_home/SETUP-COMPLETE.md" << EOF
# NVMe PCIe Boot Setup Complete

**Date**: $(date)
**Script Version**: 1.0
**System**: $(uname -a)

## ✅ Configuration Applied

### PCIe Settings
- PCIe interface: **ENABLED**
- PCIe Generation: **Gen $PCIE_GEN**
- Configuration file: \`/boot/firmware/config.txt\`

### EEPROM Boot Settings
- NVMe Controller: **ENABLED**
- NVMe Boot: **ENABLED**  
- Boot Order: **0xf461** (NVMe prioritized)
- PCIe Probe Retries: **10**

### Filesystem Protection
- Auto-repair: **ENABLED** (\`fsck.repair=yes\`)
- Force check script: \`/usr/local/bin/force-fsck.sh\`

### Monitoring System
- Boot monitor: **INSTALLED** and **ENABLED**
- Log location: \`$LOG_DIR\`
- Analysis tools: \`~/boot-status.sh\`, \`~/verify-nvme-setup.sh\`

## 🎯 Next Steps

### 1. Verify Configuration
\`\`\`bash
./verify-nvme-setup.sh
\`\`\`

### 2. Test PCIe Boot
1. **Shutdown system**: \`sudo shutdown -h now\`
2. **Disconnect USB adapter** (if using one)
3. **Connect NVMe to PCIe FFC connector**
4. **Power on and test boot**

### 3. Monitor Boot Process
\`\`\`bash
# Quick status check
./boot-status.sh

# View detailed logs
cat $LOG_DIR/latest.log
\`\`\`

## 🆘 Emergency Recovery

If PCIe boot fails:
1. **Remove PCIe FFC connector**
2. **Connect NVMe via USB adapter**
3. **Boot from USB/SD card**
4. **Run filesystem repair**: \`sudo /usr/local/bin/force-fsck.sh && sudo reboot\`

## 📚 Documentation Files

- **Issues & Solutions**: \`~/nvme-issues-solutions.md\`
- **AI Analysis Guide**: \`~/ai-warp-analysis.md\`
- **Setup Complete**: This file

## 🔧 Configuration Backups

Backups saved to: \`$BACKUP_DIR\`

---

**⚠️ Important**: Always perform clean shutdowns (\`sudo shutdown -h now\`) to prevent filesystem corruption.

**📞 Support**: Refer to documentation files for troubleshooting guidance.
EOF

    chown ${SUDO_USER:-$USER}:${SUDO_USER:-$USER} "$user_home/SETUP-COMPLETE.md"
    
    print_success "Setup documentation created"
}

perform_final_checks() {
    print_step "Performing final verification checks"
    
    # Check PCIe configuration
    if ! grep -q "dtparam=pciex1" /boot/firmware/config.txt; then
        print_error "PCIe configuration not found in config.txt"
        return 1
    fi
    
    # Check EEPROM configuration  
    if ! rpi-eeprom-config | grep -q "NVME_CONTROLLER=1"; then
        print_error "EEPROM not configured for NVMe boot"
        return 1
    fi
    
    # Check boot monitor service
    if ! systemctl is-enabled boot-monitor.service &>/dev/null; then
        print_error "Boot monitor service not enabled"
        return 1
    fi
    
    # Check filesystem repair configuration
    if ! grep -q "fsck.repair=yes" /boot/firmware/cmdline.txt; then
        print_error "Filesystem auto-repair not configured"
        return 1
    fi
    
    print_success "All verification checks passed"
    return 0
}

show_completion_summary() {
    echo ""
    echo -e "${GREEN}🎉 NVMe PCIe Boot Setup Complete!${NC}"
    echo "=================================="
    echo ""
    echo -e "${BLUE}📋 What was configured:${NC}"
    echo "  ✅ PCIe interface enabled (Gen $PCIE_GEN)"
    echo "  ✅ EEPROM bootloader configured for NVMe boot"
    echo "  ✅ Filesystem auto-repair enabled"  
    echo "  ✅ Boot monitoring system installed"
    echo "  ✅ Analysis tools created"
    echo "  ✅ Configuration backups saved"
    echo ""
    echo -e "${YELLOW}🎯 Next Steps:${NC}"
    echo "  1. Run: ./verify-nvme-setup.sh"
    echo "  2. Shutdown: sudo shutdown -h now"
    echo "  3. Connect NVMe to PCIe FFC connector"
    echo "  4. Power on and test boot"
    echo "  5. Check status: ./boot-status.sh"
    echo ""
    echo -e "${BLUE}📚 Documentation:${NC}"
    echo "  • Setup summary: ~/SETUP-COMPLETE.md"
    echo "  • Issues & solutions: ~/nvme-issues-solutions.md"  
    echo "  • Backups: $BACKUP_DIR"
    echo ""
    echo -e "${YELLOW}⚠️ Important:${NC}"
    echo "  • Always use clean shutdowns (sudo shutdown -h now)"
    echo "  • Keep USB adapter as backup boot option"
    echo "  • Monitor boot logs for any issues"
    echo ""
    echo -e "${GREEN}Ready for PCIe boot testing! 🚀${NC}"
}

# Main execution
main() {
    print_header
    
    # Check if we should proceed
    echo "This script will configure your Raspberry Pi 5 for NVMe PCIe boot."
    echo "It will modify system configuration files and install monitoring tools."
    echo ""
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Setup cancelled by user."
        exit 0
    fi
    
    echo ""
    
    # Execute all setup steps
    check_requirements
    create_backups
    update_system
    configure_pcie
    configure_eeprom
    setup_filesystem_repair
    install_monitoring_system
    create_analysis_tools
    create_documentation
    
    # Final verification
    if perform_final_checks; then
        show_completion_summary
        exit 0
    else
        print_error "Setup completed with errors. Please review the configuration."
        exit 1
    fi
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
EOF