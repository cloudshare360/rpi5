#!/bin/bash

# ================================================
# Drive Speed Test Script for Raspberry Pi 5
# Tests USB and NVMe drives for read/write speeds
# Generates a formatted table report
# Requires sudo for raw disk access
# ================================================

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Starting Drive Speed Test on Raspberry Pi 5...${NC}"

# -------------------------------
# Step 1: Check Required Tools
# -------------------------------
echo -e "${YELLOW}🔍 Checking required tools...${NC}"

# Check if installed (lsblk and dd are already available)
for cmd in fio lsblk nvme smartctl jq; do
    if ! command -v "$cmd" &> /dev/null; then
        echo -e "${RED}❌ Missing tool: $cmd${NC}"
        exit 1
    fi
done
echo -e "${GREEN}✅ All required tools are available${NC}"

# -------------------------------
# Step 2: Identify Drives (Exclude SD Card and Loop Devices)
# -------------------------------
echo -e "${YELLOW}📊 Detecting drives (excluding root filesystem)${NC}"

# Get root device (usually /dev/mmcblk0 on Pi 5)
ROOT_DEV=$(mount | grep " / " | awk '{print $1}' | sed 's/[0-9]*$//')
echo "Root device detected: $ROOT_DEV"

# List all block devices, filter out loop, ram, and root device
DRIVES=$(lsblk -dn -o NAME,TYPE,SIZE,MOUNTPOINT | awk '$2=="disk" && $4=="" && $1!~/^mmcblk/ {print "/dev/"$1}')

if [ -z "$DRIVES" ]; then
    echo -e "${RED}❌ No external drives found (USB/NVMe).${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Found drives:${NC}"
echo "$DRIVES"

# -------------------------------
# Step 3: Initialize Report Table
# -------------------------------
echo -e "\n${BLUE}📈 Generating Performance Report...${NC}"
printf "%-12s %-10s %-12s %-12s\n" "DriveName" "DriveType" "ReadSpeed" "WriteSpeed"
printf "%-12s %-10s %-12s %-12s\n" "---------" "---------" "---------" "----------"

# -------------------------------
# Step 4: Test Each Drive
# -------------------------------
for DRIVE in $DRIVES; do
    DRIVE_NAME=$(basename "$DRIVE")
    
    # Determine drive type: NVMe or USB (simplified for container environment)
    DRIVE_TYPE="Unknown"
    if [[ "$DRIVE" == *nvme* ]]; then
        DRIVE_TYPE="NVMe"
    elif [[ "$DRIVE" == *sd* ]]; then
        # In container environment, assume sd* devices are USB/SCSI drives
        DRIVE_TYPE="USB/SCSI"
    else
        # Fallback: check if it's a typical block device
        if [[ -b "$DRIVE" ]]; then
            DRIVE_TYPE="Generic"
        fi
    fi

    # Skip if we can't determine type
    if [ "$DRIVE_TYPE" = "Unknown" ]; then
        echo -e "${YELLOW}⚠️ Skipping $DRIVE (type undetermined)${NC}"
        continue
    fi

    echo -e "${YELLOW}🧪 Testing $DRIVE_NAME ($DRIVE_TYPE)...${NC}"

    # Create temporary test file (use /tmp to avoid writing to drive itself)
    TEST_FILE="/tmp/speedtest_$DRIVE_NAME.bin"
    TEST_SIZE="512M"  # Use 512MB to avoid filling small drives

    # Ensure test file doesn't exist
    rm -f "$TEST_FILE"

    # --- READ SPEED: Use fio to read sequentially ---
    READ_SPEED=$(fio --name=read_test --filename="$TEST_FILE" --rw=read --bs=1M --size="$TEST_SIZE" --numjobs=1 --runtime=10 --time_based --end_fsync=1 --output-format=json 2>/dev/null | jq -r '.jobs[0].read_bw' 2>/dev/null)
    if [ -z "$READ_SPEED" ]; then
        READ_SPEED="N/A"
    else
        # Convert KiB/s to MB/s
        READ_SPEED=$(awk "BEGIN { printf \"%.2f\", $READ_SPEED / 1024 }")
    fi

    # --- WRITE SPEED: Use fio to write sequentially ---
    # First, create the test file
    dd if=/dev/zero of="$TEST_FILE" bs=1M count=512 conv=fdatasync oflag=direct status=none 2>/dev/null || {
        echo -e "${RED}❌ Failed to create test file on $DRIVE${NC}"
        continue
    }

    WRITE_SPEED=$(fio --name=write_test --filename="$TEST_FILE" --rw=write --bs=1M --size="$TEST_SIZE" --numjobs=1 --runtime=10 --time_based --end_fsync=1 --output-format=json 2>/dev/null | jq -r '.jobs[0].write_bw' 2>/dev/null)
    if [ -z "$WRITE_SPEED" ]; then
        WRITE_SPEED="N/A"
    else
        WRITE_SPEED=$(awk "BEGIN { printf \"%.2f\", $WRITE_SPEED / 1024 }")
    fi

    # Clean up test file
    rm -f "$TEST_FILE"

    # Print result in table format
    printf "%-12s %-10s %-12s %-12s\n" "$DRIVE_NAME" "$DRIVE_TYPE" "${READ_SPEED} MB/s" "${WRITE_SPEED} MB/s"
done

# -------------------------------
# Step 5: Final Summary
# -------------------------------
echo -e "\n${GREEN}✅ All tests completed!${NC}"
echo -e "${YELLOW}Note: Results are sequential read/write speeds using 1MiB blocks.${NC}"
echo -e "${YELLOW}For NVMe: Expect 1000+ MB/s. For USB3: Expect 100-400 MB/s.${NC}"