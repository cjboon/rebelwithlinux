#!/bin/bash

# === CONFIG ===
SITE_NAME="rebelwithlinux.com"
WEB_ROOT="/var/www/${SITE_NAME}"
LOG_FILE="${1:-/var/log/apache2/${SITE_NAME}_access.log}"
INDEX_FILE="${WEB_ROOT}/html/stats.html"
# === END CONFIG ===

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

setup_systemd_timer() {
    local timer_name="os-report.timer"
    local service_name="os-report.service"
    
    if [ ! -f "/etc/systemd/system/$timer_name" ]; then
        echo "Setting up systemd timer..."
        
        # Create service file
        cat > "/etc/systemd/system/$service_name" << EOF
[Unit]
Description=Hourly OS Report Script

[Service]
Type=oneshot
ExecStart=${SCRIPT_DIR}/os_report.sh

[Install]
WantedBy=multi-user.target
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

TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

# Process log and keep only last 24 hours in one gawk command
gawk -v start_time="$START_TIME" '
BEGIN {
    # Month name to number mapping (with leading zeros for sprintf)
    months["Jan"]="01"; months["Feb"]="02"; months["Mar"]="03"; months["Apr"]="04"
    months["May"]="05"; months["Jun"]="06"; months["Jul"]="07"; months["Aug"]="08"
    months["Sep"]="09"; months["Oct"]="10"; months["Nov"]="11"; months["Dec"]="12"
}
{
    # Parse Apache combined log format
    if (match($0, /\[([0-9]+)\/([A-Za-z]+)\/([0-9]+):([0-9]+):([0-9]+):([0-9]+)/, arr)) {
        ts = mktime(sprintf("%04d %02d %02d %02d %02d %02d", arr[3], months[arr[2]], arr[1], arr[4], arr[5], arr[6]))
        
        if (ts >= start_time) {
            print
        }
    }
}
' "$LOG_FILE" > "$TMPDIR/filtered.log"

# Replace log file with filtered data (keeps only last 24 hours)
if [ -s "$TMPDIR/filtered.log" ]; then
    cat "$TMPDIR/filtered.log" > "$LOG_FILE"
    echo "$(date): Retained $(wc -l < "$TMPDIR/filtered.log") log entries from last 24 hours"
else
    : > "$LOG_FILE"
    echo "$(date): No log entries in last 24 hours, log cleared"
fi

# Process OS stats
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

# Process top pages
TOP_PAGES=$(gawk -F'"' '
{
    # Extract the request path from field 2 (split by ")
    if (match($2, /^(GET|POST|PUT|DELETE)\s+(\S+)/, arr)) {
        path = arr[2]
        # Skip common non-page requests
        if (path ~ /\.(css|js|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot|webp)(\?|$)/) next
        if (path ~ /(phpmyadmin|server-status|\.env)/) next
        # Skip empty or root
        if (path == "" || path == "/") next
        pages[path]++
    }
}
END {
    # Sort by count descending
    n = 0
    for (p in pages) {
        counts[++n] = pages[p]
        paths[n] = p
    }
    # Bubble sort
    for (i = 1; i <= n; i++) {
        for (j = i + 1; j <= n; j++) {
            if (counts[j] > counts[i]) {
                tmp = counts[i]; counts[i] = counts[j]; counts[j] = tmp
                tmp = paths[i]; paths[i] = paths[j]; paths[j] = tmp
            }
        }
    }
    # Output top 5
    if (n > 5) n = 5
    for (i = 1; i <= n; i++) {
        # Strip directory prefix - keep only filename
        n_parts = split(paths[i], parts, "/")
        display_path = parts[n_parts]
        # Truncate long filenames
        if (length(display_path) > 50) {
            display_path = substr(display_path, 1, 47) "..."
        }
        # Format number with commas
        fmt_count = counts[i]
        printf "                <div style=\"margin-bottom: 8px;\">%s - <strong>%d</strong> views</div>\n", display_path, fmt_count
    }
}
' "$TMPDIR/filtered.log")

# If no pages found, show placeholder
if [ -z "$TOP_PAGES" ]; then
    TOP_PAGES="                <div style=\"margin-bottom: 8px;\">No data available</div>"
fi

TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

python3 - "$INDEX_FILE" "$TOTAL" "$REPORT_HTML" "$TOP_PAGES" "$TIMESTAMP" << 'PYEOF'
import re
import sys

index_file = sys.argv[1]
total = sys.argv[2]
report_html = sys.argv[3]
top_pages = sys.argv[4]
timestamp = sys.argv[5]

with open(index_file, 'r') as f:
    content = f.read()

# Extract Live Server Stats section if it exists (to preserve it)
live_server_stats = ''
if '<!-- Live Server Stats -->' in content:
    match = re.search(r'(<!-- Live Server Stats -->.*?)(?=<!--|$)', content, re.DOTALL)
    if match:
        live_server_stats = match.group(1)

# Replace the OS stats section (the one with "rebelled today")
# Match from the stats section start to just before Live Server Stats (or end of section)
pattern = r'(<section id="stats"[^>]*>.*?)<!-- Live Server Stats -->'
replacement = r'\1'
content = re.sub(pattern, replacement, content, flags=re.DOTALL)

# Now replace the OS stats part
pattern2 = r'(<section id="stats"[^>]*>)' + r'.*?rebelled today.*?</ul>'
replacement2 = r'\1' + f'''
        <p style="font-family: 'IBM Plex Mono', monospace; font-size: 0.75rem; color: var(--charcoal); margin-bottom: 8px;">Last updated: {timestamp}</p>
        <h3 style="font-family: 'IBM Plex Mono', monospace; font-size: 1.25rem; margin-bottom: 16px;">{total} rebelled today.</h3>
{report_html}'''
content = re.sub(pattern2, replacement2, content, flags=re.DOTALL)

# Replace top pages section - use tmpl markers around just the content
inner_start = '<!-- tp_content_start -->'
inner_end = '<!-- tp_content_end -->'
if inner_start in content and inner_end in content:
    s = content.find(inner_start)
    e = content.find(inner_end) + len(inner_end)
    content = content[:s] + top_pages + content[e:]
else:
    # Fallback: replace entire top-pages-list div content
    start_marker = '<!-- Top Pages --><!-- tmpl_start -->'
    end_marker = '<!-- tmpl_end -->'
    s = content.find(start_marker)
    e = content.find(end_marker) + len(end_marker)
    if s != -1 and e != -1:
        new_section = f'{top_pages}\n            '
        content = content[:s] + start_marker + '\n        <div style="margin-top: 32px; padding-top: 24px;">\n            <h3 style="font-family: \'IBM Plex Mono\', monospace; font-size: 1.25rem; margin-bottom: 16px;">// PAGE VIEWS</h3>\n            <div id="top-pages-list" style="font-family: \'IBM Plex Mono\', monospace; font-size: 0.9rem; max-width: 400px; margin: 0 auto;">\n                ' + new_section + '</div>\n        </div>' + end_marker + content[e:]

# Re-insert Live Server Stats if it existed
if live_server_stats:
    content = content.replace('</ul>\n    </section>', f'</ul>\n    {live_server_stats}\n    </section>')

with open(index_file, 'w') as f:
    f.write(content)
PYEOF
