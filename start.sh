#!/bin/bash

set -e

echo "======================================"
echo " XFCE + XRDP"
echo " Railway PORT: ${PORT:-3389}"
echo "======================================"

# Railway provides PORT dynamically
XRDP_PORT="${PORT:-3389}"

# --------------------------------------------------
# Configure XRDP port
# --------------------------------------------------
sed -i "s/^port=.*/port=${XRDP_PORT}/" /etc/xrdp/xrdp.ini

# --------------------------------------------------
# Prepare XRDP directories
# --------------------------------------------------
mkdir -p /run/xrdp
mkdir -p /var/run/xrdp

chown xrdp:xrdp /run/xrdp
chown xrdp:xrdp /var/run/xrdp

# --------------------------------------------------
# Remove stale files
# --------------------------------------------------
rm -f /run/xrdp/xrdp.pid
rm -f /run/xrdp/xrdp-sesman.pid
rm -f /var/run/xrdp/xrdp.pid
rm -f /var/run/xrdp/xrdp-sesman.pid

rm -rf /tmp/.X11-unix
rm -rf /tmp/.X*-lock

mkdir -p /tmp/.X11-unix
chmod 1777 /tmp/.X11-unix

# --------------------------------------------------
# Fix ownership
# --------------------------------------------------
chown -R ubuntu:ubuntu /home/ubuntu

# --------------------------------------------------
# Start DBus
# --------------------------------------------------
mkdir -p /run/dbus

if [ ! -e /run/dbus/system_bus_socket ]; then
    dbus-daemon --system --fork
fi

# --------------------------------------------------
# Start XRDP session manager
# --------------------------------------------------
echo "Starting xrdp-sesman..."

/usr/sbin/xrdp-sesman

# --------------------------------------------------
# Start XRDP in foreground
# --------------------------------------------------
echo "Starting XRDP on port ${XRDP_PORT}..."

exec /usr/sbin/xrdp --nodaemon
