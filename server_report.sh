#!/bin/bash

# Determine the correct path (works on both VPS and SSHFS)
if [ -f "/var/www/html/index.html" ]; then
    HTML_FILE="/var/www/html/index.html"
elif [ -f "/mnt/remote/var/www/html/index.html" ]; then
    HTML_FILE="/mnt/remote/var/www/html/index.html"
else
    HTML_FILE="$(pwd)/index.html"
fi

echo "Checking file: $HTML_FILE"
if [ ! -f "$HTML_FILE" ]; then
    echo "Error: $HTML_FILE not found"
    exit 1
fi
echo "File exists"

# Check if marker exists
if grep -q "<!--INCLUDE_SERVER_REPORT-->" "$HTML_FILE"; then
    echo "Marker found"
else
    echo "Marker not found, adding it..."
    sed -i '/<!--INCLUDE_OS_STATS-->/a\    <!--INCLUDE_SERVER_REPORT-->' "$HTML_FILE"
    echo "Marker added"
fi

# Test Python works
python3 << 'PYTHON_EOF'
import os
print("Python running")

# Use the same logic as bash
if os.path.isfile("/var/www/html/index.html"):
    html_file = "/var/www/html/index.html"
elif os.path.isfile("/mnt/remote/var/www/html/index.html"):
    html_file = "/mnt/remote/var/www/html/index.html"
else:
    html_file = "index.html"

with open(html_file, 'r') as f:
    content = f.read()

if '<!--INCLUDE_SERVER_REPORT-->' in content:
    print("Marker found in content")
    
    uptime = os.popen('uptime -p 2>/dev/null || echo "uptime unavailable"').read().strip()
    loadavg = os.popen("cat /proc/loadavg | awk '{print $1}'").read().strip()
    memory = os.popen("free -h | awk '/^Mem:/ {print $3 \"/\" $2}'").read().strip()
    disk = os.popen("df -h / | awk 'NR==2 {print $3 \"/\" $2}'").read().strip()
    proc = os.popen("ps aux --sort=-%cpu | head -2 | tail -1 | awk '{print $11}'").read().strip()
    cpu = os.popen("ps aux --sort=-%cpu | head -2 | tail -1 | awk '{print $3}'").read().strip()

    print(f"Stats: {uptime} | {loadavg} | {memory}")

    report = f"""<!-- Dynamic Server Report -->
    <section style="padding: 32px; text-align: center; background: var(--ivory);">
        <h3 style="font-family: 'IBM Plex Mono', monospace; font-size: 1.25rem; margin-bottom: 16px;">// Live Server Stats</h3>
        <div style="display: flex; flex-direction: column; align-items: center; gap: 8px; font-family: 'IBM Plex Mono', monospace; font-size: 0.8rem;">
            <div><strong>Location</strong><br>Amsterdam</div>
            <div><strong>Uptime</strong><br>{uptime}</div>
            <div><strong>Load</strong><br>{loadavg}</div>
            <div><strong>Memory</strong><br>{memory}</div>
            <div><strong>Disk</strong><br>{disk}</div>
            <div><strong>Top Proc</strong><br>{proc}<br>{cpu}% CPU</div>
        </div>
    </section>
    <!--INCLUDE_SERVER_REPORT-->"""

    import re
    # Replace any existing report section + marker with the new one
    pattern = r'<!-- Dynamic Server Report -->.*?<!--INCLUDE_SERVER_REPORT-->'
    new_content = re.sub(pattern, report, content, flags=re.DOTALL)
    
    # If no existing section, just replace the marker
    if new_content == content and '<!--INCLUDE_SERVER_REPORT-->' in content:
        new_content = content.replace('<!--INCLUDE_SERVER_REPORT-->', report)
    
    if new_content != content:
        with open(html_file, 'w') as f:
            f.write(new_content)
        print("File updated")
    else:
        print("Content unchanged")
else:
    print("ERROR: Marker not found in content")
PYTHON_EOF
