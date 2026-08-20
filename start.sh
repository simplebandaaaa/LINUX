#!/bin/bash
set -e

echo "======================================"
echo " Starting XFCE + XRDP"
echo " Railway PORT: ${PORT:-3389}"
echo "======================================"

# Railway assigns the external/internal application port.
XRDP_PORT="${PORT:-3389}"

# Configure XRDP to listen on Railway's PORT
sed -i "s/^port=.*/port=${XRDP_PORT}/" /etc/xrdp/xrdp.ini

# Make sure XRDP directories exist
mkdir -p /run/xrdp
mkdir -p /var/run/xrdp

chown xrdp:xrdp /run/xrdp /var/run/xrdp

# Remove stale sockets / PID files
rm -f /run/xrdp/xrdp.pid
rm -f /run/xrdp/xrdp-sesman.pid
rm -f /var/run/xrdp/xrdp.pid
rm -f /var/run/xrdp/xrdp-sesman.pid

rm -rf /tmp/.X11-unix
rm -rf /tmp/.X*-lock

mkdir -p /tmp/.X11-unix
chmod 1777 /tmp/.X11-unix

# Ensure ubuntu owns its home
chown -R ubuntu:ubuntu /home/ubuntu

# Start DBus system bus
if [ ! -e /run/dbus/system_bus_socket ]; then
    mkdir -p /run/dbus
    dbus-daemon --system --fork
fi

echo "Starting XRDP on port ${XRDP_PORT}..."

# Start XRDP
/usr/sbin/xrdp-sesman

exec /usr/sbin/xrdp --nodaemon
