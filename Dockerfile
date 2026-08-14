FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV HOME=/root
ENV USER=root

# -------------------------------
# Base packages
# -------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    xrdp \
    xorgxrdp \
    xserver-xorg-core \
    xfce4 \
    xfce4-panel \
    xfwm4 \
    xfce4-settings \
    xfce4-session \
    xfce4-terminal \
    dbus-x11 \
    dbus-user-session \
    sudo \
    wget \
    curl \
    bzip2 \
    ca-certificates \
    ssl-cert \
    tar \
    procps \
    iproute2 \
    net-tools \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# -------------------------------
# Firefox - official Mozilla build
# -------------------------------
RUN mkdir -p /opt && \
    curl -fL \
    "https://download.mozilla.org/?product=firefox-latest-ssl&os=linux64&lang=en-US" \
    -o /tmp/firefox.tar.bz2 && \
    tar -xjf /tmp/firefox.tar.bz2 -C /opt && \
    ln -sf /opt/firefox/firefox /usr/local/bin/firefox && \
    rm -f /tmp/firefox.tar.bz2

# -------------------------------
# ROOT USER
# -------------------------------
RUN echo "root:root" | chpasswd

USER root
WORKDIR /root

# -------------------------------
# Xorg configuration
# -------------------------------
RUN mkdir -p /etc/X11 && \
    printf '%s\n' \
    'allowed_users=anybody' \
    'needs_root_rights=yes' \
    > /etc/X11/Xwrapper.config

# -------------------------------
# XRDP configuration
# -------------------------------
RUN sed -i 's/^crypt_level=.*/crypt_level=low/' /etc/xrdp/xrdp.ini || true && \
    sed -i 's/^security_layer=.*/security_layer=rdp/' /etc/xrdp/xrdp.ini || true && \
    sed -i 's/^max_bpp=.*/max_bpp=16/' /etc/xrdp/xrdp.ini || true && \
    sed -i 's/^use_compression=.*/use_compression=yes/' /etc/xrdp/xrdp.ini || true && \
    adduser xrdp ssl-cert || true

# -------------------------------
# XFCE configuration
# -------------------------------
RUN mkdir -p /root/.config/xfce4/xfconf/xfce-perchannel-xml && \
    printf '%s\n' \
    '<?xml version="1.0" encoding="UTF-8"?>' \
    '<channel name="xfwm4" version="1.0">' \
    '<property name="general" type="empty">' \
    '<property name="use_compositing" type="bool" value="false"/>' \
    '</property>' \
    '</channel>' \
    > /root/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml

# -------------------------------
# Root XFCE session
# -------------------------------
RUN printf '%s\n' \
    '#!/bin/sh' \
    'export XDG_CURRENT_DESKTOP=XFCE' \
    'export XDG_SESSION_DESKTOP=xfce' \
    'export XDG_CONFIG_DIRS=/etc/xdg/xdg-xfce:/etc/xdg' \
    'unset DBUS_SESSION_BUS_ADDRESS' \
    'unset XDG_RUNTIME_DIR' \
    'exec startxfce4' \
    > /root/.xsession && \
    chmod +x /root/.xsession

# -------------------------------
# Firefox desktop shortcut
# -------------------------------
RUN mkdir -p /root/Desktop && \
    printf '%s\n' \
    '[Desktop Entry]' \
    'Version=1.0' \
    'Type=Application' \
    'Name=Firefox' \
    'Comment=Web Browser' \
    'Exec=firefox --no-sandbox' \
    'Icon=firefox' \
    'Terminal=false' \
    'Categories=Network;WebBrowser;' \
    > /root/Desktop/firefox.desktop && \
    chmod +x /root/Desktop/firefox.desktop

# -------------------------------
# XRDP startup script
# -------------------------------
RUN printf '%s\n' \
    '#!/bin/bash' \
    'set -e' \
    '' \
    'export HOME=/root' \
    'export USER=root' \
    '' \
    'mkdir -p /run/xrdp' \
    'mkdir -p /var/run/dbus' \
    'rm -rf /tmp/.X11-unix/* /tmp/.X*-lock 2>/dev/null || true' \
    '' \
    'chown root:root /root' \
    'chmod 700 /root' \
    '' \
    'if [ -x /usr/bin/dbus-daemon ]; then' \
    '    dbus-daemon --system --fork 2>/dev/null || true' \
    'fi' \
    '' \
    'rm -f /var/run/xrdp/xrdp.pid /var/run/xrdp/xrdp-sesman.pid 2>/dev/null || true' \
    '' \
    'echo "================================="' \
    'echo " XRDP ROOT DESKTOP"' \
    'echo "================================="' \
    'echo "User: root"' \
    'echo "Port: ${PORT:-3389}"' \
    'echo "================================="' \
    '' \
    'if [ -n "${PORT}" ] && [ "${PORT}" != "3389" ]; then' \
    '    sed -i "s/^port=.*/port=${PORT}/" /etc/xrdp/xrdp.ini' \
    'fi' \
    '' \
    'xrdp-sesman &' \
    'sleep 2' \
    'exec xrdp --nodaemon' \
    > /start.sh && \
    chmod +x /start.sh

# -------------------------------
# XRDP port
# -------------------------------
EXPOSE 3389

# -------------------------------
# Run as ROOT
# -------------------------------
USER root

CMD ["/start.sh"]
