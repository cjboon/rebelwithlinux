#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

CONFIG_FILE="/root/.mailcow_setup.conf"

load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    fi
}

print_header() { echo -e "\n${BLUE}========================================${NC}\n${BLUE}$1${NC}\n${BLUE}========================================${NC}"; }
print_success() { echo -e "${GREEN}[✓] $1${NC}"; }
print_warning() { echo -e "${YELLOW}[!] $1${NC}"; }
print_error() { echo -e "${RED}[✗] $1${NC}"; }
print_info() { echo -e "${BLUE}[i] $1${NC}"; }

confirm() {
    local prompt="$1"
    local response
    read -p "$prompt [y/N]: " response
    [[ "$response" =~ ^[Yy]$ ]]
}

get_docker_compose() {
    if command -v docker-compose &>/dev/null; then
        echo "docker-compose"
    elif docker compose version &>/dev/null; then
        echo "docker compose"
    else
        echo ""
    fi
}

stop_mailcow() {
    print_info "Stopping Mailcow containers..."
    load_config
    
    if [ -z "$MAILCOW_DIR" ]; then
        read -p "Enter Mailcow directory: " MAILCOW_DIR
    fi
    
    if [ ! -d "$MAILCOW_DIR" ]; then
        print_error "Mailcow directory not found: $MAILCOW_DIR"
        return 1
    fi
    
    cd "$MAILCOW_DIR"
    
    DOCKER_COMPOSE=$(get_docker_compose)
    if [ -z "$DOCKER_COMPOSE" ]; then
        print_error "Docker Compose not found"
        return 1
    fi
    
    sudo $DOCKER_COMPOSE down
    print_success "Mailcow containers stopped"
}

remove_containers() {
    print_info "Removing Mailcow containers..."
    load_config
    
    if [ -z "$MAILCOW_DIR" ]; then
        read -p "Enter Mailcow directory: " MAILCOW_DIR
    fi
    
    cd "$MAILCOW_DIR"
    
    DOCKER_COMPOSE=$(get_docker_compose)
    sudo $DOCKER_COMPOSE down --remove-orphans
    print_success "Mailcow containers removed"
}

remove_images() {
    print_info "Removing Mailcow Docker images..."
    load_config
    
    if [ -z "$MAILCOW_DIR" ]; then
        read -p "Enter Mailcow directory: " MAILCOW_DIR
    fi
    
    cd "$MAILCOW_DIR"
    
    DOCKER_COMPOSE=$(get_docker_compose)
    sudo $DOCKER_COMPOSE down --rmi local
    print_success "Mailcow images removed"
}

remove_directory() {
    print_info "Removing Mailcow directory..."
    load_config
    
    if [ -z "$MAILCOW_DIR" ]; then
        read -p "Enter Mailcow directory: " MAILCOW_DIR
    fi
    
    if [ -d "$MAILCOW_DIR" ]; then
        rm -rf "$MAILCOW_DIR"
        print_success "Removed $MAILCOW_DIR"
    else
        print_warning "Directory does not exist: $MAILCOW_DIR"
    fi
}

remove_firewall_rules() {
    print_info "Removing firewall rules..."
    
    for port in 25 80 443 587 465 993 995; do
        ufw delete allow $port/tcp 2>/dev/null || true
    done
    
    print_success "Firewall rules removed"
}

remove_config() {
    print_info "Removing Mailcow config..."
    
    if [ -f "$CONFIG_FILE" ]; then
        rm -f "$CONFIG_FILE"
        print_success "Config removed"
    fi
}

check_apache2() {
    print_info "Checking Apache2 status..."
    
    if systemctl is-active --quiet apache2; then
        print_info "Apache2 is already running"
    else
        print_warning "Apache2 is not running, starting..."
        systemctl start apache2
        if systemctl is-active --quiet apache2; then
            print_success "Apache2 started"
        else
            print_error "Failed to start Apache2"
        fi
    fi
}

show_menu() {
    echo ""
    print_header "Mail Server Uninstall Script (Mailcow)"
    echo ""
    echo -e "${CYAN}Uninstall Steps:${NC}"
    echo "  1) Stop Mailcow containers"
    echo "  2) Remove containers"
    echo "  3) Remove images (optional)"
    echo "  4) Remove Mailcow directory"
    echo "  5) Remove firewall rules"
    echo "  6) Remove config file"
    echo "  a) Run all steps (complete uninstall)"
    echo "  q) Quit"
    echo ""
}

main() {
    if [ -n "$1" ]; then
        case "$1" in
            1) stop_mailcow ;;
            2) remove_containers ;;
            3) remove_images ;;
            4) remove_directory ;;
            5) remove_firewall_rules ;;
            6) remove_config ;;
            a)
                stop_mailcow
                remove_containers
                if confirm "Remove Docker images as well?"; then
                    remove_images
                fi
                remove_directory
                if confirm "Remove firewall rules?"; then
                    remove_firewall_rules
                fi
                remove_config
                check_apache2
                print_success "Uninstall complete!"
                ;;
            q) echo "Goodbye!"; exit 0 ;;
            *) echo "Invalid option" ;;
        esac
    else
        while true; do
            show_menu
            echo -n "Selection: "
            read -r selection
            case "$selection" in
                1) stop_mailcow ;;
                2) remove_containers ;;
                3) remove_images ;;
                4) remove_directory ;;
                5) remove_firewall_rules ;;
                6) remove_config ;;
                a)
                    stop_mailcow
                    remove_containers
                    if confirm "Remove Docker images as well?"; then
                        remove_images
                    fi
                    remove_directory
                    if confirm "Remove firewall rules?"; then
                        remove_firewall_rules
                    fi
                    remove_config
                    print_success "Uninstall complete!"
                    ;;
                q) echo "Goodbye!"; exit 0 ;;
                *) echo "Invalid option" ;;
            esac
        done
    fi
}

main "$@"
