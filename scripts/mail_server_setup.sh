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

save_config() {
    echo "MAILCOW_DIR=\"$MAILCOW_DIR\"" > "$CONFIG_FILE"
}

print_header() { echo -e "\n${BLUE}========================================${NC}\n${BLUE}$1${NC}\n${BLUE}========================================${NC}"; }
print_success() { echo -e "${GREEN}[✓] $1${NC}"; }
print_warning() { echo -e "${YELLOW}[!] $1${NC}"; }
print_error() { echo -e "${RED}[✗] $1${NC}"; }
print_info() { echo -e "${BLUE}[i] $1${NC}"; }

show_step_info() {
    local title="$1"
    local description="$2"
    local changes="$3"
    
    echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  $title${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${YELLOW}What this does:${NC}"
    echo "$description"
    echo ""
    echo -e "${YELLOW}Changes made:${NC}"
    echo "$changes"
    echo ""
}

confirm() {
    local prompt="$1"
    local response
    read -p "$prompt [y/N]: " response
    [[ "$response" =~ ^[Yy]$ ]]
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "This script must be run as root"
        exit 1
    fi
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

step_install_prerequisites() {
    show_step_info \
        "Install Prerequisites" \
        "Mailcow requires Docker, Docker Compose, Git, and jq. This step checks if they're installed." \
        "• Checks if Docker is installed
• Checks if Docker Compose is installed
• Checks if Git is installed
• Checks if jq is installed"
    
    if confirm "Check and install prerequisites?"; then
        # Check and install jq (required for Mailcow)
        if ! command -v jq &>/dev/null; then
            print_warning "jq is not installed"
            if confirm "Install jq now?"; then
                apt update && apt install -y jq
                print_success "jq installed"
            fi
        fi
        
        # Check and install git
        if ! command -v git &>/dev/null; then
            print_warning "Git is not installed"
            if confirm "Install Git now?"; then
                apt update && apt install -y git
                print_success "Git installed"
            fi
        fi
        
        # Check and install docker
        if ! command -v docker &>/dev/null; then
            print_warning "Docker is not installed"
            if confirm "Install Docker now?"; then
                curl -fsSL https://get.docker.com | sh
                print_success "Docker installed"
            else
                print_error "Docker is required for Mailcow"
                exit 1
            fi
        fi
        
        DOCKER_COMPOSE=$(get_docker_compose)
        if [ -z "$DOCKER_COMPOSE" ]; then
            print_warning "Docker Compose is not installed"
            if confirm "Install Docker Compose now?"; then
                apt update && apt install -y docker-compose
            else
                print_error "Docker Compose is required"
                exit 1
            fi
        fi
        
        DOCKER_COMPOSE=$(get_docker_compose)
        export DOCKER_COMPOSE
        print_success "All prerequisites installed"
    else
        print_warning "Skipped"
    fi
}

step_download_mailcow() {
    show_step_info \
        "Download Mailcow" \
        "Mailcow is a ready-to-use mail server suite. We'll clone the official repository from GitHub." \
        "• Clones mailcow-dockerized repository
• Downloads docker-compose.yml
• Downloads generate_config.sh script"
    
    if confirm "Download Mailcow?"; then
        load_config
        
        read -p "Enter directory for mail server (default: /opt/mailcow): " MAILCOW_DIR_INPUT
        MAILCOW_DIR=${MAILCOW_DIR_INPUT:-/opt/mailcow}
        save_config
        
        # Check if directory exists and has content
        if [ -d "$MAILCOW_DIR" ] && [ "$(ls -A $MAILCOW_DIR 2>/dev/null)" ]; then
            print_warning "Directory $MAILCOW_DIR already exists and is not empty"
            if confirm "Remove and re-clone?"; then
                rm -rf "$MAILCOW_DIR"
            else
                print_info "Using existing directory"
            fi
        fi
        
        # Check for git
        if ! command -v git &>/dev/null; then
            print_info "Installing git..."
            apt install -y git
        fi
        
        # Clone mailcow repo
        print_info "Cloning Mailcow repository..."
        if [ ! -d "$MAILCOW_DIR" ]; then
            if git clone https://github.com/mailcow/mailcow-dockerized.git "$MAILCOW_DIR"; then
                print_success "Mailcow cloned to $MAILCOW_DIR"
            else
                print_error "Failed to clone Mailcow"
                return 1
            fi
        fi
        
        cd "$MAILCOW_DIR"
        
        print_success "Mailcow ready at $MAILCOW_DIR"
        print_info "Next: Run step 3 to configure"
    else
        print_warning "Skipped"
    fi
}

step_configure_mailcow() {
    show_step_info \
        "Configure Mailcow" \
        "Configure Mailcow with your domain and settings." \
        "• Set your domain
• Configure hostname
• Set admin password"
    
    if confirm "Configure Mailcow?"; then
        load_config
        
        if [ -z "$MAILCOW_DIR" ]; then
            read -p "Enter mail server directory: " MAILCOW_DIR
            save_config
        fi
        
        # Check if files exist
        if [ ! -f "$MAILCOW_DIR/docker-compose.yml" ]; then
            print_error "Mailcow files not found. Please run step 2 first."
            return 1
        fi
        
        cd "$MAILCOW_DIR"
        
        # Check for jq (required)
        if ! command -v jq &>/dev/null; then
            print_info "Installing jq..."
            apt install -y jq
        fi
        
        # Run generate_config.sh with sudo (it needs root to write .env file)
        print_info "Running Mailcow configuration..."
        print_warning "This will prompt for your domain and generate the .env file."
        echo ""
        
        if sudo ./generate_config.sh; then
            print_success "Mailcow configured successfully!"
            print_info "Now run step 4 to start Mailcow"
        else
            print_error "Configuration failed. Try running manually:"
            echo "  cd $MAILCOW_DIR"
            echo "  sudo ./generate_config.sh"
        fi
    else
        print_warning "Skipped"
    fi
}

step_start_mailcow() {
    show_step_info \
        "Start Mailcow" \
        "This starts all the Mailcow containers. It pulls the official images and starts the mail server stack." \
        "• Pulls Mailcow Docker images
• Creates Docker network
• Starts all services
• This may take a few minutes"
    
    if confirm "Start Mailcow containers?"; then
        load_config
        
        if [ -z "$MAILCOW_DIR" ]; then
            print_error "Please set MAILCOW_DIR first (step 2)"
            return 1
        fi
        
        cd "$MAILCOW_DIR"
        
        if [ ! -f "docker-compose.yml" ]; then
            print_error "Mailcow not found. Please run step 2 first."
            return 1
        fi
        
        # Check if ports 80/443 are in use (by Apache/Nginx)
        if ss -tuln | grep -q ':80 ' || ss -tuln | grep -q ':443 '; then
            print_warning "Port 80 or 443 is already in use"
            print_info "Stopping existing web servers..."
            systemctl stop apache2 2>/dev/null || true
            systemctl stop nginx 2>/dev/null || true
            print_success "Web servers stopped"
        fi
        
        # Check if port 25 is in use (by exim4/postfix)
        if ss -tuln | grep -q ':25 '; then
            print_warning "Port 25 is already in use (likely exim4 or postfix)"
            print_info "Stopping mail server..."
            systemctl stop exim4 2>/dev/null || true
            systemctl stop postfix 2>/dev/null || true
            systemctl disable exim4 2>/dev/null || true
            systemctl disable postfix 2>/dev/null || true
            print_success "Mail server stopped"
        fi
        
        DOCKER_COMPOSE=$(get_docker_compose)
        
        print_info "Starting Mailcow (this may take a few minutes)..."
        sudo $DOCKER_COMPOSE up -d
        
        print_info "Checking container status..."
        sudo $DOCKER_COMPOSE ps
        
        print_success "Mailcow started successfully"
        
        # Get domain
        DOMAIN=$(grep "^MAILCOW_HOSTNAME=" mailcow.conf 2>/dev/null | cut -d= -f2 | sed 's/mail.//')
        
        if [ -n "$DOMAIN" ]; then
            print_info "=============================================="
            print_info "MAILCOW IS NOW RUNNING!"
            print_info "=============================================="
            echo ""
            print_info "Access your mail server at:"
            echo "  • https://mail.$DOMAIN"
            echo ""
            print_warning "DEFAULT CREDENTIALS (CHANGE IMMEDIATELY!):"
            echo "  • Username: admin"
            echo "  • Password: moohoo"
            echo ""
            print_info "To log in, go to: https://mail.$DOMAIN"
            echo ""
            print_warning "IMPORTANT NEXT STEPS:"
            echo "  1. Log in and CHANGE THE PASSWORD immediately"
            echo "  2. Set up DNS records (MX, SPF, DKIM)"
            echo "  3. Create your first email account"
            echo ""
        fi
    else
        print_warning "Skipped"
    fi
}

step_configure_firewall() {
    show_step_info \
        "Configure Firewall" \
        "Mail servers need several ports open to function." \
        "• Port 25 - SMTP (receiving mail)
• Port 587 - SMTP submission
• Port 465 - SMTPS
• Port 993 - IMAPS
• Port 80/443 - Web UI"
    
    if confirm "Configure firewall?"; then
        if ! command -v ufw &>/dev/null; then
            apt install -y ufw
        fi
        
        for port in 25 80 443 587 465 993 995; do
            ufw allow $port/tcp 2>/dev/null || true
        done
        
        print_success "Firewall configured"
        ufw status | grep -E "^(25|80|443|587|465|993|995)"
    else
        print_warning "Skipped"
    fi
}

step_dns_info() {
    show_step_info \
        "DNS Configuration" \
        "This step explains what DNS records you need to set up." \
        "MX Records, SPF, DKIM, DMARC, Reverse DNS"
    
    if confirm "Show DNS configuration?"; then
        load_config
        
        cd "$MAILCOW_DIR" 2>/dev/null
        DOMAIN=$(grep "^MAILCOW_DOMAIN=" mailcow.conf 2>/dev/null | cut -d= -f2)
        
        if [ -z "$DOMAIN" ]; then
            read -p "Enter your domain: " DOMAIN
        fi
        
        SERVER_IP=$(hostname -I 2>/dev/null | awk '{print $1}')
        
        echo ""
        print_info "Your DNS records should be:"
        echo ""
        echo -e "${CYAN}MX Record:${NC}"
        echo "  Host: @"
        echo "  Value: mail.$DOMAIN"
        echo "  Priority: 10"
        echo ""
        echo -e "${CYAN}A Record:${NC}"
        echo "  Host: mail"
        echo "  Value: $SERVER_IP"
        echo ""
        echo -e "${CYAN}SPF Record:${NC}"
        echo "  Host: @"
        echo "  Value: v=spf1 mx a:mail.$DOMAIN ~all"
        echo ""
        echo -e "${CYAN}DKIM:${NC}"
        echo "  Enable in Mailcow UI at: https://mail.$DOMAIN/admin"
        echo "  Go to: Configuration > Content Filter > ARC"
        echo ""
        print_warning "DNS changes can take up to 48 hours to propagate"
    else
        print_warning "Skipped"
    fi
}

show_menu() {
    echo ""
    print_header "Mail Server Setup Script (Mailcow)"
    echo ""
    echo -e "${CYAN}Setup Steps:${NC}"
    echo "  1) Install prerequisites        - Docker & Docker Compose"
    echo "  2) Download Mailcow            - Get mail server files"
    echo "  3) Configure Mailcow           - Set domain and password"
    echo "  4) Start Mailcow               - Launch mail server"
    echo "  5) Configure firewall          - Open mail ports"
    echo "  6) DNS configuration           - MX, SPF, DKIM records"
    echo ""
    echo -e "${CYAN}Commands:${NC}"
    echo "  a) Run steps 1-5 (basic setup)"
    echo "  q) Quit"
    echo ""
}

main() {
    check_root
    load_config
    DOCKER_COMPOSE=$(get_docker_compose)
    export DOCKER_COMPOSE
    
    if [ -n "$1" ]; then
        case "$1" in
            1) step_install_prerequisites ;;
            2) step_download_mailcow ;;
            3) step_configure_mailcow ;;
            4) step_start_mailcow ;;
            5) step_configure_firewall ;;
            6) step_dns_info ;;
            a) 
                step_install_prerequisites
                step_download_mailcow
                step_configure_mailcow
                step_start_mailcow
                step_configure_firewall
                print_success "Basic setup complete!"
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
                1) step_install_prerequisites ;;
                2) step_download_mailcow ;;
                3) step_configure_mailcow ;;
                4) step_start_mailcow ;;
                5) step_configure_firewall ;;
                6) step_dns_info ;;
                a) 
                    step_install_prerequisites
                    step_download_mailcow
                    step_configure_mailcow
                    step_start_mailcow
                    step_configure_firewall
                    print_success "Basic setup complete!"
                    ;;
                q) echo "Goodbye!"; exit 0 ;;
                *) echo "Invalid option" ;;
            esac
        done
    fi
}

main "$@"
