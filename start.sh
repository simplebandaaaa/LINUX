#!/bin/bash

# XRDP के लिए ज़रूरी रनटाइम डायरेक्टरी बनाना
mkdir -p /var/run/xrdp
mkdir -p /var/run/dbus

# किसी भी पुराने बचे हुए सॉकेट या PID फाइलों को डिलीट करना
rm -f /var/run/xrdp/xrdp.pid
rm -f /var/run/xrdp/xrdp-sesman.pid
rm -f /var/run/xrdp/xrdp_sesman.socket

# D-Bus और मशीन आईडी को सही से कॉन्फ़िगर और स्टार्ट करना
dbus-uuidgen --ensure
dbus-daemon --system --fork

# XRDP सेशन मैनेजर (sesman) को बैकग्राउंड में स्टार्ट करना
xrdp-sesman --nodaemon &

# थोड़ा रुकना ताकि sesman पूरी तरह एक्टिव हो जाए
sleep 2

# मुख्य XRDP सर्वर को फोरग्राउंड में चलाना
exec xrdp --nodaemon
