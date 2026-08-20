FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Multi-arch support block for Wine32
RUN dpkg --add-architecture i386

# Firefox via Mozilla PPA
RUN apt-get update && apt-get install -y --no-install-recommends \
    software-properties-common \
    gnupg \
    ca-certificates && \
    add-apt-repository -y ppa:mozillateam/ppa && \
    printf 'Package: firefox*\nPin: release o=LP-PPA-mozillateam\nPin-Priority: 1001\n' > /etc/apt/preferences.d/mozilla-firefox

# Essential packages
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
    curl \
    wget \
    tar \
    xz-utils \
    gtk2-engines-murrine \
    gtk2-engines-pixbuf \
    ssl-cert \
    wine64 \
    wine32:i386 \
    firefox && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# ---- 🛠️ SAFE USER SETUP ---- #
RUN echo "ubuntu:ubuntu" | chpasswd && \
    usermod -aG sudo ubuntu && \
    echo "ubuntu ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Grant Xorg execution permissions
RUN echo "allowed_users=anybody" > /etc/X11/Xwrapper.config && \
    echo "needs_root_rights=yes" >> /etc/X11/Xwrapper.config

# 🍎 WHITESUR GTK THEME & ICONS (PRE-COMPILED RELEASES) 🍎
# Install WhiteSur GTK Themes directly
RUN mkdir -p /usr/share/themes && \
    curl -sL https://github.com/vinceliuice/WhiteSur-gtk-theme/releases/latest/download/WhiteSur-Light.tar.xz | tar -xJ -C /usr/share/themes/ || \
    curl -sL https://github.com/vinceliuice/WhiteSur-gtk-theme/archive/refs/heads/master.tar.gz | tar -xz -C /tmp && \
    if [ -d /tmp/WhiteSur-gtk-theme-master ]; then cp -r /tmp/WhiteSur-gtk-theme-master /usr/share/themes/WhiteSur-Light; rm -rf /tmp/WhiteSur-gtk-theme-master; fi

# Install WhiteSur Icon Theme directly
RUN mkdir -p /usr/share/icons && \
    curl -sL https://github.com/vinceliuice/WhiteSur-icon-theme/releases/latest/download/WhiteSur.tar.xz | tar -xJ -C /usr/share/icons/ || true

# ⚡ SUPER SMOOTH & LIGHTWEIGHT XRDP SETTINGS ⚡
RUN sed -i 's/crypt_level=high/crypt_level=low/' /etc/xrdp/xrdp.ini && \
    sed -i 's/security_layer=negotiate/security_layer=rdp/' /etc/xrdp/xrdp.ini && \
    sed -i 's/max_bpp=32/max_bpp=16/' /etc/xrdp/xrdp.ini && \
    sed -i 's/#tcp_send_buffer_size=32768/tcp_send_buffer_size=131072/' /etc/xrdp/xrdp.ini && \
    adduser xrdp ssl-cert

# 🍎 DEFAULT XFCE CONFIGURATION FOR WHITESUR THEME 🍎
RUN mkdir -p /home/ubuntu/.config/xfce4/xfconf/xfce-perchannel-xml/

# Apply WhiteSur GTK & Icon Theme
RUN printf '<?xml version="1.0" encoding="UTF-8"?>\n\
<channel name="xsettings" version="1.0">\n\
  <property name="Net" type="empty">\n\
    <property name="ThemeName" type="string" value="WhiteSur-Light"/>\n\
    <property name="IconThemeName" type="string" value="WhiteSur"/>\n\
  </property>\n\
</channel>' > /home/ubuntu/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml

# Apply Window Manager (xfwm4) Theme & Disable Compositing
RUN printf '<?xml version="1.0" encoding="UTF-8"?>\n\
<channel name="xfwm4" version="1.0">\n\
  <property name="general" type="empty">\n\
    <property name="theme" type="string" value="WhiteSur-Light"/>\n\
    <property name="use_compositing" type="bool" value="false"/>\n\
  </property>\n\
</channel>' > /home/ubuntu/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml

# XFCE Environment Scripts
RUN printf 'export XDG_CURRENT_DESKTOP=XFCE\nexport XDG_SESSION_DESKTOP=xfce\nstartxfce4\n' > /home/ubuntu/.xsession && \
    chmod +x /home/ubuntu/.xsession && \
    cp /home/ubuntu/.xsession /home/ubuntu/.xsessionrc && \
    chown -R ubuntu:ubuntu /home/ubuntu

COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 3389

CMD ["/start.sh"]
