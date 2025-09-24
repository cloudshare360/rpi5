# 📖 Installation Guide - RPi5 Overclocking Configurations

**Step-by-step guide to safely install overclocking configurations on your Raspberry Pi 5**

## ⚠️ **Before You Begin - CRITICAL SAFETY STEPS**

### **1. System Requirements Check**
- **Raspberry Pi 5** (4GB or 8GB model)
- **Official 5V 5A USB-C Power Supply** (or equivalent quality)
- **microSD card** (Class 10 or better, 32GB+ recommended)
- **Adequate cooling** (heatsink minimum, active cooling for >2600MHz)
- **Updated Raspberry Pi OS** (latest version recommended)

### **2. Risk Assessment**
```
⚠️  OVERCLOCKING RISKS:
• May void warranty
• Potential hardware damage if done incorrectly
• System instability possible
• Silicon lottery - your Pi may not reach these frequencies
• Increased power consumption and heat generation
```

### **3. Mandatory Backup**
**NEVER skip this step!**
```bash
# Backup your current configuration
sudo cp /boot/firmware/config.txt /boot/firmware/config.txt.backup

# Verify backup was created
ls -la /boot/firmware/config.txt*
```

## 🎯 **Choosing Your Target Frequency**

### **Recommended Progression Path**
1. **Start Conservative**: Begin with 2200MHz or 2400MHz
2. **Test Thoroughly**: Run stress tests for at least 1 hour
3. **Monitor Temperatures**: Ensure temperatures stay below 75°C
4. **Increment Gradually**: Move up one frequency level at a time
5. **Validate Each Step**: Never skip stability testing

### **Frequency Recommendations by Use Case**

| Use Case | Recommended Frequency | Reason |
|----------|----------------------|---------|
| **Everyday Use** | 2200-2400MHz | Best balance of performance and safety |
| **Development** | 2400-2500MHz | Good performance boost, stable |
| **Gaming/Media** | 2500-2600MHz | High performance, manageable heat |
| **Maximum Performance** | 2700-2800MHz | For enthusiasts, requires excellent cooling |

## 🛠️ **Installation Steps**

### **Step 1: Download Configuration File**
Choose your target frequency and download the corresponding config file:
- `config_2200MHz.txt` - Conservative (10% boost)
- `config_2300MHz.txt` - Light (15% boost)
- `config_2400MHz.txt` - Moderate (20% boost)
- `config_2500MHz.txt` - Moderate+ (25% boost)
- `config_2600MHz.txt` - Aggressive (30% boost)
- `config_2700MHz.txt` - High Performance (35% boost)
- `config_2800MHz.txt` - Maximum (40% boost)

### **Step 2: Apply Configuration**

#### **Method A: Direct Copy (Recommended)**
```bash
# Replace XXXX with your target frequency (e.g., 2400)
sudo cp config_XXXXMHz.txt /boot/firmware/config.txt

# Verify the configuration was applied
sudo tail -20 /boot/firmware/config.txt
```

#### **Method B: Manual Edit**
```bash
# Edit the config file manually
sudo nano /boot/firmware/config.txt

# Add the configuration from your chosen file to the end
# Save with Ctrl+X, then Y, then Enter
```

### **Step 3: Reboot System**
```bash
sudo reboot
```

### **Step 4: Verify Configuration Applied**
After reboot, check that your overclock is active:
```bash
# Check current CPU frequency
vcgencmd measure_clock arm

# Check temperature
vcgencmd measure_temp

# Check for throttling (should show 0x0)
vcgencmd get_throttled

# View detailed CPU info
lscpu | grep MHz
```

## 📊 **Validation and Testing**

### **Immediate Health Check**
Run these commands right after reboot:
```bash
# Temperature check (should be reasonable)
vcgencmd measure_temp

# Throttling check (should be 0x0)
vcgencmd get_throttled  

# Frequency verification
echo "Current frequency: $(vcgencmd measure_clock arm | cut -d'=' -f2 | awk '{print int($1/1000000)}')MHz"
```

### **Basic Stability Test**
```bash
# Quick 5-minute stress test
stress-ng --cpu $(nproc) --timeout 300s --metrics-brief

# Monitor temperature during test
watch -n 2 'vcgencmd measure_temp && vcgencmd get_throttled'
```

### **Comprehensive Testing (Recommended)**
If you have the stress test tools from this repository:
```bash
# Run the full stress test suite
./tools/stress_test_2800mhz.sh

# This includes:
# - 6-minute CPU intensive test
# - 4-minute memory bandwidth test  
# - 5-minute mixed workload test
# - System responsiveness validation
```

## 🚨 **Troubleshooting**

### **Problem: System Won't Boot**
**Symptoms**: Pi doesn't start, no display output, LED behavior unusual

**Solutions**:
1. **Power off completely** (unplug power)
2. **Remove SD card** and insert into another computer
3. **Restore backup configuration**:
   ```bash
   # On another computer, edit the SD card
   cp config.txt.backup config.txt
   ```
4. **Reinsert SD card** and power on Pi
5. **Try lower frequency** configuration

### **Problem: System Boots But Unstable**
**Symptoms**: Random crashes, freezes, applications crashing

**Solutions**:
1. **Check temperatures**: `watch -n 1 vcgencmd measure_temp`
2. **Check for throttling**: `vcgencmd get_throttled` 
3. **Reduce frequency** to next lower level
4. **Improve cooling** if temperatures >70°C
5. **Verify power supply** is adequate (5V 5A minimum)

### **Problem: Performance Not Improved**
**Symptoms**: Benchmarks show no improvement

**Solutions**:
1. **Verify frequency applied**: `vcgencmd measure_clock arm`
2. **Check for throttling**: System may be downclocking due to heat
3. **Check power supply**: Inadequate power causes downclocking
4. **Improve cooling**: High temperatures trigger thermal throttling

### **Problem: High Temperatures**
**Symptoms**: Temperatures consistently >75°C

**Solutions**:
1. **Improve cooling immediately**:
   - Add heatsink if not present
   - Add active cooling (fan)
   - Improve case ventilation
2. **Reduce overclock frequency**
3. **Check ambient temperature**
4. **Verify thermal interface** (thermal paste/pad)

## 🔧 **Advanced Configuration**

### **Custom Tuning**
If you want to modify the configurations:

```bash
# Key parameters to adjust:
arm_freq=XXXX          # CPU frequency in MHz
over_voltage=X         # Voltage boost (1-20, be careful!)
temp_limit=XX          # Temperature limit (default 85°C)
gpu_freq=XXX           # GPU frequency
core_freq=XXX          # Core frequency
sdram_freq=XXXX        # Memory frequency
```

### **Monitoring Tools**
```bash
# Real-time monitoring script
#!/bin/bash
while true; do
    echo "$(date) - Freq: $(vcgencmd measure_clock arm | cut -d'=' -f2 | awk '{print int($1/1000000)}')MHz Temp: $(vcgencmd measure_temp) Throttle: $(vcgencmd get_throttled)"
    sleep 5
done
```

## 🛡️ **Safety Best Practices**

### **Temperature Management**
- **Never exceed 80°C** for extended periods
- **Monitor continuously** during first hour of use
- **Install temperature monitoring** for peace of mind
- **Have cooling solution ready** before overclocking

### **Power Supply**
- **Use official 5V 5A supply** or equivalent quality
- **Avoid USB hubs** and extension cables
- **Check voltage stability** with multimeter if possible
- **Watch for undervoltage warnings**

### **Recovery Planning**
- **Always have backup configuration**
- **Know how to access SD card externally**
- **Keep second SD card** with working system
- **Document what works** for your specific Pi

## 📈 **Expected Results**

### **Performance Gains by Frequency**
- **2200MHz**: ~10% improvement in CPU tasks
- **2400MHz**: ~20% improvement, excellent stability
- **2600MHz**: ~30% improvement, monitor temperatures
- **2800MHz**: ~40% improvement, maximum performance

### **Temperature Expectations**
- **Idle**: Should remain similar to stock (40-50°C)
- **Light Load**: 10-15°C increase from stock
- **Heavy Load**: 20-25°C increase, watch for 75°C+
- **Stress Test**: Peak temperatures, should stay <80°C

## ✅ **Success Indicators**

Your overclock is successful when:
- ✅ System boots reliably every time
- ✅ Temperatures stay below 75°C during normal use
- ✅ No throttling occurs (`vcgencmd get_throttled` shows 0x0)
- ✅ System passes stress tests for 1+ hours
- ✅ No random crashes or instability
- ✅ Performance improvements visible in benchmarks

## 🆘 **Emergency Recovery**

If your Pi becomes completely unbootable:

1. **Power off completely**
2. **Remove SD card**
3. **Insert SD card into computer**
4. **Navigate to boot partition**
5. **Restore config**: `cp config.txt.backup config.txt`
6. **Safely eject SD card**
7. **Reinsert into Pi and power on**

## 📞 **Getting Help**

If you encounter issues:
- Check the troubleshooting section above
- Review the SAFETY_GUIDE.md for thermal issues
- Consult the GitHub issues section
- Remember: when in doubt, revert to lower frequency

---

**Good luck with your overclocking adventure! 🚀**

*Remember: Start conservative, test thoroughly, monitor closely*