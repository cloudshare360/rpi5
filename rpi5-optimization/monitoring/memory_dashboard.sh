#!/bin/bash
# Real-time memory dashboard for intensive applications

clear
while true; do
    clear
    echo "🖥️  MEMORY DASHBOARD - $(date)"
    echo "======================================="
    echo ""
    
    # System overview
    echo "📊 SYSTEM OVERVIEW:"
    free -h | head -2
    echo ""
    
    echo "💾 MEMORY BY APPLICATION:"
    echo "Teams:    $(ps aux | grep teams-for-linux | grep -v grep | awk '{print $4}' | head -1 || echo "0")% ($(ps aux | grep teams-for-linux | grep -v grep | awk '{print int($6/1024)}' | head -1 || echo "0")MB)"
    echo "Chrome:   $(ps aux | grep chromium | grep -v grep | awk '{sum+=$4} END {print sum}' || echo "0")% ($(ps aux | grep chromium | grep -v grep | awk '{sum+=$6} END {print int(sum/1024)}' || echo "0")MB total)"
    echo "Warp:     $(ps aux | grep warp-terminal | grep -v grep | awk '{print $4}' | head -1 || echo "0")% ($(ps aux | grep warp-terminal | grep -v grep | awk '{print int($6/1024)}' | head -1 || echo "0")MB)"
    echo ""
    
    echo "⚡ PERFORMANCE:"
    uptime | awk -F'load average:' '{print "Load: " $2}'
    echo "Available: $(free -h | awk 'NR==2{print $7}')"
    echo "Swap Used: $(free -h | awk 'NR==3{print $3}')"
    echo ""
    
    echo "Press Ctrl+C to exit"
    sleep 5
done
