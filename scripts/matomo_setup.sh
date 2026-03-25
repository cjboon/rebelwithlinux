#!/bin/bash

# === CONFIG ===
SITE_NAME="rebelwithlinux.com"
WEB_ROOT="/var/www/${SITE_NAME}"
MATOMO_DIR="/var/www/matomo"
# === END CONFIG ===

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

confirm() {
    local prompt="$1"
    local response
    read -p "$prompt [y/N]: " response
    [[ "$response" =~ ^[Yy]$ ]]
}

print_header "Matomo Setup Script"

print_info "This script will set up Matomo analytics on your server."
print_info ""
print_info "Prerequisites:"
print_info "  1. Create a DNS A record for your subdomain (e.g., matomo.yourdomain.com)"
print_info "     pointing to your server's IP address"
print_info "  2. Wait for DNS to propagate (can take up to 24 hours)"
print_info "  3. Disable adblocker/uBlock during Matomo setup wizard"
print_info ""

# Check dependencies
print_header "Checking Dependencies"

MISSING_DEPS=()

# Check PHP
if ! command -v php &> /dev/null; then
    MISSING_DEPS+=("php")
fi

# Check MariaDB/MySQL
if ! command -v mysql &> /dev/null; then
    MISSING_DEPS+=("mariadb-server")
fi

# Check required PHP extensions
PHP_EXTENSIONS=("php-mysql" "php-curl" "php-gd" "php-mbstring" "php-xml" "php-ldap")
for ext in "${PHP_EXTENSIONS[@]}"; do
    if ! dpkg -l | grep -q "^ii  $ext"; then
        MISSING_DEPS+=("$ext")
    fi
done

if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
    print_warning "Missing dependencies: ${MISSING_DEPS[*]}"
    if confirm "Install missing dependencies?"; then
        apt update
        apt install -y "${MISSING_DEPS[@]}"
        print_success "Dependencies installed."
    else
        print_error "Cannot proceed without required dependencies."
        exit 1
    fi
else
    print_success "All dependencies found."
fi

if ! confirm "Continue with Matomo setup?"; then
    print_warning "Setup cancelled."
    exit 0
fi

# Get Matomo domain
print_header "Configuration"
read -p "Enter Matomo subdomain (e.g., matomo.yourdomain.com): " MATOMO_DOMAIN
read -p "Enter Matomo database name [matomo]: " DB_NAME
DB_NAME=${DB_NAME:-matomo}
read -p "Enter Matomo database user [matomo]: " DB_USER
DB_NAME=${DB_USER:-matomo}
read -p "Enter Matomo database password: " -s DB_PASS
echo ""

# Download Matomo
print_header "Downloading Matomo"
if [ -d "$MATOMO_DIR" ]; then
    print_warning "Matomo already exists at $MATOMO_DIR"
    if ! confirm "Overwrite existing installation?"; then
        print_info "Skipping download."
    else
        rm -rf "$MATOMO_DIR"
        cd "$(dirname "$MATOMO_DIR")"
        curl -L -o matomo.tar.gz "https://builds.matomo.org/matomo.tar.gz"
        tar -xzf matomo.tar.gz
        rm matomo.tar.gz
        print_success "Matomo downloaded."
    fi
else
    cd "$(dirname "$MATOMO_DIR")"

    chown -R www-data:www-data "$MATOMO_DIR"
    chmod -R 755 "$MATOMO_DIR"

    cat > /etc/apache2/sites-available/matomo.conf <<EOF
    <VirtualHost *:80>
        ServerName analytics.${SITE_NAME}
        DocumentRoot $MATOMO_DIR

        <Directory $MATOMO_DIR>
            DirectoryIndex index.php
            Options -Indexes +FollowSymLinks
            AllowOverride All
            Require all granted
        </Directory>

        <Directory $MATOMO_DIR/tmp>
            Require all denied
        </Directory>
        <Directory $MATOMO_DIR/config>
            Require all denied
        </Directory>
    </VirtualHost>
EOF

    if [ -f "$MATOMO_DIR/config/config.ini.php" ]; then
        if ! grep -q "force_ssl" "$MATOMO_DIR/config/config.ini.php"; then
            sed -i '/^\[General\]/a force_ssl = 1' "$MATOMO_DIR/config/config.ini.php"
        print_success "Force SSL enabled in Matomo."
    else
        print_info "Force SSL already configured."
    fi
else
    print_warning "Matomo not configured yet. Run the web installer first."
fi

print_header "Setup Complete!"
echo ""
echo -e "${GREEN}Matomo is ready!${NC}"
echo ""
echo "Next steps:"
echo "  1. Visit https://${MATOMO_DOMAIN} in your browser"
echo "  2. Complete the Matomo web installer"
echo "  3. Add your website(s) in Matomo dashboard"
echo "  4. Add tracking code to your site:"
echo ""
echo "     <script src=\"https://${MATOMO_DOMAIN}/matomo.js\"></script>"
echo "     <script>"
echo "       var _paq = window._paq = window._paq || [];"
echo "       _paq.push(['trackPageView']);"
echo "       _paq.push(['enableLinkTracking']);"
echo "       (function() {"
echo "         var u=\"https://${MATOMO_DOMAIN}/\";"
echo "         _paq.push(['setTrackerUrl', u+'matomo.php']);"
echo "         _paq.push(['setSiteId', '1']);"
echo "         var d=document, g=d.createElement('script'), s=d.getElementsByTagName('script')[0];"
echo "         g.type='text/javascript'; g.async=true; g.src=u+'matomo.js'; s.parentNode.insertBefore(g,s);"
echo "       })();"
echo "     </script>"
echo ""
echo "Database details:"
echo "  Host: localhost"
echo "  Database: ${DB_NAME}"
echo "  User: ${DB_USER}"
echo "  Password: ${DB_PASS}"
echo ""
