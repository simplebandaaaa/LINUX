#!/bin/bash

set -e

export HOME=/root
export USER=root
export LOGNAME=root

export XDG_CURRENT_DESKTOP=XFCE
export XDG_SESSION_DESKTOP=xfce
export XDG_CONFIG_HOME=/root/.config
export XDG_CACHE_HOME=/root/.cache

PORT="${PORT:-3389}"

echo "=========================================="
echo "        MODERN XFCE RDP"
echo "=========================================="
echo "User : root"
echo "Port : ${PORT}"
echo "Theme: Greybird Dark"
echo "Icons: Papirus Dark"
echo "Dock : Plank"
echo "=========================================="

# =========================================================
# CLEAN OLD FILES
# =========================================================

rm -rf /tmp/.X*
rm -rf /tmp/.x*
rm -rf /var/run/xrdp/*

mkdir -p /tmp/.X11-unix
mkdir -p /var/run/xrdp
mkdir -p /var/run/dbus

chmod 1777 /tmp/.X11-unix

chown xrdp:xrdp /var/run/xrdp || true

# =========================================================
# XRDP PORT
# =========================================================

if grep -q "^port=" /etc/xrdp/xrdp.ini; then
    sed -i "s/^port=.*/port=${PORT}/" /etc/xrdp/xrdp.ini
else
    sed -i "1i port=${PORT}" /etc/xrdp/xrdp.ini
fi

# =========================================================
# ROOT PASSWORD
# =========================================================

echo "root:root" | chpasswd

# =========================================================
# XFCE SESSION
# =========================================================

cat > /root/.xsession <<'EOF'
#!/bin/sh

export HOME=/root
export USER=root
export LOGNAME=root

export XDG_CURRENT_DESKTOP=XFCE
export XDG_SESSION_DESKTOP=xfce
export XDG_CONFIG_HOME=/root/.config
export XDG_CACHE_HOME=/root/.cache

unset DBUS_SESSION_BUS_ADDRESS
unset XDG_RUNTIME_DIR

mkdir -p /root/.config
mkdir -p /root/.cache

exec dbus-run-session -- startxfce4
EOF

chmod +x /root/.xsession

# =========================================================
# DESKTOP PERMISSIONS
# =========================================================

chmod +x /root/Desktop/*.desktop 2>/dev/null || true

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
