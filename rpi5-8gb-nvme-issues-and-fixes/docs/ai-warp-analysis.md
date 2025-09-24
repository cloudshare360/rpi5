# AI Warp Analysis - PCIe Boot Troubleshooting Guide

**System**: Raspberry Pi 5 with NVMe drive via PCIe FFC connector  
**Created**: 2025-09-15  
**Purpose**: Guide for AI agent analysis of PCIe boot failures  

## 📋 Overview

This document provides structured guidance for AI agents to analyze boot failures when attempting to boot from NVMe drive connected via PCIe FFC connector on Raspberry Pi 5.

## 🔧 Current Configuration Status

### Hardware Setup
- **Board**: Raspberry Pi 5
- **Storage**: NVMe drive (currently working via USB adapter)
- **Target**: Boot via PCIe FFC connector (Gen 1 speeds)
- **Filesystem**: EXT4 with journaling (corruption detected - needs repair)

### Configuration Applied
- **PCIe enabled**: `dtparam=pciex1` in `/boot/firmware/config.txt`
- **PCIe speed**: `dtparam=pciex1_gen=1` (Gen 1 for compatibility)
- **Boot order**: NVMe prioritized (`BOOT_ORDER=0xf461`)
- **EEPROM settings**:
  - `NVME_CONTROLLER=1`
  - `NVME_BOOT=1`
  - `PCIE_PROBE_RETRIES=10`
- **Filesystem repair**: Scheduled on next reboot (`/forcefsck` created)

## 🚨 Known Issues to Address

### Critical - Filesystem Corruption
```
EXT4-fs error (device nvme0n1p2): __ext4_find_entry:1639: reading directory
EXT4-fs error (device nvme0n1p2): ext4_journal_check_start:84: Detected aborted journal
EXT4-fs (nvme0n1p2): Remounting filesystem read-only
```
**Status**: ⚠️ MUST fix before PCIe boot testing

## 📊 Boot Monitoring System

### Log Locations
```bash
/var/log/boot-monitor/
├── boot_YYYYMMDD_HHMMSS.log  # Timestamped boot logs
└── latest.log                # Symlink to most recent
```

### Analysis Scripts
```bash
~/boot-status.sh      # Quick status overview
~/analyze-boot.sh     # Interactive detailed analysis
```

### Service Status
```bash
sudo systemctl status boot-monitor.service  # Auto-runs at boot
```

## 🤖 AI Agent Analysis Instructions

### 1. Initial Assessment
When PCIe boot fails, run this sequence:

```bash
# Quick status check
./boot-status.sh

# Check if logs exist
ls -la /var/log/boot-monitor/

# View latest boot attempt
cat /var/log/boot-monitor/latest.log
```

### 2. Critical Areas to Analyze

#### A. PCIe Detection & Initialization
**Search terms**: `pcie`, `PCIe`, `nvme`, `controller`

**Key indicators**:
- ✅ `PCIe: Probing` - PCIe enumeration started
- ✅ `nvme nvme0: pci function` - NVMe controller detected
- ❌ `pcie timeout` - PCIe detection failed
- ❌ `no PCIe devices found` - Hardware connection issue

#### B. NVMe Device Enumeration
**Search terms**: `nvme0n1`, `namespace`, `sectors`

**Success patterns**:
```
nvme nvme0: 1/0/0 default/read/poll queues
nvme0n1: p1 p2
```

**Failure patterns**:
```
nvme nvme0: controller is down; will reset
nvme nvme0: Removing after probe failure
```

#### C. Storage Device Recognition
**Search terms**: `sda`, `nvme0n1`, `/dev/`, `partition`

**Expected progression**:
1. PCIe detection → NVMe controller → Device enumeration → Partition detection

#### D. Boot Process Analysis
**Search terms**: `root=`, `PARTUUID`, `mount`, `switch_root`

**Critical checkpoints**:
- Root partition identification
- Filesystem mounting
- Init system handover

### 3. Common Failure Patterns & Solutions

#### Pattern 1: PCIe Not Detected
**Symptoms**:
```
No PCIe messages in kernel log
Device shows as USB (sda) instead of NVMe
```
**Analysis**:
- Check FFC connector seating
- Verify `dtparam=pciex1` in config.txt
- Check EEPROM settings

#### Pattern 2: PCIe Detected, NVMe Not Found
**Symptoms**:
```
PCIe bridge detected
No nvme controller messages
```
**Analysis**:
- M.2 drive seating issue
- Power supply insufficient
- Drive compatibility with Gen 1 speeds

#### Pattern 3: NVMe Detected, Boot Fails
**Symptoms**:
```
nvme0n1 device found
Partition table read successfully
Root mount fails or hangs
```
**Analysis**:
- Filesystem corruption (check EXT4 errors)
- Wrong PARTUUID in cmdline.txt
- Missing bootloader files

#### Pattern 4: Intermittent Detection
**Symptoms**:
```
Sometimes works, sometimes fails
Timeout messages during PCIe probe
```
**Analysis**:
- Increase `PCIE_PROBE_RETRIES`
- Power supply stability
- FFC connector quality

### 4. Diagnostic Commands Sequence

When analyzing boot failure logs, execute this sequence:

```bash
# 1. System overview
grep -E "(PCIe|pcie|nvme|sda)" /var/log/boot-monitor/latest.log

# 2. Hardware detection timeline
grep -E "\[.*\].*nvme\|\[.*\].*pci" /var/log/boot-monitor/latest.log | head -20

# 3. Error analysis
grep -i "error\|fail\|timeout" /var/log/boot-monitor/latest.log

# 4. Boot sequence analysis
grep -E "root=\|mount\|switch_root" /var/log/boot-monitor/latest.log

# 5. Filesystem health
grep -i "ext4\|journal\|fsck" /var/log/boot-monitor/latest.log
```

### 5. Configuration Verification

Before each boot test, verify:

```bash
# Config.txt PCIe settings
tail -5 /boot/firmware/config.txt

# EEPROM boot settings  
rpi-eeprom-config | grep -E "(NVME|PCIE|BOOT_ORDER)"

# Filesystem scheduled repair
ls -la /forcefsck

# Boot monitor service
systemctl is-enabled boot-monitor.service
```

### 6. Success Indicators

**Successful PCIe boot should show**:
1. ✅ PCIe enumeration messages
2. ✅ NVMe controller detection: `nvme nvme0: X/Y/Z queues`
3. ✅ Device recognition: `nvme0n1: pX pY` (partitions)
4. ✅ Root mount: `nvme0n1p2 on / type ext4`
5. ✅ No EXT4 errors
6. ✅ Clean boot completion

### 7. Failure Response Actions

#### If PCIe not detected:
1. Verify FFC connector connection
2. Check power supply (official 27W+ recommended)
3. Test with minimal config (remove unnecessary dtoverlays)

#### If NVMe not enumerated:
1. Try different M.2 NVMe drive
2. Check M.2 connector seating
3. Increase probe retries: `PCIE_PROBE_RETRIES=20`

#### If filesystem errors:
1. Boot from USB/SD and run: `sudo fsck.ext4 -f -y /dev/nvme0n1p2`
2. Check drive health: `sudo smartctl -a /dev/nvme0n1`

#### If boot hangs:
1. Check PARTUUID matches in cmdline.txt
2. Verify bootloader files on /boot/firmware
3. Test with USB boot first to confirm OS integrity

## 🎯 Quick Decision Tree

```
Boot Failure Detected
├─ No PCIe messages?
│  ├─ Hardware connection issue
│  └─ Configuration problem
├─ PCIe detected, no NVMe?
│  ├─ Drive seating/compatibility
│  └─ Power supply issue  
├─ NVMe detected, boot fails?
│  ├─ Filesystem corruption
│  └─ Boot configuration issue
└─ Intermittent failures?
   ├─ Timing/probe issues
   └─ Power stability
```

## 🔍 Analysis Report Template

When providing analysis, structure the response as:

```markdown
## Boot Failure Analysis Report

### Status: [SUCCESS/PARTIAL/FAILED]

### Hardware Detection:
- PCIe Bridge: [DETECTED/NOT_FOUND]
- NVMe Controller: [DETECTED/NOT_FOUND] 
- Storage Device: [nvme0n1/sda/NONE]

### Key Findings:
- [Primary failure point]
- [Supporting evidence from logs]
- [Secondary issues identified]

### Recommended Actions:
1. [Immediate fix required]
2. [Configuration changes needed]
3. [Hardware checks to perform]

### Next Steps:
- [What to try next]
- [Alternative approaches]
```

## 📚 Reference Information

### File Locations
- **Boot config**: `/boot/firmware/config.txt`
- **Kernel cmdline**: `/boot/firmware/cmdline.txt`
- **EEPROM config**: `rpi-eeprom-config`
- **Boot logs**: `/var/log/boot-monitor/latest.log`
- **System logs**: `/var/log/syslog`, `dmesg`

### Key Configuration Values
- **PARTUUID**: Check `sudo blkid /dev/sda2` for current UUID
- **Boot order**: `0xf461` prioritizes NVMe
- **PCIe Gen**: Currently set to Gen 1 for compatibility

### Hardware Specifications
- **PCIe**: Single lane (x1) Gen 2/3 capable, configured for Gen 1
- **Power**: M.2 drives typically require 3.3V/5V
- **Connector**: 16-pin FFC, ensure correct orientation

---

**Note for AI Agent**: Always check filesystem corruption first, then hardware detection, then boot configuration. Use the monitoring logs as primary data source and cross-reference with system commands for verification.