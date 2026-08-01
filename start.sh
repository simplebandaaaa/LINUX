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

# X11/Xorg के पुराने लॉग्स और लॉक फाइल्स साफ़ करें ताकि कोई कॉन्फ्लिक्ट न हो
rm -f /tmp/.X*lock
rm -rf /tmp/.X11-unix
mkdir -p /tmp/.X11-unix
chmod 1777 /tmp/.X11-unix

# जनरेट करें RDP कीज़
if [ ! -f /etc/xrdp/rsakeys.ini ]; then
    xrdp-keygen xrdp /etc/xrdp/rsakeys.ini
fi

# सर्विसेज चालू करें
xrdp-sesman --nodaemon &
exec xrdp --nodaemon
