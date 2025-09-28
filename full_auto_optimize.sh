#!/bin/bash

# Full Automatic RPI5 Optimization Script
# Runs all optimizations sequentially without any user input

# Configuration
SCRIPT_DIR="/home/sri/rpi5-optimization"
LOG_DIR="$SCRIPT_DIR/logs"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
AUTO_LOG="$LOG_DIR/full_auto_optimize_$TIMESTAMP.log"

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

# Create log directory
mkdir -p "$LOG_DIR"

# Enhanced output functions with logging
log_and_print() {
    local level="$1"
    shift
    local message="$*"
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') [$level] $message" | tee -a "$AUTO_LOG"
}

print_banner() { echo -e "${WHITE}${BOLD}$*${NC}" | tee -a "$AUTO_LOG"; }
print_success() { echo -e "${GREEN}✅ $*${NC}" | tee -a "$AUTO_LOG"; }
print_error() { echo -e "${RED}❌ $*${NC}" | tee -a "$AUTO_LOG"; }
print_warning() { echo -e "${YELLOW}⚠️  $*${NC}" | tee -a "$AUTO_LOG"; }
print_info() { echo -e "${BLUE}ℹ️  $*${NC}" | tee -a "$AUTO_LOG"; }
print_step() { echo -e "${PURPLE}🔧 $*${NC}" | tee -a "$AUTO_LOG"; }

# Start optimization
print_banner "🚀 FULL AUTOMATIC RPI5 OPTIMIZATION"
print_banner "======================================="
log_and_print "INFO" "Starting full automatic optimization sequence"
echo ""

print_info "System Analysis:"
print_info "• Memory: $(free -h | awk 'NR==2{printf "%s total, %s available", $2, $7}')"
print_info "• Swap: $(free -h | awk 'NR==3{printf "%s total, %s used", $2, $3}')"
print_info "• Swappiness: $(cat /proc/sys/vm/swappiness)"
print_info "• Storage: $(df -h / | awk 'NR==2{print $5}') used"
echo ""

# Optimization scripts to run in sequence
OPTIMIZATIONS=(
    "$SCRIPT_DIR/fix_swap_memory_pressure.sh:Swap Memory Pressure Optimization"
    "$SCRIPT_DIR/nvme/nvme_optimize.sh:NVMe Storage Performance Optimization"
    "$SCRIPT_DIR/chrome/chrome_optimize.sh:Chrome Browser Optimization"
    "$SCRIPT_DIR/advanced_memory_optimization.sh:Advanced Memory Management"
)

successful_count=0
total_count=${#OPTIMIZATIONS[@]}

for i in "${!OPTIMIZATIONS[@]}"; do
    IFS=':' read -r script_path description <<< "${OPTIMIZATIONS[$i]}"
    
    print_banner "🚀 OPTIMIZATION $((i+1))/$total_count: $description"
    echo "=========================================="
    
    if [[ ! -f "$script_path" ]]; then
        print_error "Script not found: $script_path"
        continue
    fi
    
    if [[ ! -x "$script_path" ]]; then
        print_step "Making script executable: $script_path"
        chmod +x "$script_path"
    fi
    
    print_step "Executing: $script_path"
    log_and_print "INFO" "Starting optimization: $script_path"
    
    # Run optimization with timeout
    if timeout 300 bash "$script_path" >> "$AUTO_LOG" 2>&1; then
        print_success "Optimization completed: $description"
        ((successful_count++))
        
        # Brief pause for system stabilization
        print_info "Waiting for system stabilization (5 seconds)..."
        sleep 5
    else
        local exit_code=$?
        print_error "Optimization failed: $description (exit code: $exit_code)"
        log_and_print "ERROR" "Failed optimization: $script_path with exit code $exit_code"
    fi
    
    echo ""
done

# Final results
print_banner "📊 OPTIMIZATION RESULTS"
echo "========================"
print_info "Completed: $successful_count/$total_count optimizations"

if [[ $successful_count -eq $total_count ]]; then
    print_success "🎉 ALL OPTIMIZATIONS COMPLETED SUCCESSFULLY!"
    
    # Create completion marker
    echo "$(date '+%Y-%m-%d %H:%M:%S'): Full automatic optimization completed successfully" > "$SCRIPT_DIR/last_optimization_success.txt"
    
    print_info ""
    print_info "🎯 OPTIMIZATION SUMMARY:"
    print_info "• Swap memory pressure optimized"
    print_info "• NVMe storage performance enhanced"
    print_info "• Chrome browser optimized for better tab management"
    print_info "• Advanced memory management configured"
    print_info ""
    print_info "💡 RECOMMENDATIONS:"
    print_info "• Restart the system to ensure all optimizations take effect: sudo reboot"
    print_info "• Monitor performance with: htop, free -h, ~/rpi5-optimization/monitoring/"
    print_info "• View logs: tail -f $AUTO_LOG"
    
elif [[ $successful_count -gt 0 ]]; then
    print_warning "⚠️  PARTIAL SUCCESS: $successful_count/$total_count optimizations completed"
    print_info "Check the log for details: $AUTO_LOG"
    print_info "You can retry failed optimizations individually"
else
    print_error "❌ NO OPTIMIZATIONS COMPLETED"
    print_error "Check the log for details: $AUTO_LOG"
    print_error "You may need to run optimizations individually or check system status"
fi

print_info ""
print_info "📋 System Status After Optimization:"
print_info "• Memory: $(free -h | awk 'NR==2{printf "%s total, %s available", $2, $7}')"
print_info "• Swap: $(free -h | awk 'NR==3{printf "%s total, %s used", $2, $3}')"
print_info "• Swappiness: $(cat /proc/sys/vm/swappiness)"
print_info "• Load Average: $(uptime | awk -F'load average:' '{print $2}')"

echo ""
print_info "Full automatic optimization completed at: $(date)"
log_and_print "INFO" "Full automatic optimization sequence finished"

# Return appropriate exit code
if [[ $successful_count -eq $total_count ]]; then
    exit 0
else
    exit 1
fi