#!/bin/bash
# Quick Boot Status - Instant overview for Warp analysis

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
    NVME_INFO=$(grep -i "nvme" "$LOG_FILE" | head -1)
    echo "   $NVME_INFO"
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

echo ""
echo "For detailed analysis, run: ./analyze-boot.sh"