#!/bin/bash
# =================================================================
# NVMe SETUP VERIFICATION TOOL - Raspberry Pi 5
# =================================================================
# Comprehensive verification of NVMe PCIe boot configuration
# Checks all components needed for successful NVMe boot
# =================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_banner() {
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║           🔍 NVMe PCIe Boot Configuration Verification        ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
}

check_hardware() {
    echo -e "${BLUE}📱 Hardware Verification:${NC}"
    echo "----------------------------------------"
    
    # Check if running on Pi 5
    if grep -q "Raspberry Pi 5" /proc/cpuinfo 2>/dev/null; then
        echo -e "✅ Running on ${GREEN}Raspberry Pi 5${NC}"
    else
        echo -e "❌ ${RED}Not running on Raspberry Pi 5${NC}"
        return 1
    fi
    
    # Check memory
    TOTAL_MEM=$(free -m | awk '/^Mem:/{print $2}')
    echo -e "💾 Total Memory: ${GREEN}${TOTAL_MEM}MB${NC}"
    
    # Check current storage
    echo "💾 Current Storage:"
    lsblk -o NAME,SIZE,TYPE,MOUNTPOINT | head -10
    
    echo ""
    return 0
}

check_pcie_config() {
    echo -e "${BLUE}🔌 PCIe Configuration Check:${NC}"
    echo "----------------------------------------"
    
    local issues=0
    
    # Check config.txt for PCIe settings
    if grep -q "dtparam=pciex1" /boot/firmware/config.txt; then
        echo -e "✅ PCIe interface ${GREEN}enabled${NC} in config.txt"
        
        # Show PCIe generation setting
        if grep -q "dtparam=pciex1_gen=" /boot/firmware/config.txt; then
            GEN=$(grep "dtparam=pciex1_gen=" /boot/firmware/config.txt | cut -d'=' -f2)
            echo -e "✅ PCIe Generation: ${GREEN}Gen ${GEN}${NC}"
        else
            echo -e "⚠️  PCIe generation not specified (using default)"
        fi
        
        # Show actual PCIe configuration lines
        echo "   Configuration lines:"
        grep "pciex1" /boot/firmware/config.txt | sed 's/^/   /'
        
    else
        echo -e "❌ PCIe interface ${RED}NOT enabled${NC} in config.txt"
        echo "   Add these lines to /boot/firmware/config.txt:"
        echo "   dtparam=pciex1"
        echo "   dtparam=pciex1_gen=1"
        ((issues++))
    fi
    
    echo ""
    return $issues
}

check_eeprom_config() {
    echo -e "${BLUE}🔧 EEPROM Boot Configuration:${NC}"
    echo "----------------------------------------"
    
    local issues=0
    
    # Check if rpi-eeprom-config is available
    if ! command -v rpi-eeprom-config &> /dev/null; then
        echo -e "❌ ${RED}rpi-eeprom-config not available${NC}"
        echo "   Install with: sudo apt install rpi-eeprom"
        ((issues++))
        return $issues
    fi
    
    # Get EEPROM configuration
    local eeprom_config=$(rpi-eeprom-config 2>/dev/null)
    
    # Check NVME_CONTROLLER
    if echo "$eeprom_config" | grep -q "NVME_CONTROLLER=1"; then
        echo -e "✅ NVMe controller ${GREEN}enabled${NC}"
    else
        echo -e "❌ NVMe controller ${RED}NOT enabled${NC}"
        echo "   Add: NVME_CONTROLLER=1"
        ((issues++))
    fi
    
    # Check NVME_BOOT
    if echo "$eeprom_config" | grep -q "NVME_BOOT=1"; then
        echo -e "✅ NVMe boot ${GREEN}enabled${NC}"
    else
        echo -e "❌ NVMe boot ${RED}NOT enabled${NC}"
        echo "   Add: NVME_BOOT=1"
        ((issues++))
    fi
    
    # Check BOOT_ORDER
    if echo "$eeprom_config" | grep -q "BOOT_ORDER"; then
        BOOT_ORDER=$(echo "$eeprom_config" | grep "BOOT_ORDER" | cut -d'=' -f2)
        echo -e "✅ Boot order configured: ${GREEN}$BOOT_ORDER${NC}"
        
        # Check if NVMe is prioritized (4 should come before 1 and 6)
        if [[ "$BOOT_ORDER" == *"4"*"1"* ]] || [[ "$BOOT_ORDER" == *"4"*"6"* ]]; then
            echo -e "✅ NVMe prioritized in boot order"
        else
            echo -e "⚠️  NVMe may not be prioritized in boot order"
        fi
    else
        echo -e "❌ Boot order ${RED}NOT configured${NC}"
        echo "   Add: BOOT_ORDER=0xf461"
        ((issues++))
    fi
    
    # Check PCIE_PROBE_RETRIES
    if echo "$eeprom_config" | grep -q "PCIE_PROBE_RETRIES"; then
        RETRIES=$(echo "$eeprom_config" | grep "PCIE_PROBE_RETRIES" | cut -d'=' -f2)
        echo -e "✅ PCIe probe retries: ${GREEN}$RETRIES${NC}"
    else
        echo -e "⚠️  PCIe probe retries not configured (using default)"
        echo "   Consider adding: PCIE_PROBE_RETRIES=10"
    fi
    
    # Show bootloader version
    echo "📱 Bootloader version:"
    vcgencmd bootloader_version 2>/dev/null | head -2 | sed 's/^/   /' || echo "   Could not read bootloader version"
    
    echo ""
    return $issues
}

check_filesystem_config() {
    echo -e "${BLUE}🗂️  Filesystem Auto-repair Configuration:${NC}"
    echo "----------------------------------------"
    
    local issues=0
    
    # Check cmdline.txt for fsck settings
    if grep -q "fsck.repair=yes" /boot/firmware/cmdline.txt; then
        echo -e "✅ Filesystem auto-repair ${GREEN}enabled${NC}"
        
        # Show relevant cmdline parameters
        echo "   Parameters:"
        grep -o 'fsck\.[^[:space:]]*\|elevator=[^[:space:]]*\|nvme\.[^[:space:]]*' /boot/firmware/cmdline.txt | sed 's/^/   /' || echo "   Basic fsck.repair=yes"
    else
        echo -e "❌ Filesystem auto-repair ${RED}NOT enabled${NC}"
        echo "   Consider adding to /boot/firmware/cmdline.txt:"
        echo "   fsck.repair=yes fsck.mode=force"
        ((issues++))
    fi
    
    # Check for emergency repair script
    if [ -x "/usr/local/bin/emergency-nvme-repair.sh" ]; then
        echo -e "✅ Emergency repair script ${GREEN}installed${NC}"
    else
        echo -e "⚠️  Emergency repair script not found"
    fi
    
    echo ""
    return $issues
}

check_monitoring_system() {
    echo -e "${BLUE}📊 Boot Monitoring System:${NC}"
    echo "----------------------------------------"
    
    local issues=0
    
    # Check boot monitor script
    if [ -x "/usr/local/bin/boot-monitor.sh" ]; then
        echo -e "✅ Boot monitor script ${GREEN}installed${NC}"
    else
        echo -e "❌ Boot monitor script ${RED}NOT found${NC}"
        ((issues++))
    fi
    
    # Check systemd service
    if systemctl is-enabled boot-monitor.service &>/dev/null; then
        echo -e "✅ Boot monitor service ${GREEN}enabled${NC}"
        
        # Check service status
        if systemctl is-active boot-monitor.service &>/dev/null; then
            echo -e "✅ Boot monitor service ${GREEN}running${NC}"
        else
            echo -e "⚠️  Boot monitor service not currently running"
        fi
    else
        echo -e "❌ Boot monitor service ${RED}NOT enabled${NC}"
        ((issues++))
    fi
    
    # Check log directory
    if [ -d "/var/log/boot-monitor" ]; then
        echo -e "✅ Boot monitor logs directory ${GREEN}exists${NC}"
        
        # Check for recent logs
        if [ -f "/var/log/boot-monitor/latest.log" ]; then
            LOG_TIME=$(stat -c %y "/var/log/boot-monitor/latest.log" 2>/dev/null | cut -d. -f1)
            echo -e "✅ Latest boot log: ${GREEN}$LOG_TIME${NC}"
        else
            echo -e "⚠️  No boot logs found"
        fi
    else
        echo -e "❌ Boot monitor logs directory ${RED}NOT found${NC}"
    fi
    
    echo ""
    return $issues
}

check_current_storage() {
    echo -e "${BLUE}💾 Current Storage Configuration:${NC}"
    echo "----------------------------------------"
    
    # Show block devices
    echo "Block devices:"
    lsblk -f | sed 's/^/   /'
    echo ""
    
    # Check for NVMe devices
    if ls /dev/nvme* &>/dev/null; then
        echo -e "✅ NVMe devices ${GREEN}detected${NC}:"
        ls -la /dev/nvme* | sed 's/^/   /'
        echo ""
        
        # Check if NVMe is mounted as root
        if mount | grep -q "nvme.*on / "; then
            echo -e "✅ Root filesystem on ${GREEN}NVMe${NC}"
            mount | grep "nvme.*on / " | sed 's/^/   /'
        else
            echo -e "⚠️  Root filesystem ${YELLOW}NOT on NVMe${NC}"
            ROOT_DEV=$(mount | grep " on / " | cut -d' ' -f1)
            echo "   Current root device: $ROOT_DEV"
        fi
    else
        echo -e "⚠️  No NVMe devices detected"
        echo "   This may be normal if testing configuration before connecting NVMe"
    fi
    
    # Check for USB storage (might be NVMe via adapter)
    if ls /dev/sd* &>/dev/null; then
        echo -e "ℹ️  USB/SATA devices detected:"
        ls -la /dev/sd* | sed 's/^/   /'
    fi
    
    echo ""
}

check_hardware_compatibility() {
    echo -e "${BLUE}🔬 Hardware Compatibility Check:${NC}"
    echo "----------------------------------------"
    
    # Check PCIe devices
    if command -v lspci &>/dev/null; then
        echo "PCIe devices:"
        if lspci | grep -q .; then
            lspci | sed 's/^/   /'
            
            # Specifically look for NVMe
            if lspci | grep -qi nvme; then
                echo -e "✅ NVMe controller ${GREEN}detected via PCIe${NC}"
            else
                echo -e "⚠️  No NVMe controller detected via PCIe"
            fi
        else
            echo -e "   ${YELLOW}No PCIe devices detected${NC}"
            echo "   This is expected if PCIe is not yet configured or no devices connected"
        fi
    else
        echo -e "⚠️  lspci not available"
    fi
    
    echo ""
    
    # Check kernel modules
    echo "NVMe kernel modules:"
    if lsmod | grep -q nvme; then
        lsmod | grep nvme | sed 's/^/   /'
        echo -e "✅ NVMe kernel modules ${GREEN}loaded${NC}"
    else
        echo -e "⚠️  NVMe kernel modules ${YELLOW}not loaded${NC}"
        echo "   This may be normal if no NVMe devices are connected"
    fi
    
    echo ""
}

show_setup_summary() {
    local total_issues=$1
    
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                    📊 VERIFICATION SUMMARY                     ║"
    echo "╠════════════════════════════════════════════════════════════════╣"
    
    if [ $total_issues -eq 0 ]; then
        echo "║                                                                ║"
        echo -e "║  ${GREEN}🎉 ALL CONFIGURATIONS VERIFIED SUCCESSFULLY! 🎉${NC}              ║"
        echo "║                                                                ║"
        echo "║  Your system is ready for NVMe PCIe boot testing.             ║"
        echo "║                                                                ║"
        echo "║  📋 Next Steps:                                                ║"
        echo "║  1. Shutdown: sudo shutdown -h now                            ║"
        echo "║  2. Connect NVMe to PCIe FFC connector                        ║"
        echo "║  3. Power on and test boot                                     ║"
        echo "║  4. Monitor: ./tools/diagnostic/boot-status.sh                ║"
        echo "║                                                                ║"
    elif [ $total_issues -le 2 ]; then
        echo "║                                                                ║"
        echo -e "║  ${YELLOW}⚠️  MINOR ISSUES FOUND ($total_issues)${NC}                                   ║"
        echo "║                                                                ║"
        echo "║  Most configurations are correct, but some minor issues       ║"
        echo "║  were found. Review the details above and consider fixing     ║"
        echo "║  them for optimal performance.                                ║"
        echo "║                                                                ║"
    else
        echo "║                                                                ║"
        echo -e "║  ${RED}❌ CONFIGURATION ISSUES FOUND ($total_issues)${NC}                           ║"
        echo "║                                                                ║"
        echo "║  Several configuration issues need attention before           ║"
        echo "║  attempting NVMe PCIe boot. Please review the details        ║"
        echo "║  above and run the setup script if needed.                   ║"
        echo "║                                                                ║"
        echo "║  🔧 Run setup: sudo ./scripts/setup/setup-nvme-boot.sh       ║"
        echo "║                                                                ║"
    fi
    
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

main() {
    print_banner
    
    local total_issues=0
    
    # Run all verification checks
    check_hardware
    ((total_issues+=$?))
    
    check_pcie_config
    ((total_issues+=$?))
    
    check_eeprom_config
    ((total_issues+=$?))
    
    check_filesystem_config
    ((total_issues+=$?))
    
    check_monitoring_system
    ((total_issues+=$?))
    
    check_current_storage
    
    check_hardware_compatibility
    
    # Show summary
    show_setup_summary $total_issues
    
    # Return appropriate exit code
    if [ $total_issues -eq 0 ]; then
        exit 0
    elif [ $total_issues -le 2 ]; then
        exit 1
    else
        exit 2
    fi
}

# Execute main function
main "$@"