#!/bin/bash

# NVMe Performance Optimization Script
# This script optimizes NVMe read/write performance

echo "Starting NVMe performance optimization..."

# Find all NVMe devices
NVME_DEVICES=$(lsblk -dn -o NAME | grep nvme)

for device in $NVME_DEVICES; do
    echo "Optimizing /dev/$device"
    
    # Set I/O scheduler to none (best for NVMe)
    echo none | sudo tee /sys/block/$device/queue/scheduler > /dev/null
    echo "Set I/O scheduler to 'none' for $device"
    
    # Increase queue depth for better throughput
    echo 2048 | sudo tee /sys/block/$device/queue/nr_requests > /dev/null
    echo "Set queue depth to 2048 for $device"
    
    # Optimize read-ahead (for sequential workloads)
    echo 256 | sudo tee /sys/block/$device/queue/read_ahead_kb > /dev/null
    echo "Set read-ahead to 256KB for $device"
    
    # Set optimal min/max sectors per request
    echo 8 | sudo tee /sys/block/$device/queue/minimum_io_size > /dev/null
    echo 1024 | sudo tee /sys/block/$device/queue/max_sectors_kb > /dev/null
    echo "Set optimal I/O sizes for $device"
    
    # Disable add_random for better deterministic performance
    echo 0 | sudo tee /sys/block/$device/queue/add_random > /dev/null
    echo "Disabled add_random for $device"
    
    # Enable NCQ (Native Command Queueing) if available
    if [ -f /sys/block/$device/queue/nomerges ]; then
        echo 0 | sudo tee /sys/block/$device/queue/nomerges > /dev/null
        echo "Enabled request merging for $device"
    fi
done

# Set CPU governor to performance for better NVMe performance
if [ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ]; then
    for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        echo performance | sudo tee "$cpu" > /dev/null 2>&1 || true
    done
    echo "Set CPU governor to performance mode"
fi

# Optimize virtual memory settings for SSD
echo 1 | sudo tee /proc/sys/vm/swappiness > /dev/null
echo "Set swappiness to 1"

# Increase dirty ratio for better write performance
echo 15 | sudo tee /proc/sys/vm/dirty_ratio > /dev/null
echo 5 | sudo tee /proc/sys/vm/dirty_background_ratio > /dev/null
echo "Optimized dirty ratios for SSD"

# Set optimal dirty writeback time
echo 1500 | sudo tee /proc/sys/vm/dirty_writeback_centisecs > /dev/null
echo 3000 | sudo tee /proc/sys/vm/dirty_expire_centisecs > /dev/null
echo "Set optimal dirty writeback times"

echo "NVMe optimization complete!"
echo ""
echo "Current settings:"
for device in $NVME_DEVICES; do
    echo "Device: /dev/$device"
    echo "  Scheduler: $(cat /sys/block/$device/queue/scheduler | grep -o '\[.*\]' | tr -d '[]')"
    echo "  Queue depth: $(cat /sys/block/$device/queue/nr_requests)"
    echo "  Read-ahead: $(cat /sys/block/$device/queue/read_ahead_kb)KB"
    echo "  Max sectors: $(cat /sys/block/$device/queue/max_sectors_kb)KB"
    echo ""
done