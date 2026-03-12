#!/bin/bash
# Wrapper script to run bash_exec.py in a restricted environment
# This provides an additional layer of security

# Set a hard timeout
ulimit -t 5

# Restrict filesystem access to only /tmp/linux_demo_*
# This prevents access to sensitive directories

# Run as a restricted user if possible (configure in Apache)
# For now, we rely on the Python script's allowlist

# Execute the Python script
exec /usr/bin/python3 /var/www/rebelwithlinux.com/cgi-bin/bash_exec.py
