#!/bin/bash
# =================================================================
# RASPBERRY PI 5 COMPLETE ROLLBACK SCRIPT
# =================================================================
# Reverts all optimizations back to stock settings
# 
# Author: Community Contribution
# License: MIT
# =================================================================

set -euo pipefail

# Configuration files
CONFIG_FILE="/boot/firmware/config.txt"
BACKUP_FILE="/boot/firmware/config.txt.backup"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_banner() {
    echo -e "${RED}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║               🔄 COMPLETE SYSTEM ROLLBACK                      ║"
    echo "║                                                                ║"
    echo "║   This will revert ALL optimizations back to stock settings   ║"
    echo "║   • CPU: 2800MHz → 2400MHz (stock)                            ║"
    echo "║   • GPU: All overclocks removed                               ║"
    echo "║   • Dual Monitor: Optimizations removed                       ║"
    echo "║                                                                ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

check_prerequisites() {
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}❌ This script must be run as root (use sudo)${NC}"
        exit 1
    fi
    
    # Check if backup exists
    if [[ ! -f "$BACKUP_FILE" ]]; then
        echo -e "${RED}❌ Backup file not found: $BACKUP_FILE${NC}"
        echo "Cannot perform rollback without original backup."
        echo ""
        echo "Emergency recovery options:"
        echo "1. Restore from SD card on another computer"
        echo "2. Flash fresh Raspberry Pi OS image"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Prerequisites check passed${NC}"
}

create_pre_rollback_backup() {
    echo -e "${BLUE}📂 Creating pre-rollback backup...${NC}"
    cp "$CONFIG_FILE" "/boot/firmware/config.txt.pre-rollback-$(date +%Y%m%d_%H%M%S)"
    echo -e "${GREEN}✅ Pre-rollback backup created${NC}"
}

perform_rollback() {
    echo -e "${BLUE}🔄 Restoring original configuration...${NC}"
    
    # Restore from backup
    cp "$BACKUP_FILE" "$CONFIG_FILE"
    
    echo -e "${GREEN}✅ Configuration restored from backup${NC}"
}

show_rollback_summary() {
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                      📊 ROLLBACK SUMMARY                       ║"
    echo "╠════════════════════════════════════════════════════════════════╣"
    echo "║                                                                ║"
    echo "║  🔄 REVERTED CHANGES:                                          ║"
    echo "║                                                                ║"
    echo "║  ❌ CPU Overclocking: 2800MHz → 2400MHz (stock)               ║"
    echo "║  ❌ GPU Overclocking: All boosts removed                      ║"
    echo "║  ❌ GPU Memory: 512MB → 8MB (stock)                           ║"
    echo "║  ❌ Voltage Boosts: All removed                               ║"
    echo "║  ❌ Dual Monitor Optimizations: All removed                   ║"
    echo "║                                                                ║"
    echo "║  ⚠️  WARNING: Dual monitor support may be reduced             ║"
    echo "║                                                                ║"
    echo "║  📁 BACKUPS PRESERVED:                                        ║"
    echo "║    • Pre-rollback backup created                              ║"
    echo "║    • Original backup maintained                               ║"
    echo "║                                                                ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

main() {
    print_banner
    
    echo -e "${YELLOW}⚠️  WARNING: This will remove ALL performance optimizations${NC}"
    echo "• CPU will return to stock 2400MHz"
    echo "• GPU optimizations will be removed"
    echo "• Dual monitor blank screen issue may return"
    echo "• System will return to original performance levels"
    echo ""
    
    read -p "Are you sure you want to proceed? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Rollback cancelled."
        exit 0
    fi
    
    echo -e "${BLUE}🔄 Starting rollback process...${NC}"
    
    check_prerequisites
    create_pre_rollback_backup
    perform_rollback
    
    show_rollback_summary
    
    echo -e "${GREEN}🎉 Rollback completed successfully!${NC}"
    
    echo ""
    echo -e "${YELLOW}📋 NEXT STEPS:${NC}"
    echo "1. Reboot your system: sudo reboot"
    echo "2. Verify stock settings after reboot"
    echo "3. Re-apply optimizations if needed: sudo ./scripts/apply_optimizations.sh"
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