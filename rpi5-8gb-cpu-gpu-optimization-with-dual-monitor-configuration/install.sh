#!/bin/bash
# =================================================================
# RASPBERRY PI 5 OPTIMIZATION - ONE-COMMAND INSTALLER
# =================================================================
# Quick installer that applies optimizations in one command
# 
# Usage: curl -fsSL https://raw.githubusercontent.com/USER/REPO/main/install.sh | bash
# =================================================================

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

REPO_URL="https://github.com/YOUR_USERNAME/rpi5-8gb-cpu-gpu-optimization-with-dual-monitor-configuration.git"
INSTALL_DIR="$HOME/rpi5-optimization"

print_banner() {
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║        🚀 Raspberry Pi 5 Optimization - Quick Installer       ║"
    echo "║                                                                ║"
    echo "║  This installer will:                                          ║"
    echo "║  • Download the optimization repository                        ║"
    echo "║  • Install required dependencies                               ║"
    echo "║  • Apply CPU/GPU optimizations                                 ║"
    echo "║  • Fix dual monitor blank screen issue                         ║"
    echo "║  • Create automatic backups                                    ║"
    echo "║                                                                ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

check_prerequisites() {
    echo -e "${BLUE}🔍 Checking prerequisites...${NC}"
    
    # Check Pi 5
    if ! grep -q "Raspberry Pi 5" /proc/cpuinfo 2>/dev/null; then
        echo -e "${RED}❌ This installer is for Raspberry Pi 5 only${NC}"
        exit 1
    fi
    
    # Check if git is installed
    if ! command -v git &> /dev/null; then
        echo -e "${YELLOW}📦 Installing git...${NC}"
        sudo apt update && sudo apt install -y git
    fi
    
    echo -e "${GREEN}✅ Prerequisites check passed${NC}"
}

download_repository() {
    echo -e "${BLUE}📥 Downloading optimization repository...${NC}"
    
    if [[ -d "$INSTALL_DIR" ]]; then
        echo -e "${YELLOW}⚠️  Directory exists, updating...${NC}"
        cd "$INSTALL_DIR"
        git pull
    else
        git clone "$REPO_URL" "$INSTALL_DIR"
        cd "$INSTALL_DIR"
    fi
    
    chmod +x scripts/*.sh
    echo -e "${GREEN}✅ Repository downloaded${NC}"
}

install_dependencies() {
    echo -e "${BLUE}📦 Installing dependencies...${NC}"
    
    # Install stress-ng for testing
    if ! command -v stress-ng &> /dev/null; then
        sudo apt update && sudo apt install -y stress-ng bc
    fi
    
    echo -e "${GREEN}✅ Dependencies installed${NC}"
}

apply_optimizations() {
    echo -e "${BLUE}🚀 Applying optimizations...${NC}"
    
    # Run the main optimization script
    sudo ./scripts/apply_optimizations.sh
    
    echo -e "${GREEN}✅ Optimizations applied${NC}"
}

show_completion() {
    echo -e "${GREEN}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                   🎉 INSTALLATION COMPLETE!                   ║"
    echo "╠════════════════════════════════════════════════════════════════╣"
    echo "║                                                                ║"
    echo "║  Your Raspberry Pi 5 has been optimized with:                 ║"
    echo "║  • CPU overclocked to 2800MHz (+17% performance)              ║"
    echo "║  • GPU optimized for better graphics performance              ║"
    echo "║  • Dual monitor support enabled                               ║"
    echo "║  • Automatic backups created                                  ║"
    echo "║                                                                ║"
    echo "║  Next steps:                                                   ║"
    echo "║  1. Reboot your system: sudo reboot                           ║"
    echo "║  2. Test optimizations: ./scripts/system_health.sh            ║"
    echo "║  3. Connect dual monitors and verify they work                ║"
    echo "║                                                                ║"
    echo "║  Emergency rollback: sudo ./scripts/rollback_all.sh           ║"
    echo "║                                                                ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

main() {
    print_banner
    
    echo -e "${YELLOW}⚠️  WARNING: This will modify your system configuration${NC}"
    echo "This installer will apply CPU/GPU overclocking and dual monitor optimizations."
    echo ""
    
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled."
        exit 0
    fi
    
    check_prerequisites
    download_repository
    install_dependencies
    apply_optimizations
    show_completion
    
    echo ""
    read -p "🔄 Reboot now to apply all changes? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}🔄 Rebooting in 3 seconds...${NC}"
        sleep 3
        sudo reboot
    else
        echo -e "${YELLOW}⚠️  Remember to reboot: sudo reboot${NC}"
    fi
}

# Handle script being piped from curl
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi