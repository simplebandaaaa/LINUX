FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    software-properties-common \
    gnupg2 \
    ca-certificates \
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
    ssl-cert \
    firefox \
    arc-theme \
    papirus-icon-theme \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Ubuntu user
RUN useradd -m -s /bin/bash ubuntu && \
    echo 'ubuntu:ubuntu' | chpasswd && \
    usermod -aG sudo ubuntu && \
    echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/ubuntu && \
    chmod 440 /etc/sudoers.d/ubuntu

# Xorg permissions
RUN mkdir -p /etc/X11 && \
    printf 'allowed_users=anybody\nneeds_root_rights=no\n' \
    > /etc/X11/Xwrapper.config

# XRDP configuration
RUN adduser xrdp ssl-cert && \
    sed -i 's/^crypt_level=.*/crypt_level=low/' /etc/xrdp/xrdp.ini && \
    sed -i 's/^security_layer=.*/security_layer=rdp/' /etc/xrdp/xrdp.ini && \
    sed -i 's/^max_bpp=.*/max_bpp=16/' /etc/xrdp/xrdp.ini

# XFCE session
RUN mkdir -p /home/ubuntu/.config/xfce4/xfconf/xfce-perchannel-xml && \
    cat > /home/ubuntu/.xsession <<'EOF'
#!/bin/bash

export XDG_CURRENT_DESKTOP=XFCE
export XDG_SESSION_DESKTOP=xfce
export XDG_CONFIG_DIRS=/etc/xdg/xdg-xfce:/etc/xdg
export XDG_DATA_DIRS=/usr/share/xfce4:/usr/local/share:/usr/share

unset DBUS_SESSION_BUS_ADDRESS
unset XDG_RUNTIME_DIR

dbus-launch --exit-with-session startxfce4
EOF

RUN chmod +x /home/ubuntu/.xsession && \
    chown -R ubuntu:ubuntu /home/ubuntu

# Disable XFCE compositor for smoother RDP
RUN cat > /home/ubuntu/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="use_compositing" type="bool" value="false"/>
  </property>
</channel>
EOF

RUN chown -R ubuntu:ubuntu /home/ubuntu/.config

COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 3389

CMD ["/start.sh"]
