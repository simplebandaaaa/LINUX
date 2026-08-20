#!/bin/bash

# Purani PID aur lock files saaf karein (taaki container Crash hone par issue na aaye)
rm -f /var/run/xrdp/xrdp.pid
rm -f /var/run/xrdp/xrdp-sesman.pid
rm -f /tmp/.X*-lock

# Directories ensure karein
mkdir -p /var/run/xrdp /var/run/xrdp-sesman

# Services start karein
xrdp-sesman
xrdp --nodaemon
