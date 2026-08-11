FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# ==================================================
# i386 support - required for Wine32
# ==================================================
RUN dpkg --add-architecture i386

# ==================================================
# System packages
# ==================================================
RUN apt-get update && apt-get install -y --no-install-recommends \
    locales \
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
    dbus \
    sudo \
    wget \
    curl \
    bzip2 \
    xz-utils \
    ca-certificates \
    ssl-cert \
    file \
    wine \
    wine32:i386 \
    libnss3 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libdbus-1-3 \
    libgtk-3-0 \
    libx11-xcb1 \
    libasound2t64 \
    && locale-gen en_US.UTF-8 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ==================================================
# Firefox - official Mozilla Linux x86_64 build
# ==================================================
RUN set -eux; \
    mkdir -p /opt; \
    curl -fL \
        "https://download.mozilla.org/?product=firefox-latest-ssl&os=linux64&lang=en-US" \
        -o /tmp/firefox.tar.xz; \
    file /tmp/firefox.tar.xz; \
    tar -xJf /tmp/firefox.tar.xz -C /opt; \
    test -x /opt/firefox/firefox; \
    ln -sf /opt/firefox/firefox /usr/local/bin/firefox; \
    rm -f /tmp/firefox.tar.xz

# ==================================================
# Ubuntu user
# ==================================================
RUN useradd -m -s /bin/bash ubuntu \
    && echo "ubuntu:ubuntu" | chpasswd \
    && usermod -aG sudo,ssl-cert ubuntu \
    && echo "ubuntu ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ubuntu \
    && chmod 0440 /etc/sudoers.d/ubuntu

# ==================================================
# XRDP permissions
# ==================================================
RUN adduser xrdp ssl-cert || true

# ==================================================
# Xorg configuration
# ==================================================
RUN mkdir -p /etc/X11 \
    && printf '%s\n' \
       'allowed_users=anybody' \
       'needs_root_rights=no' \
       > /etc/X11/Xwrapper.config

# ==================================================
# XRDP configuration
# ==================================================
RUN sed -i -E \
        's/^[[:space:]]*crypt_level=.*/crypt_level=low/' \
        /etc/xrdp/xrdp.ini \
    && sed -i -E \
        's/^[[:space:]]*security_layer=.*/security_layer=rdp/' \
        /etc/xrdp/xrdp.ini \
    && sed -i -E \
        's/^[[:space:]]*max_bpp=.*/max_bpp=16/' \
        /etc/xrdp/xrdp.ini

# ==================================================
# Disable XFCE compositor
# ==================================================
RUN mkdir -p \
        /home/ubuntu/.config/xfce4/xfconf/xfce-perchannel-xml \
    && cat > /home/ubuntu/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>

<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="use_compositing" type="bool" value="false"/>
  </property>
</channel>
EOF

# ==================================================
# XFCE XRDP session
# ==================================================
RUN cat > /home/ubuntu/.xsession <<'EOF'
#!/bin/sh

export XDG_CURRENT_DESKTOP=XFCE
export XDG_SESSION_DESKTOP=xfce
export XDG_CONFIG_DIRS=/etc/xdg/xdg-xfce:/etc/xdg
export XDG_DATA_DIRS=/usr/share/xfce4:/usr/local/share:/usr/share

unset DBUS_SESSION_BUS_ADDRESS

exec startxfce4
EOF

RUN chmod +x /home/ubuntu/.xsession \
    && cp /home/ubuntu/.xsession /home/ubuntu/.xsessionrc

# ==================================================
# Firefox desktop shortcut
# ==================================================
RUN mkdir -p /home/ubuntu/Desktop \
    && cat > /home/ubuntu/Desktop/firefox.desktop <<'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Firefox
Comment=Web Browser
Exec=/usr/local/bin/firefox
Icon=/opt/firefox/browser/chrome/icons/default/default128.png
Terminal=false
Categories=Network;WebBrowser;
EOF

RUN chmod +x /home/ubuntu/Desktop/firefox.desktop \
    && chown -R ubuntu:ubuntu /home/ubuntu

# ==================================================
# Startup script
# ==================================================
COPY start.sh /start.sh

RUN chmod +x /start.sh

# ==================================================
# Railway
# ==================================================
EXPOSE 3389

CMD ["/start.sh"]
