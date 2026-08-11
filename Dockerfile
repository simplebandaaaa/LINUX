FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# ============================================================
# WINE 32-BIT SUPPORT
# ============================================================

RUN dpkg --add-architecture i386

# ============================================================
# LIGHTWEIGHT DESKTOP + XRDP + FIREFOX + WINE
# ============================================================

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        xrdp \
        xorgxrdp \
        xserver-xorg-core \
        icewm \
        icewm-common \
        rox-filer \
        xterm \
        dbus-x11 \
        dbus-user-session \
        sudo \
        ca-certificates \
        curl \
        wget \
        unzip \
        p7zip-full \
        firefox-esr \
        wine \
        wine32:i386 \
        libnss3 \
        libgtk-3-0 \
        libx11-xcb1 \
        libasound2 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ============================================================
# USER
# ============================================================

RUN useradd -m -s /bin/bash ubuntu && \
    echo 'ubuntu:ubuntu' | chpasswd && \
    usermod -aG sudo ubuntu && \
    echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' \
        > /etc/sudoers.d/ubuntu && \
    chmod 0440 /etc/sudoers.d/ubuntu

# ============================================================
# XORG
# ============================================================

RUN mkdir -p /etc/X11 && \
    cat > /etc/X11/Xwrapper.config <<'EOF'
allowed_users=anybody
needs_root_rights=no
EOF

# ============================================================
# XRDP
# ============================================================

RUN adduser xrdp ssl-cert || true

RUN sed -i \
    's/^max_bpp=.*/max_bpp=16/' \
    /etc/xrdp/xrdp.ini || true

# ============================================================
# XSESSION
# ============================================================

RUN cat > /home/ubuntu/.xsession <<'EOF'
#!/bin/sh

export XDG_CURRENT_DESKTOP=IceWM
export XDG_SESSION_DESKTOP=icewm
export XDG_SESSION_TYPE=x11

unset DBUS_SESSION_BUS_ADDRESS
unset XDG_RUNTIME_DIR

exec icewm-session
EOF

RUN chmod +x /home/ubuntu/.xsession

# ============================================================
# ICEWM CONFIG
# ============================================================

RUN mkdir -p /home/ubuntu/.icewm

RUN cat > /home/ubuntu/.icewm/preferences <<'EOF'
TaskBarShowClock=1
TaskBarShowWindowListMenu=1
TaskBarShowWorkspaces=0
ShowDesktop=1
FocusOnAppRaise=1
QuickSwitch=0
ShowMoveSizeStatus=0
EOF

# ============================================================
# ICEWM MENU
# ============================================================

RUN cat > /home/ubuntu/.icewm/menu <<'EOF'
menu "Applications" folder {
    prog "Firefox ESR" firefox-esr firefox-esr
    prog "Files" rox rox
    prog "Terminal" xterm xterm
}
EOF

# ============================================================
# FIREFOX ESR POLICY
# ============================================================

RUN mkdir -p /etc/firefox-esr/policies

RUN cat > /etc/firefox-esr/policies/policies.json <<'EOF'
{
  "policies": {
    "DisableTelemetry": true,
    "DisableFirefoxStudies": true,
    "DisablePocket": true,
    "DisableFirefoxAccounts": true,
    "OverrideFirstRunPage": "",
    "OverridePostUpdatePage": ""
  }
}
EOF

# ============================================================
# DESKTOP
# ============================================================

RUN mkdir -p /home/ubuntu/Desktop

# Firefox
RUN cat > /home/ubuntu/Desktop/firefox.desktop <<'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Firefox ESR
Comment=Web Browser
Exec=firefox-esr
Icon=firefox-esr
Terminal=false
Categories=Network;WebBrowser;
EOF

# Terminal
RUN cat > /home/ubuntu/Desktop/terminal.desktop <<'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Terminal
Exec=xterm
Icon=utilities-terminal
Terminal=false
EOF

# Files
RUN cat > /home/ubuntu/Desktop/files.desktop <<'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Files
Exec=rox
Icon=folder
Terminal=false
EOF

# ============================================================
# MAKE DESKTOP FILES EXECUTABLE
# ============================================================

RUN chmod +x /home/ubuntu/Desktop/*.desktop

# ============================================================
# WINE DIRECTORY
# ============================================================

RUN mkdir -p /home/ubuntu/.wine

# ============================================================
# PERMISSIONS
# ============================================================

RUN chown -R ubuntu:ubuntu /home/ubuntu

# ============================================================
# START
# ============================================================

COPY start.sh /start.sh

RUN chmod +x /start.sh

EXPOSE 3389

CMD ["/start.sh"]
