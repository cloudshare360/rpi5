#!/bin/bash
# Emergency memory recovery for when system becomes unresponsive

echo "🆘 EMERGENCY MEMORY RECOVERY"
echo "============================"

# Immediate actions
echo "Clearing all caches..."
sudo sysctl vm.drop_caches=3

echo "Optimizing memory pressure..."
echo 1 | sudo tee /proc/sys/vm/swappiness > /dev/null

echo "Forcing garbage collection..."
for pid in $(pgrep -f "chromium|teams-for-linux|warp-terminal"); do
    kill -USR1 $pid 2>/dev/null || true
done

echo "Memory recovery complete. System should be more responsive."
free -h
