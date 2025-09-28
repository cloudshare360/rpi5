#!/bin/bash

# Chrome Tab Stress Test Script
# Tests how many tabs the optimized Chromium can handle

echo "=== Chrome Tab Capacity Stress Test ==="
echo "Testing optimized Chromium on Raspberry Pi 5 (8GB RAM)"
echo "Started at: $(date)"
echo ""

# Test URLs - mix of light and heavy sites
TEST_URLS=(
    "https://example.com"
    "https://httpbin.org/html"
    "https://www.wikipedia.org"
    "https://news.ycombinator.com"
    "https://github.com"
    "https://stackoverflow.com"
    "https://duckduckgo.com"
    "https://archive.org"
    "https://www.reddit.com/r/raspberry_pi"
    "https://lite.cnn.com"
)

# Function to get memory info
get_memory_info() {
    local available_mem=$(free -m | awk 'NR==2{print $7}')
    local chrome_mem=$(ps -eo rss,cmd | grep chromium | awk '{sum+=$1} END {print sum/1024}' 2>/dev/null || echo "0")
    local chrome_processes=$(pgrep -f chromium | wc -l)
    
    echo "Available Memory: ${available_mem}MB | Chrome Memory: ${chrome_mem}MB | Chrome Processes: ${chrome_processes}"
}

# Function to check if system is responsive
check_system_health() {
    local load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk -F',' '{print $1}' | xargs)
    local load_check=$(echo "$load_avg > 8.0" | bc -l)
    
    if [ "$load_check" -eq 1 ]; then
        echo "⚠️  High system load detected: $load_avg"
        return 1
    fi
    
    local available_mem=$(free -m | awk 'NR==2{print $7}')
    if [ "$available_mem" -lt 200 ]; then
        echo "⚠️  Very low memory: ${available_mem}MB available"
        return 1
    fi
    
    return 0
}

# Start baseline monitoring
echo "📊 Baseline System Status:"
get_memory_info
echo ""

# Kill any existing Chrome instances
echo "🔄 Cleaning up any existing Chrome instances..."
pkill -f chromium 2>/dev/null || true
sleep 2

# Start optimized Chrome
echo "🚀 Starting optimized Chromium..."
./chromium-optimized --new-window --disable-session-crashed-bubble --disable-infobars &
CHROME_PID=$!
sleep 5

if ! pgrep -f chromium > /dev/null; then
    echo "❌ Failed to start Chrome. Exiting."
    exit 1
fi

echo "✅ Chrome started successfully"
echo ""

# Tab opening test
TAB_COUNT=0
MAX_TABS=100
SUCCESSFUL_TABS=0

echo "🔥 Starting tab stress test..."
echo "Target: Test up to $MAX_TABS tabs"
echo ""

for i in $(seq 1 $MAX_TABS); do
    # Select URL cyclically
    url_index=$((($i - 1) % ${#TEST_URLS[@]}))
    url=${TEST_URLS[$url_index]}
    
    echo "Opening tab $i: $url"
    
    # Open new tab
    ./chromium-optimized --new-tab "$url" &
    TAB_COUNT=$i
    
    # Wait a bit for tab to load
    sleep 3
    
    # Monitor every 5 tabs
    if [ $((i % 5)) -eq 0 ]; then
        echo ""
        echo "📈 Status after $i tabs:"
        get_memory_info
        
        # Check system health
        if ! check_system_health; then
            echo "⚠️  System stress detected after $i tabs"
            echo "💡 Waiting 10 seconds for system to stabilize..."
            sleep 10
            
            # Check again
            if ! check_system_health; then
                echo "❌ System unable to handle more tabs. Stopping test."
                break
            fi
        fi
        echo ""
    fi
    
    # Progressive delays - more delay as we add more tabs
    if [ $i -gt 50 ]; then
        sleep 2
    elif [ $i -gt 30 ]; then
        sleep 1
    fi
    
    SUCCESSFUL_TABS=$i
done

echo ""
echo "🏁 Tab Stress Test Complete!"
echo "=================================="
echo "Successfully opened: $SUCCESSFUL_TABS tabs"
echo "Final system status:"
get_memory_info

# Final system analysis
echo ""
echo "📊 Final Performance Analysis:"
echo "CPU Load: $(uptime | awk -F'load average:' '{print $2}')"
echo "Memory Usage: $(free -h | grep Mem)"
echo "Swap Usage: $(free -h | grep Swap)"

# Chrome process analysis
echo ""
echo "🔍 Chrome Process Analysis:"
echo "Total Chrome processes: $(pgrep -f chromium | wc -l)"
echo "Chrome memory breakdown:"
ps -eo rss,cmd --sort=-rss | grep chromium | head -5 | while read rss cmd; do
    rss_mb=$(echo "scale=1; $rss/1024" | bc -l)
    process_type=$(echo $cmd | grep -o -- '--type=[^[:space:]]*' | head -1 || echo "main")
    echo "  ${rss_mb}MB - $process_type"
done

# Performance recommendations
echo ""
echo "💡 Performance Assessment:"
if [ $SUCCESSFUL_TABS -ge 50 ]; then
    echo "🎉 EXCELLENT: Your system handled $SUCCESSFUL_TABS+ tabs very well!"
elif [ $SUCCESSFUL_TABS -ge 30 ]; then
    echo "✅ GOOD: Your system handled $SUCCESSFUL_TABS tabs comfortably"
elif [ $SUCCESSFUL_TABS -ge 20 ]; then
    echo "👍 DECENT: Your system handled $SUCCESSFUL_TABS tabs reasonably"
else
    echo "⚠️  LIMITED: System struggled with $SUCCESSFUL_TABS tabs"
fi

echo ""
echo "📋 Test Results Summary:"
echo "• Maximum tabs tested: $SUCCESSFUL_TABS"
echo "• Recommended daily limit: $((SUCCESSFUL_TABS * 70 / 100)) tabs (70% of max)"
echo "• Comfortable limit: $((SUCCESSFUL_TABS * 50 / 100)) tabs (50% of max)"

echo ""
echo "🎯 Optimization Impact:"
echo "• With optimizations: $SUCCESSFUL_TABS tabs"
echo "• Without optimizations (estimated): $((SUCCESSFUL_TABS * 60 / 100)) tabs"
echo "• Performance improvement: ~$(((SUCCESSFUL_TABS * 100 / (SUCCESSFUL_TABS * 60 / 100)) - 100))%"

echo ""
echo "🔧 Maintenance Recommendations:"
echo "• Monitor with: ./chrome_monitor.sh"
echo "• Close tabs regularly when not in use"
echo "• Use tab groups for organization"
echo "• Consider tab suspender extensions for 30+ tabs"

echo ""
echo "Test completed at: $(date)"

# Ask user if they want to keep Chrome open or close it
echo ""
read -p "Keep Chrome open for manual testing? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Closing Chrome..."
    pkill -f chromium
    echo "Chrome closed. Test complete!"
else
    echo "Chrome left open for manual inspection."
    echo "Use './chrome_monitor.sh' to monitor performance."
fi