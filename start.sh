#!/bin/bash

set -e

XRDP_PORT="${PORT:-3389}"

echo "======================================"
echo " Starting XFCE + XRDP"
echo " XRDP PORT: ${XRDP_PORT}"
echo "======================================"

# Railway PORT -> XRDP port
sed -i "s/^port=.*/port=${XRDP_PORT}/" /etc/xrdp/xrdp.ini

# Runtime directories
mkdir -p /run/xrdp
mkdir -p /var/run/xrdp
mkdir -p /run/dbus

chown xrdp:xrdp /run/xrdp
chown xrdp:xrdp /var/run/xrdp

# Remove stale files
rm -f /run/xrdp/*.pid
rm -f /var/run/xrdp/*.pid

rm -rf /tmp/.X11-unix
rm -rf /tmp/.X*-lock

mkdir -p /tmp/.X11-unix
chmod 1777 /tmp/.X11-unix

# Home permissions
chown -R ubuntu:ubuntu /home/ubuntu

# Start DBus
if [ ! -e /run/dbus/system_bus_socket ]; then
    dbus-daemon --system --fork
fi

echo "Starting xrdp-sesman..."
/usr/sbin/xrdp-sesman

echo "Starting XRDP on port ${XRDP_PORT}..."

exec /usr/sbin/xrdp --nodaemon
