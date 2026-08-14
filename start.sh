#!/bin/bash
set -e

export HOME=/root
export USER=root

echo "================================="
echo " ROOT XFCE + XRDP"
echo "================================="
echo "User: root"
echo "Port: ${PORT:-3389}"
echo "================================="

# Runtime directories
mkdir -p /run/xrdp
mkdir -p /var/run/xrdp
mkdir -p /var/run/dbus

# Clean stale X/ XRDP files
rm -rf /tmp/.X11-unix/* 2>/dev/null || true
rm -f /tmp/.X*-lock 2>/dev/null || true
rm -f /var/run/xrdp/*.pid 2>/dev/null || true

# Railway / Render / container platforms
# Use their assigned PORT when available
if [ -n "${PORT:-}" ] && [ "$PORT" != "3389" ]; then
    sed -i "s/^port=.*/port=${PORT}/" /etc/xrdp/xrdp.ini
fi

# Start system DBus
if command -v dbus-daemon >/dev/null 2>&1; then
    dbus-daemon --system --fork 2>/dev/null || true
fi

# Make sure XRDP runtime directory exists
chown xrdp:xrdp /var/run/xrdp 2>/dev/null || true
chmod 755 /var/run/xrdp

# Start XRDP session manager
echo "[+] Starting xrdp-sesman..."
/usr/sbin/xrdp-sesman &

sleep 2

echo "[+] Starting XRDP..."
echo "[+] XRDP is ready."

# Keep XRDP in foreground
exec /usr/sbin/xrdp --nodaemon
