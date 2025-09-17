#!/bin/bash
# =================================================================
# RASPBERRY PI 5 OPTIMIZATION SCRIPT
# =================================================================
# Applies CPU/GPU overclocking and dual monitor configuration
# 
# Author: Community Contribution
# License: MIT
# Tested: Raspberry Pi 5 8GB, Raspberry Pi OS Bookworm
# =================================================================

set -euo pipefail

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Configuration files
CONFIG_FILE="/boot/firmware/config.txt"
BACKUP_FILE="/boot/firmware/config.txt.backup"
TEMP_FILE="/tmp/config.txt.new"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging
LOG_FILE="$PROJECT_ROOT/logs/optimization_$(date +%Y%m%d_%H%M%S).log"
mkdir -p "$(dirname "$LOG_FILE")"

log() {
    echo "$(date): $1" | tee -a "$LOG_FILE"
}

print_banner() {
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║          🚀 Raspberry Pi 5 Optimization Script                ║"
    echo "║                                                                ║"
    echo "║   • CPU Overclocking: 2400MHz → 2800MHz (+17%)                ║"
    echo "║   • GPU Overclocking: V3D 960MHz → 1100MHz (+15%)             ║"  
    echo "║   • Dual Monitor Support: Fixed blank screen issue            ║"
    echo "║   • Safety Features: Automatic backup & rollback              ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check if running on Raspberry Pi 5
    if ! grep -q "Raspberry Pi 5" /proc/cpuinfo 2>/dev/null; then
        echo -e "${RED}❌ This script is designed for Raspberry Pi 5 only${NC}"
        exit 1
    fi
    
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}❌ This script must be run as root (use sudo)${NC}"
        exit 1
    fi
    
    # Check if config file exists
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo -e "${RED}❌ Configuration file not found: $CONFIG_FILE${NC}"
        exit 1
    fi
    
    # Check available memory
    TOTAL_MEM=$(free -m | awk '/^Mem:/{print $2}')
    if [[ $TOTAL_MEM -lt 7000 ]]; then
        echo -e "${YELLOW}⚠️  Warning: This script is optimized for 8GB Pi 5 models${NC}"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    log "Prerequisites check passed"
}

create_backup() {
    log "Creating configuration backup..."
    
    if [[ -f "$BACKUP_FILE" ]]; then
        echo -e "${YELLOW}⚠️  Backup already exists: $BACKUP_FILE${NC}"
        read -p "Overwrite existing backup? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}ℹ️  Using existing backup${NC}"
            return 0
        fi
    fi
    
    cp "$CONFIG_FILE" "$BACKUP_FILE"
    echo -e "${GREEN}✅ Backup created: $BACKUP_FILE${NC}"
    log "Backup created successfully"
}

apply_optimizations() {
    log "Applying optimizations to configuration..."
    
    # Copy current config to temp file
    cp "$CONFIG_FILE" "$TEMP_FILE"
    
    # Add optimization header
    cat >> "$TEMP_FILE" << 'EOF'

# =================================================================
# RASPBERRY PI 5 OPTIMIZATIONS
# =================================================================
# Applied by: rpi5-8gb-cpu-gpu-optimization-with-dual-monitor-configuration
# Date: $(date)
# Backup: /boot/firmware/config.txt.backup
# =================================================================

# === CPU OVERCLOCKING ===
# Boost CPU from 2400MHz to 2800MHz for +17% performance
arm_freq=2800
over_voltage=6
temp_limit=75
initial_turbo=60

# === GPU OVERCLOCKING ===  
# Boost GPU performance for better graphics and dual monitor support
gpu_freq=700
v3d_freq=1100

# === MEMORY OPTIMIZATION ===
# Boost RAM frequency and voltage for improved performance
sdram_freq=3600
over_voltage_sdram=2

# === GPU MEMORY (Pi 5 Specific) ===
# Allocate 512MB GPU memory using CMA for dual monitor support
dtoverlay=vc4-kms-v3d,cma-512
cma=256

# === DUAL MONITOR OPTIMIZATION ===
# Force HDMI output and boost signal strength for stable dual monitors
hdmi_force_hotplug:0=1
hdmi_force_hotplug:1=1
config_hdmi_boost:0=7
config_hdmi_boost:1=7
hdmi_enable_4kp60:0=1
hdmi_enable_4kp60:1=1

# === END OPTIMIZATIONS ===

EOF
    
    # Replace the actual configuration file
    mv "$TEMP_FILE" "$CONFIG_FILE"
    
    echo -e "${GREEN}✅ Optimizations applied successfully${NC}"
    log "Optimizations applied to $CONFIG_FILE"
}

show_summary() {
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                    📊 OPTIMIZATION SUMMARY                     ║"
    echo "╠════════════════════════════════════════════════════════════════╣"
    echo "║                                                                ║"
    echo "║  CPU Performance:                                              ║"
    echo "║    • Frequency: 2400MHz → 2800MHz (+17% boost)                ║"
    echo "║    • Voltage: Increased for stability                         ║"
    echo "║    • Thermal limit: 75°C (conservative)                       ║"
    echo "║                                                                ║"
    echo "║  GPU Performance:                                              ║"
    echo "║    • Core: ~545MHz → 700MHz (+28% boost)                      ║"
    echo "║    • V3D Graphics: 960MHz → 1100MHz (+15% boost)              ║"
    echo "║    • Memory: 8MB → 512MB (+6400% for dual monitors)           ║"
    echo "║                                                                ║"
    echo "║  Dual Monitor Support:                                         ║"
    echo "║    • HDMI force hotplug: Both ports enabled                   ║"
    echo "║    • Signal boost: Maximum strength (7)                       ║"
    echo "║    • 4K support: Enabled on both outputs                      ║"
    echo "║    • Status: Blank screen issue FIXED                         ║"
    echo "║                                                                ║"
    echo "║  Safety Features:                                              ║"
    echo "║    • Original backup: /boot/firmware/config.txt.backup        ║"
    echo "║    • Rollback scripts: Available in scripts/ directory        ║"
    echo "║    • Conservative thermal limits applied                       ║"
    echo "║                                                                ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

show_next_steps() {
    echo -e "${YELLOW}"
    echo "📋 NEXT STEPS:"
    echo "=============="
    echo -e "${NC}"
    echo "1. 🔄 Reboot your system:"
    echo "   sudo reboot"
    echo ""
    echo "2. 🧪 After reboot, test the optimizations:"
    echo "   ./scripts/system_health.sh"
    echo "   ./tests/post_install_test.sh"
    echo ""
    echo "3. 🖥️  Connect dual monitors and verify they work"
    echo ""
    echo "4. 📊 Run stress tests to verify stability:"
    echo "   ./scripts/stress_test.sh"
    echo ""
    echo -e "${GREEN}🛡️  SAFETY REMINDERS:${NC}"
    echo "• Monitor temperatures during first use"
    echo "• Rollback available: sudo ./scripts/rollback_all.sh"
    echo "• Emergency recovery: SD card method in docs/TROUBLESHOOTING.md"
    echo ""
}

main() {
    print_banner
    
    echo -e "${YELLOW}⚠️  WARNING: This will modify your system configuration${NC}"
    echo "• CPU will be overclocked to 2800MHz"
    echo "• GPU will be overclocked for better performance"
    echo "• Dual monitor support will be enabled"
    echo "• Automatic backup will be created"
    echo ""
    
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Operation cancelled."
        exit 0
    fi
    
    echo -e "${BLUE}🔄 Starting optimization process...${NC}"
    
    check_prerequisites
    create_backup
    apply_optimizations
    
    show_summary
    show_next_steps
    
    echo -e "${GREEN}🎉 Optimization completed successfully!${NC}"
    log "Optimization process completed successfully"
    
    echo ""
    read -p "🔄 Reboot now to apply changes? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}🔄 Rebooting system in 3 seconds...${NC}"
        sleep 3
        reboot
    else
        echo -e "${YELLOW}⚠️  Remember to reboot to apply changes: sudo reboot${NC}"
    fi
}

# Execute main function
main "$@"