#!/bin/bash
# PID फ़ाइलों को साफ़ करें ताकि रिस्टार्ट में एरर न आए
rm -f /var/run/xrdp/xrdp*.pid

# dbus सर्विस चालू करें
service dbus start

# XRDP सर्विसेज चालू करें
xrdp-sesman
xrdp -n
