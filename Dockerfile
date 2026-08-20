FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# XRDP + Xorg + XFCE
RUN apt-get update && apt-get install -y --no-install-recommends \
    xrdp \
    xorgxrdp \
    xserver-xorg-core \
    xfce4 \
    xfce4-session \
    xfce4-panel \
    xfce4-settings \
    xfwm4 \
    xfdesktop4 \
    xfce4-terminal \
    dbus-x11 \
    dbus-user-session \
    policykit-1 \
    sudo \
    ca-certificates \
    procps \
    iproute2 \
    net-tools \
    && rm -rf /var/lib/apt/lists/*

# RDP user
RUN useradd -m -s /bin/bash rdpuser \
    && echo 'rdpuser:rdp123' | chpasswd \
    && usermod -aG sudo,audio,video,ssl-cert rdpuser

# XRDP -> XFCE
RUN cat > /etc/xrdp/startwm.sh <<'EOF'
#!/bin/sh

unset DBUS_SESSION_BUS_ADDRESS
unset SESSION_MANAGER
unset XDG_RUNTIME_DIR

export LANG=C.UTF-8
export LC_ALL=C.UTF-8
export XDG_CURRENT_DESKTOP=XFCE
export XDG_SESSION_DESKTOP=xfce
export XDG_CONFIG_DIRS=/etc/xdg/xdg-xfce:/etc/xdg
export XDG_DATA_DIRS=/usr/share/xfce4:/usr/local/share:/usr/share

exec dbus-launch --exit-with-session startxfce4
EOF

RUN chmod 755 /etc/xrdp/startwm.sh

# Explicit XFCE session for RDP user
RUN cat > /home/rdpuser/.xsession <<'EOF'
#!/bin/sh

unset DBUS_SESSION_BUS_ADDRESS
unset SESSION_MANAGER
unset XDG_RUNTIME_DIR

export LANG=C.UTF-8
export LC_ALL=C.UTF-8
export XDG_CURRENT_DESKTOP=XFCE
export XDG_SESSION_DESKTOP=xfce

exec dbus-launch --exit-with-session startxfce4
EOF

RUN chmod 755 /home/rdpuser/.xsession \
    && chown rdpuser:rdpuser /home/rdpuser/.xsession \
    && mkdir -p /home/rdpuser/.config \
    && chown -R rdpuser:rdpuser /home/rdpuser

COPY start.sh /usr/local/bin/start.sh

RUN chmod 755 /usr/local/bin/start.sh

EXPOSE 3389

ENTRYPOINT ["/usr/local/bin/start.sh"]
