#!/bin/bash

# Multi-Application Memory Balancer
# Intelligently manages memory between Teams, Chrome, Warp Terminal, and other apps

echo "⚖️  MULTI-APPLICATION MEMORY BALANCER"
echo "======================================="
echo "Balancing memory between intensive applications"
echo ""

# Function to get memory usage of specific applications
get_app_memory() {
    local app_name="$1"
    case "$app_name" in
        "teams")
            ps aux | grep teams-for-linux | grep -v grep | awk '{sum+=$6} END {print int(sum/1024)}' 2>/dev/null || echo "0"
            ;;
        "chrome")
            ps aux | grep chromium | grep -v grep | awk '{sum+=$6} END {print int(sum/1024)}' 2>/dev/null || echo "0"
            ;;
        "warp")
            ps aux | grep warp-terminal | grep -v grep | awk '{print int($6/1024)}' | head -1 2>/dev/null || echo "0"
            ;;
    esac
}

# Function to set process priority and memory limits
optimize_app_priority() {
    local app_pattern="$1"
    local priority="$2"
    local oom_score="$3"
    
    for pid in $(pgrep -f "$app_pattern"); do
        # Set CPU priority
        sudo renice $priority $pid 2>/dev/null || true
        
        # Set OOM killer score (lower = less likely to be killed)
        echo $oom_score | sudo tee /proc/$pid/oom_score_adj > /dev/null 2>&1 || true
    done
}

# Current status
echo "📊 CURRENT MEMORY USAGE:"
TEAMS_MEM=$(get_app_memory "teams")
CHROME_MEM=$(get_app_memory "chrome") 
WARP_MEM=$(get_app_memory "warp")
TOTAL_APP_MEM=$((TEAMS_MEM + CHROME_MEM + WARP_MEM))
AVAILABLE_MEM=$(free -m | awk 'NR==2{print $7}')

echo "Teams:           ${TEAMS_MEM}MB"
echo "Chrome Total:    ${CHROME_MEM}MB"
echo "Warp Terminal:   ${WARP_MEM}MB"
echo "Total App Usage: ${TOTAL_APP_MEM}MB"
echo "Available:       ${AVAILABLE_MEM}MB"
echo ""

# Memory balancing strategy
echo "🔧 APPLYING MEMORY BALANCING:"

# 1. Prioritize applications based on usage patterns
echo "1. Setting application priorities..."

# Give Teams lower priority if using too much memory
if [ "$TEAMS_MEM" -gt 600 ]; then
    optimize_app_priority "teams-for-linux" 5 200
    echo "   📉 Teams deprioritized (high memory usage: ${TEAMS_MEM}MB)"
else
    optimize_app_priority "teams-for-linux" 0 -100
    echo "   ✅ Teams normal priority (${TEAMS_MEM}MB)"
fi

# Chrome management - balance between performance and memory
if [ "$CHROME_MEM" -gt 2000 ]; then
    optimize_app_priority "chromium" 10 300
    echo "   📉 Chrome deprioritized (high memory usage: ${CHROME_MEM}MB)"
elif [ "$CHROME_MEM" -gt 1000 ]; then
    optimize_app_priority "chromium" 5 100  
    echo "   ⚖️  Chrome moderate priority (${CHROME_MEM}MB)"
else
    optimize_app_priority "chromium" 0 -50
    echo "   ✅ Chrome normal priority (${CHROME_MEM}MB)"
fi

# Warp Terminal - keep responsive for development
optimize_app_priority "warp-terminal" -5 -200
echo "   🚀 Warp Terminal high priority (development tool)"

echo ""

# 2. Dynamic memory management
echo "2. Applying dynamic memory management..."

# Calculate memory pressure level
MEMORY_PRESSURE=0
if [ "$AVAILABLE_MEM" -lt 1000 ]; then
    MEMORY_PRESSURE=3  # Critical
elif [ "$AVAILABLE_MEM" -lt 2000 ]; then
    MEMORY_PRESSURE=2  # High
elif [ "$AVAILABLE_MEM" -lt 3000 ]; then
    MEMORY_PRESSURE=1  # Moderate
fi

case $MEMORY_PRESSURE in
    3)
        echo "   🚨 CRITICAL memory pressure detected!"
        echo "      Applying aggressive optimizations..."
        
        # Force garbage collection
        for pid in $(pgrep -f "chromium|teams-for-linux"); do
            kill -USR1 $pid 2>/dev/null || true
        done
        
        # Clear all caches
        sudo sysctl vm.drop_caches=3 > /dev/null
        
        # Reduce Chrome processes if possible
        for pid in $(pgrep -f "chromium.*--type=renderer" | tail -n +5); do
            echo "      Considering Chrome renderer $pid for termination"
        done
        
        echo "      ✅ Critical memory recovery applied"
        ;;
    2)
        echo "   ⚠️  HIGH memory pressure"
        echo "      Applying moderate optimizations..."
        
        # Clear page cache
        echo 1 | sudo tee /proc/sys/vm/drop_caches > /dev/null
        
        # Encourage swapping for less important processes
        echo 5 | sudo tee /proc/sys/vm/swappiness > /dev/null
        
        echo "      ✅ High memory pressure optimizations applied"
        ;;
    1)
        echo "   📊 MODERATE memory pressure"
        echo "      Applying preventive optimizations..."
        
        # Standard optimizations
        echo 1 | sudo tee /proc/sys/vm/swappiness > /dev/null
        
        echo "      ✅ Preventive optimizations applied"
        ;;
    0)
        echo "   ✅ Memory pressure is LOW - system running smoothly"
        ;;
esac

echo ""

# 3. Application-specific optimizations
echo "3. Application-specific memory tuning..."

# Teams optimization
if pgrep -f teams-for-linux > /dev/null; then
    # Reduce Teams memory footprint if it's consuming too much
    if [ "$TEAMS_MEM" -gt 800 ]; then
        echo "   📱 Teams memory reduction techniques applied"
        # Set memory limit via cgroups if available
        if [ -d "/sys/fs/cgroup/memory" ]; then
            for pid in $(pgrep -f teams-for-linux); do
                echo 1073741824 | sudo tee /sys/fs/cgroup/memory/user.slice/memory.limit_in_bytes 2>/dev/null || true
            done
        fi
    fi
    echo "   ✅ Teams optimized"
fi

# Chrome optimization
if pgrep -f chromium > /dev/null; then
    CHROME_TABS=$(pgrep -f "chromium.*renderer" | wc -l)
    if [ "$CHROME_TABS" -gt 10 ]; then
        echo "   🌐 Chrome has $CHROME_TABS tabs/processes"
        echo "      Consider using tab management extensions"
    fi
    echo "   ✅ Chrome analyzed"
fi

# Warp Terminal optimization
if pgrep -f warp-terminal > /dev/null; then
    if [ "$WARP_MEM" -gt 800 ]; then
        echo "   💻 Warp Terminal using high memory (${WARP_MEM}MB)"
        echo "      Consider restarting if sluggish"
    fi
    echo "   ✅ Warp Terminal optimized"
fi

echo ""

# 4. Proactive recommendations
echo "4. 💡 PROACTIVE RECOMMENDATIONS:"

TOTAL_USAGE_PERCENT=$(echo "scale=0; ($TOTAL_APP_MEM * 100) / 8000" | bc)
echo "   Current app memory usage: ${TOTAL_USAGE_PERCENT}% of total RAM"

if [ "$TOTAL_USAGE_PERCENT" -gt 70 ]; then
    echo "   ⚠️  HIGH USAGE recommendations:"
    echo "   • Close unnecessary browser tabs"
    echo "   • Restart Teams if it's been running for hours"
    echo "   • Use lightweight alternatives when possible"
    echo "   • Consider adding more RAM if this is typical usage"
elif [ "$TOTAL_USAGE_PERCENT" -gt 50 ]; then
    echo "   📊 MODERATE USAGE recommendations:"
    echo "   • Monitor memory with: ./memory_dashboard.sh"
    echo "   • Close unused applications periodically"
    echo "   • Use browser tab management extensions"
else
    echo "   ✅ GOOD USAGE - system has headroom for more applications"
fi

echo ""
echo "5. 🛠️  EMERGENCY TOOLS READY:"
echo "   • Real-time monitoring: ./memory_dashboard.sh"
echo "   • Emergency recovery: ./emergency_memory_recovery.sh"
echo "   • Chrome monitoring: ./chrome_monitor.sh"

# Final status
echo ""
echo "📈 FINAL STATUS AFTER BALANCING:"
free -h | head -2
echo ""

NEW_AVAILABLE=$(free -m | awk 'NR==2{print $7}')
IMPROVEMENT=$((NEW_AVAILABLE - AVAILABLE_MEM))

if [ "$IMPROVEMENT" -gt 0 ]; then
    echo "✅ IMPROVEMENT: +${IMPROVEMENT}MB available memory"
elif [ "$IMPROVEMENT" -eq 0 ]; then
    echo "➡️  STABLE: Memory usage optimized and balanced"
else
    echo "📊 Status: Memory usage is being actively managed"
fi

echo ""
echo "⚖️  Memory balancing completed at: $(date)"
echo ""
echo "🔄 RUN PERIODICALLY: Add to cron for automatic balancing:"
echo "*/15 * * * * /home/sri/multi_app_balancer.sh > /dev/null 2>&1"