#!/bin/bash

# Emergency System Performance Fix
# Diagnoses and fixes system slowdowns

echo "🚨 EMERGENCY SYSTEM PERFORMANCE FIX"
echo "===================================="
echo "Started at: $(date)"
echo ""

# Function to check memory pressure
check_memory_pressure() {
    local available_mem=$(free -m | awk 'NR==2{print $7}')
    local swap_used=$(free -m | awk 'NR==3{print $3}')
    
    if [ "$available_mem" -lt 1000 ]; then
        echo "⚠️  CRITICAL: Low available memory (${available_mem}MB)"
        return 2
    elif [ "$available_mem" -lt 2000 ]; then
        echo "⚠️  WARNING: Moderate memory pressure (${available_mem}MB)"
        return 1
    else
        echo "✅ Memory OK: ${available_mem}MB available"
        return 0
    fi
}

# Function to identify memory hogs
identify_memory_hogs() {
    echo ""
    echo "🔍 TOP MEMORY CONSUMERS:"
    ps aux --sort=-%mem | head -6 | tail -5 | while read user pid cpu mem vsz rss tty stat start time command; do
        echo "  ${mem}% RAM (${rss}KB) - $(echo $command | cut -c1-50)..."
    done
}

# Function to identify CPU hogs
identify_cpu_hogs() {
    echo ""
    echo "🔥 TOP CPU CONSUMERS:"
    ps aux --sort=-%cpu | head -6 | tail -5 | while read user pid cpu mem vsz rss tty stat start time command; do
        if (( $(echo "$cpu > 1.0" | bc -l) )); then
            echo "  ${cpu}% CPU - $(echo $command | cut -c1-50)..."
        fi
    done
}

# Initial system status
echo "📊 SYSTEM STATUS:"
uptime
echo ""
check_memory_pressure
memory_status=$?

identify_memory_hogs
identify_cpu_hogs

echo ""
echo "🛠️  APPLYING FIXES:"

# Fix 1: Clear system caches
echo "1. Clearing system caches..."
sudo sysctl vm.drop_caches=3 > /dev/null
echo "   ✅ System caches cleared"

# Fix 2: Optimize memory pressure settings
echo "2. Optimizing memory pressure settings..."
echo 1 | sudo tee /proc/sys/vm/swappiness > /dev/null
echo 10 | sudo tee /proc/sys/vm/dirty_ratio > /dev/null
echo 5 | sudo tee /proc/sys/vm/dirty_background_ratio > /dev/null
echo 30 | sudo tee /proc/sys/vm/vfs_cache_pressure > /dev/null
echo "   ✅ Memory pressure settings optimized"

# Fix 3: Kill problematic processes if needed
echo "3. Checking for problematic processes..."

# Check for runaway processes
RUNAWAY_PROCESSES=$(ps aux --sort=-%cpu | awk 'NR>1 && $3>50' | wc -l)
if [ "$RUNAWAY_PROCESSES" -gt 0 ]; then
    echo "   ⚠️  Found $RUNAWAY_PROCESSES high-CPU processes"
    ps aux --sort=-%cpu | awk 'NR>1 && $3>50 {print "   Kill high CPU process? PID=" $2 " (" $3 "% CPU): " $11}'
else
    echo "   ✅ No runaway CPU processes found"
fi

# Fix 4: Optimize for current applications
echo "4. Optimizing for running applications..."

# Check if Teams is running and consuming too much
TEAMS_MEM=$(ps aux | grep teams-for-linux | grep -v grep | awk '{print $6}' | head -1)
if [ -n "$TEAMS_MEM" ] && [ "$TEAMS_MEM" -gt 500000 ]; then
    echo "   ⚠️  Teams is using high memory ($(echo $TEAMS_MEM/1024 | bc)MB)"
    echo "   💡 Consider restarting Teams if it's sluggish"
fi

# Check Chrome memory usage
CHROME_TOTAL_MEM=$(ps aux | grep chromium | grep -v grep | awk '{sum+=$6} END {print sum/1024}' 2>/dev/null || echo "0")
if (( $(echo "$CHROME_TOTAL_MEM > 1000" | bc -l) )); then
    echo "   ⚠️  Chrome using high memory (${CHROME_TOTAL_MEM}MB total)"
    CHROME_TABS=$(ps aux | grep chromium | grep renderer | wc -l)
    echo "   💡 Chrome has ~$CHROME_TABS renderer processes (tabs/extensions)"
fi

echo "   ✅ Application analysis complete"

# Fix 5: Enable ZRAM if not already active
echo "5. Checking ZRAM status..."
if systemctl is-active --quiet zramswap; then
    echo "   ✅ ZRAM is active"
else
    echo "   ⚠️  ZRAM not active, enabling..."
    sudo systemctl start zramswap
    echo "   ✅ ZRAM started"
fi

# Fix 6: Temporary performance boost
echo "6. Applying temporary performance boost..."
# Increase I/O scheduler performance
for device in /sys/block/nvme*/queue/scheduler; do
    if [ -f "$device" ]; then
        echo none | sudo tee "$device" > /dev/null
    fi
done
echo "   ✅ I/O schedulers optimized"

echo ""
echo "🔄 POST-FIX SYSTEM STATUS:"
uptime
free -h
echo ""

# Post-fix analysis
check_memory_pressure
new_memory_status=$?

# Improvement calculation
if [ $new_memory_status -lt $memory_status ]; then
    echo "✅ IMPROVEMENT: Memory pressure reduced"
elif [ $new_memory_status -eq $memory_status ]; then
    echo "➡️  STABLE: Memory status unchanged"
else
    echo "⚠️  CONCERN: Memory pressure may have increased"
fi

echo ""
echo "💡 RECOMMENDATIONS:"

# Check current load
LOAD_AVG=$(uptime | awk -F'load average:' '{print $2}' | awk -F',' '{print $1}' | xargs)
if (( $(echo "$LOAD_AVG > 4.0" | bc -l) )); then
    echo "• System load is high ($LOAD_AVG). Consider closing some applications."
else
    echo "• System load is acceptable ($LOAD_AVG)"
fi

# Memory recommendations
AVAILABLE_MEM=$(free -m | awk 'NR==2{print $7}')
if [ "$AVAILABLE_MEM" -lt 1500 ]; then
    echo "• Available memory is low (${AVAILABLE_MEM}MB). Consider:"
    echo "  - Closing browser tabs"
    echo "  - Restarting memory-heavy applications"
    echo "  - Using lightweight alternatives"
fi

# Swap recommendations  
SWAP_USED=$(free -m | awk 'NR==3{print $3}')
if [ "$SWAP_USED" -gt 200 ]; then
    echo "• Swap usage is high (${SWAP_USED}MB). System may feel sluggish."
    echo "  - Consider closing applications to free RAM"
fi

echo ""
echo "🛠️  AVAILABLE TOOLS:"
echo "• Monitor Chrome: ./chrome_monitor.sh"
echo "• Monitor system: htop"
echo "• Monitor I/O: sudo iotop"
echo "• Emergency cleanup: sudo sysctl vm.drop_caches=3"
echo ""
echo "Emergency fix completed at: $(date)"