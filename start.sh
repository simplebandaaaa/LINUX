#!/bin/bash

set -u

echo "========================================"
echo " Railway XRDP + XFCE"
echo "========================================"

# Railway provides PORT automatically.
# 3389 is used only when running locally.
PORT="${PORT:-3389}"

if ! [[ "$PORT" =~ ^[0-9]+$ ]] || \
   [ "$PORT" -lt 1 ] || \
   [ "$PORT" -gt 65535 ]; then

    echo "ERROR: Invalid PORT: $PORT"
    exit 1
fi

echo "XRDP PORT: $PORT"

# ========================================
# Runtime directories
# ========================================

mkdir -p /run/xrdp
mkdir -p /run/dbus
mkdir -p /var/run/xrdp
mkdir -p /var/run/dbus

chmod 755 /run/xrdp
chmod 755 /run/dbus
chmod 755 /var/run/xrdp
chmod 755 /var/run/dbus

# ========================================
# Clean stale X11 state
# ========================================

rm -rf /tmp/.X11-unix

mkdir -p /tmp/.X11-unix

chmod 1777 /tmp/.X11-unix
chmod 1777 /tmp

# ========================================
# Remove stale XRDP PID/socket files
# ========================================

rm -f /run/xrdp/*.pid 2>/dev/null || true
rm -f /var/run/xrdp/*.pid 2>/dev/null || true

rm -f /run/xrdp/*.sock 2>/dev/null || true
rm -f /var/run/xrdp/*.sock 2>/dev/null || true

# ========================================
# Configure XRDP for Railway PORT
# ========================================

echo "Configuring XRDP for port $PORT"

if grep -qE '^[[:space:]]*port=' /etc/xrdp/xrdp.ini; then

    sed -i -E \
        "s/^[[:space:]]*port=.*/port=${PORT}/" \
        /etc/xrdp/xrdp.ini

else

    sed -i \
        "/^\[Globals\]/a port=${PORT}" \
        /etc/xrdp/xrdp.ini

fi

# ========================================
# RDP password
# ========================================

RDP_PASSWORD="${RDP_PASSWORD:-rdp123}"

echo "rdpuser:${RDP_PASSWORD}" | chpasswd

# ========================================
# Clean user session state
# ========================================

rm -f /home/rdpuser/.Xauthority
rm -f /home/rdpuser/.ICEauthority
rm -f /home/rdpuser/.xsession-errors

chown -R rdpuser:rdpuser /home/rdpuser

# ========================================
# XDG runtime directory
# ========================================

UID_RDP="$(id -u rdpuser)"
GID_RDP="$(id -g rdpuser)"

mkdir -p "/run/user/${UID_RDP}"

chown "${UID_RDP}:${GID_RDP}" \
    "/run/user/${UID_RDP}"

chmod 700 "/run/user/${UID_RDP}"

# ========================================
# Start system DBus
# ========================================

echo "Starting DBus..."

if ! pgrep -x dbus-daemon >/dev/null 2>&1; then

    dbus-daemon \
        --system \
        --fork \
        >/tmp/dbus-start.log 2>&1 || true

fi

# ========================================
# Check required programs
# ========================================

echo "Checking XFCE..."

command -v startxfce4
command -v xfce4-session
command -v dbus-launch
command -v Xorg

echo "XFCE/Xorg checks passed."

# ========================================
# Start XRDP Session Manager
# ========================================

echo "Starting xrdp-sesman..."

/usr/sbin/xrdp-sesman \
    --nodaemon \
    >/tmp/xrdp-sesman.log 2>&1 &

SESMAN_PID=$!

sleep 2

if ! kill -0 "$SESMAN_PID" 2>/dev/null; then

    echo "ERROR: xrdp-sesman failed."

    echo "========== SESMAN LOG =========="

    cat /tmp/xrdp-sesman.log 2>/dev/null || true

    echo "================================"

    exit 1
fi

echo "xrdp-sesman started."
echo "PID: $SESMAN_PID"

# ========================================
# Start XRDP
# ========================================

echo "Starting XRDP..."

/usr/sbin/xrdp \
    --nodaemon \
    >/tmp/xrdp.log 2>&1 &

XRDP_PID=$!

sleep 2

if ! kill -0 "$XRDP_PID" 2>/dev/null; then

    echo "ERROR: XRDP failed."

    echo "========== XRDP LOG =========="

    cat /tmp/xrdp.log 2>/dev/null || true

    echo "========== SESMAN LOG =========="

    cat /tmp/xrdp-sesman.log 2>/dev/null || true

    echo "================================"

    exit 1
fi

# ========================================
# Ready
# ========================================

echo ""
echo "========================================"
echo "          XRDP IS READY"
echo "========================================"
echo "PORT     : $PORT"
echo "USERNAME : rdpuser"

if [ -n "${RDP_PASSWORD:-}" ]; then
    echo "PASSWORD : Railway RDP_PASSWORD"
else
    echo "PASSWORD : rdp123"
fi

echo "========================================"
echo ""

# ========================================
# Keep container alive
# ========================================

while true; do

    if ! kill -0 "$SESMAN_PID" 2>/dev/null; then

        echo "ERROR: xrdp-sesman stopped."

        echo "========== SESMAN LOG =========="

        cat /tmp/xrdp-sesman.log 2>/dev/null || true

        exit 1
    fi

    if ! kill -0 "$XRDP_PID" 2>/dev/null; then

        echo "ERROR: XRDP stopped."

        echo "========== XRDP LOG =========="

        cat /tmp/xrdp.log 2>/dev/null || true

        exit 1
    fi

    sleep 5

done
