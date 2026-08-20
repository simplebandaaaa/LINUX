FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    HOME=/root \
    USER=root

# 1. Mozilla PPA Add karke direct (non-snap) Firefox install karein
RUN apt-get update && apt-get install -y --no-install-recommends \
    software-properties-common \
    && add-apt-repository ppa:mozillateam/ppa -y \
    && printf '%s\n' \
        'Package: firefox*' \
        'Pin: release o=LP-PPA-mozillateam' \
        'Pin-Priority: 1001' \
        > /etc/apt/preferences.d/mozilla-firefox \
    && apt-get update && apt-get install -y --no-install-recommends \
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
    ca-certificates \
    ssl-cert \
    procps \
    iproute2 \
    net-tools \
    firefox \
    libasound2 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /root

# 2. System & XRDP Config
RUN echo 'root:root' | chpasswd && \
    adduser xrdp ssl-cert || true && \
    mkdir -p /var/run/xrdp /var/run/xrdp-sesman && \
    mkdir -p /etc/X11 && \
    printf '%s\n' \
    'allowed_users=anybody' \
    'needs_root_rights=yes' \
    > /etc/X11/Xwrapper.config

RUN sed -i 's/^crypt_level=.*/crypt_level=low/' /etc/xrdp/xrdp.ini || true && \
    sed -i 's/^security_layer=.*/security_layer=rdp/' /etc/xrdp/xrdp.ini || true && \
    sed -i 's/^max_bpp=.*/max_bpp=16/' /etc/xrdp/xrdp.ini || true && \
    sed -i 's/^use_compression=.*/use_compression=yes/' /etc/xrdp/xrdp.ini || true

# 3. XFCE Session Config
RUN mkdir -p /root/.config/xfce4/xfconf/xfce-perchannel-xml /root/Desktop && \
    printf '%s\n' \
    '#!/bin/sh' \
    'export HOME=/root' \
    'export USER=root' \
    'export XDG_CURRENT_DESKTOP=XFCE' \
    'export XDG_SESSION_DESKTOP=xfce' \
    'unset DBUS_SESSION_BUS_ADDRESS' \
    'unset XDG_RUNTIME_DIR' \
    'exec startxfce4' \
    > /root/.xsession && \
    chmod +x /root/.xsession && \
    printf '%s\n' \
    '<?xml version="1.0" encoding="UTF-8"?>' \
    '<channel name="xfwm4" version="1.0">' \
    '<property name="general" type="empty">' \
    '<property name="use_compositing" type="bool" value="false"/>' \
    '</property>' \
    '</channel>' \
    > /root/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml

# 4. Firefox Desktop Shortcut (Root Flag Fix)
RUN printf '%s\n' \
    '[Desktop Entry]' \
    'Version=1.0' \
    'Type=Application' \
    'Name=Firefox' \
    'Comment=Web Browser' \
    'Exec=firefox --no-remote %u' \
    'Icon=firefox' \
    'Terminal=false' \
    'Categories=Network;WebBrowser;' \
    > /root/Desktop/firefox.desktop && \
    chmod +x /root/Desktop/firefox.desktop

COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 3389

CMD ["/start.sh"]
