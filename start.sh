#!/bin/bash

set -e

mkdir -p /run/dbus
mkdir -p /run/xrdp

rm -rf /tmp/.X11-unix/* 2>/dev/null || true

dbus-daemon --system --fork 2>/dev/null || true

/usr/sbin/xrdp-sesman

exec /usr/sbin/xrdp --nodaemon
