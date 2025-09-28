#!/bin/bash

# Chrome Memory Monitoring Script
# Monitors Chrome/Chromium memory usage and provides recommendations

echo "=== Chrome Memory Monitor ==="
echo "Timestamp: $(date)"
echo ""

# Check if Chrome/Chromium is running
CHROME_PROCESSES=$(pgrep -f chromium)
if [ -z "$CHROME_PROCESSES" ]; then
    echo "❌ Chrome/Chromium is not running"
    exit 0
fi

echo "✅ Chrome/Chromium is running"
echo ""

# System memory overview
echo "📊 System Memory Overview:"
free -h | head -2
echo ""

# Chrome process information
echo "🔍 Chrome Process Details:"
echo "Process Count: $(pgrep -f chromium | wc -l)"
echo ""

# Memory usage by Chrome processes
echo "💾 Chrome Memory Usage:"
ps -eo pid,ppid,cmd,pmem,rss --sort=-rss | grep -E "(chromium|PID)" | head -10
echo ""

# Top memory consuming Chrome processes
echo "🏆 Top Memory-Consuming Chrome Processes:"
ps -eo pid,cmd,rss --sort=-rss | grep chromium | head -5 | while read pid cmd rss; do
    rss_mb=$(echo "scale=1; $rss/1024" | bc -l)
    echo "PID: $pid | Memory: ${rss_mb}MB | Command: $(echo $cmd | cut -c1-60)..."
done
echo ""

# Total Chrome memory usage
TOTAL_CHROME_MEM=$(ps -eo rss,cmd | grep chromium | awk '{sum+=$1} END {print sum}')
if [ -n "$TOTAL_CHROME_MEM" ]; then
    TOTAL_MB=$(echo "scale=1; $TOTAL_CHROME_MEM/1024" | bc -l)
    echo "📈 Total Chrome Memory Usage: ${TOTAL_MB}MB"
else
    echo "📈 Total Chrome Memory Usage: Unable to calculate"
fi

# System load and available memory
echo ""
echo "⚡ System Performance:"
echo "Load Average: $(uptime | awk -F'load average:' '{print $2}')"
AVAILABLE_MEM=$(free -m | awk 'NR==2{print $7}')
echo "Available Memory: ${AVAILABLE_MEM}MB"

# Memory pressure recommendations
echo ""
echo "💡 Recommendations:"
if [ "$AVAILABLE_MEM" -lt 1000 ]; then
    echo "⚠️  LOW MEMORY WARNING!"
    echo "   • Close unnecessary tabs immediately"
    echo "   • Consider restarting Chrome"
    echo "   • Use 'killall chromium' if system becomes unresponsive"
elif [ "$AVAILABLE_MEM" -lt 2000 ]; then
    echo "⚠️  Memory getting low"
    echo "   • Close some tabs to free up memory"
    echo "   • Group related tabs together"
elif [ "$AVAILABLE_MEM" -lt 4000 ]; then
    echo "✅ Memory usage is moderate"
    echo "   • You can open a few more tabs safely"
else
    echo "✅ Plenty of memory available"
    echo "   • System is performing well"
fi

# Check for tab suspender extensions
echo ""
echo "🔧 Optimization Status:"
if [ -f "/home/sri/chromium-optimized" ]; then
    echo "✅ Optimized Chrome launcher is available"
else
    echo "❌ Run chrome_optimize.sh to create optimized launcher"
fi

echo ""
echo "📋 Quick Actions:"
echo "• Monitor in real-time: htop"
echo "• Check I/O usage: sudo iotop"
echo "• Kill Chrome: killall chromium"
echo "• Start optimized Chrome: ./chromium-optimized"