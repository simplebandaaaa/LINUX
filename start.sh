#!/bin/bash

set -e

echo "======================================"
echo " Starting Ubuntu XFCE + XRDP"
echo "======================================"

# ==================================================
# 1. Railway dynamic port
# ==================================================

XRDP_PORT="${PORT:-3389}"

echo "XRDP port: ${XRDP_PORT}"

# Replace existing XRDP port
sed -i -E \
    "s/^[[:space:]]*port=.*/port=${XRDP_PORT}/" \
    /etc/xrdp/xrdp.ini

# ==================================================
# 2. Runtime directories
# ==================================================

mkdir -p /run/xrdp
mkdir -p /run/dbus

chown xrdp:xrdp /run/xrdp || true
chmod 755 /run/xrdp

rm -f /run/xrdp/xrdp.pid
rm -f /run/xrdp/xrdp-sesman.pid

# ==================================================
# 3. X11 sockets
# ==================================================

mkdir -p /tmp/.X11-unix

chmod 1777 /tmp/.X11-unix

rm -f /tmp/.X11-unix/X*
rm -f /tmp/.X*-lock

# ==================================================
# 4. DBus
# ==================================================

echo "Starting DBus..."

if command -v dbus-uuidgen >/dev/null 2>&1; then
    dbus-uuidgen --ensure=/var/lib/dbus/machine-id || true
fi

if ! pgrep -x dbus-daemon >/dev/null 2>&1; then
    dbus-daemon --system --fork || true
fi

# ==================================================
# 5. Check XRDP configuration
# ==================================================

echo "Checking XRDP configuration..."

xrdp -v

echo "XRDP configuration:"
grep -E '^[[:space:]]*(port|security_layer|crypt_level|max_bpp)=' \
    /etc/xrdp/xrdp.ini || true

# ==================================================
# 6. Start XRDP Session Manager
# ==================================================

echo "Starting XRDP Session Manager..."

xrdp-sesman --nodaemon &

SESman_PID=$!

sleep 2

# ==================================================
# 7. Start XRDP
# ==================================================

echo "Starting XRDP Server on port ${XRDP_PORT}..."

exec xrdp --nodaemon
