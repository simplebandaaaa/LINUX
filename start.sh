#!/bin/bash

set -e

# =========================================================
# ENVIRONMENT
# =========================================================

export HOME=/root
export USER=root
export LOGNAME=root

export XDG_CURRENT_DESKTOP=XFCE
export XDG_SESSION_DESKTOP=xfce
export XDG_CONFIG_HOME=/root/.config
export XDG_CACHE_HOME=/root/.cache

PORT="${PORT:-3389}"

echo "=========================================="
echo "          MODERN XFCE RDP"
echo "=========================================="
echo "User     : root"
echo "Port     : ${PORT}"
echo "Desktop  : XFCE"
echo "Theme    : Greybird Dark"
echo "Icons    : Papirus Dark"
echo "Dock     : Plank"
echo "Browser  : Falkon"
echo "=========================================="

# =========================================================
# CLEAN OLD RUNTIME FILES
# =========================================================

rm -rf /tmp/.X11-unix/*
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

    sed -i \
        "s/^port=.*/port=${PORT}/" \
        /etc/xrdp/xrdp.ini

else

    sed -i \
        "1i port=${PORT}" \
        /etc/xrdp/xrdp.ini

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
# MAKE DESKTOP FILES EXECUTABLE
# =========================================================

chmod +x /root/Desktop/*.desktop 2>/dev/null || true

# =========================================================
# CHECK IMPORTANT PROGRAMS
# =========================================================

echo ""
echo "Checking installation..."

command -v xfce4-session || true
command -v startxfce4 || true
command -v falkon || true
command -v plank || true
command -v thunar || true
command -v xrdp || true

echo ""

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
