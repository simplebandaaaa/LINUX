FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# ============================================================
# 32-BIT SUPPORT FOR WINE
# ============================================================

RUN dpkg --add-architecture i386

# ============================================================
# ULTRA-LIGHT DESKTOP + XRDP + FIREFOX ESR + WINE
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

RUN useradd \
        -m \
        -s /bin/bash \
        ubuntu && \
    echo "ubuntu:ubuntu" | chpasswd && \
    usermod -aG sudo ubuntu && \
    echo "ubuntu ALL=(ALL) NOPASSWD:ALL" \
        > /etc/sudoers.d/ubuntu && \
    chmod 0440 /etc/sudoers.d/ubuntu

# ============================================================
# XORG CONFIG
# ============================================================

RUN mkdir -p /etc/X11 && \
    printf '%s\n' \
        'allowed_users=anybody' \
        'needs_root_rights=no' \
        > /etc/X11/Xwrapper.config

# ============================================================
# XRDP CONFIG
# ============================================================

RUN adduser xrdp ssl-cert || true

# Lower color depth to reduce RDP bandwidth
RUN sed -i \
    's/^max_bpp=.*/max_bpp=16/' \
    /etc/xrdp/xrdp.ini || true

# ============================================================
# ICEWM SESSION
# ============================================================

RUN printf '%s\n' \
    '#!/bin/sh' \
    'export XDG_CURRENT_DESKTOP=IceWM' \
    'export XDG_SESSION_DESKTOP=icewm' \
    'export XDG_SESSION_TYPE=x11' \
    'export XDG_CONFIG_DIRS=/etc/xdg' \
    'unset DBUS_SESSION_BUS_ADDRESS' \
    'unset XDG_RUNTIME_DIR' \
    'exec icewm-session' \
    > /home/ubuntu/.xsession && \
    chmod +x /home/ubuntu/.xsession

# ============================================================
# ICEWM LOW-RAM CONFIGURATION
# ============================================================

RUN mkdir -p /home/ubuntu/.icewm && \
    printf '%s\n' \
        'TaskBarShowClock=1' \
        'TaskBarShowWindowListMenu=1' \
        'TaskBarShowWorkspaces=0' \
        'ShowDesktop=1' \
        'FocusOnAppRaise=1' \
        'QuickSwitch=0' \
        'ShowMoveSizeStatus=0' \
        > /home/ubuntu/.icewm/preferences

# ============================================================
# ICEWM MENU
# ============================================================

RUN printf '%s\n' \
    'menu "Applications" folder {' \
    '  prog "Firefox ESR" firefox-esr firefox-esr' \
    '  prog "Files" rox rox' \
    '  prog "Terminal" xterm xterm' \
    '}' \
    > /home/ubuntu/.icewm/menu

# ============================================================
# FIREFOX ESR - LOW RESOURCE POLICIES
# ============================================================

RUN mkdir -p /etc/firefox-esr/policies

RUN printf '%s\n' \
    '{' \
    '  "policies": {' \
    '    "DisableTelemetry": true,' \
    '    "DisableFirefoxStudies": true,' \
    '    "DisablePocket": true,' \
    '    "DisableFirefoxAccounts": true,' \
    '    "OverrideFirstRunPage": "",' \
    '    "OverridePostUpdatePage": ""' \
    '  }' \
    '}' \
    > /etc/firefox-esr/policies/policies.json

# ============================================================
# DESKTOP DIRECTORY
# ============================================================

RUN mkdir -p /home/ubuntu/Desktop

# ============================================================
# FIREFOX SHORTCUT
# ============================================================

RUN printf '%s\n' \
    '[Desktop Entry]' \
    'Version=1.0' \
    'Type=Application' \
    'Name=Firefox ESR' \
    'Comment=Web Browser' \
    'Exec=firefox-esr' \
    'Icon=firefox-esr' \
    'Terminal=false' \
    'Categories=Network;WebBrowser;' \
    > /home/ubuntu/Desktop/firefox.desktop && \
    chmod +x /home/ubuntu/Desktop/firefox.desktop

# ============================================================
# TERMINAL SHORTCUT
# ============================================================

RUN printf '%s\n' \
    '[Desktop Entry]' \
    'Version=1.0' \
    'Type=Application' \
    'Name=Terminal' \
    'Exec=xterm' \
    'Icon=utilities-terminal' \
    'Terminal=false' \
    > /home/ubuntu/Desktop/terminal.desktop && \
    chmod +x /home/ubuntu/Desktop/terminal.desktop

# ============================================================
# FILE MANAGER SHORTCUT
# ============================================================

RUN printf '%s\n' \
    '[Desktop Entry]' \
    'Version=1.0' \
    'Type=Application' \
    'Name=Files' \
    'Exec=
