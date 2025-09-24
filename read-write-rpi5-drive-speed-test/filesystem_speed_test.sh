#!/bin/bash

# ================================================
# Filesystem Speed Test Script for Container Environment
# Tests filesystem read/write speeds instead of raw disk
# Works in container environments like Codespaces
# ================================================

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Starting Filesystem Speed Test in Container Environment...${NC}"

# -------------------------------
# Step 1: Check Required Tools
# -------------------------------
echo -e "${YELLOW}🔍 Checking required tools...${NC}"

# Check if dd is available (should be in all systems)
if ! command -v dd &> /dev/null; then
    echo -e "${RED}❌ Missing tool: dd${NC}"
    exit 1
fi

echo -e "${GREEN}✅ All required tools are available${NC}"

# -------------------------------
# Step 2: Identify Available Filesystems
# -------------------------------
echo -e "${YELLOW}📊 Detecting available filesystems...${NC}"

# Get mounted filesystems, excluding special ones
FILESYSTEMS=$(df -h | grep -v -E '(tmpfs|devtmpfs|overlay|shm|proc|sysfs|cgroup|loop)' | awk 'NR>1 {print $6":"$1":"$2":"$4}' | head -5)

if [ -z "$FILESYSTEMS" ]; then
    echo -e "${RED}❌ No suitable filesystems found for testing.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Found filesystems to test:${NC}"
echo "$FILESYSTEMS" | cut -d: -f1,3,4

# -------------------------------
# Step 3: Initialize Report Table
# -------------------------------
echo -e "\n${BLUE}📈 Generating Performance Report...${NC}"
printf "%-15s %-15s %-12s %-12s %-10s\n" "MountPoint" "Device" "ReadSpeed" "WriteSpeed" "AvailSpace"
printf "%-15s %-15s %-12s %-12s %-10s\n" "----------" "------" "---------" "----------" "----------"

# -------------------------------
# Step 4: Test Each Filesystem
# -------------------------------
echo "$FILESYSTEMS" | while IFS=: read -r MOUNT_POINT DEVICE TOTAL_SIZE AVAIL_SIZE; do
    
    echo -e "${YELLOW}🧪 Testing filesystem: $MOUNT_POINT${NC}"
    
    # Create test directory
    TEST_DIR="$MOUNT_POINT/speedtest_$$"
    TEST_FILE="$TEST_DIR/testfile.bin"
    TEST_SIZE_MB=100  # Use 100MB for testing
    
    # Skip if we don't have enough space (need at least 200MB free)
    # Convert size to MB for comparison
    AVAIL_NUM=$(echo "$AVAIL_SIZE" | sed 's/[^0-9.]//g')
    AVAIL_UNIT=$(echo "$AVAIL_SIZE" | sed 's/[0-9.]//g')
    
    # Convert to MB
    if [[ "$AVAIL_UNIT" == *"G"* ]]; then
        AVAIL_MB=$(echo "$AVAIL_NUM * 1024" | bc -l)
    elif [[ "$AVAIL_UNIT" == *"T"* ]]; then
        AVAIL_MB=$(echo "$AVAIL_NUM * 1024 * 1024" | bc -l)
    else
        AVAIL_MB=$AVAIL_NUM
    fi
    
    # Check if we have at least 200MB
    if (( $(echo "$AVAIL_MB < 200" | bc -l) )); then
        echo -e "${YELLOW}⚠️ Skipping $MOUNT_POINT (insufficient space: need 200MB, have ${AVAIL_SIZE})${NC}"
        printf "%-15s %-15s %-12s %-12s %-10s\n" "$MOUNT_POINT" "${DEVICE##*/}" "N/A" "N/A" "$AVAIL_SIZE"
        continue
    fi
    
    # Create test directory
    if ! mkdir -p "$TEST_DIR" 2>/dev/null; then
        echo -e "${YELLOW}⚠️ Skipping $MOUNT_POINT (permission denied)${NC}"
        printf "%-15s %-15s %-12s %-12s %-10s\n" "$MOUNT_POINT" "${DEVICE##*/}" "N/A" "N/A" "$AVAIL_SIZE"
        continue
    fi
    
    # --- WRITE SPEED TEST ---
    echo -e "  📝 Testing write speed..."
    WRITE_START=$(date +%s.%N)
    if dd if=/dev/zero of="$TEST_FILE" bs=1M count=$TEST_SIZE_MB conv=fdatasync 2>/dev/null; then
        WRITE_END=$(date +%s.%N)
        WRITE_TIME=$(echo "$WRITE_END - $WRITE_START" | bc -l)
        WRITE_SPEED=$(echo "scale=2; $TEST_SIZE_MB / $WRITE_TIME" | bc -l)
    else
        WRITE_SPEED="N/A"
    fi
    
    # --- READ SPEED TEST ---
    echo -e "  📖 Testing read speed..."
    if [ -f "$TEST_FILE" ]; then
        # Clear cache (if possible)
        sync 2>/dev/null || true
        echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true
        
        READ_START=$(date +%s.%N)
        if dd if="$TEST_FILE" of=/dev/null bs=1M 2>/dev/null; then
            READ_END=$(date +%s.%N)
            READ_TIME=$(echo "$READ_END - $READ_START" | bc -l)
            READ_SPEED=$(echo "scale=2; $TEST_SIZE_MB / $READ_TIME" | bc -l)
        else
            READ_SPEED="N/A"
        fi
    else
        READ_SPEED="N/A"
    fi
    
    # Clean up test files
    rm -rf "$TEST_DIR" 2>/dev/null || true
    
    # Format speeds
    if [ "$WRITE_SPEED" != "N/A" ]; then
        WRITE_SPEED="${WRITE_SPEED} MB/s"
    fi
    if [ "$READ_SPEED" != "N/A" ]; then
        READ_SPEED="${READ_SPEED} MB/s"
    fi
    
    # Print result in table format
    printf "%-15s %-15s %-12s %-12s %-10s\n" "$MOUNT_POINT" "${DEVICE##*/}" "$READ_SPEED" "$WRITE_SPEED" "$AVAIL_SIZE"
done

# -------------------------------
# Step 5: Final Summary
# -------------------------------
echo -e "\n${GREEN}✅ All tests completed!${NC}"
echo -e "${YELLOW}Note: Results are filesystem sequential read/write speeds using dd.${NC}"
echo -e "${YELLOW}This tests filesystem performance, not raw disk performance.${NC}"