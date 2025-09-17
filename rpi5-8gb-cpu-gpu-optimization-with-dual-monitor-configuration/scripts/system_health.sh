#!/bin/bash
# =================================================================
# RASPBERRY PI 5 SYSTEM HEALTH MONITOR
# =================================================================
# Monitors system performance and health after optimizations
# 
# Author: Community Contribution
# License: MIT
# =================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

print_banner() {
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║            🔍 Raspberry Pi 5 System Health Check              ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

get_cpu_status() {
    echo -e "${BLUE}📊 CPU STATUS:${NC}"
    
    # Current frequency
    CURRENT_FREQ=$(vcgencmd measure_clock arm | awk -F'=' '{printf "%.1f MHz\n", $2/1000000}')
    echo "  Current Freq: $CURRENT_FREQ"
    
    # Max frequency
    MAX_FREQ=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq | awk '{printf "%.1f MHz\n", $1/1000}')
    echo "  Max Freq:     $MAX_FREQ"
    
    # Governor
    GOVERNOR=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)
    echo "  Governor:     $GOVERNOR"
    
    echo ""
}

get_gpu_status() {
    echo -e "${BLUE}🎮 GPU STATUS:${NC}"
    
    # Core frequency
    CORE_FREQ=$(vcgencmd measure_clock core | awk -F'=' '{printf "%.1f MHz\n", $2/1000000}')
    echo "  Core Freq:    $CORE_FREQ"
    
    # V3D frequency
    V3D_FREQ=$(vcgencmd measure_clock v3d | awk -F'=' '{printf "%.1f MHz\n", $2/1000000}')
    echo "  V3D Freq:     $V3D_FREQ"
    
    echo ""
}

get_memory_status() {
    echo -e "${BLUE}💾 MEMORY STATUS:${NC}"
    
    # ARM and GPU memory
    ARM_MEM=$(vcgencmd get_mem arm | awk -F'=' '{print $2}')
    GPU_MEM=$(vcgencmd get_mem gpu | awk -F'=' '{print $2}')
    echo "  ARM Memory:   $ARM_MEM"
    echo "  GPU Memory:   $GPU_MEM"
    
    echo ""
}

get_thermal_status() {
    echo -e "${BLUE}🌡️  THERMAL STATUS:${NC}"
    
    # Temperature
    TEMP=$(vcgencmd measure_temp | awk -F'=' '{print $2}')
    echo "  Temperature:  $TEMP"
    
    # Throttling status
    THROTTLED=$(vcgencmd get_throttled)
    echo "  Throttled:    $THROTTLED"
    
    echo ""
}

get_voltage_status() {
    echo -e "${BLUE}⚡ VOLTAGE STATUS:${NC}"
    
    # Core voltage
    CORE_VOLT=$(vcgencmd measure_volts core | awk -F'=' '{print $2}')
    echo "  Core Voltage: $CORE_VOLT"
    
    echo ""
}

get_display_status() {
    echo -e "${BLUE}📺 DISPLAY STATUS:${NC}"
    
    # Check for dual monitors
    if command -v xrandr &> /dev/null; then
        DISPLAYS=$(xrandr --query 2>/dev/null | grep " connected" | wc -l)
        echo "  Connected:    $DISPLAYS display(s)"
        
        if [[ $DISPLAYS -gt 1 ]]; then
            echo -e "  Dual Monitor: ${GREEN}✅ Working${NC}"
            # Show resolution
            RESOLUTION=$(xrandr --query 2>/dev/null | grep "current" | awk '{print $8 " x " $10}' | sed 's/,//')
            echo "  Resolution:   $RESOLUTION"
        else
            echo -e "  Dual Monitor: ${YELLOW}Single display detected${NC}"
        fi
    else
        echo "  Status:       Display info not available (no X11)"
    fi
    
    echo ""
}

assess_health() {
    echo -e "${PURPLE}🏥 HEALTH ASSESSMENT:${NC}"
    
    # Temperature assessment
    TEMP_NUM=$(vcgencmd measure_temp | awk -F'=' '{print $2}' | sed 's/°C//' | sed "s/'//")
    if (( $(echo "$TEMP_NUM < 60" | bc -l) )); then
        echo -e "  ${GREEN}✅ Temperature: GOOD ($TEMP_NUM°C)${NC}"
    elif (( $(echo "$TEMP_NUM < 75" | bc -l) )); then
        echo -e "  ${YELLOW}⚠️  Temperature: WARM ($TEMP_NUM°C) - Monitor closely${NC}"
    else
        echo -e "  ${RED}❌ Temperature: HOT ($TEMP_NUM°C) - Consider rollback${NC}"
    fi
    
    # Throttling assessment
    THROTTLED=$(vcgencmd get_throttled)
    if [[ "$THROTTLED" == "throttled=0x0" ]]; then
        echo -e "  ${GREEN}✅ Throttling: NONE - System running stable${NC}"
    else
        echo -e "  ${RED}⚠️  Throttling: DETECTED - $THROTTLED${NC}"
    fi
    
    # CPU frequency assessment
    MAX_FREQ=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq)
    if [[ $MAX_FREQ -gt 2400000 ]]; then
        FREQ_MHZ=$(echo $MAX_FREQ | awk '{printf "%.1f MHz", $1/1000}')
        echo -e "  ${GREEN}🚀 CPU Overclock: ACTIVE ($FREQ_MHZ)${NC}"
    else
        echo -e "  ${BLUE}📊 CPU Overclock: STOCK (2.4 GHz)${NC}"
    fi
    
    echo ""
}

show_rollback_options() {
    echo -e "${YELLOW}🔧 AVAILABLE ACTIONS:${NC}"
    echo "  Complete Rollback:   sudo ./scripts/rollback_all.sh"
    echo "  CPU Rollback Only:   sudo ./scripts/rollback_cpu.sh"
    echo "  GPU Rollback Only:   sudo ./scripts/rollback_gpu.sh"
    echo "  Stress Test:         ./scripts/stress_test.sh"
    echo ""
}

show_quick_commands() {
    echo -e "${BLUE}📋 QUICK COMMANDS:${NC}"
    echo "  Continuous Monitor:  watch -n 1 './scripts/system_health.sh'"
    echo "  Temperature Only:    watch -n 1 'vcgencmd measure_temp'"
    echo "  CPU Frequency:       watch -n 1 'vcgencmd measure_clock arm'"
    echo "  Stress Test:         stress-ng --cpu 4 --timeout 60s"
    echo ""
}

main() {
    print_banner
    
    get_cpu_status
    get_gpu_status
    get_memory_status
    get_thermal_status
    get_voltage_status
    get_display_status
    assess_health
    show_rollback_options
    show_quick_commands
}

# Execute main function
main "$@"