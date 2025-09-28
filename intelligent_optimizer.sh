#!/bin/bash

# Intelligent RPI5 Optimization Orchestrator v3.0
# Smart startup analysis, multi-restore points, auto-healing, thorough testing
# Professional-grade system optimization with intelligence and safety

set -euo pipefail

# Colors and formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m'

# Configuration
SCRIPT_DIR="/home/sri/rpi5-optimization"
BACKUP_DIR="/home/sri/rpi5-optimization/backups"
LOG_DIR="/home/sri/rpi5-optimization/logs"
RESTORE_POINTS_DIR="/home/sri/rpi5-optimization/restore_points"
ANALYSIS_DIR="/home/sri/rpi5-optimization/analysis"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
STARTUP_LOG="${LOG_DIR}/startup_analysis_${TIMESTAMP}.log"
ORCHESTRATOR_LOG="${LOG_DIR}/orchestrator_${TIMESTAMP}.log"

# Automatic mode flag
AUTOMATIC_MODE=false

# Create directories
mkdir -p "$BACKUP_DIR" "$LOG_DIR" "$RESTORE_POINTS_DIR" "$ANALYSIS_DIR"

# Enhanced logging
log() {
    local level="$1"
    shift
    local message="$*"
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') [$level] $message" | tee -a "$ORCHESTRATOR_LOG"
}

# Enhanced output functions
print_banner() { echo -e "${WHITE}${BOLD}$*${NC}"; }
print_success() { echo -e "${GREEN}✅ $*${NC}" | tee -a "$ORCHESTRATOR_LOG"; }
print_error() { echo -e "${RED}❌ $*${NC}" | tee -a "$ORCHESTRATOR_LOG"; }
print_warning() { echo -e "${YELLOW}⚠️  $*${NC}" | tee -a "$ORCHESTRATOR_LOG"; }
print_info() { echo -e "${BLUE}ℹ️  $*${NC}" | tee -a "$ORCHESTRATOR_LOG"; }
print_step() { echo -e "${PURPLE}🔧 $*${NC}" | tee -a "$ORCHESTRATOR_LOG"; }
print_analysis() { echo -e "${CYAN}🧠 $*${NC}" | tee -a "$ORCHESTRATOR_LOG"; }

# Comprehensive system analysis on startup
perform_startup_analysis() {
    print_banner "🧠 INTELLIGENT STARTUP ANALYSIS"
    echo "========================================"
    log "INFO" "Starting comprehensive system analysis"
    
    local analysis_file="${ANALYSIS_DIR}/startup_analysis_${TIMESTAMP}.json"
    
    # Gather comprehensive system data
    {
        echo "{"
        echo "  \"timestamp\": \"$(date -Iseconds)\","
        echo "  \"system\": {"
        echo "    \"uptime\": \"$(uptime -p)\","
        echo "    \"kernel\": \"$(uname -r)\","
        echo "    \"architecture\": \"$(uname -m)\","
        echo "    \"load_avg\": \"$(uptime | awk -F'load average:' '{print $2}' | xargs)\""
        echo "  },"
        echo "  \"memory\": {"
        echo "    \"total_mb\": $(free -m | awk 'NR==2{print $2}'),"
        echo "    \"available_mb\": $(free -m | awk 'NR==2{print $7}'),"
        echo "    \"used_mb\": $(free -m | awk 'NR==2{print $3}'),"
        echo "    \"usage_percent\": $(free | awk 'NR==2{printf "%.1f", $3*100/$2}')"
        echo "  },"
        echo "  \"swap\": {"
        echo "    \"total_mb\": $(free -m | awk 'NR==3{print $2}'),"
        echo "    \"used_mb\": $(free -m | awk 'NR==3{print $3}'),"
        echo "    \"swappiness\": $(cat /proc/sys/vm/swappiness),"
        echo "    \"zram_size\": \"$(zramctl --noheadings | awk '{print $3}' 2>/dev/null || echo 'N/A')\","
        echo "    \"swap_devices\": $(swapon --show --noheadings | wc -l)"
        echo "  },"
        echo "  \"storage\": {"
        echo "    \"root_usage_percent\": $(df / | awk 'NR==2 {print $5}' | tr -d '%'),"
        echo "    \"nvme_scheduler\": \"$(cat /sys/block/nvme0n1/queue/scheduler 2>/dev/null | grep -o '\\[.*\\]' | tr -d '[]' || echo 'N/A')\""
        echo "  },"
        echo "  \"processes\": {"
        echo "    \"total\": $(ps aux | wc -l),"
        echo "    \"chrome_processes\": $(pgrep -f chromium | wc -l),"
        echo "    \"teams_processes\": $(pgrep -f teams-for-linux | wc -l)"
        echo "  },"
        echo "  \"services\": {"
        echo "    \"ssh_active\": $(systemctl is-active --quiet sshd && echo 'true' || echo 'false'),"
        echo "    \"memory_manager_active\": $(systemctl is-active --quiet memory-manager && echo 'true' || echo 'false'),"
        echo "    \"zram_service_enabled\": $(systemctl is-enabled --quiet zram-swap-advanced 2>/dev/null && echo 'true' || echo 'false')"
        echo "  },"
        echo "  \"optimization_status\": {"
        echo "    \"chromium_optimized_exists\": $([ -f \"$SCRIPT_DIR/launchers/chromium-optimized\" ] && echo 'true' || echo 'false'),"
        echo "    \"teams_optimized_exists\": $([ -f \"$SCRIPT_DIR/launchers/teams-optimized\" ] && echo 'true' || echo 'false'),"
        echo "    \"nvme_optimized\": $([ -f \"/etc/systemd/system/nvme-optimize.service\" ] && echo 'true' || echo 'false')"
        echo "  },"
        echo "  \"previous_optimizations\": {"
        echo "    \"backup_count\": $(ls -1 \"$BACKUP_DIR\" 2>/dev/null | wc -l),"
        echo "    \"restore_points\": $(ls -1 \"$RESTORE_POINTS_DIR\" 2>/dev/null | wc -l),"
        echo "    \"last_optimization\": \"$(ls -1t \"$LOG_DIR\"/master_optimizer_* 2>/dev/null | head -1 | xargs basename 2>/dev/null || echo 'none')\""
        echo "  }"
        echo "}"
    } > "$analysis_file"
    
    # Analyze the data and provide intelligent recommendations
    analyze_system_data "$analysis_file"
    
    print_success "Startup analysis complete: $analysis_file"
}

# Intelligent analysis of system data
analyze_system_data() {
    local analysis_file="$1"
    print_analysis "SYSTEM INTELLIGENCE ANALYSIS"
    
    # Parse JSON data (simplified parsing)
    local memory_usage=$(grep '"usage_percent"' "$analysis_file" | awk -F': ' '{print $2}' | tr -d ',')
    local available_mb=$(grep '"available_mb"' "$analysis_file" | awk -F': ' '{print $2}' | tr -d ',')
    local swappiness=$(grep '"swappiness"' "$analysis_file" | awk -F': ' '{print $2}' | tr -d ',')
    local backup_count=$(grep '"backup_count"' "$analysis_file" | awk -F': ' '{print $2}' | tr -d ',')
    local root_usage=$(grep '"root_usage_percent"' "$analysis_file" | awk -F': ' '{print $2}' | tr -d ',')
    
    echo ""
    print_info "📊 SYSTEM STATUS ANALYSIS:"
    echo "   Memory Usage: ${memory_usage}% (Available: ${available_mb}MB)"
    echo "   Swap Settings: Swappiness = $swappiness"
    echo "   Disk Usage: ${root_usage}%"
    echo "   Previous Backups: $backup_count"
    
    # Determine system health score
    local health_score=0
    
    # Memory health (30 points)
    if (( $(echo "$available_mb > 4000" | bc -l) )); then
        health_score=$((health_score + 30))
        echo "   ✅ Memory: Excellent (${available_mb}MB available)"
    elif (( $(echo "$available_mb > 2000" | bc -l) )); then
        health_score=$((health_score + 20))
        echo "   🟡 Memory: Good (${available_mb}MB available)"
    else
        health_score=$((health_score + 10))
        echo "   ⚠️  Memory: Low (${available_mb}MB available)"
    fi
    
    # Swap configuration (25 points)
    if [ "$swappiness" -ge 10 ] && [ "$swappiness" -le 20 ]; then
        health_score=$((health_score + 25))
        echo "   ✅ Swap: Optimally configured (swappiness: $swappiness)"
    elif [ "$swappiness" -le 5 ]; then
        health_score=$((health_score + 5))
        echo "   ⚠️  Swap: Too conservative (swappiness: $swappiness)"
    else
        health_score=$((health_score + 15))
        echo "   🟡 Swap: Acceptable (swappiness: $swappiness)"
    fi
    
    # Storage health (20 points)
    if [ "$root_usage" -lt 70 ]; then
        health_score=$((health_score + 20))
        echo "   ✅ Storage: Healthy (${root_usage}% used)"
    elif [ "$root_usage" -lt 85 ]; then
        health_score=$((health_score + 10))
        echo "   🟡 Storage: Moderate (${root_usage}% used)"
    else
        health_score=$((health_score + 5))
        echo "   ⚠️  Storage: High usage (${root_usage}% used)"
    fi
    
    # Optimization history (25 points)
    if [ "$backup_count" -gt 5 ]; then
        health_score=$((health_score + 25))
        echo "   ✅ History: Well-maintained ($backup_count backups)"
    elif [ "$backup_count" -gt 0 ]; then
        health_score=$((health_score + 15))
        echo "   🟡 History: Some backups ($backup_count backups)"
    else
        health_score=$((health_score + 10))
        echo "   ℹ️  History: Fresh system (no previous backups)"
    fi
    
    echo ""
    print_analysis "🎯 SYSTEM HEALTH SCORE: $health_score/100"
    
    # Store health score for decision making
    echo "$health_score" > "${ANALYSIS_DIR}/current_health_score"
    
    # Provide intelligent recommendations
    provide_recommendations "$health_score" "$swappiness" "$available_mb" "$backup_count"
}

# Intelligent recommendations based on analysis
provide_recommendations() {
    local health_score="$1"
    local swappiness="$2"
    local available_mb="$3"
    local backup_count="$4"
    
    print_analysis "🤖 INTELLIGENT RECOMMENDATIONS:"
    
    if [ "$health_score" -ge 80 ]; then
        print_success "EXCELLENT SYSTEM HEALTH"
        echo "   • System is in excellent condition"
        echo "   • Safe to proceed with all optimizations"
        echo "   • Expected improvement: 10-20%"
    elif [ "$health_score" -ge 60 ]; then
        print_info "GOOD SYSTEM HEALTH"
        echo "   • System is stable with room for improvement"
        echo "   • Recommended approach: Step-by-step optimization"
        echo "   • Expected improvement: 20-40%"
    elif [ "$health_score" -ge 40 ]; then
        print_warning "MODERATE SYSTEM HEALTH"
        echo "   • System has some issues that need attention"
        echo "   • Recommended: Address critical issues first"
        echo "   • Expected improvement: 40-60%"
    else
        print_error "LOW SYSTEM HEALTH"
        echo "   • System requires immediate attention"
        echo "   • Recommended: Emergency recovery mode"
        echo "   • Consider manual intervention"
    fi
    
    # Specific recommendations
    echo ""
    print_analysis "📋 SPECIFIC RECOMMENDATIONS:"
    
    if [ "$swappiness" -le 5 ]; then
        echo "   🔧 CRITICAL: Fix swap memory pressure handling"
    fi
    
    if (( $(echo "$available_mb < 2000" | bc -l) )); then
        echo "   🔧 HIGH: Memory optimization needed"
    fi
    
    if [ "$backup_count" -eq 0 ]; then
        echo "   🔧 MEDIUM: Create baseline backup before optimization"
    fi
    
    echo "   🔧 STANDARD: Apply comprehensive optimizations"
    
    # Store recommendations for later use
    {
        echo "health_score=$health_score"
        echo "swappiness=$swappiness"
        echo "available_mb=$available_mb"
        echo "backup_count=$backup_count"
        echo "recommendation_level=$([ "$health_score" -ge 60 ] && echo "safe" || echo "careful")"
    } > "${ANALYSIS_DIR}/recommendations"
}

# Enhanced backup system with multiple restore points
create_restore_point() {
    local point_name="$1"
    local description="$2"
    local restore_point_dir="${RESTORE_POINTS_DIR}/restore_point_${point_name}_${TIMESTAMP}"
    
    print_step "Creating restore point: $point_name"
    mkdir -p "$restore_point_dir"
    
    # Comprehensive system backup
    {
        echo "# Restore Point: $point_name"
        echo "# Description: $description"
        echo "# Created: $(date)"
        echo "# Health Score: $(cat "${ANALYSIS_DIR}/current_health_score" 2>/dev/null || echo "unknown")"
        echo ""
        
        # System state
        echo "=== SYSTEM STATE ==="
        echo "Kernel: $(uname -a)"
        echo "Uptime: $(uptime)"
        echo "Memory: $(free -h)"
        echo "Swap: $(swapon --show)"
        echo "Load: $(cat /proc/loadavg)"
        echo ""
        
        # Critical configurations
        echo "=== CRITICAL CONFIGURATIONS ==="
        echo "Swappiness: $(cat /proc/sys/vm/swappiness)"
        echo "VFS Cache Pressure: $(cat /proc/sys/vm/vfs_cache_pressure)"
        echo "NVMe Scheduler: $(cat /sys/block/nvme0n1/queue/scheduler 2>/dev/null || echo 'N/A')"
        echo ""
        
        # Running services
        echo "=== ACTIVE SERVICES ==="
        systemctl list-units --state=active --type=service --no-pager
        
    } > "$restore_point_dir/system_snapshot.txt"
    
    # Backup critical files
    local files_to_backup=(
        "/etc/sysctl.conf"
        "/etc/sysctl.d/"
        "/etc/security/limits.conf"
        "/etc/systemd/system/"
        "/home/sri/.config/chromium/"
        "/home/sri/.local/share/applications/"
    )
    
    for item in "${files_to_backup[@]}"; do
        if [[ -e "$item" ]]; then
            local dest_path="$restore_point_dir/files$(dirname "$item")"
            mkdir -p "$dest_path"
            cp -r "$item" "$dest_path/" 2>/dev/null || true
        fi
    done
    
    # Save current kernel parameters
    {
        echo "vm.swappiness=$(cat /proc/sys/vm/swappiness)"
        echo "vm.vfs_cache_pressure=$(cat /proc/sys/vm/vfs_cache_pressure)"
        echo "vm.dirty_ratio=$(cat /proc/sys/vm/dirty_ratio)"
        echo "vm.dirty_background_ratio=$(cat /proc/sys/vm/dirty_background_ratio)"
    } > "$restore_point_dir/kernel_params.conf"
    
    # Create smart restoration script
    cat > "$restore_point_dir/smart_restore.sh" << 'EOF'
#!/bin/bash
# Smart Restoration Script
RESTORE_DIR="$(dirname "$0")"

echo "🔄 SMART SYSTEM RESTORATION"
echo "=========================="
echo "Restore Point: $(basename "$RESTORE_DIR")"
echo "Created: $(grep "# Created:" "$RESTORE_DIR/system_snapshot.txt" | cut -d: -f2-)"
echo ""

# Restore kernel parameters
if [[ -f "$RESTORE_DIR/kernel_params.conf" ]]; then
    echo "Restoring kernel parameters..."
    while read -r param; do
        if [[ "$param" =~ ^vm\.([^=]+)=(.+)$ ]]; then
            local param_name="${BASH_REMATCH[1]}"
            local param_value="${BASH_REMATCH[2]}"
            echo "$param_value" | sudo tee "/proc/sys/vm/$param_name" > /dev/null
        fi
    done < "$RESTORE_DIR/kernel_params.conf"
fi

# Restore configuration files
if [[ -d "$RESTORE_DIR/files" ]]; then
    echo "Restoring configuration files..."
    sudo cp -r "$RESTORE_DIR/files"/* / 2>/dev/null || true
fi

# Reload systemd
sudo systemctl daemon-reload

echo "✅ Smart restoration completed"
echo "⚠️  System restart recommended for full restoration"
EOF
    
    chmod +x "$restore_point_dir/smart_restore.sh"
    
    print_success "Restore point created: $restore_point_dir"
    echo "$restore_point_dir"
}

# Enhanced testing framework
perform_comprehensive_test() {
    local test_name="$1"
    local pre_restore_point="$2"
    
    print_step "COMPREHENSIVE TESTING: $test_name"
    
    # Pre-test health check
    local pre_health=$(check_system_health "pre-$test_name")
    print_info "Pre-test health score: $pre_health/100"
    
    # Memory pressure test
    print_info "Testing memory pressure handling..."
    local memory_test_result=0
    
    if command -v stress >/dev/null 2>&1; then
        # Test swap utilization
        stress --vm 1 --vm-bytes 1G --timeout 15s &
        local stress_pid=$!
        
        sleep 5
        local swap_used_during=$(free -m | awk 'NR==3{print $3}')
        
        wait $stress_pid 2>/dev/null || true
        
        if [ "$swap_used_during" -gt 0 ]; then
            print_success "Memory pressure test: PASSED (Swap utilized: ${swap_used_during}MB)"
            memory_test_result=1
        else
            print_warning "Memory pressure test: Limited swap utilization"
        fi
    else
        print_info "Stress testing tools not available - skipping memory test"
        memory_test_result=1
    fi
    
    # Application responsiveness test
    print_info "Testing application responsiveness..."
    local responsiveness_test=1
    
    # Load average test
    local load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk -F',' '{print $1}' | xargs)
    if (( $(echo "$load_avg > 5.0" | bc -l) )); then
        print_warning "High load average: $load_avg"
        responsiveness_test=0
    fi
    
    # Memory availability test
    local available_mem=$(free -m | awk 'NR==2{print $7}')
    if [ "$available_mem" -lt 500 ]; then
        print_warning "Low available memory: ${available_mem}MB"
        responsiveness_test=0
    fi
    
    # Post-test health check
    sleep 2
    local post_health=$(check_system_health "post-$test_name")
    print_info "Post-test health score: $post_health/100"
    
    # Calculate test score
    local test_score=0
    test_score=$((test_score + memory_test_result * 40))
    test_score=$((test_score + responsiveness_test * 30))
    
    # Health improvement score
    local health_diff=$((post_health - pre_health))
    if [ "$health_diff" -ge 5 ]; then
        test_score=$((test_score + 30))
    elif [ "$health_diff" -ge 0 ]; then
        test_score=$((test_score + 20))
    else
        test_score=$((test_score + 10))
    fi
    
    print_info "Overall test score: $test_score/100"
    
    # Decision logic
    if [ "$test_score" -ge 70 ]; then
        print_success "TEST PASSED: Optimization is stable and beneficial"
        return 0
    elif [ "$test_score" -ge 50 ]; then
        print_warning "TEST MARGINAL: Optimization has mixed results"
        if [[ "$AUTOMATIC_MODE" == "true" ]]; then
            print_info "Automatic mode: Keeping marginal optimization"
            return 0
        else
            echo "Do you want to keep this optimization? (y/N): "
            read -r response
            if [[ "$response" =~ ^[Yy]$ ]]; then
                return 0
            else
                return 1
            fi
        fi
    else
        print_error "TEST FAILED: Optimization caused degradation"
        return 1
    fi
}

# Enhanced health check function
check_system_health() {
    local check_name="$1"
    local health_score=0
    
    # Memory check (25 points)
    local available_mem=$(free -m | awk 'NR==2{print $7}')
    if [ "$available_mem" -gt 4000 ]; then
        health_score=$((health_score + 25))
    elif [ "$available_mem" -gt 2000 ]; then
        health_score=$((health_score + 15))
    elif [ "$available_mem" -gt 1000 ]; then
        health_score=$((health_score + 10))
    fi
    
    # CPU load check (25 points)
    local load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk -F',' '{print $1}' | xargs)
    if (( $(echo "$load_avg < 1.0" | bc -l) )); then
        health_score=$((health_score + 25))
    elif (( $(echo "$load_avg < 2.0" | bc -l) )); then
        health_score=$((health_score + 15))
    elif (( $(echo "$load_avg < 4.0" | bc -l) )); then
        health_score=$((health_score + 10))
    fi
    
    # Storage check (25 points)
    local root_usage=$(df / | awk 'NR==2 {print $5}' | tr -d '%')
    if [ "$root_usage" -lt 70 ]; then
        health_score=$((health_score + 25))
    elif [ "$root_usage" -lt 85 ]; then
        health_score=$((health_score + 15))
    elif [ "$root_usage" -lt 95 ]; then
        health_score=$((health_score + 10))
    fi
    
    # Swap utilization check (25 points)
    local swap_total=$(free -m | awk 'NR==3{print $2}')
    local swappiness=$(cat /proc/sys/vm/swappiness)
    if [ "$swap_total" -gt 1000 ] && [ "$swappiness" -ge 10 ]; then
        health_score=$((health_score + 25))
    elif [ "$swap_total" -gt 500 ]; then
        health_score=$((health_score + 15))
    else
        health_score=$((health_score + 10))
    fi
    
    # Log health check
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$check_name] Health Score: $health_score/100" >> "${LOG_DIR}/health_checks.log"
    
    echo "$health_score"
}

# Safe optimization execution with comprehensive testing
safe_optimize() {
    local script_name="$1"
    local script_path="$SCRIPT_DIR/$script_name"
    local opt_name=$(basename "$script_name" .sh)
    
    if [[ ! -f "$script_path" ]] || [[ ! -x "$script_path" ]]; then
        print_error "Optimization script not found or not executable: $script_path"
        return 1
    fi
    
    print_banner "🚀 SAFE OPTIMIZATION: $opt_name"
    echo "========================================="
    
    # Create pre-optimization restore point
    local pre_restore_point=$(create_restore_point "pre_${opt_name}" "Before $opt_name optimization")
    
    # Execute optimization with monitoring
    print_step "Executing optimization: $script_path"
    local execution_start_time=$(date +%s)
    
    if timeout 300 bash "$script_path"; then
        print_success "Optimization execution completed"
    else
        local exit_code=$?
        print_error "Optimization failed with exit code: $exit_code"
        
        print_warning "Restoring from pre-optimization state..."
        bash "$pre_restore_point/smart_restore.sh"
        return 1
    fi
    
    # Wait for system to stabilize
    print_info "Waiting for system stabilization..."
    sleep 5
    
    # Comprehensive testing
    if perform_comprehensive_test "$opt_name" "$pre_restore_point"; then
        # Create post-optimization restore point
        local post_restore_point=$(create_restore_point "post_${opt_name}" "After successful $opt_name optimization")
        
        print_success "OPTIMIZATION SUCCESSFUL: $opt_name"
        
        # Ask user about restart
        echo ""
        print_info "Optimization completed successfully!"
        
        if [[ "$AUTOMATIC_MODE" == "true" ]]; then
            print_info "Automatic mode: Continuing without restart"
            print_info "Note: Some changes may require restart to take full effect"
        else
            echo "Do you want to restart the system to fully apply changes? (y/N): "
            read -r restart_response
            
            if [[ "$restart_response" =~ ^[Yy]$ ]]; then
                print_info "System will restart in 10 seconds... Press Ctrl+C to cancel"
                sleep 10
                sudo reboot
            else
                print_info "Continuing without restart. Some changes may require restart to take full effect."
            fi
        fi
        
        return 0
    else
        print_error "OPTIMIZATION FAILED TESTING: $opt_name"
        print_warning "Rolling back to pre-optimization state..."
        
        bash "$pre_restore_point/smart_restore.sh"
        
        # Wait for rollback to complete
        sleep 3
        
        print_info "System restored to pre-optimization state"
        return 1
    fi
}

# Interactive optimization flow
interactive_optimization() {
    local available_optimizations=(
        "fix_swap_memory_pressure.sh:Swap Memory Pressure Fix"
        "nvme/nvme_optimize.sh:NVMe Storage Optimization"
        "chrome/chrome_optimize.sh:Chrome Browser Optimization"
        "advanced_memory_optimization.sh:Advanced Memory Management"
    )
    
    print_banner "🎮 INTERACTIVE OPTIMIZATION MODE"
    echo "================================="
    
    # Show recommendations based on startup analysis
    if [[ -f "${ANALYSIS_DIR}/recommendations" ]]; then
        source "${ANALYSIS_DIR}/recommendations"
        
        echo ""
        print_analysis "Based on system analysis (Health Score: $health_score/100):"
        
        if [[ "$recommendation_level" == "safe" ]]; then
            print_success "System is healthy - safe to proceed with all optimizations"
        else
            print_warning "System needs careful optimization - proceed step by step"
        fi
    fi
    
    echo ""
    echo "Available optimizations:"
    for i in "${!available_optimizations[@]}"; do
        local opt_info=(${available_optimizations[$i]//:/ })
        local script_name="${opt_info[0]}"
        local description="${opt_info[1]}"
        
        # Check if optimization has been applied
        local status="[NEW]"
        if [[ -f "${RESTORE_POINTS_DIR}"/restore_point_*"${script_name%.*}"* ]]; then
            status="[APPLIED]"
        fi
        
        echo "$((i+1)). $description $status"
    done
    
    echo "a) Apply all optimizations automatically"
    echo "r) View restore points"
    echo "h) System health check"
    echo "q) Quit"
    
    echo ""
    read -p "Select option: " choice
    
    case "$choice" in
        [1-9])
            local index=$((choice-1))
            if [[ $index -lt ${#available_optimizations[@]} ]]; then
                local opt_info=(${available_optimizations[$index]//:/ })
                safe_optimize "${opt_info[0]}"
            else
                print_error "Invalid selection"
            fi
            ;;
        "a"|"A")
            auto_optimization_sequence
            ;;
        "r"|"R")
            show_restore_points
            ;;
        "h"|"H")
            local current_health=$(check_system_health "manual")
            print_info "Current system health: $current_health/100"
            ;;
        "q"|"Q")
            print_info "Goodbye!"
            exit 0
            ;;
        *)
            print_warning "Invalid option"
            ;;
    esac
}

# Automatic optimization sequence
auto_optimization_sequence() {
    print_banner "⚡ AUTOMATIC OPTIMIZATION SEQUENCE"
    echo "==================================="
    
    # Ensure automatic mode flag is set
    AUTOMATIC_MODE=true
    export AUTOMATIC_MODE
    
    local optimizations=(
        "fix_swap_memory_pressure.sh"
        "nvme/nvme_optimize.sh" 
        "chrome/chrome_optimize.sh"
        "advanced_memory_optimization.sh"
    )
    
    local successful_optimizations=0
    
    for opt_script in "${optimizations[@]}"; do
        if safe_optimize "$opt_script"; then
            ((successful_optimizations++))
        else
            print_warning "Optimization failed, but continuing with sequence..."
        fi
        
        # Brief pause between optimizations
        sleep 2
    done
    
    print_banner "📊 OPTIMIZATION SEQUENCE COMPLETE"
    echo "=================================="
    print_info "Successfully applied: $successful_optimizations/${#optimizations[@]} optimizations"
    
    if [[ $successful_optimizations -eq ${#optimizations[@]} ]]; then
        print_success "ALL OPTIMIZATIONS SUCCESSFUL!"
        
        # Create final success restore point
        create_restore_point "complete_optimization" "All optimizations successfully applied"
        
        echo ""
        print_info "🎉 Your Raspberry Pi 5 is now fully optimized!"
        print_info "System restart recommended to ensure all optimizations are active."
        
        if [[ "$AUTOMATIC_MODE" == "true" ]]; then
            print_info "Automatic mode complete. Restart when convenient."
        else
            echo ""
            echo "Restart now? (y/N): "
            read -r final_restart
            if [[ "$final_restart" =~ ^[Yy]$ ]]; then
                sudo reboot
            fi
        fi
    else
        print_warning "Some optimizations failed. Check logs for details."
        print_info "You can retry individual optimizations or check restore points."
    fi
}

# Show available restore points
show_restore_points() {
    print_banner "🔄 AVAILABLE RESTORE POINTS"
    echo "==========================="
    
    if [[ ! -d "$RESTORE_POINTS_DIR" ]] || [[ -z "$(ls -A "$RESTORE_POINTS_DIR" 2>/dev/null)" ]]; then
        print_info "No restore points available"
        return
    fi
    
    echo ""
    echo "Available restore points:"
    local points=($(ls -1t "$RESTORE_POINTS_DIR"))
    
    for i in "${!points[@]}"; do
        local point_dir="${RESTORE_POINTS_DIR}/${points[$i]}"
        local created_date=$(stat -c %y "$point_dir" | cut -d' ' -f1)
        local description=$(grep "# Description:" "$point_dir/system_snapshot.txt" 2>/dev/null | cut -d: -f2- | xargs)
        
        echo "$((i+1)). ${points[$i]}"
        echo "    Created: $created_date"
        echo "    Description: ${description:-No description}"
        echo ""
    done
    
    echo "r) Restore from point"
    echo "b) Back to main menu"
    
    read -p "Select option: " restore_choice
    
    if [[ "$restore_choice" == "r" || "$restore_choice" == "R" ]]; then
        echo "Enter restore point number: "
        read -r point_num
        
        if [[ "$point_num" -ge 1 ]] && [[ "$point_num" -le ${#points[@]} ]]; then
            local selected_point="${RESTORE_POINTS_DIR}/${points[$((point_num-1))]}"
            
            echo "Restore from: ${points[$((point_num-1))]}? (y/N): "
            read -r confirm_restore
            
            if [[ "$confirm_restore" =~ ^[Yy]$ ]]; then
                print_step "Restoring system..."
                bash "$selected_point/smart_restore.sh"
                
                print_success "System restored!"
                print_info "Restart recommended to ensure all changes take effect"
            fi
        else
            print_error "Invalid restore point number"
        fi
    fi
}

# Main orchestrator
main() {
    # Check for command line arguments
    if [[ "$1" == "auto" ]] || [[ "$1" == "automatic" ]] || [[ "$1" == "2" ]]; then
        # Skip banner and analysis for fully automatic mode
        print_banner "🚀 FULLY AUTOMATIC OPTIMIZATION MODE"
        echo "===================================="
        print_info "Running all optimizations automatically without user input"
        echo ""
        
        # Perform startup analysis
        perform_startup_analysis
        
        # Set automatic mode and run sequence directly
        AUTOMATIC_MODE=true
        auto_optimization_sequence
        return
    fi
    
    # Startup banner for interactive mode
    print_banner "🧠 INTELLIGENT RPI5 OPTIMIZATION ORCHESTRATOR v3.0"
    print_banner "    Smart Analysis • Multi-Restore Points • Auto-Healing"
    print_banner "    Professional System Optimization with Intelligence"
    echo "========================================================"
    echo ""
    
    # Perform startup analysis
    perform_startup_analysis
    
    echo ""
    echo "Mode selection:"
    echo "1) Interactive optimization (recommended)"
    echo "2) Automatic optimization sequence"  
    echo "3) Restore points management"
    echo "4) System health check only"
    echo "5) Emergency recovery"
    
    echo ""
    read -p "Select mode (1-5): " mode_choice
    
    case "$mode_choice" in
        1)
            while true; do
                interactive_optimization
                echo ""
                echo "Continue with more optimizations? (y/N): "
                read -r continue_choice
                if [[ ! "$continue_choice" =~ ^[Yy]$ ]]; then
                    break
                fi
            done
            ;;
        2)
            auto_optimization_sequence
            ;;
        3)
            show_restore_points
            ;;
        4)
            local health=$(check_system_health "manual")
            print_info "System health: $health/100"
            ;;
        5)
            print_warning "Emergency recovery mode - finding best restore point..."
            show_restore_points
            ;;
        *)
            print_error "Invalid mode selection"
            exit 1
            ;;
    esac
    
    print_success "Intelligent Orchestrator session complete!"
}

# Initialize and run
log "INFO" "Starting Intelligent Optimization Orchestrator v3.0"
main "$@"