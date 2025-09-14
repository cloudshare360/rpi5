# 🚀 Raspberry Pi 5 Drive Speed Test Suite

This repository contains scripts to test and benchmark drive performance on Raspberry Pi 5 systems, including USB 3.0 drives and NVMe SSDs via PCIe.

## 📁 Repository Structure

```
read-write-rpi5-drive-speed-test/
├── README.md                       # This instruction file
├── drive_speed_test.sh            # Original hardware-focused test script
├── filesystem_speed_test.sh       # Container-friendly filesystem test
├── complete_speed_report.sh       # Comprehensive reporting script
└── speed_test_report_*.txt        # Generated test reports
```

## 🔧 Prerequisites

### For Raspberry Pi 5 Hardware:
- Raspberry Pi 5 with connected drives (USB 3.0, NVMe via PCIe)
- Root/sudo access
- Internet connection for package installation

### For Container/Development Environment:
- Linux container with `dd`, `bc`, and basic utilities
- Write access to test directories

## 📋 Available Scripts

### 1. `drive_speed_test.sh` - Hardware Drive Testing
**Purpose**: Tests raw drive performance on actual Raspberry Pi 5 hardware
**Best for**: Physical Raspberry Pi 5 with external drives

```bash
# Make executable and run
chmod +x drive_speed_test.sh
sudo ./drive_speed_test.sh
```

**Features**:
- Auto-detects USB and NVMe drives
- Installs required tools (`fio`, `nvme-cli`, `smartmontools`)
- Tests sequential read/write speeds
- Excludes system drives to prevent corruption

**Expected Output**:
```
DriveName    DriveType  ReadSpeed    WriteSpeed  
---------    ---------  ---------    ----------
nvme0n1      NVMe       1876.23 MB/s 1790.45 MB/s
sda          USB        385.12 MB/s  372.89 MB/s
```

### 2. `filesystem_speed_test.sh` - Filesystem Performance Testing
**Purpose**: Tests filesystem performance in any environment
**Best for**: Container environments, general filesystem benchmarking

```bash
# Make executable and run
chmod +x filesystem_speed_test.sh
./filesystem_speed_test.sh
```

**Features**:
- Works in containers and restricted environments
- Tests mounted filesystems
- Automatic space checking
- Permission-aware testing

### 3. `complete_speed_report.sh` - Comprehensive Reporting
**Purpose**: Generates detailed, formatted performance reports
**Best for**: Documentation, performance monitoring, comparison testing

```bash
# Make executable and run
chmod +x complete_speed_report.sh
./complete_speed_report.sh

# Save report to file
./complete_speed_report.sh > my_speed_report_$(date +%Y%m%d).txt
```

**Features**:
- Professional formatted output
- System information inclusion
- Summary tables
- Timestamped results

## 🚀 Quick Start Guide

### Option A: Run on Raspberry Pi 5 Hardware

1. **Clone/Download the scripts to your Pi 5**:
   ```bash
   # If using git
   git clone <repository-url>
   cd read-write-rpi5-drive-speed-test
   
   # Or copy the scripts manually
   ```

2. **Connect your drives** (USB 3.0 drives, NVMe via HAT)

3. **Run the hardware test**:
   ```bash
   chmod +x drive_speed_test.sh
   sudo ./drive_speed_test.sh
   ```

4. **Generate comprehensive report**:
   ```bash
   chmod +x complete_speed_report.sh
   ./complete_speed_report.sh > rpi5_drive_report_$(date +%Y%m%d).txt
   ```

### Option B: Test in Development/Container Environment

1. **Navigate to the script directory**:
   ```bash
   cd read-write-rpi5-drive-speed-test
   ```

2. **Run filesystem test**:
   ```bash
   chmod +x filesystem_speed_test.sh
   ./filesystem_speed_test.sh
   ```

3. **Generate detailed report**:
   ```bash
   chmod +x complete_speed_report.sh
   ./complete_speed_report.sh > container_speed_report_$(date +%Y%m%d).txt
   ```

## 📊 Understanding the Results

### Speed Expectations:

| Drive Type | Expected Write Speed | Expected Read Speed |
|------------|---------------------|-------------------|
| **NVMe SSD** | 1000+ MB/s | 1500+ MB/s |
| **USB 3.0 SSD** | 100-400 MB/s | 200-500 MB/s |
| **USB 3.0 HDD** | 50-150 MB/s | 100-200 MB/s |
| **SD Card (Class 10)** | 10-30 MB/s | 50-90 MB/s |

### Performance Factors:
- **NVMe**: Limited by PCIe lanes (1x PCIe 2.0 on Pi 5)
- **USB 3.0**: Limited by USB controller and drive quality
- **Temperature**: High temps can throttle performance
- **Power Supply**: Insufficient power can cause instability

## 🔍 Troubleshooting

### Common Issues:

**"No external drives found"**
- Ensure drives are properly connected
- Check `lsblk` output manually
- Verify drives are not mounted

**"Permission denied"**
- Run hardware tests with `sudo`
- Check file permissions with `ls -la`

**"Package installation failed"**
- Update package lists: `sudo apt update`
- Check internet connection
- Install manually: `sudo apt install fio nvme-cli smartmontools`

**Low/Zero speeds reported**
- Check available disk space
- Ensure drive is not heavily used
- Try smaller test sizes for slow drives

### Manual Testing:
```bash
# Check connected drives
lsblk

# Manual speed test example
dd if=/dev/zero of=/tmp/testfile bs=1M count=100 conv=fdatasync
```

## 📝 Customization

### Modify test parameters:

**Test file size** (in `complete_speed_report.sh`):
```bash
# Change from 100MB to 500MB
dd if=/dev/zero of=testfile bs=1M count=500
```

**Block size** (for different workloads):
```bash
# Large files (default)
bs=1M

# Small files
bs=4K

# Database workload
bs=8K
```

## 📈 Sample Reports

### Raspberry Pi 5 with NVMe + USB drives:
```
========================================
🚀 DRIVE SPEED TEST REPORT
========================================
Generated on: Sat Sep 14 15:30:22 UTC 2025
Environment: Raspberry Pi 5 (8GB)
Hardware: BCM2712, ARM Cortex-A76

📋 SUMMARY TABLE:
----------------------------------------
Location        Device          Write Speed  Read Speed  
--------        ------          -----------  ----------  
/mnt/nvme       nvme0n1         1250.4 MB/s 1890.2 MB/s 
/mnt/usb        sda1            287.9 MB/s   425.1 MB/s 

✅ Speed test completed successfully!
```

## 🤝 Contributing

Feel free to:
- Report issues with specific hardware configurations
- Submit performance results from different drive combinations
- Suggest improvements to the testing methodology
- Add support for additional storage types

## ⚠️ Important Notes

- **Backup your data** before running tests on production systems
- Tests create temporary files but should not affect existing data
- Hardware tests require **sudo/root access**
- Container tests are **safe** and don't require elevated privileges
- Results may vary based on system load, temperature, and hardware configuration

## 📚 References

- [Raspberry Pi 5 Documentation](https://www.raspberrypi.org/products/raspberry-pi-5/)
- [fio - Flexible I/O Tester](https://fio.readthedocs.io/)
- [NVMe on Raspberry Pi](https://www.raspberrypi.org/blog/nvme-ssd-boot/)

---

**Last Updated**: September 14, 2025  
**Version**: 1.0  
**Compatible**: Raspberry Pi 5, Linux containers, Ubuntu 20.04+