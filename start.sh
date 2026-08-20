#!/bin/sh

# D-Bus folders aur Machine ID setup
mkdir -p /var/run/dbus
dbus-uuidgen --ensure=/etc/machine-id
dbus-uuidgen --ensure=/var/lib/dbus/machine-id
dbus-daemon --system --fork

# XRDP services start
service xrdp start
service xrdp-sesman start

# Logs tail karke container ko running rakhein
tail -f /var/log/xrdp.log /var/log/xrdp-sesman.log
