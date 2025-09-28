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
