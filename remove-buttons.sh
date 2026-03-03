#!/bin/bash

# Remove dark mode buttons from all HTML files except index.html

# List of files to process
files=(
    "hyper.html"
    "hardening.html"
    "git.html"
    "docker.html"
    "dns.html"
    "css.html"
    "blog.html"
    "blog-pwa.html"
    "blog-monero.html"
    "blog-gpg.html"
    "blog-foss.html"
    "bash.html"
    "apache2.html"
    "vps.html"
    "python.html"
    "project-wireguard.html"
    "project-paste.html"
    "project-onion.html"
    "project-mail.html"
    "project-i3.html"
    "project-homelab.html"
    "project-fileshare.html"
    "project-blog.html"
    "php.html"
    "offline.html"
    "nginx.html"
    "networking.html"
    "monitoring.html"
    "mariadb.html"
    "linux.html"
    "kubernetes.html"
    "javascript.html"
)

for file in "${files[@]}"; do
    echo "Processing $file..."
    
    # Remove dark mode button from nav
    sed -i '/<themeToggle/,/</label>/d' "$file"
    
    # Remove any JavaScript dark mode functionality
    sed -i '/toggleTheme/d' "$file"
    sed -i '/localStorage/d' "$file"
    sed -i '/document.getElementById.*themeToggle/d' "$file"
    
    # Remove any remaining theme-related JavaScript
    sed -i '/'toggleTheme'/d' "$file"
    sed -i '/'themeToggle'/d' "$file"
    
    # Remove any empty lines left by deletions
    sed -i '/^\s*$/d' "$file"
    
    # Remove any orphaned <label> tags
    sed -i '/<label[^/]*>/Id' "$file"
    
    # Fix navigation spacing
    sed -i 's/\s\s/\s/g' "$file"
    
    echo "Removed dark mode button from $file"
done

echo "Done! Dark mode buttons removed from all pages except homepage."

# Now fix the homepage to remove JavaScript dark mode functionality
# (already done in previous steps)