FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# ============================================================
# 32-BIT SUPPORT FOR WINE
# ============================================================

RUN dpkg --add-architecture i386

# ============================================================
# ULTRA LIGHT DESKTOP
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
        bzip2 \
        unzip \
        p7zip-full \
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
# XRDP
# ============================================================

RUN adduser xrdp ssl-cert || true

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
    'unset DBUS_SESSION_BUS_ADDRESS' \
    'unset XDG_RUNTIME_DIR' \
    'exec icewm-session' \
    > /home/ubuntu/.xsession && \
    chmod +x /home/ubuntu/.xsession

# ============================================================
# ICEWM LOW RAM CONFIG
# ============================================================

RUN mkdir -p /home/ubuntu/.icewm && \
    printf '%s\n' \
        'TaskBarShowClock=1' \
        'TaskBarShowWindowListMenu=1' \
        'TaskBarShowWorkspaces=0' \
        'ShowDesktop=1' \
        'FocusOnAppRaise=1' \
        'QuickSwitch=0' \
        > /home/ubuntu/.icewm/preferences

# ============================================================
# ICEWM MENU
# ============================================================

RUN printf '%s\n' \
    'menu "Applications" folder {' \
    '  prog "Firefox" firefox firefox' \
    '  prog "Files" rox rox' \
    '  prog "Terminal" xterm xterm' \
    '}' \
    > /home/ubuntu/.icewm/menu

# ============================================================
# FIREFOX
# ============================================================

RUN mkdir -p /opt && \
    curl -L \
        'https://download.mozilla.org/?product=firefox-latest-ssl&os=linux64&lang=en-US' \
        -o /tmp/firefox.tar.bz2 && \
    tar -xjf /tmp/firefox.tar.bz2 -C /opt && \
    ln -sf /opt/firefox/firefox /usr/local/bin/firefox && \
    rm -f /tmp/firefox.tar.bz2

# ============================================================
# FIREFOX POLICIES
# ============================================================

RUN mkdir -p /opt/firefox/distribution && \
    printf '%s\n' \
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
        > /opt/firefox/distribution/policies.json

# ============================================================
# DESKTOP SHORTCUTS
# ============================================================

RUN mkdir -p /home/ubuntu/Desktop

RUN printf '%s\n' \
    '[Desktop Entry]' \
    'Version=1.0' \
    'Type=Application' \
    'Name=Firefox' \
    'Exec=/usr/local/bin/firefox' \
    'Icon=firefox' \
    'Terminal=false' \
    'Categories=Network;WebBrowser;' \
    > /home/ubuntu/Desktop/firefox.desktop && \
    chmod +x /home/ubuntu/Desktop/firefox.desktop

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

RUN printf '%s\n' \
    '[Desktop Entry]' \
    'Version=1.0' \
    'Type=Application' \
    'Name=Files' \
    'Exec=rox' \
    'Icon=folder' \
    'Terminal=false' \
    > /home/ubuntu/Desktop/files.desktop && \
    chmod +x /home/ubuntu/Desktop/files.desktop

# ============================================================
# PERMISSIONS
# ============================================================

RUN chown -R ubuntu:ubuntu /home/ubuntu

# ============================================================
# START SCRIPT
# ============================================================

COPY start.sh /start.sh

RUN chmod +x /start.sh

EXPOSE 3389

CMD ["/start.sh"]
