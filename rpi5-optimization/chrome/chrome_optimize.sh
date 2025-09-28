#!/bin/bash

# Chrome/Chromium Optimization Script
# This script optimizes system and browser settings for better tab management

echo "=== Chrome/Chromium Tab Optimization Script ==="
echo "System: Raspberry Pi 5 with 8GB RAM and 4 cores"
echo ""

# System information
echo "Current system resources:"
echo "• Memory: $(free -h | awk 'NR==2{printf "%.1fGB total, %.1fGB available", $2/1000000000, $7/1000000000}')"
echo "• CPU: $(nproc) cores ($(lscpu | grep "Model name" | cut -d: -f2 | xargs))"
echo "• Swap: $(free -h | awk 'NR==3{printf "%s total", $2}')"
echo ""

echo "Applying system-level optimizations..."

# Increase file descriptor limits for browser processes
echo "1. Increasing file descriptor limits..."
if ! grep -q "* soft nofile 65536" /etc/security/limits.conf; then
    echo "* soft nofile 65536" | sudo tee -a /etc/security/limits.conf
    echo "* hard nofile 65536" | sudo tee -a /etc/security/limits.conf
    echo "Added file descriptor limits to /etc/security/limits.conf"
else
    echo "File descriptor limits already configured"
fi

# Optimize VM settings for browser workloads
echo ""
echo "2. Optimizing virtual memory settings for browser performance..."
echo 50 | sudo tee /proc/sys/vm/vfs_cache_pressure > /dev/null
echo "Set vfs_cache_pressure to 50 (better for browser caching)"

echo 20 | sudo tee /proc/sys/vm/dirty_ratio > /dev/null
echo 5 | sudo tee /proc/sys/vm/dirty_background_ratio > /dev/null
echo "Optimized dirty ratios for browser writes"

# Increase shared memory limits
echo ""
echo "3. Increasing shared memory limits for Chrome..."
echo "kernel.shmmax = 134217728" | sudo tee -a /etc/sysctl.d/99-chrome-optimization.conf > /dev/null
echo "kernel.shmall = 2097152" | sudo tee -a /etc/sysctl.d/99-chrome-optimization.conf > /dev/null
echo "vm.vfs_cache_pressure = 50" | sudo tee -a /etc/sysctl.d/99-chrome-optimization.conf > /dev/null
echo "Added shared memory optimizations to sysctl"

# Create Chrome launcher script with optimized flags
echo ""
echo "4. Creating optimized Chrome launcher..."
cat > /home/sri/chromium-optimized << 'EOF'
#!/bin/bash

# Optimized Chromium launcher for better tab management
# ARM64 Raspberry Pi 5 optimizations

CHROMIUM_FLAGS=(
    # Memory management
    "--max_old_space_size=2048"
    "--memory-pressure-off"
    "--max-active-webgl-contexts=8"
    "--memory-pressure-thresholds=0.7,0.8,0.9"
    
    # Process management
    "--process-per-site"
    "--max-renderer-process-limit=4"
    "--renderer-process-limit=4"
    
    # Tab management
    "--aggressive-tab-unloading"
    "--enable-memory-info"
    "--enable-tab-audio-muting"
    
    # Performance optimizations
    "--enable-gpu-rasterization"
    "--enable-accelerated-video-decode"
    "--use-gl=egl"
    "--enable-features=VaapiVideoDecoder"
    "--disable-features=VizServiceSharingFromGpuProcess"
    
    # Network optimizations
    "--aggressive-cache-discard"
    "--enable-tcp-fast-open"
    "--enable-quic"
    
    # ARM64 specific optimizations
    "--enable-hardware-overlays"
    "--enable-gpu-sandbox"
    "--disable-dev-shm-usage"
    
    # Disable unnecessary features
    "--disable-background-networking"
    "--disable-background-timer-throttling"
    "--disable-renderer-backgrounding"
    "--disable-backgrounding-occluded-windows"
    
    # Security optimizations
    "--enable-strict-site-isolation"
    "--site-per-process"
)

# Launch Chromium with optimized flags
exec /usr/bin/chromium "${CHROMIUM_FLAGS[@]}" "$@"
EOF

chmod +x /home/sri/chromium-optimized
echo "Created optimized Chromium launcher at /home/sri/chromium-optimized"

# Create Chrome configuration directory if it doesn't exist
mkdir -p ~/.config/chromium/Default

# Create or update Chrome preferences for tab management
echo ""
echo "5. Configuring Chrome preferences for tab optimization..."
cat > ~/.config/chromium/Default/Preferences << 'EOF'
{
   "profile": {
      "managed_user_id": "",
      "name": "Person 1"
   },
   "browser": {
      "check_default_browser": false,
      "show_home_button": false
   },
   "session": {
      "restore_on_startup": 4,
      "startup_urls": [ "chrome://newtab/" ]
   },
   "memory_pressure": {
      "moderate_threshold_mb": 1024,
      "critical_threshold_mb": 2048
   },
   "tabs": {
      "memory_pressure": {
         "aggressive_tab_discard_enabled": true
      }
   }
}
EOF
echo "Updated Chrome preferences for memory optimization"

echo ""
echo "6. Installing system monitoring tools..."
sudo apt update -qq && sudo apt install -y htop iotop zram-tools

echo ""
echo "=== Optimization Complete! ==="
echo ""
echo "What was optimized:"
echo "✓ File descriptor limits increased to 65536"
echo "✓ Virtual memory settings optimized for browsers"  
echo "✓ Shared memory limits increased"
echo "✓ Chrome launcher with performance flags created"
echo "✓ Chrome preferences configured for tab management"
echo "✓ System monitoring tools installed"
echo ""
echo "Usage:"
echo "• Use './chromium-optimized' instead of regular chromium"
echo "• Monitor memory usage with 'htop' or 'free -h'"
echo "• Restart system for all changes to take effect"
echo ""
echo "Additional recommendations:"
echo "• Keep max 20-30 tabs open at once"
echo "• Use Chrome's built-in tab groups for organization"
echo "• Consider using extensions like Tab Suspender"
echo "• Close unused tabs regularly"