#!/bin/bash
# Data Collection Script for AI Agent Analysis
# Gathers all relevant information for PCIe boot troubleshooting

OUTPUT_DIR="/home/sri/ai-analysis-data"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
REPORT_FILE="$OUTPUT_DIR/boot-analysis-${TIMESTAMP}.md"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Start the report
cat > "$REPORT_FILE" << 'EOF'
# PCIe Boot Analysis Data

**Generated**: $(date)
**System**: Raspberry Pi 5 with NVMe PCIe boot attempt

## Quick Status Summary

EOF

# Add quick status
echo '```' >> "$REPORT_FILE"
./boot-status.sh >> "$REPORT_FILE" 2>&1
echo '```' >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# Configuration status
cat >> "$REPORT_FILE" << 'EOF'
## Current Configuration

### PCIe Configuration in config.txt
```bash
EOF

echo "$ tail -10 /boot/firmware/config.txt" >> "$REPORT_FILE"
tail -10 /boot/firmware/config.txt >> "$REPORT_FILE"

cat >> "$REPORT_FILE" << 'EOF'
```

### EEPROM Boot Configuration
```bash
EOF

echo "$ rpi-eeprom-config" >> "$REPORT_FILE"
rpi-eeprom-config >> "$REPORT_FILE" 2>&1

cat >> "$REPORT_FILE" << 'EOF'
```

### Kernel Command Line
```bash
EOF

echo "$ cat /boot/firmware/cmdline.txt" >> "$REPORT_FILE"
cat /boot/firmware/cmdline.txt >> "$REPORT_FILE"

cat >> "$REPORT_FILE" << 'EOF'
```

## Hardware Detection Status

### Current Storage Devices
```bash
EOF

echo "$ lsblk -f" >> "$REPORT_FILE"
lsblk -f >> "$REPORT_FILE"

cat >> "$REPORT_FILE" << 'EOF'
```

### PCI Devices
```bash
EOF

echo "$ lspci -v" >> "$REPORT_FILE"
lspci -v >> "$REPORT_FILE" 2>/dev/null || echo "No PCIe devices detected" >> "$REPORT_FILE"

cat >> "$REPORT_FILE" << 'EOF'
```

### Device Files
```bash
EOF

echo "$ ls -la /dev/nvme* /dev/sd*" >> "$REPORT_FILE"
ls -la /dev/nvme* /dev/sd* 2>/dev/null >> "$REPORT_FILE"

cat >> "$REPORT_FILE" << 'EOF'
```

## Boot Log Analysis

### Latest Boot Log Available
EOF

if [[ -f "/var/log/boot-monitor/latest.log" ]]; then
    echo "✅ Boot log found: $(stat -c %y /var/log/boot-monitor/latest.log | cut -d. -f1)" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    # PCIe related messages
    cat >> "$REPORT_FILE" << 'EOF'

### PCIe Detection Messages
```
EOF
    
    echo "$ grep -i 'pcie\|nvme' /var/log/boot-monitor/latest.log" >> "$REPORT_FILE"
    grep -i 'pcie\|nvme' /var/log/boot-monitor/latest.log >> "$REPORT_FILE" 2>/dev/null || echo "No PCIe/NVMe messages found" >> "$REPORT_FILE"
    
    # Error messages
    cat >> "$REPORT_FILE" << 'EOF'
```

### Error Messages
```
EOF
    
    echo "$ grep -i 'error\|fail\|timeout' /var/log/boot-monitor/latest.log" >> "$REPORT_FILE"
    grep -i 'error\|fail\|timeout' /var/log/boot-monitor/latest.log >> "$REPORT_FILE" 2>/dev/null || echo "No error messages found" >> "$REPORT_FILE"
    
    # Storage detection
    cat >> "$REPORT_FILE" << 'EOF'
```

### Storage Detection Messages
```
EOF
    
    echo "$ grep -E '(sda|nvme|mount|partition)' /var/log/boot-monitor/latest.log | head -20" >> "$REPORT_FILE"
    grep -E '(sda|nvme|mount|partition)' /var/log/boot-monitor/latest.log | head -20 >> "$REPORT_FILE" 2>/dev/null
    
    cat >> "$REPORT_FILE" << 'EOF'
```

### Filesystem Health Messages
```
EOF
    
    echo "$ grep -i 'ext4\|journal\|fsck' /var/log/boot-monitor/latest.log" >> "$REPORT_FILE"
    grep -i 'ext4\|journal\|fsck' /var/log/boot-monitor/latest.log >> "$REPORT_FILE" 2>/dev/null || echo "No filesystem messages found" >> "$REPORT_FILE"
    
    echo '```' >> "$REPORT_FILE"
    
else
    echo "❌ No boot log available" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "**Action needed**: Run 'sudo systemctl start boot-monitor.service' or reboot to generate logs" >> "$REPORT_FILE"
fi

# System information
cat >> "$REPORT_FILE" << 'EOF'

## System Information

### Kernel and OS
```bash
EOF

echo "$ uname -a" >> "$REPORT_FILE"
uname -a >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "$ cat /etc/os-release | head -5" >> "$REPORT_FILE"
cat /etc/os-release | head -5 >> "$REPORT_FILE"

# Service status
cat >> "$REPORT_FILE" << 'EOF'
```

### Boot Monitor Service Status
```bash
EOF

echo "$ systemctl is-enabled boot-monitor.service" >> "$REPORT_FILE"
systemctl is-enabled boot-monitor.service >> "$REPORT_FILE" 2>&1

echo "$ ls -la /forcefsck" >> "$REPORT_FILE"
ls -la /forcefsck >> "$REPORT_FILE" 2>/dev/null || echo "/forcefsck not present" >> "$REPORT_FILE"

cat >> "$REPORT_FILE" << 'EOF'
```

## Filesystem Status

### Current Mounts
```bash
EOF

echo "$ mount | grep -E '(sda|nvme|ext4)'" >> "$REPORT_FILE"
mount | grep -E '(sda|nvme|ext4)' >> "$REPORT_FILE"

cat >> "$REPORT_FILE" << 'EOF'
```

### Disk Usage
```bash
EOF

echo "$ df -h /" >> "$REPORT_FILE"
df -h / >> "$REPORT_FILE"

cat >> "$REPORT_FILE" << 'EOF'
```

### Recent Kernel Messages
```bash
EOF

echo "$ dmesg | tail -30" >> "$REPORT_FILE"
dmesg | tail -30 >> "$REPORT_FILE" 2>/dev/null

cat >> "$REPORT_FILE" << 'EOF'
```

---

## AI Analysis Instructions

Please analyze this data using the guidelines in `ai-warp-analysis.md` and provide:

1. **Boot Status Assessment**: SUCCESS/PARTIAL/FAILED
2. **Hardware Detection Status**: PCIe bridge, NVMe controller, storage device
3. **Primary Issues Identified**: Root cause analysis
4. **Recommended Actions**: Step-by-step troubleshooting
5. **Next Steps**: What to try next if this fails

Focus on:
- PCIe detection and enumeration
- NVMe device recognition  
- Filesystem integrity
- Boot configuration accuracy
- Hardware connection issues

EOF

# Create a copy with timestamp
cp "$REPORT_FILE" "$OUTPUT_DIR/latest-analysis.md"

# Set permissions
chmod 644 "$REPORT_FILE" "$OUTPUT_DIR/latest-analysis.md"

echo "Analysis data collected and saved to:"
echo "  Primary: $REPORT_FILE" 
echo "  Latest:  $OUTPUT_DIR/latest-analysis.md"
echo ""
echo "This file contains all data needed for AI agent analysis."
echo "Share this file with the AI agent along with ai-warp-analysis.md"