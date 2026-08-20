#!/bin/bash
set -e

# Create runtime directory for D-Bus to prevent XFCE login session crashes
mkdir -p /run/user/1000
chown -R ubuntu:ubuntu /run/user/1000
chmod 700 /run/user/1000

# Fix permissions on Ubuntu home directory
chown -R ubuntu:ubuntu /home/ubuntu

# Start essential system services
service dbus start

# Clear old XRDP lock files if container restarted
rm -f /var/run/xrdp/xrdp*.pid
rm -f /var/run/xrdp/xrdp-sesman.pid

# Start XRDP daemon
service xrdp start

# Keep container running and output logs
tail -f /var/log/xrdp.log
