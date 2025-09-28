#!/bin/bash
# Intelligent Memory Manager
# Automatically manages memory when applications consume too much

while true; do
    AVAILABLE_MEM=$(free -m | awk 'NR==2{print $7}')
    SWAP_USED=$(free -m | awk 'NR==3{print $3}')
    
    # If available memory is low (less than 1GB)
    if [ "$AVAILABLE_MEM" -lt 1000 ]; then
        # Clear caches
        echo 1 > /proc/sys/vm/drop_caches 2>/dev/null || sudo sysctl vm.drop_caches=1
        
        # If Teams is using too much memory, suggest optimization
        TEAMS_MEM=$(ps aux | grep teams-for-linux | grep -v grep | awk '{print $6}' | head -1)
        if [ -n "$TEAMS_MEM" ] && [ "$TEAMS_MEM" -gt 800000 ]; then
            echo "$(date): Teams using high memory ($(echo $TEAMS_MEM/1024 | bc)MB)" >> ~/memory_manager.log
        fi
        
        # If Chrome is using too much, log it
        CHROME_MEM=$(ps aux | grep chromium | grep -v grep | awk '{sum+=$6} END {print sum/1024}' 2>/dev/null || echo "0")
        if (( $(echo "$CHROME_MEM > 2000" | bc -l) )); then
            echo "$(date): Chrome using high memory (${CHROME_MEM}MB)" >> ~/memory_manager.log
        fi
    fi
    
    # If swap usage is high, be more aggressive with cache clearing
    if [ "$SWAP_USED" -gt 500 ]; then
        echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || sudo sysctl vm.drop_caches=3
    fi
    
    sleep 30
done
