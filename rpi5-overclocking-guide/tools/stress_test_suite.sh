#!/bin/bash

# RPi5 Comprehensive Stress Test Suite
# Tests system stability before and after optimizations

set -e

TEST_DURATION_SHORT=60  # 1 minute for quick tests
TEST_DURATION_MEDIUM=300  # 5 minutes for medium tests
TEST_DURATION_LONG=900   # 15 minutes for thorough tests

LOG_DIR="/home/sri/rpi5-optimization-backup/stress_test_logs"
mkdir -p "$LOG_DIR"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_test_result() {
    local test_name="$1"
    local result="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $test_name: $result" >> "$LOG_DIR/test_results.log"
}

print_header() {
    echo -e "\n${BLUE}=== $1 ===${NC}"
}

print_status() {
    echo -e "${YELLOW}$1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Function to monitor system during tests
monitor_system() {
    local test_name="$1"
    local duration="$2"
    local monitor_file="$LOG_DIR/${test_name}_monitor.log"
    
    echo "Starting system monitoring for $test_name (${duration}s)..."
    
    # Start background monitoring
    {
        echo "System Monitoring for $test_name - $(date)"
        echo "Duration: ${duration} seconds"
        echo "================================"
        
        for ((i=0; i<duration; i+=10)); do
            echo ""
            echo "--- Timestamp: $(date) (${i}s elapsed) ---"
            echo "Memory Usage:"
            free -h
            echo ""
            echo "CPU Temperature:"
            vcgencmd measure_temp 2>/dev/null || echo "Temperature monitoring unavailable"
            echo ""
            echo "CPU Frequency:"
            vcgencmd measure_clock arm 2>/dev/null || echo "CPU frequency monitoring unavailable"
            echo ""
            echo "Load Average:"
            cat /proc/loadavg
            echo ""
            echo "Top Processes (by CPU):"
            ps aux --sort=-%cpu | head -5
            sleep 10
        done
    } > "$monitor_file" 2>&1 &
    
    local monitor_pid=$!
    return $monitor_pid
}

# Function to stop monitoring
stop_monitoring() {
    local monitor_pid="$1"
    kill $monitor_pid 2>/dev/null || true
    wait $monitor_pid 2>/dev/null || true
}

# Test 1: CPU Stress Test
test_cpu_stress() {
    print_header "CPU Stress Test"
    local test_duration=$1
    
    print_status "Running CPU stress test for ${test_duration} seconds..."
    monitor_system "cpu_stress" "$test_duration"
    local monitor_pid=$!
    
    # Run CPU stress test
    if timeout "${test_duration}s" stress-ng --cpu $(nproc) --timeout "${test_duration}s" --metrics-brief > "$LOG_DIR/cpu_stress_output.log" 2>&1; then
        print_success "CPU stress test completed successfully"
        log_test_result "CPU_STRESS_${test_duration}s" "PASSED"
    else
        print_error "CPU stress test failed or was terminated"
        log_test_result "CPU_STRESS_${test_duration}s" "FAILED"
    fi
    
    stop_monitoring $monitor_pid
}

# Test 2: Memory Stress Test
test_memory_stress() {
    print_header "Memory Stress Test"
    local test_duration=$1
    
    print_status "Running memory stress test for ${test_duration} seconds..."
    monitor_system "memory_stress" "$test_duration"
    local monitor_pid=$!
    
    # Use 80% of available memory for stress test
    local available_mem=$(free -m | awk 'NR==2{printf "%.0f\n", $7*0.8}')
    
    if timeout "${test_duration}s" stress-ng --vm 2 --vm-bytes "${available_mem}M" --timeout "${test_duration}s" --metrics-brief > "$LOG_DIR/memory_stress_output.log" 2>&1; then
        print_success "Memory stress test completed successfully"
        log_test_result "MEMORY_STRESS_${test_duration}s" "PASSED"
    else
        print_error "Memory stress test failed or was terminated"
        log_test_result "MEMORY_STRESS_${test_duration}s" "FAILED"
    fi
    
    stop_monitoring $monitor_pid
}

# Test 3: I/O Stress Test
test_io_stress() {
    print_header "I/O Stress Test"
    local test_duration=$1
    
    print_status "Running I/O stress test for ${test_duration} seconds..."
    monitor_system "io_stress" "$test_duration"
    local monitor_pid=$!
    
    # Create temporary directory for I/O test
    local temp_dir="/tmp/rpi5_io_test"
    mkdir -p "$temp_dir"
    
    if timeout "${test_duration}s" stress-ng --hdd 4 --hdd-bytes 1G --temp-path "$temp_dir" --timeout "${test_duration}s" --metrics-brief > "$LOG_DIR/io_stress_output.log" 2>&1; then
        print_success "I/O stress test completed successfully"
        log_test_result "IO_STRESS_${test_duration}s" "PASSED"
    else
        print_error "I/O stress test failed or was terminated"
        log_test_result "IO_STRESS_${test_duration}s" "FAILED"
    fi
    
    # Clean up
    rm -rf "$temp_dir"
    stop_monitoring $monitor_pid
}

# Test 4: Combined System Stress Test
test_combined_stress() {
    print_header "Combined System Stress Test"
    local test_duration=$1
    
    print_status "Running combined stress test for ${test_duration} seconds..."
    print_status "This test simulates heavy browser usage with multiple processes..."
    monitor_system "combined_stress" "$test_duration"
    local monitor_pid=$!
    
    # Create temporary directory for combined test
    local temp_dir="/tmp/rpi5_combined_test"
    mkdir -p "$temp_dir"
    
    # Combined stress: CPU + Memory + I/O (simulating browser behavior)
    if timeout "${test_duration}s" stress-ng \
        --cpu $(nproc) \
        --vm 4 --vm-bytes 512M \
        --hdd 2 --hdd-bytes 512M \
        --temp-path "$temp_dir" \
        --timeout "${test_duration}s" \
        --metrics-brief > "$LOG_DIR/combined_stress_output.log" 2>&1; then
        print_success "Combined stress test completed successfully"
        log_test_result "COMBINED_STRESS_${test_duration}s" "PASSED"
    else
        print_error "Combined stress test failed or was terminated"
        log_test_result "COMBINED_STRESS_${test_duration}s" "FAILED"
    fi
    
    # Clean up
    rm -rf "$temp_dir"
    stop_monitoring $monitor_pid
}

# Test 5: Browser Simulation Test
test_browser_simulation() {
    print_header "Browser Simulation Test"
    local test_duration=$1
    
    print_status "Simulating heavy browser usage for ${test_duration} seconds..."
    monitor_system "browser_simulation" "$test_duration"
    local monitor_pid=$!
    
    # Simulate browser behavior with multiple memory-intensive processes
    if timeout "${test_duration}s" stress-ng \
        --fork 8 --fork-max 16 \
        --vm 6 --vm-bytes 256M \
        --cache 4 \
        --timeout "${test_duration}s" \
        --metrics-brief > "$LOG_DIR/browser_simulation_output.log" 2>&1; then
        print_success "Browser simulation test completed successfully"
        log_test_result "BROWSER_SIMULATION_${test_duration}s" "PASSED"
    else
        print_error "Browser simulation test failed or was terminated"
        log_test_result "BROWSER_SIMULATION_${test_duration}s" "FAILED"
    fi
    
    stop_monitoring $monitor_pid
}

# Generate test report
generate_report() {
    local test_type="$1"
    local report_file="$LOG_DIR/stress_test_report_${test_type}_$(date +%Y%m%d_%H%M%S).txt"
    
    print_header "Generating Test Report"
    
    {
        echo "RPi5 8GB Stress Test Report - $test_type"
        echo "Generated: $(date)"
        echo "======================================="
        echo ""
        
        echo "System Information:"
        echo "- Architecture: $(uname -m)"
        echo "- Kernel: $(uname -r)"
        echo "- CPU: $(lscpu | grep 'Model name' | cut -d':' -f2 | xargs)"
        echo "- Total RAM: $(free -h | awk 'NR==2{print $2}')"
        echo "- Available Swap: $(free -h | awk 'NR==3{print $2}')"
        echo ""
        
        echo "Test Results Summary:"
        if [[ -f "$LOG_DIR/test_results.log" ]]; then
            cat "$LOG_DIR/test_results.log"
        fi
        echo ""
        
        echo "Temperature During Tests:"
        for monitor_file in "$LOG_DIR"/*_monitor.log; do
            if [[ -f "$monitor_file" ]]; then
                echo "$(basename "$monitor_file" _monitor.log):"
                grep -E "Temperature|temp=" "$monitor_file" | tail -5 || echo "  No temperature data available"
                echo ""
            fi
        done
        
        echo "Recommendations:"
        echo "- If all tests PASSED: System is stable for optimization"
        echo "- If any test FAILED: Review system stability before applying optimizations"
        echo "- Monitor temperature during heavy loads (should stay below 80°C)"
        echo ""
        
        echo "Log Files Location: $LOG_DIR"
        
    } > "$report_file"
    
    print_success "Test report generated: $report_file"
    echo ""
    echo "=== TEST REPORT SUMMARY ==="
    cat "$report_file"
}

# Main test execution function
run_stress_tests() {
    local test_level="$1"  # quick, medium, thorough
    
    print_header "RPi5 Stress Test Suite - $test_level Testing"
    echo "Test logs will be saved to: $LOG_DIR"
    echo ""
    
    # Initialize log file
    echo "RPi5 Stress Test Results - $(date)" > "$LOG_DIR/test_results.log"
    echo "Test Level: $test_level" >> "$LOG_DIR/test_results.log"
    echo "=================================" >> "$LOG_DIR/test_results.log"
    
    case "$test_level" in
        "quick")
            echo "Running Quick Tests (1 minute each)..."
            test_cpu_stress $TEST_DURATION_SHORT
            test_memory_stress $TEST_DURATION_SHORT
            ;;
        "medium")
            echo "Running Medium Tests (5 minutes each)..."
            test_cpu_stress $TEST_DURATION_MEDIUM
            test_memory_stress $TEST_DURATION_MEDIUM
            test_io_stress $TEST_DURATION_MEDIUM
            ;;
        "thorough")
            echo "Running Thorough Tests (15 minutes each)..."
            test_cpu_stress $TEST_DURATION_LONG
            test_memory_stress $TEST_DURATION_LONG
            test_io_stress $TEST_DURATION_LONG
            test_combined_stress $TEST_DURATION_LONG
            test_browser_simulation $TEST_DURATION_LONG
            ;;
        *)
            echo "Invalid test level. Use: quick, medium, or thorough"
            exit 1
            ;;
    esac
    
    generate_report "$test_level"
}

# Script main execution
if [[ $# -eq 0 ]]; then
    echo "Usage: $0 {quick|medium|thorough}"
    echo ""
    echo "Test Levels:"
    echo "  quick    - 1 minute tests (CPU, Memory)"
    echo "  medium   - 5 minute tests (CPU, Memory, I/O)"
    echo "  thorough - 15 minute tests (All tests including browser simulation)"
    echo ""
    echo "Recommended: Run 'medium' tests before applying optimizations"
    exit 1
fi

run_stress_tests "$1"