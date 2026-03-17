#!/bin/bash

# === CONFIG ===
SITE_NAME="rebelwithlinux.com"
WEB_ROOT="/var/www/${SITE_NAME}"
DEFAULT_LOCATION="Unknown"
# === END CONFIG ===

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HTML_FILE="${WEB_ROOT}/index.html"

setup_systemd_timer() {
    local timer_name="server-report.timer"
    local service_name="server-report.service"
    
    if [ ! -f "/etc/systemd/system/$timer_name" ]; then
        echo "Setting up systemd timer..."
        
        # Create service file
        cat > "/etc/systemd/system/$service_name" << 'EOF'
[Unit]
Description=Hourly Server Report Script

[Service]
Type=oneshot
ExecStart=${SCRIPT_DIR}/server_report.sh
EOF
        
        # Create timer file
        cat > "/etc/systemd/system/$timer_name" << 'EOF'
[Unit]
Description=Hourly Server Report Timer

[Timer]
OnCalendar=hourly
Persistent=true

[Install]
WantedBy=timers.target
EOF
        
        systemctl daemon-reload
        systemctl enable --now "$timer_name"
        echo "Timer installed and enabled"
    fi
}

# Setup systemd timer if needed
setup_systemd_timer

echo "Checking file: $HTML_FILE"
if [ ! -f "$HTML_FILE" ]; then
    echo "Error: $HTML_FILE not found"
    exit 1
fi
echo "File exists"

# Update server stats inside the Stats section
export DEFAULT_LOCATION

python3 << 'PYTHON_EOF'
import os
import sys
import json
import re

html_file = os.environ.get('HTML_FILE', '/var/www/rebelwithlinux.com/index.html')
default_location = os.environ.get('DEFAULT_LOCATION', 'Ogden, Utah')

print(f"Checking file: {html_file}")
if not os.path.isfile(html_file):
    print(f"Error: {html_file} not found")
    sys.exit(1)
print("File exists")

with open(html_file, 'r') as f:
    content = f.read()

# Get server stats
uptime = os.popen('uptime -p 2>/dev/null || echo "uptime unavailable"').read().strip()
loadavg = os.popen("cat /proc/loadavg | awk '{print $1}'").read().strip()
memory = os.popen("free -h | awk '/^Mem:/ {print $3\"/\"$2}'").read().strip()
disk = os.popen("df -h / | awk 'NR==2 {print $3\"/\"$2}'").read().strip()
proc = os.popen("ps aux --sort=-%cpu | head -2 | tail -1 | awk '{print $11}'").read().strip()
cpu = os.popen("ps aux --sort=-%cpu | head -2 | tail -1 | awk '{print $3}'").read().strip()

print(f"Stats: {uptime} | {loadavg} | {memory}")

try:
    import urllib.request
    with urllib.request.urlopen('https://ipinfo.io/json', timeout=5) as response:
        location_data = json.load(response)
        location = location_data.get('city', 'Unknown')
        region = location_data.get('region', '')
        if region:
            location = f"{location}, {region}"
except:
    location = os.environ.get('DEFAULT_LOCATION', 'Unknown')

# Update server stats using class selectors
content = re.sub(r'<span class="stat-location"[^>]*>[^<]*</span>', f'<span class="stat-location">{location}</span>', content)
content = re.sub(r'<span class="stat-uptime"[^>]*>[^<]*</span>', f'<span class="stat-uptime">{uptime}</span>', content)
content = re.sub(r'<span class="stat-load"[^>]*>[^<]*</span>', f'<span class="stat-load">{loadavg}</span>', content)
content = re.sub(r'<span class="stat-memory"[^>]*>[^<]*</span>', f'<span class="stat-memory">{memory}</span>', content)
content = re.sub(r'<span class="stat-disk"[^>]*>[^<]*</span>', f'<span class="stat-disk">{disk}</span>', content)
content = re.sub(r'<span class="stat-proc"[^>]*>[^<]*</span>', f'<span class="stat-proc">{proc}<br>{cpu}% CPU</span>', content)

with open(html_file, 'w') as f:
    f.write(content)
    
print("Server stats updated in Stats section")
PYTHON_EOF
