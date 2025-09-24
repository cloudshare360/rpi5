#!/bin/bash

# ================================================
# Complete Drive Speed Report for Container Environment
# Tests both raw filesystem access and workspaces directory
# ================================================

echo "=========================================="
echo "🚀 DRIVE SPEED TEST REPORT"
echo "=========================================="
echo "Generated on: $(date)"
echo "Environment: GitHub Codespaces/DevContainer"
echo "System: $(uname -a)"
echo "=========================================="

echo ""
echo "📊 FILESYSTEM INFORMATION:"
echo "----------------------------------------"
df -h | grep -v -E '(tmpfs|devtmpfs|overlay|shm|proc|sysfs|cgroup|none)' | head -10

echo ""
echo "📈 SPEED TEST RESULTS:"
echo "----------------------------------------"
echo ""

# Test /tmp filesystem
echo "🧪 Testing /tmp filesystem (sdc1):"
echo "Size: 100MB | Method: dd with fdatasync"
TIME_START=$(date +%s.%N)
dd if=/dev/zero of=/tmp/speedtest_tmp.bin bs=1M count=100 conv=fdatasync 2>/dev/null
TIME_END=$(date +%s.%N)
WRITE_TIME=$(echo "$TIME_END - $TIME_START" | bc -l)
WRITE_SPEED=$(echo "scale=2; 100 / $WRITE_TIME" | bc -l)

# Test read speed
sync
TIME_START=$(date +%s.%N)
dd if=/tmp/speedtest_tmp.bin of=/dev/null bs=1M 2>/dev/null
TIME_END=$(date +%s.%N)
READ_TIME=$(echo "$TIME_END - $TIME_START" | bc -l)
READ_SPEED=$(echo "scale=2; 100 / $READ_TIME" | bc -l)

rm -f /tmp/speedtest_tmp.bin

echo "  ✅ Write Speed: ${WRITE_SPEED} MB/s"
echo "  ✅ Read Speed:  ${READ_SPEED} MB/s"
echo ""

# Test /workspaces filesystem
echo "🧪 Testing /workspaces filesystem (loop4):"
echo "Size: 100MB | Method: dd with fdatasync"
TIME_START=$(date +%s.%N)
dd if=/dev/zero of=/workspaces/rpi5/read-write-rpi5-drive-speed-test/speedtest_ws.bin bs=1M count=100 conv=fdatasync 2>/dev/null
TIME_END=$(date +%s.%N)
WRITE_TIME=$(echo "$TIME_END - $TIME_START" | bc -l)
WRITE_SPEED=$(echo "scale=2; 100 / $WRITE_TIME" | bc -l)

# Test read speed
sync
TIME_START=$(date +%s.%N)
dd if=/workspaces/rpi5/read-write-rpi5-drive-speed-test/speedtest_ws.bin of=/dev/null bs=1M 2>/dev/null
TIME_END=$(date +%s.%N)
READ_TIME=$(echo "$TIME_END - $TIME_START" | bc -l)
READ_SPEED=$(echo "scale=2; 100 / $READ_TIME" | bc -l)

rm -f /workspaces/rpi5/read-write-rpi5-drive-speed-test/speedtest_ws.bin

echo "  ✅ Write Speed: ${WRITE_SPEED} MB/s"
echo "  ✅ Read Speed:  ${READ_SPEED} MB/s"
echo ""

echo "📋 SUMMARY TABLE:"
echo "----------------------------------------"
printf "%-15s %-15s %-12s %-12s\n" "Location" "Device" "Write Speed" "Read Speed"
printf "%-15s %-15s %-12s %-12s\n" "--------" "------" "-----------" "----------"

# Re-run tests for summary table
# /tmp test
TIME_START=$(date +%s.%N)
dd if=/dev/zero of=/tmp/speedtest_tmp.bin bs=1M count=50 conv=fdatasync 2>/dev/null
TIME_END=$(date +%s.%N)
WRITE_TIME=$(echo "$TIME_END - $TIME_START" | bc -l)
TMP_WRITE=$(echo "scale=1; 50 / $WRITE_TIME" | bc -l)

TIME_START=$(date +%s.%N)
dd if=/tmp/speedtest_tmp.bin of=/dev/null bs=1M 2>/dev/null
TIME_END=$(date +%s.%N)
READ_TIME=$(echo "$TIME_END - $TIME_START" | bc -l)
TMP_READ=$(echo "scale=1; 50 / $READ_TIME" | bc -l)
rm -f /tmp/speedtest_tmp.bin

# /workspaces test
TIME_START=$(date +%s.%N)
dd if=/dev/zero of=/workspaces/rpi5/read-write-rpi5-drive-speed-test/speedtest_ws.bin bs=1M count=50 conv=fdatasync 2>/dev/null
TIME_END=$(date +%s.%N)
WRITE_TIME=$(echo "$TIME_END - $TIME_START" | bc -l)
WS_WRITE=$(echo "scale=1; 50 / $WRITE_TIME" | bc -l)

TIME_START=$(date +%s.%N)
dd if=/workspaces/rpi5/read-write-rpi5-drive-speed-test/speedtest_ws.bin of=/dev/null bs=1M 2>/dev/null
TIME_END=$(date +%s.%N)
READ_TIME=$(echo "$TIME_END - $TIME_START" | bc -l)
WS_READ=$(echo "scale=1; 50 / $READ_TIME" | bc -l)
rm -f /workspaces/rpi5/read-write-rpi5-drive-speed-test/speedtest_ws.bin

printf "%-15s %-15s %-12s %-12s\n" "/tmp" "sdc1" "${TMP_WRITE} MB/s" "${TMP_READ} MB/s"
printf "%-15s %-15s %-12s %-12s\n" "/workspaces" "loop4" "${WS_WRITE} MB/s" "${WS_READ} MB/s"

echo ""
echo "📝 NOTES:"
echo "----------------------------------------"
echo "• Tests performed in container environment (not native hardware)"
echo "• /tmp is backed by SSD storage (sdc1)"
echo "• /workspaces is backed by loop device (loop4)"
echo "• Speeds reflect filesystem performance, not raw disk performance"
echo "• For native Raspberry Pi 5 performance, run on actual hardware"
echo ""
echo "✅ Speed test completed successfully!"
echo "=========================================="