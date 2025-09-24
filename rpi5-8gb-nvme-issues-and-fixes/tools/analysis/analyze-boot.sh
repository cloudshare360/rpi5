#!/bin/bash
# Boot Log Analyzer - Real-time analysis script for Warp
# Helps quickly identify boot issues and PCIe problems

LOG_DIR="/var/log/boot-monitor"
LATEST_LOG="$LOG_DIR/latest.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}🔍 BOOT LOG ANALYZER${NC}"
    echo -e "${BLUE}================================${NC}"
    echo ""
}

check_latest_log() {
    if [[ -f "$LATEST_LOG" ]]; then
        echo -e "${GREEN}✅ Latest boot log found: $LATEST_LOG${NC}"
        echo -e "${BLUE}Boot time:${NC} $(stat -c %y "$LATEST_LOG" | cut -d. -f1)"
        echo ""
    else
        echo -e "${RED}❌ No boot log found. Run 'sudo systemctl start boot-monitor.service' or reboot.${NC}"
        exit 1
    fi
}

analyze_pcie() {
    echo -e "${YELLOW}🔌 PCIe Analysis:${NC}"
    echo "----------------------------------------"
    
    if grep -q "nvme" "$LATEST_LOG"; then
        echo -e "${GREEN}✅ NVMe devices detected${NC}"
        grep -A5 -B5 "nvme" "$LATEST_LOG" | head -20
    else
        echo -e "${RED}❌ No NVMe devices found${NC}"
    fi
    
    if grep -q "pcie" "$LATEST_LOG"; then
        echo -e "${GREEN}✅ PCIe messages found${NC}"
        grep -i "pcie" "$LATEST_LOG" | head -10
    else
        echo -e "${YELLOW}⚠️ No PCIe messages in log${NC}"
    fi
    echo ""
}

analyze_storage() {
    echo -e "${YELLOW}💾 Storage Analysis:${NC}"
    echo "----------------------------------------"
    
    # Check for storage device detection
    if grep -q "sda\|nvme" "$LATEST_LOG"; then
        echo -e "${GREEN}✅ Storage devices detected:${NC}"
        grep -E "(sda|nvme)" "$LATEST_LOG" | grep -v "grep" | head -10
    else
        echo -e "${RED}❌ No storage devices found${NC}"
    fi
    echo ""
}

analyze_errors() {
    echo -e "${YELLOW}⚠️ Error Analysis:${NC}"
    echo "----------------------------------------"
    
    # Check for filesystem errors
    if grep -qi "ext4.*error\|journal.*abort" "$LATEST_LOG"; then
        echo -e "${RED}❌ EXT4/Journal errors found:${NC}"
        grep -i "ext4.*error\|journal.*abort" "$LATEST_LOG"
        echo ""
    else
        echo -e "${GREEN}✅ No EXT4 errors detected${NC}"
    fi
    
    # Check for general errors
    ERROR_COUNT=$(grep -i "error\|fail" "$LATEST_LOG" | wc -l)
    if [[ $ERROR_COUNT -gt 0 ]]; then
        echo -e "${YELLOW}⚠️ Found $ERROR_COUNT error/fail messages:${NC}"
        grep -i "error\|fail" "$LATEST_LOG" | head -10
    else
        echo -e "${GREEN}✅ No critical errors found${NC}"
    fi
    echo ""
}

show_boot_summary() {
    echo -e "${YELLOW}📊 Boot Summary:${NC}"
    echo "----------------------------------------"
    
    # System info
    echo -e "${BLUE}System:${NC} $(grep -A1 "System Information" "$LATEST_LOG" | tail -1 || echo "Unknown")"
    
    # Uptime
    UPTIME=$(grep -A1 "System Uptime" "$LATEST_LOG" | tail -1 | grep -v "Command" || echo "Unknown")
    echo -e "${BLUE}Uptime:${NC} $UPTIME"
    
    # Storage mounts
    echo -e "${BLUE}Root mount:${NC}"
    grep -A5 "Storage Mounts" "$LATEST_LOG" | grep -E "(sda|nvme)" | head -1 || echo "Not found"
    
    echo ""
}

# Interactive menu
show_menu() {
    echo -e "${BLUE}Options:${NC}"
    echo "1. Show full log"
    echo "2. Watch log in real-time (tail -f)"
    echo "3. Search for specific term"
    echo "4. Show last 50 lines"
    echo "5. Export summary to file"
    echo "q. Quit"
    echo ""
}

# Main execution
print_header
check_latest_log
show_boot_summary
analyze_pcie
analyze_storage
analyze_errors

# Interactive mode
while true; do
    show_menu
    read -p "Choose an option: " choice
    
    case $choice in
        1)
            echo -e "${BLUE}Full boot log:${NC}"
            echo "========================================"
            cat "$LATEST_LOG"
            ;;
        2)
            echo -e "${BLUE}Watching log in real-time (Ctrl+C to stop):${NC}"
            tail -f "$LATEST_LOG"
            ;;
        3)
            read -p "Enter search term: " term
            echo -e "${BLUE}Searching for '$term':${NC}"
            grep -i "$term" "$LATEST_LOG" || echo "No matches found"
            ;;
        4)
            echo -e "${BLUE}Last 50 lines:${NC}"
            tail -50 "$LATEST_LOG"
            ;;
        5)
            SUMMARY_FILE="/home/sri/boot-summary-$(date +%Y%m%d_%H%M%S).txt"
            {
                echo "Boot Analysis Summary - $(date)"
                echo "========================================"
                echo ""
                show_boot_summary
                analyze_pcie
                analyze_storage
                analyze_errors
            } > "$SUMMARY_FILE"
            echo -e "${GREEN}✅ Summary exported to: $SUMMARY_FILE${NC}"
            ;;
        q|Q)
            echo "Goodbye!"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option. Please try again.${NC}"
            ;;
    esac
    echo ""
    read -p "Press Enter to continue..."
    clear
    print_header
done