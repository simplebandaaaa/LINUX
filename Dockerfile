FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV HOME=/root
ENV USER=root

# =========================================================
# PACKAGES
# =========================================================
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
    ca-certificates \
    ssl-cert \
    procps \
    iproute2 \
    net-tools \
    falkon \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# =========================================================
# ROOT USER
# =========================================================
USER root
WORKDIR /root
RUN echo 'root:root' | chpasswd

# =========================================================
# XORG CONFIGURATION
# =========================================================
RUN mkdir -p /etc/X11 && \
    printf '%s\n' \
    'allowed_users=anybody' \
    'needs_root_rights=yes' \
    > /etc/X11/Xwrapper.config

# =========================================================
# XRDP CONFIGURATION
# =========================================================
RUN sed -i 's/^crypt_level=.*/crypt_level=low/' /etc/xrdp/xrdp.ini || true && \
    sed -i 's/^security_layer=.*/security_layer=rdp/' /etc/xrdp/xrdp.ini || true && \
    sed -i 's/^max_bpp=.*/max_bpp=16/' /etc/xrdp/xrdp.ini || true && \
    sed -i 's/^use_compression=.*/use_compression=yes/' /etc/xrdp/xrdp.ini || true && \
    adduser xrdp ssl-cert || true

# =========================================================
# XFCE ROOT SESSION
# =========================================================
RUN mkdir -p \
    /root/.config/xfce4/xfconf/xfce-perchannel-xml \
    /root/Desktop

RUN printf '%s\n' \
    '#!/bin/sh' \
    'export HOME=/root' \
    'export USER=root' \
    'export XDG_CURRENT_DESKTOP=XFCE' \
    'export XDG_SESSION_DESKTOP=xfce' \
    'eval $(dbus-launch --sh-syntax --exit-with-session)' \
    'exec startxfce4' \
    > /root/.xsession && \
    chmod +x /root/.xsession

# =========================================================
# DISABLE XFCE COMPOSITING
# =========================================================
RUN printf '%s\n' \
    '<?xml version="1.0" encoding="UTF-8"?>' \
    '<channel name="xfwm4" version="1.0">' \
    '<property name="general" type="empty">' \
    '<property name="use_compositing" type="bool" value="false"/>' \
    '</property>' \
    '</channel>' \
    > /root/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml

# =========================================================
# FALKON DESKTOP SHORTCUT & SYSTEM WRAPPER
# =========================================================
# Root user ke liye --no-sandbox flag ZAROORI hota hai
RUN mv /usr/bin/falkon /usr/bin/falkon-bin && \
    printf '%s\n' \
    '#!/bin/sh' \
    'exec /usr/bin/falkon-bin --no-sandbox "$@"' \
    > /usr/bin/falkon && \
    chmod +x /usr/bin/falkon

RUN printf '%s\n' \
    '[Desktop Entry]' \
    'Version=1.0' \
    'Type=Application' \
    'Name=Falkon' \
    'Comment=Web Browser' \
    'Exec=falkon' \
    'Icon=falkon' \
    'Terminal=false' \
    'Categories=Network;WebBrowser;' \
    > /root/Desktop/falkon.desktop && \
    chmod +x /root/Desktop/falkon.desktop

# =========================================================
# START SCRIPT
# =========================================================
COPY start.sh /start.sh
RUN chmod +x /start.sh

# =========================================================
# XRDP PORT
# =========================================================
EXPOSE 3389

USER root
CMD ["/start.sh"]
