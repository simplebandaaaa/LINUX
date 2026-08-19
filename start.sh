#!/bin/bash

set -e

PORT="${PORT:-3389}"

echo "=========================================="
echo "          XFCE XRDP DESKTOP"
echo "=========================================="
echo "User   : rdpuser"
echo "Pass   : rdp123"
echo "Port   : ${PORT}"
echo "Theme  : Greybird Dark"
echo "Icons  : Papirus Dark"
echo "Dock   : Plank"
echo "Browser: Falkon"
echo "=========================================="

# =========================================================
# RUNTIME DIRECTORIES
# =========================================================

mkdir -p \
    /run/xrdp \
    /run/dbus \
    /tmp/.X11-unix

chmod 1777 /tmp/.X11-unix

chown xrdp:xrdp /run/xrdp || true

# =========================================================
# CLEAN OLD SESSION FILES
# =========================================================

rm -rf /tmp/.X11-unix/*
rm -rf /tmp/.X*
rm -rf /tmp/.x*
rm -rf /run/xrdp/*

# =========================================================
# XRDP PORT
# =========================================================

if grep -q "^port=" /etc/xrdp/xrdp.ini; then
    sed -i "s/^port=.*/port=${PORT}/" /etc/xrdp/xrdp.ini
else
    echo "port=${PORT}" >> /etc/xrdp/xrdp.ini
fi

# =========================================================
# RDP USER
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
export XDG_CONFIG_HOME=/home/rdpuser/.config
export XDG_CACHE_HOME=/home/rdpuser/.cache

exec dbus-run-session -- startxfce4
EOF

chmod +x /home/rdpuser/.xsession

chown rdpuser:rdpuser /home/rdpuser/.xsession

# =========================================================
# START SYSTEM DBUS
# =========================================================

if command -v dbus-daemon >/dev/null 2>&1; then

    if [ ! -S /run/dbus/system_bus_socket ]; then
        dbus-daemon --system --fork || true
    fi

fi

# =========================================================
# START XRDP SESSION MANAGER
# =========================================================

echo "Starting xrdp-sesman..."

/usr/sbin/xrdp-sesman --nodaemon &

sleep 2

# =========================================================
# START XRDP
# =========================================================

echo "Starting XRDP on port ${PORT}..."

exec /usr/sbin/xrdp --nodaemon
