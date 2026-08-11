#!/bin/bash
set -e

echo "======================================"
echo " Starting XRDP Container"
echo "======================================"

# --------------------------------------------------
# 1. Railway dynamic PORT
# --------------------------------------------------
if [ -n "${PORT:-}" ]; then
    echo "XRDP listening on Railway PORT: ${PORT}"

    # Replace existing port setting
    sed -i -E "s/^[[:space:]]*port=.*/port=${PORT}/" \
        /etc/xrdp/xrdp.ini
else
    echo "PORT not set, using default XRDP port 3389"
fi

# --------------------------------------------------
# 2. Prepare runtime directories
# --------------------------------------------------
mkdir -p /run/xrdp
mkdir -p /run/dbus

chown xrdp:xrdp /run/xrdp || true
chmod 755 /run/xrdp

# Remove only XRDP's own stale files
rm -f /run/xrdp/xrdp.pid
rm -f /run/xrdp/xrdp-sesman.pid

# --------------------------------------------------
# 3. Clean stale X11 sockets
# --------------------------------------------------
rm -f /tmp/.X11-unix/X*
rm -f /tmp/.X*-lock

mkdir -p /tmp/.X11-unix
chmod 1777 /tmp/.X11-unix

# --------------------------------------------------
# 4. D-Bus
# --------------------------------------------------
if command -v dbus-daemon >/dev/null 2>&1; then
    echo "Starting system D-Bus..."

    dbus-uuidgen --ensure=/var/lib/dbus/machine-id 2>/dev/null || true

    if ! pgrep -x dbus-daemon >/dev/null 2>&1; then
        dbus-daemon --system --fork
    fi
fi

# --------------------------------------------------
# 5. Start XRDP Session Manager
# --------------------------------------------------
echo "Starting XRDP Session Manager..."

xrdp-sesman --nodaemon &
SESman_PID=$!

sleep 1

# --------------------------------------------------
# 6. Start XRDP server
# --------------------------------------------------
echo "Starting XRDP Server..."

exec xrdp --nodaemon
