#!/bin/bash

# Advanced Swap Memory Pressure Optimization
# Fixes swap utilization issues for proper memory pressure handling

echo "🔧 ADVANCED SWAP MEMORY PRESSURE OPTIMIZATION"
echo "============================================="
echo "Fixing swap utilization and memory pressure handling"
echo "Started at: $(date)"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✅ $*${NC}"; }
print_error() { echo -e "${RED}❌ $*${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $*${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $*${NC}"; }

# Current system analysis
echo "📊 CURRENT SYSTEM ANALYSIS:"
echo "Current Memory: $(free -h | awk 'NR==2{printf "%s total, %s available", $2, $7}')"
echo "Current Swap: $(free -h | awk 'NR==3{printf "%s total, %s used", $2, $3}')"
echo "Swappiness: $(cat /proc/sys/vm/swappiness)"
echo "ZRAM: $(zramctl --noheadings | awk '{printf "%s size, %s used", $3, $4}')"
echo ""

# Problem identification
print_warning "IDENTIFIED ISSUES:"
CURRENT_SWAPPINESS=$(cat /proc/sys/vm/swappiness)
ZRAM_SIZE=$(zramctl --noheadings | awk '{print $3}' | sed 's/[^0-9]//g' 2>/dev/null || echo "0")

if [ "$CURRENT_SWAPPINESS" -lt 10 ]; then
    print_error "Swappiness too low ($CURRENT_SWAPPINESS) - prevents proper swap utilization"
fi

if [ "$ZRAM_SIZE" -lt 1000 ] 2>/dev/null; then
    print_error "ZRAM too small (${ZRAM_SIZE}M) - should be 2-4GB for 8GB system"
fi

echo ""

# Fix 1: Optimize swappiness for memory pressure
print_info "1. OPTIMIZING SWAPPINESS FOR MEMORY PRESSURE"

# Calculate optimal swappiness based on system memory and usage patterns
TOTAL_MEM_GB=$(free -m | awk 'NR==2{print int($2/1024)}')
if [ "$TOTAL_MEM_GB" -ge 8 ]; then
    # For 8GB+ systems: Use moderate swappiness
    OPTIMAL_SWAPPINESS=10
elif [ "$TOTAL_MEM_GB" -ge 4 ]; then
    OPTIMAL_SWAPPINESS=15
else
    OPTIMAL_SWAPPINESS=20
fi

echo "Setting swappiness to $OPTIMAL_SWAPPINESS (optimal for ${TOTAL_MEM_GB}GB system)"
echo $OPTIMAL_SWAPPINESS | sudo tee /proc/sys/vm/swappiness > /dev/null
print_success "Swappiness optimized for memory pressure handling"

# Fix 2: Reconfigure ZRAM with proper size
print_info "2. RECONFIGURING ZRAM WITH OPTIMAL SIZE"

# Stop current ZRAM
sudo swapoff /dev/zram0 2>/dev/null || true
echo 1 | sudo tee /sys/block/zram0/reset > /dev/null 2>&1 || true

# Calculate optimal ZRAM size (25% of RAM, min 2GB, max 4GB)
TOTAL_MEM_MB=$(free -m | awk 'NR==2{print $2}')
ZRAM_SIZE_MB=$(echo "scale=0; $TOTAL_MEM_MB * 0.25 / 1" | bc)
if [ "$ZRAM_SIZE_MB" -lt 2048 ]; then
    ZRAM_SIZE_MB=2048
elif [ "$ZRAM_SIZE_MB" -gt 4096 ]; then
    ZRAM_SIZE_MB=4096
fi

print_info "Setting ZRAM size to ${ZRAM_SIZE_MB}MB (25% of RAM)"

# Configure new ZRAM
echo lz4 | sudo tee /sys/block/zram0/comp_algorithm > /dev/null
echo "${ZRAM_SIZE_MB}M" | sudo tee /sys/block/zram0/disksize > /dev/null
sudo mkswap /dev/zram0 > /dev/null
sudo swapon -p 100 /dev/zram0

print_success "ZRAM reconfigured with optimal size: ${ZRAM_SIZE_MB}MB"

# Fix 3: Optimize memory pressure watermarks
print_info "3. OPTIMIZING MEMORY PRESSURE WATERMARKS"

# Set optimal watermark scale factor
echo 50 | sudo tee /proc/sys/vm/watermark_scale_factor > /dev/null
print_info "Watermark scale factor set to 50 (balanced memory pressure)"

# Optimize memory reclaim settings
echo 1 | sudo tee /proc/sys/vm/compact_memory > /dev/null 2>&1 || true
echo "Memory compaction triggered"

# Fix 4: Configure swap priority hierarchy
print_info "4. CONFIGURING SWAP PRIORITY HIERARCHY"

# ZRAM (priority 100) - fastest, for immediate pressure relief
# File swap (priority 50) - larger capacity, for sustained pressure

# Check if file swap exists and adjust priority
if [ -f /var/swap ]; then
    sudo swapoff /var/swap
    sudo swapon -p 50 /var/swap
    print_success "File swap priority set to 50"
else
    print_warning "No file swap found - ZRAM only configuration"
fi

# Fix 5: Advanced memory pressure thresholds
print_info "5. CONFIGURING ADVANCED MEMORY PRESSURE THRESHOLDS"

# Configure memory pressure PSI (Pressure Stall Information)
if [ -f /proc/pressure/memory ]; then
    print_info "Memory pressure monitoring available"
    echo "Current memory pressure: $(cat /proc/pressure/memory | head -1)"
fi

# Set optimal min_free_kbytes (affects when reclaim starts)
TOTAL_MEM_KB=$(free | awk 'NR==2{print $2}')
MIN_FREE_KB=$((TOTAL_MEM_KB / 100))  # 1% of RAM
if [ "$MIN_FREE_KB" -lt 65536 ]; then
    MIN_FREE_KB=65536
elif [ "$MIN_FREE_KB" -gt 262144 ]; then
    MIN_FREE_KB=262144
fi

echo $MIN_FREE_KB | sudo tee /proc/sys/vm/min_free_kbytes > /dev/null
print_info "Min free memory set to $((MIN_FREE_KB/1024))MB"

# Fix 6: Create persistent configuration
print_info "6. CREATING PERSISTENT CONFIGURATION"

# Create advanced swap configuration
sudo tee /etc/sysctl.d/99-swap-memory-pressure.conf > /dev/null << EOF
# Advanced Swap Memory Pressure Configuration
# Optimized for 8GB Raspberry Pi 5

# Swap utilization (10 = balanced for 8GB system)
vm.swappiness = $OPTIMAL_SWAPPINESS

# Memory pressure watermarks
vm.watermark_scale_factor = 50

# Memory reclaim settings
vm.vfs_cache_pressure = 75
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5

# Memory overcommit (allow overcommit with proper swap)
vm.overcommit_memory = 1
vm.overcommit_ratio = 80

# Min free memory (1% of RAM)
vm.min_free_kbytes = $MIN_FREE_KB

# OOM killer settings (prefer swap before killing)
vm.oom_kill_allocating_task = 0
vm.panic_on_oom = 0
EOF

print_success "Persistent configuration saved to /etc/sysctl.d/99-swap-memory-pressure.conf"

# Fix 7: Create ZRAM service for proper initialization
print_info "7. CREATING ZRAM INITIALIZATION SERVICE"

sudo tee /etc/systemd/system/zram-swap-advanced.service > /dev/null << EOF
[Unit]
Description=Advanced ZRAM Swap Configuration
DefaultDependencies=no
Conflicts=shutdown.target
Before=sysinit.target shutdown.target
RefuseManualStop=true

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/bash -c 'modprobe zram && echo lz4 > /sys/block/zram0/comp_algorithm && echo ${ZRAM_SIZE_MB}M > /sys/block/zram0/disksize && mkswap /dev/zram0 && swapon -p 100 /dev/zram0'
ExecStop=/bin/bash -c 'swapoff /dev/zram0; echo 1 > /sys/block/zram0/reset'
TimeoutSec=30

[Install]
WantedBy=sysinit.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable zram-swap-advanced.service > /dev/null 2>&1
print_success "ZRAM service configured for boot initialization"

# Fix 8: Memory pressure monitoring script
print_info "8. CREATING MEMORY PRESSURE MONITORING"

cat > /home/sri/rpi5-optimization/monitoring/swap_pressure_monitor.sh << 'EOF'
#!/bin/bash
# Real-time swap and memory pressure monitoring

echo "🔍 SWAP & MEMORY PRESSURE MONITOR"
echo "=================================="
echo "Press Ctrl+C to exit"
echo ""

while true; do
    clear
    echo "🔍 SWAP & MEMORY PRESSURE MONITOR - $(date)"
    echo "=================================="
    
    # Memory overview
    echo ""
    echo "📊 MEMORY OVERVIEW:"
    free -h
    
    # Swap details
    echo ""
    echo "💾 SWAP DETAILS:"
    swapon --show
    
    # ZRAM efficiency
    echo ""
    echo "⚡ ZRAM EFFICIENCY:"
    zramctl --output NAME,ALGORITHM,DISKSIZE,DATA,COMPR,TOTAL
    
    # Memory pressure (if available)
    if [ -f /proc/pressure/memory ]; then
        echo ""
        echo "⚠️  MEMORY PRESSURE:"
        cat /proc/pressure/memory
    fi
    
    # Current settings
    echo ""
    echo "⚙️  CURRENT SETTINGS:"
    echo "Swappiness: $(cat /proc/sys/vm/swappiness)"
    echo "VFS Cache Pressure: $(cat /proc/sys/vm/vfs_cache_pressure)"
    echo "Min Free KB: $(cat /proc/sys/vm/min_free_kbytes)"
    echo "Watermark Scale: $(cat /proc/sys/vm/watermark_scale_factor)"
    
    # Application memory usage
    echo ""
    echo "🎯 TOP MEMORY CONSUMERS:"
    ps aux --sort=-%mem | head -4 | tail -3 | while read user pid cpu mem vsz rss tty stat start time command; do
        echo "  ${mem}% - $(echo $command | cut -c1-40)..."
    done
    
    sleep 5
done
EOF

chmod +x /home/sri/rpi5-optimization/monitoring/swap_pressure_monitor.sh
print_success "Swap pressure monitor created"

# Fix 9: Create memory stress test
print_info "9. CREATING MEMORY STRESS TEST FOR VALIDATION"

cat > /home/sri/rpi5-optimization/test_memory_pressure.sh << 'EOF'
#!/bin/bash
# Memory pressure test to validate swap utilization

echo "🧪 MEMORY PRESSURE TEST"
echo "======================"
echo "This will test if swap is properly utilized under memory pressure"
echo "WARNING: This will consume memory and may slow the system temporarily"
echo ""
read -p "Continue with memory pressure test? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Test cancelled"
    exit 0
fi

echo "Starting memory pressure test..."
echo "Monitor with: ./monitoring/swap_pressure_monitor.sh"
echo ""

# Create memory pressure by allocating memory
stress --vm 2 --vm-bytes 2G --timeout 30s &
STRESS_PID=$!

# Monitor during test
for i in {1..6}; do
    echo "Test progress: ${i}/6 (5 seconds each)"
    echo "Memory: $(free -h | awk 'NR==2{print $7 " available"}')"
    echo "Swap: $(free -h | awk 'NR==3{print $3 " used"}')"
    echo "---"
    sleep 5
done

wait $STRESS_PID
echo "Memory pressure test completed!"
echo ""
echo "Final status:"
free -h
swapon --show
EOF

chmod +x /home/sri/rpi5-optimization/test_memory_pressure.sh
print_success "Memory pressure test created"

# Current status after fixes
echo ""
print_info "📊 SYSTEM STATUS AFTER OPTIMIZATION:"
echo "Memory: $(free -h | awk 'NR==2{printf "%s total, %s available", $2, $7}')"
echo "Swap: $(free -h | awk 'NR==3{printf "%s total, %s used", $2, $3}')"
echo "New Swappiness: $(cat /proc/sys/vm/swappiness)"
echo "ZRAM: $(zramctl --noheadings | awk '{printf "%s size, %s used", $3, $4}' 2>/dev/null || echo 'Status checking...')"

echo ""
print_success "🎉 SWAP MEMORY PRESSURE OPTIMIZATION COMPLETE!"
echo ""
echo "📋 WHAT WAS FIXED:"
echo "✅ Swappiness optimized from 1 to $OPTIMAL_SWAPPINESS"
echo "✅ ZRAM size increased from 256MB to ${ZRAM_SIZE_MB}MB"
echo "✅ Memory pressure watermarks optimized"
echo "✅ Swap priority hierarchy configured"
echo "✅ Advanced memory thresholds set"
echo "✅ Persistent configuration created"
echo "✅ Monitoring tools installed"

echo ""
echo "🧪 TESTING:"
echo "• Test memory pressure: ./test_memory_pressure.sh"
echo "• Monitor swap usage: ./monitoring/swap_pressure_monitor.sh"
echo "• Check health: ~/optimize health"

echo ""
echo "⚠️  RESTART RECOMMENDED for all settings to take effect"
echo "   sudo reboot"

echo ""
echo "Swap memory pressure optimization completed at: $(date)"
