# 🚀 Raspberry Pi 5 Projects Repository

**Collection of Raspberry Pi 5 optimization, configuration, and utility projects**

## 📋 **Projects Overview**

### 🔥 **[RPi5 Overclocking Guide](./rpi5-overclocking-guide/)**
**Complete overclocking guide with validated configurations from 2200MHz to 2800MHz**
- ✅ **40% performance increase** (2000MHz → 2800MHz)
- ✅ **Comprehensive stress testing** and thermal analysis
- ✅ **Ready-to-use configuration files** for each frequency
- ✅ **Safety guides** and emergency recovery procedures
- ✅ **Passive cooling sufficient** up to 2800MHz
- ❌ **2900MHz limit identified** (silicon lottery)

[→ View Overclocking Guide](./rpi5-overclocking-guide/README.md)

### 💾 **System Optimization & Configuration**
- **[Increase Swap Memory Guide](./raspberry-pi-increase-swap-memory.md)** - Optimize memory management
- **[CPU/GPU Optimization with Dual Monitor](./rpi5-8gb-cpu-gpu-optimization-with-dual-monitor-configuration/)** - Complete system optimization
- **[NVMe Issues & Fixes](./rpi5-8gb-nvme-issues-and-fixes/)** - NVMe boot solutions and troubleshooting

### 🔧 **Development & Tools**
- **[Docker Setup](./docker-setup/)** - Complete Docker installation and configuration
- **[VSCode Configuration](./.vscode/)** - Optimized development environment setup
- **[Drive Speed Testing](./read-write-rpi5-drive-speed-test/)** - Storage performance testing tools

## 🌟 **Featured: RPi5 Overclocking Results**

| Frequency | Performance Gain | Max Temperature | Status |
|-----------|------------------|-----------------|--------|
| 2200MHz | +10% | 55.4°C | ✅ Stable |
| 2400MHz | +20% | 54.3°C | ✅ Perfect |
| 2600MHz | +30% | 56.5°C | ✅ Excellent |
| 2800MHz | +40% | 71.9°C | ✅ Maximum |
| 2900MHz | +45% | N/A | ❌ Boot Fail |

**Tested System**: RPi5 8GB, Official 5V 5A PSU, Passive Cooling Only

## 🚀 **Quick Start**

### For Overclocking:
```bash
# Download and apply 2400MHz configuration (recommended starting point)
wget https://raw.githubusercontent.com/cloudshare360/rpi5/main/rpi5-overclocking-guide/configs/config_2400MHz.txt
sudo cp config_2400MHz.txt /boot/firmware/config.txt
sudo reboot
```

### For Swap Increase:
```bash
# Follow the swap memory guide
https://itsfoss.com/pi-swap-increase/
```

## ⚠️ **Safety Notice**

**Overclocking can void warranty and damage hardware.** Always:
- ✅ Backup your configuration before changes
- ✅ Monitor temperatures continuously  
- ✅ Start with conservative settings
- ✅ Read the safety guide thoroughly

## 🤝 **Contributing**

We welcome contributions! Each project has its own contribution guidelines. Please:
1. Test thoroughly on your hardware
2. Document your system specifications
3. Include temperature and stability data
4. Follow existing project structure

---

**Hardware tested**: Raspberry Pi 5 (8GB) with official accessories
**Results may vary**: Silicon lottery affects individual performance


