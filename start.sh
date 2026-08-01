#!/bin/bash

# D-Bus को स्टार्ट करें
if [ ! -d /var/run/dbus ]; then
    mkdir -p /var/run/dbus
fi
dbus-daemon --system --fork

# XRDP के लिए डायरेक्टरीज़ और परमिशन सेट करें
mkdir -p /var/run/xrdp
mkdir -p /var/run/xrdp/sockdir
chown -R xrdp:xrdp /var/run/xrdp

# जनरेट करें RDP कीज़ (अगर पहले से मौजूद नहीं हैं)
if [ ! -f /etc/xrdp/rsakeys.ini ]; then
    xrdp-keygen xrdp /etc/xrdp/rsakeys.ini
fi

# सर्विसेज चालू करें
xrdp-sesman --nodaemon &
exec xrdp --nodaemon
