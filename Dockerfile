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

# Essential packages + Reliable GTK themes
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
    gtk2-engines-murrine \
    gtk2-engines-pixbuf \
    numix-gtk-theme \
    greybird-gtk-theme \
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

# 🍎 WHITESUR GTK THEME & ICONS (GUARANTEED MANUAL INSTALL) 🍎
RUN git clone https://github.com/vinceliuice/WhiteSur-gtk-theme.git --depth 1 /tmp/WhiteSur-gtk-theme && \
    mkdir -p /home/ubuntu/.themes && \
    cp -r /tmp/WhiteSur-gtk-theme/src/other/xfwm4 /home/ubuntu/.themes/WhiteSur-Light || true && \
    /tmp/WhiteSur-gtk-theme/install.sh -d /home/ubuntu/.themes -t light -s standard --xfce || true && \
    rm -rf /tmp/WhiteSur-gtk-theme

RUN git clone https://github.com/vinceliuice/WhiteSur-icon-theme.git --depth 1 /tmp/WhiteSur-icon-theme && \
    mkdir -p /home/ubuntu/.icons && \
    /tmp/WhiteSur-icon-theme/install.sh -d /home/ubuntu/.icons || true && \
    rm -rf /tmp/WhiteSur-icon-theme

# Copy user themes to system root to ensure detection
RUN cp -r /home/ubuntu/.themes/* /usr/share/themes/ 2>/dev/null || true && \
    cp -r /home/ubuntu/.icons/* /usr/share/icons/ 2>/dev/null || true

# ⚡ XRDP SETTINGS ⚡
RUN sed -i 's/crypt_level=high/crypt_level=low/' /etc/xrdp/xrdp.ini && \
    sed -i 's/security_layer=negotiate/security_layer=rdp/' /etc/xrdp/xrdp.ini && \
    sed -i 's/max_bpp=32/max_bpp=16/' /etc/xrdp/xrdp.ini && \
    sed -i 's/#tcp_send_buffer_size=32768/tcp_send_buffer_size=131072/' /etc/xrdp/xrdp.ini && \
    adduser xrdp ssl-cert

# Environment Scripts
RUN printf 'export XDG_CURRENT_DESKTOP=XFCE\nexport XDG_SESSION_DESKTOP=xfce\nstartxfce4\n' > /home/ubuntu/.xsession && \
    chmod +x /home/ubuntu/.xsession && \
    cp /home/ubuntu/.xsession /home/ubuntu/.xsessionrc && \
    chown -R ubuntu:ubuntu /home/ubuntu

COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 3389

CMD ["/start.sh"]
