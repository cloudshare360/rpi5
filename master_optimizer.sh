#!/bin/bash

# RPI5 Master Optimization Script with Auto-Healing
# Professional-grade optimization with backup, rollback, and recovery capabilities
# Version: 2.0 Enterprise Edition

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="/home/sri/rpi5-optimization"
BACKUP_DIR="/home/sri/rpi5-optimization/backups"
LOG_DIR="/home/sri/rpi5-optimization/logs"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
LOG_FILE="${LOG_DIR}/master_optimizer_${TIMESTAMP}.log"
HEALTH_CHECK_LOG="${LOG_DIR}/health_checks.log"

# Create necessary directories
mkdir -p "$BACKUP_DIR" "$LOG_DIR"

# Logging function
log() {
    local level="$1"
    shift
    local message="$*"
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') [$level] $message" | tee -a "$LOG_FILE"
}

# Colored output functions
print_header() { echo -e "${WHITE}$*${NC}"; }
print_success() { echo -e "${GREEN}✅ $*${NC}" | tee -a "$LOG_FILE"; }
print_error() { echo -e "${RED}❌ $*${NC}" | tee -a "$LOG_FILE"; }
print_warning() { echo -e "${YELLOW}⚠️  $*${NC}" | tee -a "$LOG_FILE"; }
print_info() { echo -e "${BLUE}ℹ️  $*${NC}" | tee -a "$LOG_FILE"; }
print_step() { echo -e "${PURPLE}🔧 $*${NC}" | tee -a "$LOG_FILE"; }

# System health check function
check_system_health() {
    local check_name="$1"
    log "INFO" "Running health check: $check_name"
    
    local health_score=0
    local max_score=100
    
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
    
    # Filesystem check (25 points)
    local root_usage=$(df / | awk 'NR==2 {print $5}' | tr -d '%')
    if [ "$root_usage" -lt 80 ]; then
        health_score=$((health_score + 25))
    elif [ "$root_usage" -lt 90 ]; then
        health_score=$((health_score + 15))
    elif [ "$root_usage" -lt 95 ]; then
        health_score=$((health_score + 10))
    fi
    
    # Services check (25 points)
    local critical_services=("sshd" "networkd" "systemd-resolved")
    local service_score=0
    for service in "${critical_services[@]}"; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            service_score=$((service_score + 8))
        fi
    done
    health_score=$((health_score + service_score))
    
    # Log health check results
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$check_name] Health Score: $health_score/$max_score (Available Memory: ${available_mem}MB, Load: $load_avg, Root Usage: ${root_usage}%)" >> "$HEALTH_CHECK_LOG"
    
    echo "$health_score"
}

# Backup system configuration
create_system_backup() {
    local backup_name="$1"
    local backup_path="${BACKUP_DIR}/backup_${backup_name}_${TIMESTAMP}"
    
    print_step "Creating system backup: $backup_name"
    mkdir -p "$backup_path"
    
    # Backup critical system files
    local files_to_backup=(
        "/etc/sysctl.conf"
        "/etc/sysctl.d/"
        "/etc/security/limits.conf"
        "/etc/systemd/system/"
        "/proc/sys/vm/swappiness"
        "/proc/sys/vm/vfs_cache_pressure"
        "/proc/sys/vm/dirty_ratio"
        "/proc/sys/vm/dirty_background_ratio"
        "/sys/block/nvme*/queue/scheduler"
        "/home/sri/.config/chromium/Default/Preferences"
        "/home/sri/.local/share/applications/chromium.desktop"
    )
    
    for item in "${files_to_backup[@]}"; do
        if [[ -e "$item" ]]; then
            local dest_path="$backup_path/$(dirname "$item")"
            mkdir -p "$dest_path"
            cp -r "$item" "$dest_path/" 2>/dev/null || {
                # For /proc and /sys files, save their values instead
                if [[ "$item" == /proc/* ]] || [[ "$item" == /sys/* ]]; then
                    echo "$(cat "$item" 2>/dev/null || echo 'N/A')" > "${backup_path}/${item//\//_}"
                fi
            }
        fi
    done
    
    # Backup current system state
    {
        echo "=== SYSTEM STATE BACKUP ==="
        echo "Timestamp: $(date)"
        echo "Kernel: $(uname -a)"
        echo "Memory: $(free -h)"
        echo "Load: $(uptime)"
        echo "Mounted filesystems: $(mount)"
        echo "Active services: $(systemctl list-units --state=active --no-pager)"
        echo "Network: $(ip addr)"
        echo "=== END BACKUP ==="
    } > "$backup_path/system_state.txt"
    
    # Create restoration script
    cat > "$backup_path/restore.sh" << 'EOF'
#!/bin/bash
# Auto-generated restoration script
BACKUP_DIR="$(dirname "$0")"
echo "🔄 Restoring system configuration from backup..."

# Restore sysctl parameters
if [[ -f "$BACKUP_DIR/_proc_sys_vm_swappiness" ]]; then
    echo "$(cat "$BACKUP_DIR/_proc_sys_vm_swappiness")" | sudo tee /proc/sys/vm/swappiness > /dev/null
fi

if [[ -f "$BACKUP_DIR/_proc_sys_vm_vfs_cache_pressure" ]]; then
    echo "$(cat "$BACKUP_DIR/_proc_sys_vm_vfs_cache_pressure")" | sudo tee /proc/sys/vm/vfs_cache_pressure > /dev/null
fi

if [[ -f "$BACKUP_DIR/_proc_sys_vm_dirty_ratio" ]]; then
    echo "$(cat "$BACKUP_DIR/_proc_sys_vm_dirty_ratio")" | sudo tee /proc/sys/vm/dirty_ratio > /dev/null
fi

# Restore configuration files
if [[ -d "$BACKUP_DIR/etc" ]]; then
    sudo cp -r "$BACKUP_DIR/etc"/* /etc/ 2>/dev/null || true
fi

if [[ -d "$BACKUP_DIR/home" ]]; then
    cp -r "$BACKUP_DIR/home"/* /home/ 2>/dev/null || true
fi

# Reload systemd and restart services
sudo systemctl daemon-reload
echo "✅ System restoration complete"
EOF
    chmod +x "$backup_path/restore.sh"
    
    print_success "Backup created: $backup_path"
    echo "$backup_path" # Return backup path
}

# Restore from backup
restore_from_backup() {
    local backup_path="$1"
    print_warning "SYSTEM RECOVERY: Restoring from backup $backup_path"
    
    if [[ -f "$backup_path/restore.sh" ]]; then
        bash "$backup_path/restore.sh"
        print_success "System restored from backup"
        return 0
    else
        print_error "Backup restoration script not found"
        return 1
    fi
}

# Auto-healing function
auto_heal_system() {
    print_warning "AUTO-HEALING: System health degraded, attempting recovery..."
    
    # Find the most recent healthy backup
    local latest_backup=""
    local best_health=0
    
    for backup in "$BACKUP_DIR"/backup_*; do
        if [[ -f "$backup/system_state.txt" ]]; then
            # Extract health score from backup (simplified)
            local backup_timestamp=$(basename "$backup" | cut -d'_' -f3-4)
            if [[ -n "$backup_timestamp" ]] && [[ "$backup_timestamp" > "$(date -d '1 hour ago' '+%Y%m%d_%H%M%S')" ]]; then
                latest_backup="$backup"
                break
            fi
        fi
    done
    
    if [[ -n "$latest_backup" ]]; then
        print_info "Found suitable backup for recovery: $latest_backup"
        restore_from_backup "$latest_backup"
        
        # Wait and check health again
        sleep 5
        local new_health=$(check_system_health "post-recovery")
        if [[ "$new_health" -gt 60 ]]; then
            print_success "AUTO-HEALING SUCCESSFUL: System health restored"
            return 0
        else
            print_error "AUTO-HEALING PARTIAL: System partially recovered"
            return 1
        fi
    else
        print_error "AUTO-HEALING FAILED: No suitable backup found"
        return 1
    fi
}

# Safe execution wrapper
safe_execute() {
    local script_path="$1"
    local script_name=$(basename "$script_path" .sh)
    local pre_health=$(check_system_health "pre-$script_name")
    
    print_header "🚀 EXECUTING: $script_name"
    print_info "Pre-execution health score: $pre_health/100"
    
    # Create backup before execution
    local backup_path=$(create_system_backup "$script_name")
    
    # Execute the script with timeout and error handling
    local execution_result=0
    print_step "Running $script_path..."
    
    if timeout 300 bash "$script_path"; then
        print_success "$script_name completed successfully"
    else
        execution_result=$?
        print_error "$script_name failed with exit code $execution_result"
    fi
    
    # Health check after execution
    sleep 2
    local post_health=$(check_system_health "post-$script_name")
    print_info "Post-execution health score: $post_health/100"
    
    # Determine if we need to rollback
    local health_degradation=$((pre_health - post_health))
    
    if [[ "$execution_result" -ne 0 ]] || [[ "$post_health" -lt 50 ]] || [[ "$health_degradation" -gt 20 ]]; then
        print_warning "SYSTEM HEALTH DEGRADED: Rolling back changes"
        restore_from_backup "$backup_path"
        
        # Final health check
        sleep 2
        local final_health=$(check_system_health "post-rollback-$script_name")
        if [[ "$final_health" -lt "$pre_health" ]]; then
            print_error "ROLLBACK INCOMPLETE: Attempting auto-healing"
            auto_heal_system
        else
            print_success "ROLLBACK SUCCESSFUL: System restored"
        fi
        return 1
    else
        print_success "$script_name applied successfully (Health: $pre_health → $post_health)"
        return 0
    fi
}

# Main optimization sequence
run_optimization_sequence() {
    local optimization_scripts=(
        "$SCRIPT_DIR/nvme/nvme_optimize.sh"
        "$SCRIPT_DIR/chrome/chrome_optimize.sh"
        "$SCRIPT_DIR/fix_swap_memory_pressure.sh"
        "$SCRIPT_DIR/advanced_memory_optimization.sh"
    )
    
    print_header "🎯 RPI5 MASTER OPTIMIZATION SEQUENCE"
    print_info "Starting comprehensive system optimization with auto-healing"
    print_info "Backup directory: $BACKUP_DIR"
    print_info "Log file: $LOG_FILE"
    
    local initial_health=$(check_system_health "initial")
    print_info "Initial system health: $initial_health/100"
    
    if [[ "$initial_health" -lt 40 ]]; then
        print_warning "System health is low. Consider manual intervention before optimization."
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Optimization cancelled by user"
            exit 0
        fi
    fi
    
    # Create master backup
    local master_backup=$(create_system_backup "master_pre_optimization")
    
    local successful_optimizations=0
    local total_optimizations=${#optimization_scripts[@]}
    
    for script in "${optimization_scripts[@]}"; do
        if [[ -f "$script" && -x "$script" ]]; then
            if safe_execute "$script"; then
                ((successful_optimizations++))
            else
                print_warning "Optimization $(basename "$script") failed, continuing with others..."
            fi
        else
            print_warning "Script not found or not executable: $script"
        fi
        
        # Brief pause between optimizations
        sleep 1
    done
    
    # Final system assessment
    local final_health=$(check_system_health "final")
    print_header "📊 OPTIMIZATION COMPLETE"
    print_info "Successful optimizations: $successful_optimizations/$total_optimizations"
    print_info "Final system health: $final_health/100 (Initial: $initial_health/100)"
    
    if [[ "$final_health" -gt "$initial_health" ]] && [[ "$successful_optimizations" -gt 0 ]]; then
        print_success "OPTIMIZATION SUCCESSFUL: System performance improved!"
        
        # Create success snapshot
        create_system_backup "success_snapshot"
        
        print_info "🎯 Next steps:"
        print_info "1. Restart system to apply all optimizations: sudo reboot"
        print_info "2. Use optimized launchers: $SCRIPT_DIR/launchers/"
        print_info "3. Monitor performance: $SCRIPT_DIR/monitoring/"
    else
        print_warning "OPTIMIZATION MIXED RESULTS: Some improvements may not have applied"
        print_info "Consider running individual optimization scripts manually"
        print_info "Master backup available at: $master_backup"
    fi
}

# Emergency recovery mode
emergency_recovery() {
    print_header "🆘 EMERGENCY RECOVERY MODE"
    print_warning "Attempting to find and restore most recent healthy backup..."
    
    # Find all backups and their health scores
    local best_backup=""
    local best_score=0
    
    for backup_dir in "$BACKUP_DIR"/backup_*; do
        if [[ -d "$backup_dir" ]] && [[ -f "$backup_dir/restore.sh" ]]; then
            print_info "Found backup: $(basename "$backup_dir")"
            best_backup="$backup_dir"
        fi
    done
    
    if [[ -n "$best_backup" ]]; then
        print_info "Using backup: $best_backup"
        restore_from_backup "$best_backup"
        
        # System recovery actions
        print_step "Performing additional recovery actions..."
        sudo systemctl daemon-reload
        sudo sysctl vm.drop_caches=3
        
        # Restart critical services
        for service in sshd networking systemd-resolved; do
            if systemctl is-enabled --quiet "$service" 2>/dev/null; then
                sudo systemctl restart "$service" 2>/dev/null || true
            fi
        done
        
        print_success "Emergency recovery completed"
        print_warning "System restart recommended: sudo reboot"
    else
        print_error "No suitable backup found for recovery"
        print_info "Manual intervention required"
        exit 1
    fi
}

# Interactive mode
interactive_mode() {
    print_header "🎮 INTERACTIVE OPTIMIZATION MODE"
    
    while true; do
        echo ""
        echo "Available options:"
        echo "1) Run full optimization sequence"
        echo "2) Run individual optimization"
        echo "3) System health check"
        echo "4) View recent backups"
        echo "5) Emergency recovery"
        echo "6) View logs"
        echo "7) Exit"
        echo ""
        read -p "Select option (1-7): " choice
        
        case $choice in
            1)
                run_optimization_sequence
                ;;
            2)
                echo "Available individual optimizations:"
                echo "a) NVMe optimization"
                echo "b) Chrome optimization"
                echo "c) Memory optimization"
                read -p "Select (a-c): " opt_choice
                case $opt_choice in
                    a) safe_execute "$SCRIPT_DIR/nvme/nvme_optimize.sh" ;;
                    b) safe_execute "$SCRIPT_DIR/chrome/chrome_optimize.sh" ;;
                    c) safe_execute "$SCRIPT_DIR/advanced_memory_optimization.sh" ;;
                    *) print_warning "Invalid option" ;;
                esac
                ;;
            3)
                local current_health=$(check_system_health "manual")
                print_info "Current system health: $current_health/100"
                ;;
            4)
                echo "Recent backups:"
                ls -lt "$BACKUP_DIR" | head -10
                ;;
            5)
                emergency_recovery
                ;;
            6)
                echo "Recent log entries:"
                tail -20 "$LOG_FILE" 2>/dev/null || echo "No logs available"
                ;;
            7)
                print_info "Goodbye!"
                exit 0
                ;;
            *)
                print_warning "Invalid option. Please select 1-7."
                ;;
        esac
    done
}

# Command line argument processing
main() {
    case "${1:-interactive}" in
        "auto"|"--auto")
            run_optimization_sequence
            ;;
        "recovery"|"--recovery")
            emergency_recovery
            ;;
        "health"|"--health")
            local health=$(check_system_health "manual")
            print_info "System health: $health/100"
            ;;
        "interactive"|"--interactive"|"")
            interactive_mode
            ;;
        "help"|"--help")
            print_header "RPI5 Master Optimizer - Usage"
            echo "Usage: $0 [mode]"
            echo ""
            echo "Modes:"
            echo "  auto        - Run full optimization sequence automatically"
            echo "  recovery    - Emergency recovery mode"
            echo "  health      - Check current system health"
            echo "  interactive - Interactive mode (default)"
            echo "  help        - Show this help"
            ;;
        *)
            print_error "Unknown option: $1"
            print_info "Use '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Script initialization
print_header "🚀 RPI5 MASTER OPTIMIZER v2.0 - Enterprise Edition"
print_info "Professional optimization with backup, rollback, and auto-healing"
print_info "System: Raspberry Pi 5 (8GB) - Debian GNU/Linux"

# Verify we're running on the right system
if [[ ! -f "/proc/cpuinfo" ]] || ! grep -q "Raspberry Pi" /proc/cpuinfo 2>/dev/null; then
    print_warning "This script is optimized for Raspberry Pi 5"
fi

# Ensure we have required tools
for tool in bc timeout systemctl free df uptime; do
    if ! command -v "$tool" &> /dev/null; then
        print_error "Required tool not found: $tool"
        exit 1
    fi
done

# Start main function
main "$@"