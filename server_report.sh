#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/report_config.sh" ]; then
    source "$SCRIPT_DIR/report_config.sh"
fi

SITE_NAME="${SITE_NAME:-rebelwithlinux.com}"
WEB_ROOT="${WEB_ROOT:-/var/www/${SITE_NAME}}"
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

python3 << 'PYTHON_EOF'
import os
import sys
import json
import re

script_dir = os.path.dirname(os.path.abspath(sys.argv[0]))

# Load config if exists
config = {}
config_file = os.path.join(script_dir, "report_config.sh")
if os.path.isfile(config_file):
    with open(config_file) as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#') and '=' in line:
                key, val = line.split('=', 1)
                config[key] = val.strip('"').strip("'")

site_name = config.get('SITE_NAME', 'rebelwithlinux.com')
default_location = config.get('DEFAULT_LOCATION', 'Ogden, Utah')

# Determine HTML file
web_root = config.get('WEB_ROOT', f'/var/www/{site_name}')
html_file = os.path.join(web_root, 'index.html')
if not os.path.isfile(html_file):
    html_file = '/var/www/html/index.html'
if not os.path.isfile(html_file):
    html_file = os.path.join(script_dir, 'index.html')

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
    location = default_location

# Read current values from HTML and replace with new values
location_match = re.search(r'>([^<]+location[^<]*)<', content)
if location_match:
    old_location = location_match.group(1)
    content = content.replace(f'>{old_location}<', f'>{location}<', 1)

uptime_match = re.search(r'>([^<]+uptime[^<]*)<', content, re.IGNORECASE)
if uptime_match:
    old_uptime = uptime_match.group(1)
    content = content.replace(f'>{old_uptime}<', f'>{uptime}<', 1)

load_match = re.search(r'>(\d+\.\d+)<', content)
if load_match:
    old_load = load_match.group(1)
    content = content.replace(f'>{old_load}<', f'>{loadavg}<', 1)

mem_match = re.search(r'>(\d+\.?\d*[GM]i?/\d+\.?\d*[GM]i?)<', content)
if mem_match:
    old_mem = mem_match.group(1)
    content = content.replace(f'>{old_mem}<', f'>{memory}<', 1)

disk_match = re.search(r'>(\d+\.?\d*[GM]?/\d+\.?\d*[GM]?)<', content)
if disk_match:
    old_disk = disk_match.group(1)
    content = content.replace(f'>{old_disk}<', f'>{disk}<', 1)

# Update process and CPU
content = re.sub(r'>([^<]+)<br>\d+\.\d+% CPU', f'>{proc}<br>{cpu}% CPU', content)

with open(html_file, 'w') as f:
    f.write(content)
    
print("Server stats updated in Stats section")
PYTHON_EOF
