#!/bin/sh

# D-Bus daemon system bus ko start aur setup karein
mkdir -p /var/run/dbus
dbus-daemon --system --fork

# XRDP services start karein
service xrdp start
service xrdp-sesman start

# Container ko exit hone se rokne ke liye logs ko tail karein
tail -f /var/log/xrdp.log /var/log/xrdp-sesman.log
