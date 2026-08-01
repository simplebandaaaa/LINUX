#!/bin/bash
set -e

# 1. Railway Dynamic Port Assignment
if [ -n "$PORT" ]; then
    echo "Configuring XRDP to listen on Railway allocated port: $PORT"
    sed -i "s/port=3389/port=$PORT/g" /etc/xrdp/xrdp.ini
fi

# 2. पुरानी क्रैश लॉक्स और X11 सॉकेट्स को साफ़ करना
rm -rf /tmp/.X* /tmp/.x* /var/run/xrdp/*
mkdir -p /var/run/xrdp
chown xrdp:xrdp /var/run/xrdp

# 3. System D-Bus को बैकग्राउंड में शुरू करना
mkdir -p /var/run/dbus
rm -f /var/run/dbus/pid
dbus-uuidgen --ensure
dbus-daemon --system --fork

# 4. XRDP सर्विसेस को लॉन्च करना
echo "Starting XRDP Session Manager..."
xrdp-sesman --config /etc/xrdp/sesman.ini

echo "Starting XRDP Server in Foreground..."
exec xrdp --nodaemon
