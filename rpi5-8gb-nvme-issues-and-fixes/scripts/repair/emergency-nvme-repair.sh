#!/bin/bash
# =================================================================
# EMERGENCY NVMe REPAIR SCRIPT - Raspberry Pi 5
# =================================================================
# Critical filesystem repair for severely corrupted NVMe drives
# Handles EXT4 corruption, journal failures, and I/O errors
# =================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging
LOG_FILE="/var/log/emergency-nvme-repair-$(date +%Y%m%d_%H%M%S).log"
mkdir -p "$(dirname "$LOG_FILE")"

log() {
    echo "$(date): $1" | tee -a "$LOG_FILE"
}

print_banner() {
    echo -e "${RED}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║              🚨 EMERGENCY NVMe REPAIR SCRIPT                 ║"
    echo "║                                                               ║"
    echo "║  CRITICAL: This script handles severe filesystem corruption   ║"
    echo "║  Only use when standard fsck fails or system won't boot      ║"
    echo "║                                                               ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

detect_nvme_device() {
    log "Detecting NVMe device..."
    echo -e "${BLUE}🔍 Device Detection:${NC}"
    
    # Show all available block devices
    lsblk -f
    echo ""
    
    # Try to identify NVMe device
    if [ -b "/dev/nvme0n1p2" ]; then
        NVME_DEV="/dev/nvme0n1p2"
        NVME_DISK="/dev/nvme0n1"
        echo -e "${GREEN}✅ NVMe device found: $NVME_DEV${NC}"
    elif [ -b "/dev/sda2" ]; then
        NVME_DEV="/dev/sda2"
        NVME_DISK="/dev/sda"
        echo -e "${YELLOW}⚠️  Using USB adapter: $NVME_DEV${NC}"
    else
        echo -e "${RED}❌ No suitable device found${NC}"
        echo "Available devices:"
        lsblk
        echo ""
        echo "Please connect your NVMe drive via:"
        echo "1. PCIe FFC connector, or"
        echo "2. USB adapter"
        exit 1
    fi
    
    log "Using device: $NVME_DEV"
}

check_device_health() {
    echo -e "${BLUE}🏥 Hardware Health Check:${NC}"
    log "Checking hardware health for $NVME_DISK"
    
    # SMART health check
    if command -v smartctl >/dev/null 2>&1; then
        echo "SMART Health Status:"
        if smartctl -H "$NVME_DISK" 2>/dev/null; then
            echo -e "${GREEN}✅ Drive hardware appears healthy${NC}"
        else
            echo -e "${YELLOW}⚠️  SMART check failed or drive has issues${NC}"
        fi
        
        # Temperature check
        echo "Drive Temperature:"
        smartctl -A "$NVME_DISK" 2>/dev/null | grep -i temperature || echo "Temperature data not available"
        
        # Error log check
        echo "Error Log:"
        smartctl -l error "$NVME_DISK" 2>/dev/null | head -10 || echo "Error log not available"
    else
        echo -e "${YELLOW}⚠️  smartctl not available, skipping SMART checks${NC}"
    fi
    echo ""
}

force_unmount() {
    echo -e "${BLUE}📤 Force Unmounting Device:${NC}"
    log "Attempting to unmount $NVME_DEV"
    
    # Try graceful unmount first
    if umount "$NVME_DEV" 2>/dev/null; then
        echo -e "${GREEN}✅ Device unmounted successfully${NC}"
    else
        echo -e "${YELLOW}⚠️  Graceful unmount failed, trying force unmount${NC}"
        
        # Force unmount
        if umount -f "$NVME_DEV" 2>/dev/null; then
            echo -e "${GREEN}✅ Force unmount successful${NC}"
        else
            echo -e "${YELLOW}⚠️  Force unmount failed, device may not be mounted${NC}"
        fi
    fi
    
    # Kill any processes using the device
    if command -v lsof >/dev/null 2>&1; then
        echo "Checking for processes using the device..."
        lsof "$NVME_DEV" 2>/dev/null || echo "No processes found using the device"
    fi
    echo ""
}

run_comprehensive_repair() {
    echo -e "${RED}🔧 COMPREHENSIVE REPAIR SEQUENCE:${NC}"
    log "Starting comprehensive repair sequence for $NVME_DEV"
    
    # Phase 1: Standard fsck
    echo -e "${YELLOW}Phase 1: Standard filesystem check${NC}"
    if fsck.ext4 -f -y -v -C 0 "$NVME_DEV" 2>&1 | tee -a "$LOG_FILE"; then
        echo -e "${GREEN}✅ Phase 1 completed successfully${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️  Phase 1 failed, proceeding to Phase 2${NC}"
    fi
    
    # Phase 2: Backup superblock repair
    echo -e "${YELLOW}Phase 2: Backup superblock repair${NC}"
    echo "Trying backup superblock at block 32768..."
    if e2fsck -f -y -v -C 0 -b 32768 "$NVME_DEV" 2>&1 | tee -a "$LOG_FILE"; then
        echo -e "${GREEN}✅ Phase 2 completed successfully${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️  Phase 2 failed, trying alternative backup superblock${NC}"
    fi
    
    # Phase 2b: Alternative backup superblock
    echo "Trying backup superblock at block 98304..."
    if e2fsck -f -y -v -C 0 -b 98304 "$NVME_DEV" 2>&1 | tee -a "$LOG_FILE"; then
        echo -e "${GREEN}✅ Phase 2b completed successfully${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️  Phase 2b failed, proceeding to Phase 3${NC}"
    fi
    
    # Phase 3: Bad block check and repair
    echo -e "${YELLOW}Phase 3: Bad block detection and repair${NC}"
    echo "This may take a long time..."
    if e2fsck -f -y -v -c -C 0 "$NVME_DEV" 2>&1 | tee -a "$LOG_FILE"; then
        echo -e "${GREEN}✅ Phase 3 completed successfully${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️  Phase 3 failed, proceeding to Phase 4${NC}"
    fi
    
    # Phase 4: Directory optimization
    echo -e "${YELLOW}Phase 4: Directory structure optimization${NC}"
    if e2fsck -D -f -y -v "$NVME_DEV" 2>&1 | tee -a "$LOG_FILE"; then
        echo -e "${GREEN}✅ Phase 4 completed successfully${NC}"
        return 0
    else
        echo -e "${RED}❌ All repair phases failed${NC}"
        return 1
    fi
}

attempt_data_recovery() {
    echo -e "${BLUE}💾 Data Recovery Attempt:${NC}"
    log "Attempting data recovery before major repairs"
    
    # Create recovery directory
    RECOVERY_DIR="/tmp/nvme-recovery-$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$RECOVERY_DIR"
    
    echo "Creating recovery directory: $RECOVERY_DIR"
    
    # Try read-only mount for data extraction
    if mount -o ro "$NVME_DEV" "$RECOVERY_DIR" 2>/dev/null; then
        echo -e "${GREEN}✅ Read-only mount successful${NC}"
        echo "You can now manually copy important data from: $RECOVERY_DIR"
        echo "Press Enter when ready to continue with repair..."
        read
        umount "$RECOVERY_DIR"
    else
        echo -e "${YELLOW}⚠️  Cannot mount even in read-only mode${NC}"
        echo "Filesystem is severely damaged, proceeding with repair"
    fi
}

validate_repair() {
    echo -e "${BLUE}✅ Repair Validation:${NC}"
    log "Validating repair results"
    
    # Run read-only check
    echo "Running read-only filesystem check..."
    if fsck.ext4 -f -n -v "$NVME_DEV" 2>&1 | tee -a "$LOG_FILE"; then
        echo -e "${GREEN}✅ Filesystem structure appears healthy${NC}"
    else
        echo -e "${YELLOW}⚠️  Some issues may remain${NC}"
    fi
    
    # Check filesystem statistics
    echo "Filesystem information:"
    dumpe2fs -h "$NVME_DEV" 2>/dev/null | grep -E "(state|errors|mounts)" || echo "Could not read filesystem info"
    
    echo ""
}

show_recovery_summary() {
    echo -e "${GREEN}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║                    📊 RECOVERY SUMMARY                        ║"
    echo "╠═══════════════════════════════════════════════════════════════╣"
    echo "║                                                               ║"
    echo "║  Emergency repair sequence completed                          ║"
    echo "║                                                               ║"
    echo "║  📁 Log File: $LOG_FILE"
    echo "║  💾 Device: $NVME_DEV"
    echo "║  🕐 Completed: $(date)"
    echo "║                                                               ║"
    echo "║  🔄 NEXT STEPS:                                               ║"
    echo "║  1. Review log file for detailed results                     ║"
    echo "║  2. Test mount: sudo mount $NVME_DEV /mnt                    ║"
    echo "║  3. Check data integrity                                      ║"
    echo "║  4. Consider backup before normal use                        ║"
    echo "║                                                               ║"
    echo "║  ⚠️  IMPORTANT:                                              ║"
    echo "║  • Monitor system closely after recovery                     ║"
    echo "║  • Run regular health checks                                 ║"
    echo "║  • Investigate root cause of corruption                      ║"
    echo "║                                                               ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

main() {
    print_banner
    
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}❌ This script must be run as root (use sudo)${NC}"
        exit 1
    fi
    
    echo -e "${YELLOW}⚠️  WARNING: EMERGENCY REPAIR PROCEDURE${NC}"
    echo "This script will attempt to repair severely corrupted filesystems."
    echo "It may result in data loss in extreme cases."
    echo ""
    echo "Recommended prerequisites:"
    echo "1. Boot from USB/SD card (not from the corrupted NVMe)"
    echo "2. Connect NVMe via USB adapter if PCIe boot fails"
    echo "3. Have backups if possible"
    echo ""
    
    read -p "Do you want to continue with emergency repair? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Emergency repair cancelled."
        exit 0
    fi
    
    echo ""
    log "Emergency NVMe repair started by user"
    
    # Execute repair sequence
    detect_nvme_device
    check_device_health
    
    # Ask about data recovery attempt
    echo -e "${BLUE}💾 Data Recovery:${NC}"
    read -p "Attempt data recovery before repair? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        attempt_data_recovery
    fi
    
    force_unmount
    
    echo -e "${RED}🔧 Starting repair sequence...${NC}"
    echo "This may take several minutes to hours depending on drive size and damage."
    echo ""
    
    if run_comprehensive_repair; then
        echo -e "${GREEN}🎉 Repair sequence completed successfully!${NC}"
        validate_repair
        show_recovery_summary
        log "Emergency repair completed successfully"
    else
        echo -e "${RED}❌ Repair sequence failed${NC}"
        echo ""
        echo -e "${YELLOW}📋 Options when repair fails:${NC}"
        echo "1. Hardware may be failing - run SMART diagnostics"
        echo "2. Try different recovery tools (testdisk, photorec)"
        echo "3. Professional data recovery may be needed"
        echo "4. Reformat as last resort (destroys all data)"
        echo ""
        echo -e "${BLUE}Log file for analysis: $LOG_FILE${NC}"
        log "Emergency repair failed - manual intervention needed"
        exit 1
    fi
}

# Execute main function
main "$@"