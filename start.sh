#!/bin/bash

set -e

PORT="${PORT:-3389}"

echo "=========================================="
echo "          XFCE XRDP DESKTOP"
echo "=========================================="
echo "Username : rdpuser"
echo "Password : rdp123"
echo "Port     : ${PORT}"
echo "Theme    : Greybird Dark"
echo "Icons    : Papirus Dark"
echo "Browser  : Falkon"
echo "=========================================="

# =========================================================
# RUNTIME
# =========================================================

mkdir -p /run/xrdp
mkdir -p /run/dbus
mkdir -p /tmp/.X11-unix

chmod 1777 /tmp/.X11-unix
chown xrdp:xrdp /run/xrdp || true

# =========================================================
# CLEAN OLD FILES
# =========================================================

rm -rf /run/xrdp/*
rm -rf /tmp/.X11-unix/*
rm -rf /tmp/.X*
rm -rf /tmp/.x*

# =========================================================
# PORT
# =========================================================

if grep -q "^port=" /etc/xrdp/xrdp.ini; then
    sed -i "s/^port=.*/port=${PORT}/" /etc/xrdp/xrdp.ini
else
    echo "port=${PORT}" >> /etc/xrdp/xrdp.ini
fi

# =========================================================
# USER
# =========================================================

echo "rdpuser:rdp123" | chpasswd

mkdir -p \
    /home/rdpuser/.config \
    /home/rdpuser/.cache \
    /home/rdpuser/Desktop

chown -R rdpuser:rdpuser /home/rdpuser

# =========================================================
# SESSION FILE
# =========================================================

cat > /home/rdpuser/.xsession <<'EOF'
#!/bin/sh

unset DBUS_SESSION_BUS_ADDRESS
unset XDG_RUNTIME_DIR

export HOME=/home/rdpuser
export USER=rdpuser
export LOGNAME=rdpuser

export XDG_CURRENT_DESKTOP=XFCE
export XDG_SESSION_DESKTOP=xfce

exec startxfce4
EOF

chmod +x /home/rdpuser/.xsession
chown rdpuser:rdpuser /home/rdpuser/.xsession

# =========================================================
# VERIFY
# =========================================================

echo ""
echo "Checking components..."

command -v startxfce4
command -v xfce4-session
command -v xrdp
command -v xrdp-sesman
command -v falkon
command -v thunar

echo ""

# =========================================================
# DBUS SYSTEM SERVICE
# =========================================================

if [ ! -S /run/dbus/system_bus_socket ]; then
    dbus-daemon --system --fork || true
fi

# =========================================================
# XRDP SESSION MANAGER
# =========================================================

echo "Starting xrdp-sesman..."

/usr/sbin/xrdp-sesman --nodaemon &

sleep 2

# =========================================================
# XRDP
# =========================================================

echo "Starting XRDP on port ${PORT}..."

exec /usr/sbin/xrdp --nodaemon
