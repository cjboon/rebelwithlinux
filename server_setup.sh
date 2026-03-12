#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() { echo -e "\n${BLUE}========================================${NC}\n${BLUE}$1${NC}\n${BLUE}========================================${NC}"; }
print_success() { echo -e "${GREEN}[✓] $1${NC}"; }
print_warning() { echo -e "${YELLOW}[!] $1${NC}"; }
print_error() { echo -e "${RED}[✗] $1${NC}"; }
print_info() { echo -e "${BLUE}[i] $1${NC}"; }

STEPS=()
STEP_NAMES=()

add_step() { STEPS+=("$1"); STEP_NAMES+=("$2"); }

confirm() {
    local prompt="$1"
    local response
    read -p "$prompt [y/N]: " response
    [[ "$response" =~ ^[Yy]$ ]]
}

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

step_update_system() {
    show_step_info \
        "Update System" \
        "Downloads and installs the latest package updates from Debian repositories. This ensures all software has the latest security patches and bug fixes." \
        "• Runs apt update to refresh package lists
• Runs apt upgrade to install new versions of all packages
• Total time depends on number of updates available"
    
    if confirm "Proceed with system update?"; then
        apt update && apt upgrade -y
        print_success "System updated"
    else
        print_warning "Skipped"
    fi
}

step_security_tools() {
    show_step_info \
        "Install Security Tools" \
        "Installs essential security packages that will be used throughout the setup process." \
        "• ufw - Uncomplicated Firewall (simplified iptables management)
• fail2ban - Automatically bans IPs that fail authentication
• gnupg2 - Encryption tools
• lsof, net-tools - Network diagnostic tools"
    
    if confirm "Proceed with installing security tools?"; then
        apt install -y ufw fail2ban gnupg2 lsof net-tools
        print_success "Security tools installed"
    else
        print_warning "Skipped"
    fi
}

step_check_swap() {
    show_step_info \
        "Check/Create Swap" \
        "Checks if swap memory is configured. Swap acts as virtual RAM when physical RAM is full, preventing out-of-memory errors." \
        "• Checks existing swap with swapon --show
• If no swap exists, creates a 2GB swapfile at /swapfile
• Sets proper permissions (600) for security
• Enables swap and adds to /etc/fstab for persistence"
    
    if confirm "Proceed with swap configuration?"; then
        if swapon --show | grep -q .; then
            print_info "Swap already enabled"
            swapon --show
        else
            SWAP_SIZE_GB=2
            SWAPFILE="/swapfile"
            print_info "Creating ${SWAP_SIZE_GB}GB swapfile..."
            fallocate -l ${SWAP_SIZE_GB}G $SWAPFILE 2>/dev/null || dd if=/dev/zero of=$SWAPFILE bs=1G count=$SWAP_SIZE_GB
            chmod 600 $SWAPFILE
            mkswap $SWAPFILE
            swapon $SWAPFILE
            grep -q "$SWAPFILE" /etc/fstab || echo "$SWAPFILE none swap sw 0 0" >> /etc/fstab
            print_success "Swap created"
            swapon --show
        fi
    else
        print_warning "Skipped"
    fi
}

step_firewall() {
    show_step_info \
        "Configure Firewall" \
        "Sets up UFW (Uncomplicated Firewall) to protect your server from unauthorized access." \
        "• Enables UFW firewall
• Sets default policy: deny all incoming connections
• Sets default policy: allow all outgoing connections
• Allows SSH on your configured port (prevents lockout)"
    
    if confirm "Proceed with firewall configuration?"; then
        ufw --force enable
        ufw default deny incoming
        ufw default allow outgoing
        ufw allow ${SSH_PORT:-22}/tcp
        print_success "Firewall configured"
        ufw status numbered
    else
        print_warning "Skipped"
    fi
}

step_user_setup() {
    show_step_info \
        "User Setup" \
        "Creates a non-root user with sudo privileges and configures SSH key-based authentication. This is critical for server security." \
        "• Creates new user with home directory and bash shell
• Prompts for password (required even with SSH keys)
• Adds user to sudo group for administrative tasks
• Copies your SSH public key to the new user's authorized_keys
• Disables root login later (step 6) for security"
    
    if confirm "Proceed with user setup?"; then
        read -p "Enter new username: " NEW_USER
        if ! id "$NEW_USER" &>/dev/null; then
            useradd -m -s /bin/bash "$NEW_USER"
            read -s -p "Enter password for $NEW_USER: " USER_PASS
            echo "$NEW_USER:$USER_PASS" | chpasswd
            print_success "User $NEW_USER created"
        else
            print_warning "User $NEW_USER already exists"
        fi
        usermod -aG sudo "$NEW_USER"
        
        print_info "Setting up SSH public key..."
        echo "Enter your SSH public key (starts with ssh-rsa, ssh-ed25519, etc.)"
        echo "Or press Enter to skip (you can add it later)"
        read -p "SSH Public Key: " SSH_KEY
        
        if [ -n "$SSH_KEY" ]; then
            mkdir -p "/home/$NEW_USER/.ssh"
            echo "$SSH_KEY" > "/home/$NEW_USER/.ssh/authorized_keys"
            chmod 700 "/home/$NEW_USER/.ssh"
            chmod 600 "/home/$NEW_USER/.ssh/authorized_keys"
            chown -R "$NEW_USER:$NEW_USER" "/home/$NEW_USER/.ssh"
            print_success "SSH key added for $NEW_USER"
        else
            print_warning "No SSH key provided - you can add it manually later"
        fi
    else
        print_warning "Skipped"
    fi
}

step_ssh_setup() {
    show_step_info \
        "SSH Setup" \
        "Hardens SSH configuration to prevent unauthorized access. This step disables password authentication and root login." \
        "• Changes SSH port (optional, helps avoid automated attacks)
• Disables root login (must use non-root user)
• Disables password authentication (key-only access)
• Enables pubkey authentication
• Sets MaxAuthTries to 3
• Configures ClientAliveInterval to detect dropped connections
• Disables X11 forwarding and TCP forwarding
• Restarts SSH service to apply changes"
    
    if confirm "Proceed with SSH hardening?"; then
        read -p "Enter SSH port (default 22): " SSH_PORT
        SSH_PORT=${SSH_PORT:-22}
        
        cat > /etc/ssh/sshd_config.d/custom.conf << EOF
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2
X11Forwarding no
AllowTcpForwarding no
PermitEmptyPasswords no
ChallengeResponseAuthentication no
Port $SSH_PORT
EOF
        
        systemctl restart ssh
        print_success "SSH configured on port $SSH_PORT"
        print_warning "Make sure you can login with your SSH key before disconnecting!"
    else
        print_warning "Skipped"
    fi
}

step_fail2ban() {
    show_step_info \
        "Configure Fail2ban" \
        "Fail2ban automatically monitors login attempts and bans IPs that fail authentication too many times. Protects against brute-force attacks." \
        "• Creates jail.local configuration
• Sets ban time to 1 hour
• Sets detection window to 10 minutes
• Maximum 5 retries before ban
• Monitors SSH on your configured port
• Enables and starts fail2ban service"
    
    if confirm "Proceed with fail2ban configuration?"; then
        cat > /etc/fail2ban/jail.local << EOF
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 5

[sshd]
enabled = true
port = ${SSH_PORT:-22}
EOF
        systemctl enable fail2ban && systemctl restart fail2ban
        
        sleep 2
        
        if fail2ban-client ping &>/dev/null; then
            print_success "Fail2ban configured and running"
            fail2ban-client status
        else
            print_warning "Fail2ban installed but not yet running - will start on next boot"
        fi
    else
        print_warning "Skipped"
    fi
}

step_kernel_hardening() {
    show_step_info \
        "Kernel Hardening" \
        "Configures Linux kernel parameters to enhance network security and protect against various attacks." \
        "• TCP SYN cookies - Prevents SYN flood attacks
• Reverse path filtering - Prevents IP spoofing
• Disables source routing - Prevents routed packets
• Ignores broadcast ICMP - Prevents ping floods
• Disables ICMP redirects - Prevents redirect attacks
• Logs martian packets - Logs suspicious packets
• Ignores bogus ICMP errors - Reduces log noise"
    
    if confirm "Proceed with kernel hardening?"; then
        cat > /etc/sysctl.d/99-custom.conf << EOF
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1
EOF
        sysctl -p /etc/sysctl.d/99-custom.conf 2>/dev/null || true
        print_success "Kernel hardened"
    else
        print_warning "Skipped"
    fi
}

step_auto_updates() {
    show_step_info \
        "Automatic Security Updates" \
        "Configures unattended-upgrades to automatically install security patches without manual intervention." \
        "• Installs unattended-upgrades package
• Configures automatic security updates
• Enables automatic reboot for kernel updates
• Sets reboot time to 2:00 AM (configurable)
• Checks updates from security and updates repositories"
    
    if confirm "Proceed with automatic updates setup?"; then
        apt install -y unattended-upgrades
        cat > /etc/apt/apt.conf.d/50unattended-upgrades << EOF
Unattended-Upgrade::Allowed-Origins {
    "\${distro_id}:\${distro_codename}-security";
    "\${distro_id}:\${distro_codename}-updates";
};
Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-RebootTime "02:00";
EOF
        print_success "Automatic updates configured"
    else
        print_warning "Skipped"
    fi
}

step_log_monitoring() {
    show_step_info \
        "Log Monitoring" \
        "Installs and configures Logwatch to provide daily email summaries of system activity, helping detect suspicious behavior." \
        "• Installs logwatch package
• Creates daily cron job to run logwatch
• Configures detailed log analysis
• Reports sent to root email (forward externally if needed)"
    
    if confirm "Proceed with log monitoring setup?"; then
        apt install -y logwatch
        cat > /etc/cron.daily/logwatch << 'EOF'
#!/bin/sh
/usr/sbin/logwatch --output mail --mailto root --detail high
EOF
        chmod 755 /etc/cron.daily/logwatch
        print_success "Log monitoring configured"
    else
        print_warning "Skipped"
    fi
}

step_file_permissions() {
    show_step_info \
        "File Permissions" \
        "Secures file permissions on sensitive directories to prevent unauthorized access." \
        "• Sets /root directory to 700 (owner only)
• Sets all .ssh directories to 700
• Sets all authorized_keys files to 600
• Ensures only owners can read their SSH keys"
    
    if confirm "Proceed with file permissions?"; then
        chmod 700 /root
        chmod 700 /home/*/.ssh 2>/dev/null || true
        chmod 600 /home/*/.ssh/authorized_keys 2>/dev/null || true
        print_success "File permissions secured"
    else
        print_warning "Skipped"
    fi
}

step_core_dumps() {
    show_step_info \
        "Disable Core Dumps" \
        "Core dumps contain memory snapshots that could expose sensitive data if a program crashes. Disabling them improves security." \
        "• Sets soft and hard core limits to 0 in limits.conf
• Sets fs.suid_dumpable to 0 in sysctl
• Prevents setuid programs from dumping core
• Protects potentially sensitive data in memory"
    
    if confirm "Proceed with disabling core dumps?"; then
        echo "* soft core 0" >> /etc/security/limits.conf
        echo "* hard core 0" >> /etc/security/limits.conf
        echo "fs.suid_dumpable = 0" >> /etc/sysctl.d/99-custom.conf
        sysctl -p /etc/sysctl.d/99-custom.conf
        print_success "Core dumps disabled"
    else
        print_warning "Skipped"
    fi
}

step_disable_services() {
    show_step_info \
        "Disable Unnecessary Services" \
        "Stops and disables services that aren't needed, reducing attack surface and improving performance." \
        "• apache2 - Web server (disable if not using)
        • nginx - Web server (disable if not using)
        • cups - Print service (unnecessary on servers)
        • bluetooth - Unnecessary on most servers
        • avahi-daemon - Service discovery (unnecessary)"
    
    if confirm "Proceed with disabling unnecessary services?"; then
        for svc in apache2 nginx cups bluetooth avahi-daemon; do
            systemctl stop $svc 2>/dev/null || true
            systemctl disable $svc 2>/dev/null || true
        done
        print_success "Unnecessary services disabled"
    else
        print_warning "Skipped"
    fi
}

step_cleanup() {
    show_step_info \
        "Cleanup" \
        "Removes unnecessary packages and cache files to free up disk space." \
        "• Runs apt autoremove to remove unused packages
• Runs apt autoclean to clear apt cache
• Does not affect system functionality"
    
    if confirm "Proceed with cleanup?"; then
        apt autoremove -y && apt autoclean
        print_success "Cleanup complete"
    else
        print_warning "Skipped"
    fi
}

step_apache() {
    show_step_info \
        "Apache Setup" \
        "Installs and configures Apache web server with security best practices." \
        "• Installs Apache2 web server
• Enables SSL, rewrite, and headers modules
• Configures security headers:
  - ServerTokens Prod (hides version info)
  - ServerSignature Off
  - TraceEnable Off
  - X-Frame-Options
  - X-Content-Type-Options
  - X-XSS-Protection
  - Referrer-Policy
• Enables Apache to start on boot
• Opens ports 80 and 443 in UFW"
    
    if confirm "Proceed with Apache installation?"; then
        read -p "Install Apache? (y/n): " INSTALL_APACHE
        if [[ "$INSTALL_APACHE" =~ ^[Yy]$ ]]; then
            apt install -y apache2
            a2enmod ssl rewrite headers
            cat > /etc/apache2/conf-available/security.conf << EOF
ServerTokens Prod
ServerSignature Off
TraceEnable Off
Header always set X-Frame-Options "SAMEORIGIN"
Header always set X-Content-Type-Options "nosniff"
Header always set X-XSS-Protection "1; mode=block"
Header always set Referrer-Policy "strict-origin-when-cross-origin"
EOF
            a2enconf security
            systemctl enable apache2 && systemctl restart apache2
            if command -v ufw &>/dev/null && ufw status | grep -q "Status: active"; then
                ufw allow 'Apache Full'
            fi
            print_success "Apache installed and configured"
        fi
    else
        print_warning "Skipped"
    fi
}

step_hidden_service() {
    show_step_info \
        "Hidden Service Setup (Tor)" \
        "Creates a Tor onion service, allowing your site to be accessed via a .onion address without revealing your real IP." \
        "• Installs Tor daemon
• Creates hidden service directory
• Generates .onion address (public key)
• Routes ports 80 and 443 to your web server
• Provides anonymity for both server and visitors
• Useful for privacy-sensitive applications

⚠️ NOTE: Apache2 must be installed first (step 15). If you haven't installed Apache, skip this step and run step 15 first."
    
    if confirm "Proceed with Tor hidden service setup?"; then
        if ! command -v apache2 &>/dev/null; then
            print_error "Apache2 is not installed. Please run step 15 (Apache setup) first."
            print_info "You can install Apache, then return to run this step again."
            return 1
        fi
        
        read -p "Set up Tor hidden service? (y/n): " SETUP_TOR
        if [[ "$SETUP_TOR" =~ ^[Yy]$ ]]; then
            apt install -y tor
            mkdir -p /var/lib/tor/hidden_service
            chown debian-tor:debian-tor /var/lib/tor/hidden_service
            chmod 700 /var/lib/tor/hidden_service
            cat > /etc/tor/torrc << EOF
HiddenServiceDir /var/lib/tor/hidden_service/
HiddenServicePort 80 127.0.0.1:80
HiddenServicePort 443 127.0.0.1:443
EOF
            systemctl enable tor && systemctl restart tor
            sleep 2
            
            print_info "By default, Tor hidden service serves from Apache's default document root (/var/www/html)"
            echo ""
            read -p "Redirect hidden service to an existing site's document root? (y/n): " REDIRECT_SITE
            if [[ "$REDIRECT_SITE" =~ ^[Yy]$ ]]; then
                echo "Available sites:"
                ls -1 /etc/apache2/sites-enabled/ 2>/dev/null | grep -v "^000-default" | grep -v "^default-ssl" || true
                read -p "Enter site domain (e.g., example.com): " TOR_DOMAIN
                if [ -d "/var/www/$TOR_DOMAIN" ]; then
                    cat > /etc/apache2/sites-available/hidden_service.conf << EOF
<VirtualHost *:80>
    ServerName localhost
    DocumentRoot /var/www/$TOR_DOMAIN

    ServerSignature Off

    <Directory /var/www/$TOR_DOMAIN>
        Options -Indexes -FollowSymLinks +SymLinksIfOwnerMatch
        AllowOverride None
        Require all granted

        <FilesMatch "^\.">
            Require all denied
        </FilesMatch>
    </Directory>

    <IfModule mod_headers.c>
        Header always set X-Content-Type-Options "nosniff"
        Header always set X-Frame-Options "DENY"
        Header always set X-XSS-Protection "1; mode=block"
        Header always set Referrer-Policy "no-referrer"
        Header always set Permissions-Policy "geolocation=(), microphone=(), camera=()"
    </IfModule>
</VirtualHost>
EOF
                    a2ensite hidden_service.conf
                    systemctl reload apache2
                    print_success "Hidden service now serves from /var/www/$TOR_DOMAIN"
                else
                    print_error "Site /var/www/$TOR_DOMAIN does not exist"
                    print_info "Hidden service will use default Apache document root"
                fi
            else
                print_info "Hidden service will use default Apache document root (/var/www/html)"
            fi
            
            if [ -f /var/lib/tor/hidden_service/hostname ]; then
                print_success "Hidden service created!"
                print_info "Your .onion address:"
                cat /var/lib/tor/hidden_service/hostname
            fi
        fi
    else
        print_warning "Skipped"
    fi
}

create_site() {
    print_header "Create New Site"
    
    show_step_info \
        "Create New Site" \
        "Creates a new Apache virtual host with basic configuration." \
        "• Creates document root directory
• Creates basic index.html
• Sets correct ownership (www-data)
• Creates Apache virtual host config
• Enables the site in Apache"
    
    if confirm "Create new site?"; then
        read -p "Enter domain name (e.g., example.com): " DOMAIN
        read -p "Enter document root (default: /var/www/$DOMAIN): " DOCROOT
        DOCROOT=${DOCROOT:-/var/www/$DOMAIN}
        
        mkdir -p "$DOCROOT"
        echo "<html><head><title>$DOMAIN</title></head><body><h1>Welcome to $DOMAIN</h1></body></html>" > "$DOCROOT/index.html"
        chown -R www-data:www-data "$DOCROOT"
        chmod -R 755 "$DOCROOT"
        
        cat > /etc/apache2/sites-available/${DOMAIN}.conf << EOF
<VirtualHost *:80>
    ServerName $DOMAIN
    ServerAlias www.$DOMAIN
    DocumentRoot $DOCROOT

    ServerSignature Off

    <Directory $DOCROOT>
        Options -Indexes -FollowSymLinks +SymLinksIfOwnerMatch
        AllowOverride None
        Require all granted

        <FilesMatch "^\.">
            Require all denied
        </FilesMatch>
    </Directory>

    <IfModule mod_headers.c>
        Header always set X-Content-Type-Options "nosniff"
        Header always set X-Frame-Options "DENY"
        Header always set X-XSS-Protection "1; mode=block"
        Header always set Referrer-Policy "strict-origin-when-cross-origin"
        Header always set Permissions-Policy "geolocation=(), microphone=(), camera=()"
    </IfModule>

    ErrorLog \${APACHE_LOG_DIR}/${DOMAIN}_error.log
    CustomLog \${APACHE_LOG_DIR}/${DOMAIN}_access.log combined
</VirtualHost>
EOF
        
        a2ensite ${DOMAIN}.conf
        systemctl restart apache2
        
        print_success "Site $DOMAIN created"
        print_info "Document root: $DOCROOT"
    else
        print_warning "Skipped"
    fi
}

add_site_ssl() {
    print_header "Add SSL to Site"
    
    show_step_info \
        "Add SSL (Let's Encrypt)" \
        "Obtains and installs a free SSL certificate from Let's Encrypt." \
        "• Installs certbot if not present
        • Verifies domain ownership
        • Obtains SSL certificate
        • Modifies Apache config for HTTPS
        • Sets up automatic renewal
        • Enables both HTTP and HTTPS"
    
    if confirm "Add SSL to site?"; then
        read -p "Enter domain name: " DOMAIN
        CONF_FILE="/etc/apache2/sites-available/${DOMAIN}.conf"
        
        if [ ! -f "$CONF_FILE" ]; then
            print_error "Site $DOMAIN does not exist"
            return 1
        fi
        
        if ! command -v certbot &>/dev/null; then
            print_info "Installing certbot..."
            apt install -y python3-certbot-apache
        fi
        
        read -p "Enter email for Let's Encrypt: " EMAIL
        
        if command -v ufw &>/dev/null && ufw status | grep -q "Status: active"; then
            ufw allow 80/tcp
            ufw allow 443/tcp
        fi
        
        certbot --apache -d "$DOMAIN" -d "www.$DOMAIN" --non-interactive --agree-tos --email "$EMAIL"

        SSL_CONF="/etc/apache2/sites-available/${DOMAIN}-le-ssl.conf"
        if [ -f "$SSL_CONF" ]; then
            if ! grep -q "X-Content-Type-Options" "$SSL_CONF"; then
                sed -i '/<\/VirtualHost>/i\        Header always set X-Content-Type-Options "nosniff"\n        Header always set X-Frame-Options "DENY"\n        Header always set X-XSS-Protection "1; mode=block"\n        Header always set Referrer-Policy "strict-origin-when-cross-origin"\n        Header always set Permissions-Policy "geolocation=(), microphone=(), camera=()"\n        Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"' "$SSL_CONF"
            fi

            if grep -q "AllowOverride All" "$SSL_CONF"; then
                sed -i 's/AllowOverride All/AllowOverride None/g' "$SSL_CONF"
            fi

            if ! grep -q "Options -Indexes" "$SSL_CONF"; then
                sed -i 's/Require all granted/Options -Indexes -FollowSymLinks +SymLinksIfOwnerMatch\n        Require all granted/g' "$SSL_CONF"
            fi
        fi

        systemctl reload apache2
        print_success "SSL enabled for $DOMAIN"
    else
        print_warning "Skipped"
    fi
}

show_menu() {
    echo "=== Server Setup Script ==="
    echo ""
    echo -e "${CYAN}Available steps:${NC}"
    echo "  1) Update system              - Install latest packages"
    echo "  2) Install security tools     - UFW, fail2ban, utilities"
    echo "  3) Check/create swap         - Virtual memory configuration"
    echo "  4) Configure firewall        - UFW rules"
    echo "  5) User setup                 - Create non-root user with SSH key"
    echo "  6) SSH setup                  - Disable root, key-only auth"
    echo "  7) Configure fail2ban         - Auto-ban brute force"
    echo "  8) Kernel hardening          - Network security sysctl"
    echo "  9) Automatic security updates"
    echo " 10) Log monitoring            - Daily log summaries"
    echo " 11) File permissions          - Secure SSH directories"
    echo " 12) Disable core dumps        - Prevent memory leaks"
    echo " 13) Disable unnecessary services"
    echo " 14) Cleanup                   - Remove unused packages"
    echo " 15) Apache setup              - Install & secure Apache"
    echo " 16) Create new site          - Add Apache virtual host"
    echo " 17) Hidden service (Tor)     - Create .onion address"
    echo ""
    echo -e "${CYAN}Site Management:${NC}"
    echo " 18) Add SSL to site"
    echo ""
    echo -e "${CYAN}Commands:${NC}"
    echo "  a) Run all steps"
    echo "  q) Quit"
    echo ""
}

parse_selection() {
    local input="$1"
    
    if [[ "$input" == "q" ]]; then
        echo "Goodbye!"
        exit 0
    elif [[ "$input" == "a" ]]; then
        for i in "${!STEP_NAMES[@]}"; do
            "${STEPS[$i]}"
        done
    else
        for token in $(echo "$input" | tr ',' ' '); do
            case "$token" in
                1) step_update_system ;;
                2) step_security_tools ;;
                3) step_check_swap ;;
                4) step_firewall ;;
                5) step_user_setup ;;
                6) step_ssh_setup ;;
                7) step_fail2ban ;;
                8) step_kernel_hardening ;;
                9) step_auto_updates ;;
                10) step_log_monitoring ;;
                11) step_file_permissions ;;
                12) step_core_dumps ;;
                13) step_disable_services ;;
                14) step_cleanup ;;
                15) step_apache ;;
                16) create_site ;;
                17) step_hidden_service ;;
                18) add_site_ssl ;;
                *) echo -e "${RED}Invalid selection: $token${NC}" ;;
            esac
        done
    fi
}

init_steps() {
    STEPS=()
    STEP_NAMES=()
    add_step "step_update_system" "Update system"
    add_step "step_security_tools" "Install security tools"
    add_step "step_check_swap" "Check/create swap"
    add_step "step_firewall" "Configure firewall"
    add_step "step_user_setup" "User setup"
    add_step "step_ssh_setup" "SSH setup"
    add_step "step_fail2ban" "Configure fail2ban"
    add_step "step_kernel_hardening" "Kernel hardening"
    add_step "step_auto_updates" "Automatic security updates"
    add_step "step_log_monitoring" "Log monitoring"
    add_step "step_file_permissions" "File permissions"
    add_step "step_core_dumps" "Disable core dumps"
    add_step "step_disable_services" "Disable unnecessary services"
    add_step "step_cleanup" "Cleanup"
    add_step "step_apache" "Apache setup"
    add_step "step_hidden_service" "Hidden service (Tor)"
}

main() {
    init_steps
    
    if [ -n "$1" ]; then
        parse_selection "$1"
    else
        while true; do
            show_menu
            echo -n "Selection: "
            read -r selection
            parse_selection "$selection"
            echo ""
        done
    fi
}

main "$@"
