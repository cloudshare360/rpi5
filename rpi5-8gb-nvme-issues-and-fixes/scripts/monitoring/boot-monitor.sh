#!/bin/bash
# Boot Monitor Script - Logs comprehensive boot information for analysis
# Created for Raspberry Pi 5 PCIe boot troubleshooting

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
log_command "date" "Current Date/Time"

# Hardware Detection
log_command "lscpu" "CPU Information"
log_command "lsblk -f" "Block Devices with Filesystems"
log_command "lspci -v" "PCI Devices (Verbose)"
log_command "lsusb" "USB Devices"

# Storage Information
log_command "fdisk -l" "Disk Partitions"
log_command "mount | grep -E '(sda|nvme)'" "Storage Mounts"
log_command "df -h" "Disk Usage"

# PCIe and NVMe Specific
log_command "ls -la /dev/nvme*" "NVMe Device Files"
log_command "ls -la /dev/sd*" "SCSI/SATA Device Files"
log_command "dmesg | grep -i pcie" "PCIe Related Kernel Messages"
log_command "dmesg | grep -i nvme" "NVMe Related Kernel Messages"
log_command "dmesg | grep -i 'scsi\\|ata\\|usb-storage'" "Storage Detection Messages"

# Filesystem Health
log_command "dmesg | grep -i ext4" "EXT4 Filesystem Messages"
log_command "dmesg | grep -i error" "Error Messages in Kernel Log"
log_command "dmesg | grep -i fail" "Failure Messages in Kernel Log"

# Boot Configuration
log_command "cat /boot/firmware/config.txt" "Boot Configuration"
log_command "cat /boot/firmware/cmdline.txt" "Kernel Command Line"
log_command "rpi-eeprom-config" "EEPROM Configuration"

# Memory and Performance
log_command "free -h" "Memory Usage"
log_command "iostat -x 1 3" "I/O Statistics (3 samples)" || log_with_timestamp "iostat not available"

# Network (if relevant)
log_command "ip addr show" "Network Interfaces"

# Process Information
log_command "ps aux | head -20" "Top 20 Processes"
log_command "systemctl --failed" "Failed Services"

# Temperature and Power
log_command "vcgencmd measure_temp" "CPU Temperature"
log_command "vcgencmd measure_volts" "System Voltages" || log_with_timestamp "vcgencmd volts not available"

# Final Kernel Messages
log_command "dmesg | tail -50" "Last 50 Kernel Messages"

# Boot completion
log_with_timestamp "📊 Boot Monitor Script Completed"
log_with_timestamp "Log saved to: $BOOT_LOG"

# Create a symlink to latest log
ln -sf "$BOOT_LOG" "$LOG_DIR/latest.log"

# Set permissions for easy access
chmod 644 "$BOOT_LOG"
chmod 644 "$LOG_DIR/latest.log"

echo "Boot monitor completed. Log saved to: $BOOT_LOG"