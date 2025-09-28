#!/bin/bash

# NVMe Performance Benchmark Script
# This script runs various I/O benchmarks to test NVMe performance

echo "=== NVMe Performance Benchmark ==="
echo "Device: Samsung SSD 990 EVO Plus 1TB"
echo "Test directory: /tmp/nvme_test"
echo ""

# Create test directory
mkdir -p /tmp/nvme_test
cd /tmp/nvme_test

echo "Running performance benchmarks (this may take several minutes)..."
echo ""

# Sequential Read Test
echo "1. Sequential Read Test (1GB, 1MB blocks)"
fio --name=seq_read --filename=/tmp/nvme_test/seq_read.tmp --rw=read --bs=1M --size=1G --numjobs=1 --time_based --runtime=30 --group_reporting --ioengine=libaio --direct=1 --iodepth=32

echo ""
echo "2. Sequential Write Test (1GB, 1MB blocks)"
fio --name=seq_write --filename=/tmp/nvme_test/seq_write.tmp --rw=write --bs=1M --size=1G --numjobs=1 --time_based --runtime=30 --group_reporting --ioengine=libaio --direct=1 --iodepth=32

echo ""
echo "3. Random Read Test (4KB blocks)"
fio --name=rand_read --filename=/tmp/nvme_test/rand_read.tmp --rw=randread --bs=4k --size=1G --numjobs=4 --time_based --runtime=30 --group_reporting --ioengine=libaio --direct=1 --iodepth=64

echo ""
echo "4. Random Write Test (4KB blocks)"
fio --name=rand_write --filename=/tmp/nvme_test/rand_write.tmp --rw=randwrite --bs=4k --size=1G --numjobs=4 --time_based --runtime=30 --group_reporting --ioengine=libaio --direct=1 --iodepth=64

echo ""
echo "5. Mixed Random Read/Write Test (70/30 ratio, 4KB blocks)"
fio --name=mixed_rw --filename=/tmp/nvme_test/mixed_rw.tmp --rw=randrw --rwmixread=70 --bs=4k --size=1G --numjobs=4 --time_based --runtime=30 --group_reporting --ioengine=libaio --direct=1 --iodepth=32

echo ""
echo "6. Quick hdparm sequential read test"
sudo hdparm -tT /dev/nvme0n1

echo ""
echo "7. Current NVMe settings:"
echo "I/O Scheduler: $(cat /sys/block/nvme0n1/queue/scheduler | grep -o '\[.*\]' | tr -d '[]')"
echo "Queue depth: $(cat /sys/block/nvme0n1/queue/nr_requests)"
echo "Read-ahead: $(cat /sys/block/nvme0n1/queue/read_ahead_kb)KB"
echo "Max sectors: $(cat /sys/block/nvme0n1/queue/max_sectors_kb)KB"

# Clean up test files
echo ""
echo "Cleaning up test files..."
rm -rf /tmp/nvme_test

echo "Benchmark complete!"