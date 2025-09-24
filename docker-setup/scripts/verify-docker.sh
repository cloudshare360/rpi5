#!/bin/bash

# Docker Verification Script for Raspberry Pi 5 (ARM64)
# Author: Auto-generated Docker Setup
# Date: $(date +%Y-%m-%d)
# Purpose: Verify Docker and Docker Compose installations

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TOTAL_TESTS=0

# Logging functions
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1" >&2
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO:${NC} $1"
}

success() {
    echo -e "${GREEN}✓${NC} $1"
}

fail() {
    echo -e "${RED}✗${NC} $1"
}

# Test function wrapper
run_test() {
    local test_name="$1"
    local test_func="$2"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo
    info "Running test: $test_name"
    
    if $test_func; then
        success "$test_name passed"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        fail "$test_name failed"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Test 1: Check if Docker command exists
test_docker_command() {
    if command -v docker &> /dev/null; then
        info "Docker command found at: $(which docker)"
        return 0
    else
        error "Docker command not found in PATH"
        return 1
    fi
}

# Test 2: Check Docker version
test_docker_version() {
    local version
    if version=$(docker --version 2>&1); then
        info "Docker version: $version"
        return 0
    else
        error "Failed to get Docker version"
        return 1
    fi
}

# Test 3: Check Docker Compose version
test_docker_compose_version() {
    local version
    if version=$(docker compose version 2>&1); then
        info "Docker Compose version: $version"
        return 0
    else
        error "Failed to get Docker Compose version"
        return 1
    fi
}

# Test 4: Check Docker service status
test_docker_service() {
    if systemctl is-active docker &> /dev/null; then
        info "Docker service is active and running"
        return 0
    else
        error "Docker service is not running"
        return 1
    fi
}

# Test 5: Check if user is in docker group
test_user_docker_group() {
    if groups "$USER" | grep -q docker; then
        info "User $USER is in the docker group"
        return 0
    else
        warn "User $USER is not in the docker group"
        return 1
    fi
}

# Test 6: Test Docker without sudo (if possible)
test_docker_without_sudo() {
    if groups "$USER" | grep -q docker; then
        # Try to run docker info without sudo
        if timeout 10 docker info &> /dev/null; then
            info "Docker runs successfully without sudo"
            return 0
        else
            warn "Docker requires sudo (you may need to log out and back in)"
            return 1
        fi
    else
        warn "Cannot test docker without sudo - user not in docker group"
        return 1
    fi
}

# Test 7: Test Docker with hello-world container
test_docker_hello_world() {
    local use_sudo=""
    
    # Determine if we need sudo
    if ! groups "$USER" | grep -q docker || ! timeout 5 docker info &> /dev/null; then
        use_sudo="sudo"
        info "Using sudo for Docker commands"
    fi
    
    info "Running hello-world container test..."
    if $use_sudo docker run --rm hello-world &> /tmp/docker-hello-test.log; then
        info "Hello-world container test successful"
        rm -f /tmp/docker-hello-test.log
        return 0
    else
        error "Hello-world container test failed"
        echo "Error output:"
        cat /tmp/docker-hello-test.log 2>/dev/null || echo "No error log available"
        rm -f /tmp/docker-hello-test.log
        return 1
    fi
}

# Test 8: Test Docker Compose with simple configuration
test_docker_compose_functionality() {
    local use_sudo=""
    local test_dir="/tmp/docker-compose-test-$$"
    
    # Determine if we need sudo
    if ! groups "$USER" | grep -q docker || ! timeout 5 docker info &> /dev/null; then
        use_sudo="sudo"
    fi
    
    # Create temporary test directory
    mkdir -p "$test_dir"
    cd "$test_dir"
    
    # Create simple docker-compose.yml
    cat > docker-compose.yml << 'EOF'
services:
  test:
    image: hello-world
EOF
    
    info "Testing Docker Compose functionality..."
    if $use_sudo docker compose up --no-log-prefix 2>&1 | grep -q "Hello from Docker!"; then
        info "Docker Compose test successful"
        $use_sudo docker compose down &> /dev/null || true
        cd - > /dev/null
        rm -rf "$test_dir"
        return 0
    else
        error "Docker Compose test failed"
        $use_sudo docker compose down &> /dev/null || true
        cd - > /dev/null
        rm -rf "$test_dir"
        return 1
    fi
}

# Test 9: Check available Docker images
test_docker_images() {
    local use_sudo=""
    
    if ! groups "$USER" | grep -q docker || ! timeout 5 docker info &> /dev/null; then
        use_sudo="sudo"
    fi
    
    info "Checking Docker images..."
    if $use_sudo docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" 2>/dev/null; then
        return 0
    else
        warn "Could not list Docker images"
        return 1
    fi
}

# Test 10: Check Docker system info
test_docker_system_info() {
    local use_sudo=""
    
    if ! groups "$USER" | grep -q docker || ! timeout 5 docker info &> /dev/null; then
        use_sudo="sudo"
    fi
    
    info "Getting Docker system information..."
    local docker_info
    if docker_info=$($use_sudo docker info --format '{{.ServerVersion}}|{{.Architecture}}|{{.OSType}}' 2>/dev/null); then
        IFS='|' read -r version arch os_type <<< "$docker_info"
        info "Docker Server Version: $version"
        info "Architecture: $arch"
        info "OS Type: $os_type"
        return 0
    else
        warn "Could not get Docker system information"
        return 1
    fi
}

# Display system information
show_system_info() {
    echo
    echo "================================================================="
    echo "System Information"
    echo "================================================================="
    echo "Hostname: $(hostname)"
    echo "Architecture: $(uname -m)"
    echo "OS: $(lsb_release -d 2>/dev/null | cut -f2 || echo "Unknown")"
    echo "Kernel: $(uname -r)"
    echo "User: $USER"
    echo "Groups: $(groups "$USER")"
    echo "Date: $(date)"
    echo "================================================================="
}

# Display test results summary
show_test_summary() {
    echo
    echo "================================================================="
    echo "Test Results Summary"
    echo "================================================================="
    echo "Total Tests: $TOTAL_TESTS"
    echo "Passed: $TESTS_PASSED"
    echo "Failed: $TESTS_FAILED"
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}All tests passed! Docker installation is working correctly.${NC}"
        return 0
    else
        echo -e "${YELLOW}Some tests failed. Docker may still be functional but requires attention.${NC}"
        return 1
    fi
}

# Show recommendations
show_recommendations() {
    echo
    echo "================================================================="
    echo "Recommendations"
    echo "================================================================="
    
    if ! groups "$USER" | grep -q docker; then
        echo "• Add user to docker group: sudo usermod -aG docker $USER"
        echo "• Log out and log back in for group changes to take effect"
    fi
    
    if ! systemctl is-active docker &> /dev/null; then
        echo "• Start Docker service: sudo systemctl start docker"
        echo "• Enable Docker service: sudo systemctl enable docker"
    fi
    
    echo "• For security, consider using rootless Docker for non-production use"
    echo "• Use 'docker compose' instead of deprecated 'docker-compose'"
    echo "• Check Docker documentation at: https://docs.docker.com/"
    echo "================================================================="
}

# Main verification function
main() {
    log "Starting Docker verification for Raspberry Pi 5 (ARM64)"
    
    show_system_info
    
    # Run all tests
    run_test "Docker Command Existence" test_docker_command
    run_test "Docker Version Check" test_docker_version
    run_test "Docker Compose Version Check" test_docker_compose_version
    run_test "Docker Service Status" test_docker_service
    run_test "User Docker Group Membership" test_user_docker_group
    run_test "Docker Without Sudo" test_docker_without_sudo
    run_test "Docker Hello World Test" test_docker_hello_world
    run_test "Docker Compose Functionality" test_docker_compose_functionality
    run_test "Docker Images List" test_docker_images
    run_test "Docker System Information" test_docker_system_info
    
    show_test_summary
    show_recommendations
    
    if [ $TESTS_FAILED -eq 0 ]; then
        log "Docker verification completed successfully"
        exit 0
    else
        warn "Docker verification completed with some failures"
        exit 1
    fi
}

# Handle script interruption
trap 'error "Verification interrupted"; exit 1' INT TERM

# Run main function
main "$@"