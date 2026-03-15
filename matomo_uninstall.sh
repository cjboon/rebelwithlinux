#!/bin/bash

# Matomo Uninstaller
# Run with: sudo bash matomo_uninstall.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() { echo -e "\n${BLUE}========================================${NC}\n${BLUE}$1${NC}\n${BLUE}========================================${NC}"; }
print_success() { echo -e "${GREEN}[✓] $1${NC}"; }
print_warning() { echo -e "${YELLOW}[!] $1${NC}"; }

confirm() {
    local prompt="$1"
    local response
    read -p "$prompt [y/N]: " response
    [[ "$response" =~ ^[Yy]$ ]]
}

print_header "Matomo Uninstaller"

if ! confirm "This will remove Matomo and all tracking. Continue?"; then
    print_warning "Uninstall cancelled."
    exit 0
fi

# Remove Matomo files
print_header "Removing Matomo Files"
if [ -d "/var/www/matomo" ]; then
    rm -rf /var/www/matomo
    print_success "Removed /var/www/matomo"
else
    print_warning "Matomo directory not found"
fi

# Remove database
print_header "Removing Database"
if confirm "Remove Matomo database and user?"; then
    mysql -u root -e "DROP DATABASE IF EXISTS matomo;"
    mysql -u root -e "DROP USER IF EXISTS 'matomo'@'localhost';"
    print_success "Database removed"
fi

# Remove Apache config
print_header "Removing Apache Config"
if [ -f /etc/apache2/sites-available/matomo.conf ]; then
    a2dissite matomo.conf 2>/dev/null || true
    rm -f /etc/apache2/sites-available/matomo.conf
    print_success "Apache config removed"
fi

# Remove SSL cert
print_header "Removing SSL Certificate"
if confirm "Remove SSL certificate for matomo.yourdomain.com?"; then
    certbot delete --non-interactive --cert-name matomo.yourdomain.com 2>/dev/null || print_warning "SSL cert may already be removed"
    print_success "SSL certificate removed"
fi

# Remove tracking code from website
print_header "Removing Tracking Code"
cd /var/www/rebelwithlinux.com 2>/dev/null || cd /var/www/html
if [ -f "index.html" ]; then
    sed -i '/<!-- Matomo Analytics -->/d' index.html
    sed -i '/<script src="matomo.js"><\/script>/d' index.html
    rm -f matomo.js matomo.html
    print_success "Removed tracking code from website"
fi

systemctl reload apache2

print_header "Uninstall Complete!"
echo ""
echo "Removed:"
echo "  - Matomo files"
echo "  - Database"
echo "  - Apache config"
echo "  - SSL certificate"
echo "  - Tracking code"
echo ""
