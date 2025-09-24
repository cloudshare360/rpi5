#!/bin/bash

# Docker Setup Launcher Script
# Provides easy access to all Docker setup tools

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

show_banner() {
    echo -e "${BLUE}"
    echo "================================================================="
    echo "           Docker Setup for Raspberry Pi 5 (ARM64)"
    echo "================================================================="
    echo -e "${NC}"
}

show_menu() {
    echo "Available options:"
    echo
    echo -e "${GREEN}1)${NC} Install Docker and Docker Compose"
    echo -e "${GREEN}2)${NC} Verify Docker installation" 
    echo -e "${GREEN}3)${NC} Test with Hello World example"
    echo -e "${GREEN}4)${NC} Run Web Application example"
    echo -e "${GREEN}5)${NC} Run Development Environment example"
    echo -e "${GREEN}6)${NC} View system and Docker information"
    echo -e "${GREEN}7)${NC} Clean up Docker resources"
    echo -e "${RED}8)${NC} Uninstall Docker (WARNING: Removes all data!)"
    echo -e "${YELLOW}9)${NC} Show documentation"
    echo -e "${BLUE}0)${NC} Exit"
    echo
}

run_install() {
    echo -e "${GREEN}Running Docker installation...${NC}"
    if [[ -f "$SCRIPT_DIR/scripts/install-docker.sh" ]]; then
        "$SCRIPT_DIR/scripts/install-docker.sh"
    else
        echo -e "${RED}Error: install-docker.sh not found${NC}"
    fi
}

run_verify() {
    echo -e "${GREEN}Running Docker verification...${NC}"
    if [[ -f "$SCRIPT_DIR/scripts/verify-docker.sh" ]]; then
        "$SCRIPT_DIR/scripts/verify-docker.sh"
    else
        echo -e "${RED}Error: verify-docker.sh not found${NC}"
    fi
}

run_hello_world() {
    echo -e "${GREEN}Running Hello World example...${NC}"
    if [[ -f "$SCRIPT_DIR/examples/hello-world.yml" ]]; then
        cd "$SCRIPT_DIR/examples"
        if command -v docker &> /dev/null; then
            docker compose -f hello-world.yml up
        else
            echo -e "${RED}Error: Docker is not installed${NC}"
        fi
    else
        echo -e "${RED}Error: hello-world.yml not found${NC}"
    fi
}

run_web_app() {
    echo -e "${GREEN}Setting up Web Application example...${NC}"
    if [[ -f "$SCRIPT_DIR/examples/web-app.yml" ]]; then
        cd "$SCRIPT_DIR/examples"
        
        # Create html directory if it doesn't exist
        if [[ ! -d "html" ]]; then
            mkdir html
            echo "<h1>Hello from Docker on Raspberry Pi 5!</h1>" > html/index.html
            echo "<p>This is running in a Docker container.</p>" >> html/index.html
            echo "<p>Powered by Nginx on ARM64 architecture.</p>" >> html/index.html
            echo "Created html/index.html"
        fi
        
        if command -v docker &> /dev/null; then
            echo "Starting web application..."
            docker compose -f web-app.yml up -d
            echo
            echo -e "${GREEN}Web application started!${NC}"
            echo "Visit: http://localhost:8080"
            echo "To stop: docker compose -f web-app.yml down"
        else
            echo -e "${RED}Error: Docker is not installed${NC}"
        fi
    else
        echo -e "${RED}Error: web-app.yml not found${NC}"
    fi
}

run_dev_env() {
    echo -e "${GREEN}Starting Development Environment...${NC}"
    if [[ -f "$SCRIPT_DIR/examples/dev-environment.yml" ]]; then
        cd "$SCRIPT_DIR/examples"
        
        if command -v docker &> /dev/null; then
            echo "Starting development environment (this may take a few minutes)..."
            docker compose -f dev-environment.yml up -d
            echo
            echo -e "${GREEN}Development environment started!${NC}"
            echo "Services available:"
            echo "• Database Admin (Adminer): http://localhost:8080"
            echo "• PostgreSQL: localhost:5432 (User: devuser, Password: devpass123, Database: devdb)"
            echo "• Redis: localhost:6379"
            echo
            echo "To stop: docker compose -f dev-environment.yml down"
        else
            echo -e "${RED}Error: Docker is not installed${NC}"
        fi
    else
        echo -e "${RED}Error: dev-environment.yml not found${NC}"
    fi
}

show_info() {
    echo -e "${GREEN}System and Docker Information${NC}"
    echo "=================================="
    echo
    echo "System:"
    echo "  Hostname: $(hostname)"
    echo "  Architecture: $(uname -m)"
    echo "  OS: $(lsb_release -d 2>/dev/null | cut -f2 || echo "Unknown")"
    echo "  Kernel: $(uname -r)"
    echo "  User: $USER"
    echo
    
    if command -v docker &> /dev/null; then
        echo "Docker:"
        docker --version
        docker compose version
        echo
        echo "Docker Service Status:"
        systemctl is-active docker && echo "  Status: Active" || echo "  Status: Inactive"
        echo
        echo "User Groups:"
        echo "  Groups: $(groups "$USER")"
        echo
    else
        echo -e "${YELLOW}Docker is not installed${NC}"
    fi
}

cleanup_docker() {
    echo -e "${YELLOW}Docker Cleanup Options${NC}"
    echo "======================"
    echo "1) Remove stopped containers"
    echo "2) Remove unused images"
    echo "3) Remove unused volumes"
    echo "4) Full cleanup (all unused resources)"
    echo "5) Back to main menu"
    echo
    read -p "Select option (1-5): " -n 1 -r
    echo
    
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Error: Docker is not installed${NC}"
        return
    fi
    
    case $REPLY in
        1)
            echo "Removing stopped containers..."
            docker container prune -f
            ;;
        2)
            echo "Removing unused images..."
            docker image prune -a -f
            ;;
        3)
            echo "Removing unused volumes..."
            docker volume prune -f
            ;;
        4)
            echo "Performing full cleanup..."
            docker system prune -a -f --volumes
            ;;
        5)
            return
            ;;
        *)
            echo "Invalid option"
            ;;
    esac
    
    echo -e "${GREEN}Cleanup completed${NC}"
}

run_uninstall() {
    echo -e "${RED}Docker Uninstallation${NC}"
    echo "====================="
    echo -e "${RED}WARNING: This will remove Docker completely and delete all data!${NC}"
    echo
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [[ -f "$SCRIPT_DIR/scripts/uninstall-docker.sh" ]]; then
            "$SCRIPT_DIR/scripts/uninstall-docker.sh"
        else
            echo -e "${RED}Error: uninstall-docker.sh not found${NC}"
        fi
    else
        echo "Uninstallation cancelled"
    fi
}

show_docs() {
    echo -e "${GREEN}Documentation${NC}"
    echo "============="
    echo
    if [[ -f "$SCRIPT_DIR/USAGE.md" ]]; then
        cat "$SCRIPT_DIR/USAGE.md"
    else
        echo "For detailed documentation, see README.md in $SCRIPT_DIR"
    fi
}

main() {
    while true; do
        show_banner
        show_menu
        
        read -p "Select option (0-9): " -n 1 -r
        echo
        
        case $REPLY in
            1)
                run_install
                ;;
            2)
                run_verify
                ;;
            3)
                run_hello_world
                ;;
            4)
                run_web_app
                ;;
            5)
                run_dev_env
                ;;
            6)
                show_info
                ;;
            7)
                cleanup_docker
                ;;
            8)
                run_uninstall
                ;;
            9)
                show_docs
                ;;
            0)
                echo -e "${GREEN}Goodbye!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option. Please select 0-9.${NC}"
                ;;
        esac
        
        echo
        read -p "Press Enter to continue..."
        clear
    done
}

# Handle script interruption
trap 'echo -e "\n${YELLOW}Setup interrupted${NC}"; exit 1' INT TERM

# Make sure we're in the right directory
cd "$SCRIPT_DIR"

# Run main function
main