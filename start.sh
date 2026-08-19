#!/bin/bash

set -e

export HOME=/root
export USER=root
export LOGNAME=root

PORT="${PORT:-3389}"

echo "=========================================="
echo "        XFCE XRDP STARTING"
echo "=========================================="
echo "User: root"
echo "Port: ${PORT}"
echo "=========================================="

# ---------------------------------------------------------
# Runtime directories
# ---------------------------------------------------------

mkdir -p /run/xrdp
mkdir -p /run/dbus
mkdir -p /tmp/.X11-unix

chmod 1777 /tmp/.X11-unix

chown xrdp:xrdp /run/xrdp 2>/dev/null || true

# ---------------------------------------------------------
# Clean previous sessions
# ---------------------------------------------------------

rm -rf /tmp/.X11-unix/*
rm -rf /tmp/.X*
rm -rf /tmp/.x*

rm -rf /run/xrdp/*
rm -f /run/dbus/pid

# ---------------------------------------------------------
# Railway / PORT support
# ---------------------------------------------------------

if grep -q "^port=" /etc/xrdp/xrdp.ini; then
    sed -i "s/^port=.*/port=${PORT}/" /etc/xrdp/xrdp.ini
else
    echo "port=${PORT}" >> /etc/xrdp/xrdp.ini
fi

# ---------------------------------------------------------
# Root password
# ---------------------------------------------------------

echo "root:root" | chpasswd

# ---------------------------------------------------------
# XRDP startwm.sh
# ---------------------------------------------------------

cat > /etc/xrdp/startwm.sh <<'EOF'
#!/bin/sh

unset DBUS_SESSION_BUS_ADDRESS
unset XDG_RUNTIME_DIR

export HOME=/root
export USER=root
export LOGNAME=root

export XDG_CURRENT_DESKTOP=XFCE
export XDG_SESSION_DESKTOP=xfce

if test -r /etc/profile; then
    . /etc/profile
fi

if test -r /etc/default/locale; then
    . /etc/default/locale
    export LANG
    export LANGUAGE
    export LC_ALL
fi

mkdir -p /root/.config
mkdir -p /root/.cache

exec dbus-run-session -- startxfce4
EOF

chmod +x /etc/xrdp/startwm.sh

# ---------------------------------------------------------
# User .xsession
# ---------------------------------------------------------

cat > /root/.xsession <<'EOF'
#!/bin/sh

unset DBUS_SESSION_BUS_ADDRESS
unset XDG_RUNTIME_DIR

export HOME=/root
export USER=root
export LOGNAME=root

export XDG_CURRENT_DESKTOP=XFCE
export XDG_SESSION_DESKTOP=xfce

exec dbus-run-session -- startxfce4
EOF

chmod +x /root/.xsession

# ---------------------------------------------------------
# XFCE theme
# ---------------------------------------------------------

mkdir -p \
    /root/.config/xfce4/xfconf/xfce-perchannel-xml

if command -v xfconf-query >/dev/null 2>&1; then

    xfconf-query \
        -c xsettings \
        -p /Net/ThemeName \
        -n \
        -t string \
        -s "Greybird-dark" \
        2>/dev/null || true

    xfconf-query \
        -c xsettings \
        -p /Net/IconThemeName \
        -n \
        -t string \
        -s "Papirus-Dark" \
        2>/dev/null || true

    xfconf-query \
        -c xfwm4 \
        -p /general/use_compositing \
        -n \
        -t bool \
        -s false \
        2>/dev/null || true

fi

# ---------------------------------------------------------
# Desktop permissions
# ---------------------------------------------------------

chmod +x /root/Desktop/*.desktop 2>/dev/null || true

# ---------------------------------------------------------
# Show useful diagnostics
# ---------------------------------------------------------

echo ""
echo "Installed programs:"
command -v startxfce4 || true
command -v xfce4-session || true
command -v falkon || true
command -v plank || true
command -v xrdp || true
echo ""

# ---------------------------------------------------------
# Start DBus system daemon if available
# ---------------------------------------------------------

if command -v dbus-daemon >/dev/null 2>&1; then

    if [ ! -S /run/dbus/system_bus_socket ]; then
        dbus-daemon --system --fork || true
    fi

fi

# ---------------------------------------------------------
# Start xrdp-sesman
# ---------------------------------------------------------

echo "Starting xrdp-sesman..."

rm -f /run/xrdp/sesman.pid 2>/dev/null || true

/usr/sbin/xrdp-sesman --nodaemon &

sleep 2

# ---------------------------------------------------------
# Start XRDP
# ---------------------------------------------------------

echo "Starting xrdp on port ${PORT}..."

exec /usr/sbin/xrdp --nodaemon
