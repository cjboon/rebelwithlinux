#!/bin/bash

# Determine the correct path (works on both VPS and SSHFS)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "/var/www/rebelwithlinux.com/index.html" ]; then
    HTML_FILE="/var/www/rebelwithlinux.com/index.html"
elif [ -f "/var/www/html/index.html" ]; then
    HTML_FILE="/var/www/html/index.html"
elif [ -f "/mnt/remote/var/www/html/index.html" ]; then
    HTML_FILE="/mnt/remote/var/www/html/index.html"
else
    HTML_FILE="$SCRIPT_DIR/index.html"
fi

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
ExecStart=/var/www/rebelwithlinux.com/server_report.sh
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

# Use the same logic as bash
if os.path.isfile("/var/www/rebelwithlinux.com/index.html"):
    html_file = "/var/www/rebelwithlinux.com/index.html"
elif os.path.isfile("/var/www/html/index.html"):
    html_file = "/var/www/html/index.html"
elif os.path.isfile("/mnt/remote/var/www/html/index.html"):
    html_file = "/mnt/remote/var/www/html/index.html"
else:
    html_file = os.path.join(script_dir, "index.html")

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
    location = "Unknown"

# Update the stats inside the #stats section using simpler replacements
content = content.replace('>Ogden, Utah<', f'>{location}<')
content = content.replace('>up 14 hours, 44 minutes<', f'>{uptime}<')
content = content.replace('>0.52<', f'>{loadavg}<')
content = content.replace('>1.5Gi/1.9Gi<', f'>{memory}<')
content = content.replace('>5.9G/59G<', f'>{disk}<')
content = content.replace('/root/.opencode/bin/opencode<br>21.2% CPU', f'{proc}<br>{cpu}% CPU')

with open(html_file, 'w') as f:
    f.write(content)
    
print("Server stats updated in Stats section")
PYTHON_EOF
