#!/bin/bash

# === CONFIG ===
SITE_NAME="rebelwithlinux.com"
WEB_ROOT="/var/www/${SITE_NAME}"
LOG_FILE="${1:-/var/log/apache2/${SITE_NAME}_access.log}"
INDEX_FILE="${WEB_ROOT}/index.html"
# === END CONFIG ===

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

setup_systemd_timer() {
    local timer_name="os-report.timer"
    local service_name="os-report.service"
    
    if [ ! -f "/etc/systemd/system/$timer_name" ]; then
        echo "Setting up systemd timer..."
        
        # Create service file
        cat > "/etc/systemd/system/$service_name" << 'EOF'
[Unit]
Description=Hourly OS Report Script

[Service]
Type=oneshot
ExecStart=${SCRIPT_DIR}/os_report.sh
EOF
        
        # Create timer file
        cat > "/etc/systemd/system/$timer_name" << 'EOF'
[Unit]
Description=Hourly OS Report Timer

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

NOW=$(date +%s)
START_TIME=$((NOW - 86400))

START_DATE=$(date -d "@$START_TIME" "+%d/%b/%Y")
END_DATE=$(date -d "@$NOW" "+%d/%b/%Y")

TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

while IFS= read -r line; do
  if [[ "$line" =~ \[([0-9]+)/([A-Za-z]+)/([0-9]+):([0-9]+):([0-9]+):([0-9]+) ]]; then
    day="${BASH_REMATCH[1]}"
    mon="${BASH_REMATCH[2]}"
    year="${BASH_REMATCH[3]}"
    h="${BASH_REMATCH[4]}"
    min="${BASH_REMATCH[5]}"
    s="${BASH_REMATCH[6]}"
    ts=$(date -d "$mon $day $year $h:$min:$s" +%s 2>/dev/null)
    if [ -n "$ts" ] && [ "$ts" -ge "$START_TIME" ]; then
      echo "$line"
    fi
  fi
done < "$LOG_FILE" > "$TMPDIR/filtered.log"

TOTAL=$(gawk -F'"' '{print $1, $6}' "$TMPDIR/filtered.log" | sort -u -k1,1 | gawk '{
  ua = $0
  if (ua ~ /[Ww]indows/) print "Windows", $1
  else if (ua ~ /Mac.*OS/) print "macOS", $1
  else if (ua ~ /iPhone/) print "iOS", $1
  else if (ua ~ /iPad/) print "iPadOS", $1
  else if (ua ~ /Android/) print "Android", $1
  else if (ua ~ /[Ll]inux/ && ua !~ /Android/) print "Linux", $1
  else if (ua ~ /[Bb]ot/ || ua ~ /^ *$/) next
  else print "Other", $1
}' | sort -u -k2,2 | wc -l)

REPORT_HTML=$(gawk -F'"' '{print $1, $6}' "$TMPDIR/filtered.log" | sort -u -k1,1 | gawk '{
  ua = $0
  if (ua ~ /[Ww]indows/) print "Windows", $1
  else if (ua ~ /Mac.*OS/) print "macOS", $1
  else if (ua ~ /iPhone/) print "iOS", $1
  else if (ua ~ /iPad/) print "iPadOS", $1
  else if (ua ~ /Android/) print "Android", $1
  else if (ua ~ /[Ll]inux/ && ua !~ /Android/) print "Linux", $1
  else if (ua ~ /[Bb]ot/ || ua ~ /^ *$/) next
  else print "Other", $1
}' | sort -u -k1,1 -k2,2 | gawk '
BEGIN {
  print "        <ul style=\"list-style: none; padding: 0; margin: 0;\">"
}
{
  os = $1
  ip = $2
  if (!(os in ip_count)) {
    ips[os] = ip
    ip_count[os] = 1
  } else {
    found = 0
    split(ips[os], existing_ips, ", ")
    for (i in existing_ips) {
      if (existing_ips[i] == ip) found = 1
    }
    if (!found) {
      ip_count[os]++
      ips[os] = ips[os] ", " ip
    }
  }
}
END {
  n = asort(ip_count, sorted_count)
  for (i = n; i >= 1; i--) {
    for (os in ip_count) {
      if (ip_count[os] == sorted_count[i]) {
        print "            <li>" os ": " ip_count[os] " IPs</li>"
        delete ip_count[os]
        break
      }
    }
  }
  print "        </ul>"
}
')

TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

python3 - "$INDEX_FILE" "$TOTAL" "$REPORT_HTML" "$TIMESTAMP" << 'PYEOF'
import re
import sys

index_file = sys.argv[1]
total = sys.argv[2]
report_html = sys.argv[3]
timestamp = sys.argv[4]

with open(index_file, 'r') as f:
    content = f.read()

# Replace the OS stats section (the one with "rebelled today")
# Match from the stats section start to the Live Server Stats comment
pattern = r'(<section id="stats"[^>]*>)' + r'.*?Last updated:.*?rebelled today.*?</section>'
replacement = r'\1' + f'''
        <p style="font-family: 'IBM Plex Mono', monospace; font-size: 0.75rem; color: var(--charcoal); margin-bottom: 8px;">Last updated: {timestamp}</p>
        <h3 style="font-family: 'IBM Plex Mono', monospace; font-size: 1.25rem; margin-bottom: 16px;">{total} rebelled today.</h3>
{report_html}
    </section>'''

content = re.sub(pattern, replacement, content, flags=re.DOTALL)

with open(index_file, 'w') as f:
    f.write(content)
PYEOF

