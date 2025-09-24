#!/bin/bash

# Comprehensive Stress Test for 2800MHz Configuration
# Tests CPU, memory, I/O, and thermal stability

set -e

LOG_FILE="/home/sri/rpi5-optimization-backup/stress_test_2800mhz.log"
RESULTS_FILE="/home/sri/rpi5-optimization-backup/stress_test_2800mhz_results.log"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "\n${BLUE}=== $1 ===${NC}"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] === $1 ===" >> "$LOG_FILE"
}

print_status() {
    echo -e "${YELLOW}$1${NC}"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS: $1" >> "$LOG_FILE"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" >> "$LOG_FILE"
}

# Get comprehensive system status
get_system_status() {
    local freq=$(vcgencmd measure_clock arm | cut -d'=' -f2 | awk '{print int($1/1000000)}')
    local temp=$(vcgencmd measure_temp | cut -d'=' -f2 | cut -d"'" -f1)
    local volt=$(vcgencmd measure_volts core | cut -d'=' -f2)
    local throttled=$(vcgencmd get_throttled)
    
    echo "CPU: ${freq}MHz | Temp: ${temp}°C | Voltage: $volt | Throttling: $throttled"
}

# Pre-test system verification
verify_2800mhz() {
    print_header "Pre-Test System Verification"
    
    local current_freq=$(vcgencmd measure_clock arm | cut -d'=' -f2 | awk '{print int($1/1000000)}')
    local temp=$(vcgencmd measure_temp | cut -d'=' -f2 | cut -d"'" -f1)
    local throttled=$(vcgencmd get_throttled)
    
    print_status "Current frequency: ${current_freq}MHz (expected: 2800MHz)"
    print_status "Current temperature: ${temp}°C"
    print_status "Throttling status: $throttled"
    
    if [[ $current_freq -ne 2800 ]]; then
        print_error "System not running at 2800MHz! Current: ${current_freq}MHz"
        return 1
    fi
    
    if [[ "$throttled" != "throttled=0x0" ]]; then
        print_error "System already throttled before test!"
        return 1
    fi
    
    print_success "System verified at 2800MHz, ready for stress testing"
    return 0
}

# Test 1: Intensive CPU stress test
test_cpu_intensive() {
    print_header "Test 1: Intensive CPU Stress Test (6 minutes)"
    
    local start_temp=$(vcgencmd measure_temp | cut -d'=' -f2 | cut -d"'" -f1)
    print_status "Starting temperature: ${start_temp}°C"
    
    # Run maximum CPU stress test
    print_status "Running maximum CPU stress (all 4 cores, 100% load)..."
    timeout 360 stress-ng --cpu $(nproc) --cpu-method all --timeout 360s --metrics-brief &
    local stress_pid=$!
    
    local max_temp=0
    local temp_violations=0
    
    # Monitor every 15 seconds for 6 minutes (24 checks)
    for i in {1..24}; do
        sleep 15
        local current_temp=$(vcgencmd measure_temp | cut -d'=' -f2 | cut -d"'" -f1)
        local current_freq=$(vcgencmd measure_clock arm | cut -d'=' -f2 | awk '{print int($1/1000000)}')
        local throttled=$(vcgencmd get_throttled)
        
        # Track maximum temperature
        if (( $(echo "$current_temp > $max_temp" | bc -l) )); then
            max_temp=$current_temp
        fi
        
        local progress=$((i * 100 / 24))
        print_status "Progress ${progress}%: ${current_freq}MHz at ${current_temp}°C (max: ${max_temp}°C) | $throttled"
        
        # Check for frequency drops (indicates throttling)
        if [[ $current_freq -lt 2700 ]]; then
            print_error "Frequency drop detected! Current: ${current_freq}MHz"
            temp_violations=$((temp_violations + 1))
        fi
        
        # Check for explicit throttling
        if [[ "$throttled" != "throttled=0x0" ]]; then
            print_error "Throttling detected: $throttled"
            temp_violations=$((temp_violations + 1))
        fi
        
        # Emergency temperature check
        if (( $(echo "$current_temp > 80" | bc -l) )); then
            print_error "EMERGENCY: Temperature too high: ${current_temp}°C - Stopping test"
            kill $stress_pid 2>/dev/null || true
            return 1
        fi
    done
    
    # Wait for stress test to complete
    wait $stress_pid 2>/dev/null || true
    
    local end_temp=$(vcgencmd measure_temp | cut -d'=' -f2 | cut -d"'" -f1)
    
    # Results
    echo "CPU_STRESS_RESULTS: Max temp: ${max_temp}°C, End temp: ${end_temp}°C, Violations: ${temp_violations}" >> "$RESULTS_FILE"
    
    if [[ $temp_violations -eq 0 ]]; then
        print_success "CPU stress test PASSED - Max temp: ${max_temp}°C, No throttling"
        return 0
    else
        print_error "CPU stress test FAILED - ${temp_violations} violations detected"
        return 1
    fi
}

# Test 2: Memory bandwidth stress
test_memory_stress() {
    print_header "Test 2: Memory Bandwidth Stress Test (4 minutes)"
    
    print_status "Testing memory bandwidth and stability..."
    
    # High memory pressure test
    timeout 240 stress-ng --vm 8 --vm-bytes 900M --vm-method all --timeout 240s --metrics-brief &
    local stress_pid=$!
    
    # Monitor every 20 seconds for 4 minutes (12 checks)
    for i in {1..12}; do
        sleep 20
        local status=$(get_system_status)
        local progress=$((i * 100 / 12))
        print_status "Memory test ${progress}%: $status"
        
        local throttled=$(vcgencmd get_throttled)
        if [[ "$throttled" != "throttled=0x0" ]]; then
            print_error "Memory test caused throttling: $throttled"
            kill $stress_pid 2>/dev/null || true
            return 1
        fi
    done
    
    wait $stress_pid 2>/dev/null || true
    print_success "Memory stress test completed successfully"
    return 0
}

# Test 3: Mixed workload with I/O
test_mixed_workload() {
    print_header "Test 3: Mixed CPU+Memory+I/O Stress (5 minutes)"
    
    print_status "Running comprehensive mixed workload..."
    
    # Heavy mixed workload
    timeout 300 stress-ng --cpu 2 --vm 4 --vm-bytes 512M --io 2 --hdd 1 --hdd-bytes 256M --timeout 300s --metrics-brief &
    local stress_pid=$!
    
    local max_temp=0
    
    # Monitor every 25 seconds for 5 minutes (12 checks)
    for i in {1..12}; do
        sleep 25
        local current_temp=$(vcgencmd measure_temp | cut -d'=' -f2 | cut -d"'" -f1)
        local status=$(get_system_status)
        local progress=$((i * 100 / 12))
        
        if (( $(echo "$current_temp > $max_temp" | bc -l) )); then
            max_temp=$current_temp
        fi
        
        print_status "Mixed workload ${progress}%: $status (max temp: ${max_temp}°C)"
        
        local throttled=$(vcgencmd get_throttled)
        if [[ "$throttled" != "throttled=0x0" ]]; then
            print_error "Mixed workload caused throttling: $throttled"
            kill $stress_pid 2>/dev/null || true
            return 1
        fi
    done
    
    wait $stress_pid 2>/dev/null || true
    echo "MIXED_WORKLOAD_RESULTS: Max temp: ${max_temp}°C" >> "$RESULTS_FILE"
    print_success "Mixed workload test completed - Max temp: ${max_temp}°C"
    return 0
}

# Test 4: System responsiveness under load
test_responsiveness() {
    print_header "Test 4: System Responsiveness Under Load"
    
    print_status "Testing system responsiveness with background load..."
    
    # Start background CPU load
    stress-ng --cpu 3 --timeout 120s &
    local bg_stress_pid=$!
    
    local total_response_time=0
    local test_count=10
    
    for i in $(seq 1 $test_count); do
        local start_time=$(date +%s.%N)
        
        # Perform various system operations
        ls -la /home/sri > /dev/null
        ps aux | wc -l > /dev/null
        df -h > /dev/null
        free -m > /dev/null
        
        local end_time=$(date +%s.%N)
        local duration=$(echo "$end_time - $start_time" | bc)
        total_response_time=$(echo "$total_response_time + $duration" | bc)
        
        print_status "Responsiveness test ${i}/${test_count}: ${duration}s"
        sleep 10
    done
    
    wait $bg_stress_pid 2>/dev/null || true
    
    local avg_response=$(echo "scale=3; $total_response_time / $test_count" | bc)
    echo "RESPONSIVENESS_RESULTS: Average response time: ${avg_response}s" >> "$RESULTS_FILE"
    
    # Good responsiveness is under 0.1s average
    if (( $(echo "$avg_response < 0.2" | bc -l) )); then
        print_success "Responsiveness test PASSED - Average: ${avg_response}s"
        return 0
    else
        print_error "Responsiveness test FAILED - Average: ${avg_response}s (should be < 0.2s)"
        return 1
    fi
}

# Generate final report
generate_report() {
    print_header "2800MHz Stress Test Final Report"
    
    local end_temp=$(vcgencmd measure_temp | cut -d'=' -f2 | cut -d"'" -f1)
    local final_freq=$(vcgencmd measure_clock arm | cut -d'=' -f2 | awk '{print int($1/1000000)}')
    local final_throttled=$(vcgencmd get_throttled)
    
    print_status "Final system state:"
    print_status "  Frequency: ${final_freq}MHz"
    print_status "  Temperature: ${end_temp}°C"
    print_status "  Throttling: $final_throttled"
    
    if [[ -f "$RESULTS_FILE" ]]; then
        print_status "\nDetailed results:"
        cat "$RESULTS_FILE"
    fi
    
    # Overall assessment
    if [[ $final_freq -eq 2800 ]] && [[ "$final_throttled" == "throttled=0x0" ]]; then
        print_success "\n🎉 2800MHz STRESS TEST PASSED!"
        print_success "System demonstrates excellent stability at 2800MHz overclock"
        return 0
    else
        print_error "\n❌ 2800MHz stress test revealed issues"
        return 1
    fi
}

# Main execution
main() {
    print_header "RPi5 2800MHz Comprehensive Stress Test"
    print_status "Test started at: $(date)"
    print_status "Logging to: $LOG_FILE"
    
    # Clear previous results
    > "$RESULTS_FILE"
    
    # Run all tests
    if ! verify_2800mhz; then
        print_error "Pre-test verification failed!"
        exit 1
    fi
    
    local tests_passed=0
    local total_tests=4
    
    if test_cpu_intensive; then
        tests_passed=$((tests_passed + 1))
    fi
    
    # Cool down between intensive tests
    print_status "Cooling down for 30 seconds..."
    sleep 30
    
    if test_memory_stress; then
        tests_passed=$((tests_passed + 1))
    fi
    
    sleep 15
    
    if test_mixed_workload; then
        tests_passed=$((tests_passed + 1))
    fi
    
    sleep 10
    
    if test_responsiveness; then
        tests_passed=$((tests_passed + 1))
    fi
    
    # Final report
    generate_report
    
    print_status "\nTest Summary: ${tests_passed}/${total_tests} tests passed"
    
    if [[ $tests_passed -eq $total_tests ]]; then
        print_success "🏆 ALL TESTS PASSED - 2800MHz is stable and excellent!"
        exit 0
    else
        print_error "⚠️  Some tests failed - 2800MHz may need tuning"
        exit 1
    fi
}

# Handle script interruption
trap 'print_error "Test interrupted by user"; pkill -f stress-ng 2>/dev/null || true; exit 1' INT TERM

# Run the tests
main "$@"