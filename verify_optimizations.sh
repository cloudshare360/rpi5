#!/bin/bash

# Comprehensive Optimization Verification Script
# Verifies all applied optimizations are working correctly after restart

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m'

# Output functions
print_banner() { echo -e "${WHITE}${BOLD}$*${NC}"; }
print_success() { echo -e "${GREEN}✅ $*${NC}"; }
print_error() { echo -e "${RED}❌ $*${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $*${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $*${NC}"; }
print_check() { echo -e "${CYAN}🔍 $*${NC}"; }

# Verification results
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

# Function to perform a check
verify_check() {
    local description="$1"
    local command="$2"
    local expected="$3"
    local comparison="${4:-equals}"
    
    ((TOTAL_CHECKS++))
    print_check "Checking: $description"
    
    local result
    result=$(eval "$command" 2>/dev/null || echo "ERROR")
    
    local status="FAIL"
    case "$comparison" in
        "equals")
            if [[ "$result" == "$expected" ]]; then
                status="PASS"
                ((PASSED_CHECKS++))
            else
                ((FAILED_CHECKS++))
            fi
            ;;
        "contains")
            if [[ "$result" == *"$expected"* ]]; then
                status="PASS"
                ((PASSED_CHECKS++))
            else
                ((FAILED_CHECKS++))
            fi
            ;;
        "greater")
            if (( $(echo "$result > $expected" | bc -l 2>/dev/null || echo 0) )); then
                status="PASS"
                ((PASSED_CHECKS++))
            else
                ((FAILED_CHECKS++))
            fi
            ;;
        "exists")
            if [[ -f "$expected" ]] || [[ -d "$expected" ]]; then
                status="PASS"
                ((PASSED_CHECKS++))
            else
                ((FAILED_CHECKS++))
            fi
            ;;
    esac
    
    if [[ "$status" == "PASS" ]]; then
        print_success "$description: $result"
    else
        print_error "$description: Expected '$expected', got '$result'"
    fi
}

print_banner "🔍 COMPREHENSIVE OPTIMIZATION VERIFICATION"
print_banner "==========================================="
echo ""

print_info "System Info:"
print_info "• Hostname: $(hostname)"
print_info "• Kernel: $(uname -r)"
print_info "• Uptime: $(uptime -p)"
print_info "• Architecture: $(uname -m)"
echo ""

# =============================================================================
print_banner "1️⃣  SWAP MEMORY PRESSURE OPTIMIZATIONS"
echo "========================================"

verify_check "Swappiness setting" "cat /proc/sys/vm/swappiness" "1"
verify_check "VFS cache pressure" "cat /proc/sys/vm/vfs_cache_pressure" "75"
verify_check "Dirty ratio" "cat /proc/sys/vm/dirty_ratio" "15"
verify_check "Dirty background ratio" "cat /proc/sys/vm/dirty_background_ratio" "5"
verify_check "Watermark scale factor" "cat /proc/sys/vm/watermark_scale_factor" "50"

print_check "ZRAM configuration:"
if zramctl --noheadings | grep -q "zram0"; then
    local zram_size=$(zramctl --noheadings | awk '{print $3}' | head -1)
    print_success "ZRAM active: $zram_size"
    ((PASSED_CHECKS++))
else
    print_error "ZRAM not active"
    ((FAILED_CHECKS++))
fi
((TOTAL_CHECKS++))

verify_check "Swap configuration file" "test -f /etc/sysctl.d/99-swap-memory-pressure.conf && echo 'exists'" "exists"
verify_check "ZRAM service enabled" "systemctl is-enabled zram-swap-advanced 2>/dev/null || echo 'disabled'" "enabled"

echo ""

# =============================================================================
print_banner "2️⃣  NVME STORAGE OPTIMIZATIONS"
echo "==============================="

# Check NVMe devices exist
if ls /dev/nvme* >/dev/null 2>&1; then
    for device in $(lsblk -dn -o NAME | grep nvme); do
        print_check "NVMe device: /dev/$device"
        
        verify_check "I/O Scheduler (/dev/$device)" "cat /sys/block/$device/queue/scheduler | grep -o '\\[.*\\]' | tr -d '[]'" "none"
        verify_check "Queue depth (/dev/$device)" "cat /sys/block/$device/queue/nr_requests" "2048"
        verify_check "Read-ahead (/dev/$device)" "cat /sys/block/$device/queue/read_ahead_kb" "256"
        verify_check "Max sectors (/dev/$device)" "cat /sys/block/$device/queue/max_sectors_kb" "1024"
        
        local add_random=$(cat /sys/block/$device/queue/add_random 2>/dev/null || echo "1")
        if [[ "$add_random" == "0" ]]; then
            print_success "add_random disabled for /dev/$device"
            ((PASSED_CHECKS++))
        else
            print_error "add_random not disabled for /dev/$device"
            ((FAILED_CHECKS++))
        fi
        ((TOTAL_CHECKS++))
    done
else
    print_warning "No NVMe devices found"
fi

# Check CPU governor
print_check "CPU Governor settings:"
local gov_count=0
local perf_count=0
for cpu_gov in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    if [[ -f "$cpu_gov" ]]; then
        local governor=$(cat "$cpu_gov" 2>/dev/null || echo "unknown")
        ((gov_count++))
        if [[ "$governor" == "performance" ]]; then
            ((perf_count++))
        fi
    fi
done

if [[ $perf_count -eq $gov_count ]] && [[ $gov_count -gt 0 ]]; then
    print_success "All $gov_count CPU cores set to performance governor"
    ((PASSED_CHECKS++))
else
    print_error "CPU governor not set to performance on all cores ($perf_count/$gov_count)"
    ((FAILED_CHECKS++))
fi
((TOTAL_CHECKS++))

echo ""

# =============================================================================
print_banner "3️⃣  CHROME BROWSER OPTIMIZATIONS"
echo "=================================="

verify_check "File descriptor limits (soft)" "ulimit -n" "65536"
verify_check "Optimized Chromium launcher" "test -f ~/rpi5-optimization/launchers/chromium-optimized && echo 'exists'" "exists" "exists"
verify_check "Chrome preferences file" "test -f ~/.config/chromium/Default/Preferences && echo 'exists'" "exists" "exists"

# Check sysctl optimizations
verify_check "Chrome sysctl config" "test -f /etc/sysctl.d/99-chrome-optimization.conf && echo 'exists'" "exists" "exists"

if [[ -f /etc/security/limits.conf ]]; then
    if grep -q "nofile.*65536" /etc/security/limits.conf; then
        print_success "File descriptor limits configured in limits.conf"
        ((PASSED_CHECKS++))
    else
        print_error "File descriptor limits not found in limits.conf"
        ((FAILED_CHECKS++))
    fi
else
    print_error "limits.conf not found"
    ((FAILED_CHECKS++))
fi
((TOTAL_CHECKS++))

echo ""

# =============================================================================
print_banner "4️⃣  ADVANCED MEMORY MANAGEMENT"
echo "==============================="

verify_check "Memory overcommit setting" "cat /proc/sys/vm/overcommit_memory" "1"
verify_check "Overcommit ratio" "cat /proc/sys/vm/overcommit_ratio" "80"

# Check min_free_kbytes (should be reasonable for 8GB system)
local min_free=$(cat /proc/sys/vm/min_free_kbytes)
if [[ $min_free -ge 65536 ]] && [[ $min_free -le 262144 ]]; then
    print_success "Min free memory appropriately set: ${min_free} KB"
    ((PASSED_CHECKS++))
else
    print_error "Min free memory not optimally set: ${min_free} KB"
    ((FAILED_CHECKS++))
fi
((TOTAL_CHECKS++))

echo ""

# =============================================================================
print_banner "5️⃣  SYSTEM PERFORMANCE METRICS"
echo "==============================="

# Memory analysis
local total_mem=$(free -m | awk 'NR==2{print $2}')
local available_mem=$(free -m | awk 'NR==2{print $7}')
local mem_usage_percent=$(( (total_mem - available_mem) * 100 / total_mem ))

print_info "Memory Analysis:"
print_info "• Total: ${total_mem}MB"
print_info "• Available: ${available_mem}MB"
print_info "• Usage: ${mem_usage_percent}%"

if [[ $available_mem -gt 4000 ]]; then
    print_success "Excellent memory availability: ${available_mem}MB"
elif [[ $available_mem -gt 2000 ]]; then
    print_success "Good memory availability: ${available_mem}MB"
else
    print_warning "Low memory availability: ${available_mem}MB"
fi

# Load average
local load_1min=$(uptime | awk -F'load average:' '{print $2}' | awk -F',' '{print $1}' | xargs)
print_info "Load Average (1min): $load_1min"

if (( $(echo "$load_1min < 1.0" | bc -l) )); then
    print_success "Excellent system load: $load_1min"
elif (( $(echo "$load_1min < 2.0" | bc -l) )); then
    print_success "Good system load: $load_1min"
else
    print_warning "High system load: $load_1min"
fi

# Storage performance check
print_info "Storage Performance:"
if command -v hdparm >/dev/null 2>&1 && ls /dev/nvme* >/dev/null 2>&1; then
    for nvme_device in /dev/nvme0n1; do
        if [[ -b "$nvme_device" ]]; then
            print_info "• Testing read speed for $nvme_device..."
            local read_speed=$(sudo hdparm -t "$nvme_device" 2>/dev/null | grep "Timing" | awk '{print $11, $12}')
            if [[ -n "$read_speed" ]]; then
                print_success "Read speed: $read_speed"
            fi
        fi
    done
else
    print_info "• hdparm not available or no NVMe devices found"
fi

echo ""

# =============================================================================
print_banner "6️⃣  SERVICES AND MONITORING"
echo "============================="

verify_check "Memory manager service" "systemctl is-active memory-manager 2>/dev/null || echo 'inactive'" "active"

# Check monitoring tools
print_check "Monitoring tools availability:"
local monitoring_tools=("htop" "iotop" "stress")
for tool in "${monitoring_tools[@]}"; do
    if command -v "$tool" >/dev/null 2>&1; then
        print_success "$tool: Available"
        ((PASSED_CHECKS++))
    else
        print_error "$tool: Not available"
        ((FAILED_CHECKS++))
    fi
    ((TOTAL_CHECKS++))
done

# Check custom monitoring scripts
local monitoring_scripts=(
    "~/rpi5-optimization/monitoring/memory_dashboard.sh"
    "~/rpi5-optimization/monitoring/swap_pressure_monitor.sh"
    "~/rpi5-optimization/monitoring/chrome_monitor.sh"
)

for script in "${monitoring_scripts[@]}"; do
    script_path=$(eval echo "$script")
    if [[ -f "$script_path" ]]; then
        print_success "Monitoring script: $(basename "$script_path")"
        ((PASSED_CHECKS++))
    else
        print_error "Missing monitoring script: $(basename "$script_path")"
        ((FAILED_CHECKS++))
    fi
    ((TOTAL_CHECKS++))
done

echo ""

# =============================================================================
print_banner "📊 VERIFICATION SUMMARY"
echo "========================"

local success_rate=$(( PASSED_CHECKS * 100 / TOTAL_CHECKS ))

print_info "Total Checks: $TOTAL_CHECKS"
print_success "Passed: $PASSED_CHECKS"
if [[ $FAILED_CHECKS -gt 0 ]]; then
    print_error "Failed: $FAILED_CHECKS"
else
    print_success "Failed: $FAILED_CHECKS"
fi
print_info "Success Rate: ${success_rate}%"

echo ""

if [[ $success_rate -ge 90 ]]; then
    print_success "🎉 EXCELLENT! Your system is fully optimized and working perfectly!"
    print_success "All critical optimizations are active and functioning correctly."
elif [[ $success_rate -ge 75 ]]; then
    print_success "✅ GOOD! Most optimizations are working correctly."
    print_warning "A few minor issues detected - check the failed items above."
else
    print_warning "⚠️  NEEDS ATTENTION! Several optimizations may not be working correctly."
    print_error "Please review the failed checks and consider re-running optimizations."
fi

echo ""
print_info "💡 PERFORMANCE TIPS:"
print_info "• Monitor system: htop"
print_info "• Check memory: free -h"
print_info "• Monitor Chrome: ~/rpi5-optimization/monitoring/chrome_monitor.sh"
print_info "• View logs: tail -f ~/rpi5-optimization/logs/"
print_info "• Emergency recovery: ~/rpi5-optimization/emergency/"

echo ""
print_info "Verification completed at: $(date)"

# Exit with appropriate code
if [[ $success_rate -ge 75 ]]; then
    exit 0
else
    exit 1
fi