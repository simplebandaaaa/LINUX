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

# Essential packages + macOS-like system themes & engines
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
    git \
    tar \
    bc \
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

# 🍎 WHITESUR GTK THEME & ICONS INSTALLATION 🍎
RUN git clone https://github.com/vinceliuice/WhiteSur-gtk-theme.git --depth 1 /tmp/WhiteSur-gtk-theme && \
    /tmp/WhiteSur-gtk-theme/install.sh --dest /usr/share/themes && \
    rm -rf /tmp/WhiteSur-gtk-theme

RUN git clone https://github.com/vinceliuice/WhiteSur-icon-theme.git --depth 1 /tmp/WhiteSur-icon-theme && \
    /tmp/WhiteSur-icon-theme/install.sh -d /usr/share/icons && \
    rm -rf /tmp/WhiteSur-icon-theme

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
