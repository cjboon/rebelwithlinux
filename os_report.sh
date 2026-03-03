#!/bin/bash

LOG_FILE="${1:-/var/log/apache2/rebelwithlinux.com_access.log}"
INDEX_FILE="/var/www/html/index.html"

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

TOTAL=$(awk -F'"' '{print $1, $6}' "$TMPDIR/filtered.log" | sort -u -k1,1 | awk '{
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

REPORT_HTML=$(awk -F'"' '{print $1, $6}' "$TMPDIR/filtered.log" | sort -u -k1,1 | awk '{
  ua = $0
  if (ua ~ /[Ww]indows/) print "Windows", $1
  else if (ua ~ /Mac.*OS/) print "macOS", $1
  else if (ua ~ /iPhone/) print "iOS", $1
  else if (ua ~ /iPad/) print "iPadOS", $1
  else if (ua ~ /Android/) print "Android", $1
  else if (ua ~ /[Ll]inux/ && ua !~ /Android/) print "Linux", $1
  else if (ua ~ /[Bb]ot/ || ua ~ /^ *$/) next
  else print "Other", $1
}' | sort -u -k1,1 -k2,2 | awk '
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

content = re.sub(r'\s*<!--\s*Daily OS Report\s*-->.*?<!--\s*INCLUDE_OS_STATS\s*-->', '<!--INCLUDE_OS_STATS-->', content, flags=re.DOTALL)

section_html = f'''    <!-- Daily OS Report -->
    <section id="stats" style="padding: 32px; text-align: center; background: var(--ivory); border-top: 2px solid var(--black);">
        <p style="font-family: 'IBM Plex Mono', monospace; font-size: 0.75rem; color: var(--charcoal); margin-bottom: 8px;">Last updated: {timestamp}</p>
        <h3 style="font-family: 'IBM Plex Mono', monospace; font-size: 1.25rem; margin-bottom: 16px;">{total} rebelled today.</h3>
{report_html}
    </section>
    <!--INCLUDE_OS_STATS-->'''

content = content.replace('<!--INCLUDE_OS_STATS-->', section_html)

with open(index_file, 'w') as f:
    f.write(content)
PYEOF

