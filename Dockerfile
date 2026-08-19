FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV HOME=/root
ENV USER=root
ENV LOGNAME=root
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# =========================================================
# XFCE + XRDP + FALKON + MODERN THEME
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
    xfconf \
    thunar \
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
    plank \
    papirus-icon-theme \
    greybird-gtk-theme \
    fonts-dejavu \
    fonts-liberation \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

USER root

WORKDIR /root

RUN echo 'root:root' | chpasswd

# =========================================================
# XRDP
# =========================================================
RUN adduser xrdp ssl-cert || true

RUN mkdir -p \
    /var/run/xrdp \
    /var/run/dbus \
    /tmp/.X11-unix \
    /root/.config \
    /root/.cache \
    /root/.local/share \
    /root/Desktop

RUN chmod 1777 /tmp/.X11-unix && \
    chown xrdp:xrdp /var/run/xrdp

# =========================================================
# XORG
# =========================================================
RUN mkdir -p /etc/X11 && \
    printf '%s\n' \
    'allowed_users=anybody' \
    'needs_root_rights=yes' \
    > /etc/X11/Xwrapper.config

# =========================================================
# XRDP CONFIG
# =========================================================
RUN sed -i 's/^crypt_level=.*/crypt_level=low/' /etc/xrdp/xrdp.ini || true && \
    sed -i 's/^security_layer=.*/security_layer=rdp/' /etc/xrdp/xrdp.ini || true && \
    sed -i 's/^max_bpp=.*/max_bpp=16/' /etc/xrdp/xrdp.ini || true && \
    sed -i 's/^use_compression=.*/use_compression=yes/' /etc/xrdp/xrdp.ini || true

# =========================================================
# CUSTOM WALLPAPER
# =========================================================
RUN mkdir -p /usr/share/backgrounds && \
cat > /usr/share/backgrounds/rdp-dark.svg <<'EOF'
<svg xmlns="http://www.w3.org/2000/svg"
     width="1920" height="1080" viewBox="0 0 1920 1080">

<defs>
  <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0%" stop-color="#07111f"/>
    <stop offset="55%" stop-color="#102746"/>
    <stop offset="100%" stop-color="#050914"/>
  </linearGradient>

  <linearGradient id="mountain" x1="0" y1="0" x2="1" y2="1">
    <stop offset="0%" stop-color="#182f50"/>
    <stop offset="100%" stop-color="#050914"/>
  </linearGradient>

  <radialGradient id="moon">
    <stop offset="0%" stop-color="#ffffff" stop-opacity=".9"/>
    <stop offset="100%" stop-color="#ffffff" stop-opacity="0"/>
  </radialGradient>
</defs>

<rect width="1920" height="1080" fill="url(#sky)"/>

<circle cx="1500" cy="230" r="170" fill="url(#moon)"/>
<circle cx="1500" cy="230" r="55" fill="#dce8ff"/>

<g fill="#ffffff" opacity=".75">
  <circle cx="220" cy="180" r="2"/>
  <circle cx="410" cy="270" r="2"/>
  <circle cx="620" cy="130" r="2"/>
  <circle cx="850" cy="220" r="2"/>
  <circle cx="1040" cy="120" r="2"/>
  <circle cx="1270" cy="320" r="2"/>
  <circle cx="1700" cy="150" r="2"/>
  <circle cx="1800" cy="350" r="2"/>
</g>

<path d="
M0 850
L220 650
L360 760
L560 500
L720 720
L960 430
L1120 690
L1370 390
L1560 620
L1770 470
L1920 650
L1920 1080
L0 1080 Z"
fill="url(#mountain)"/>

<path d="
M0 930
L260 760
L430 840
L650 670
L820 810
L1060 610
L1250 790
L1480 570
L1670 760
L1920 640
L1920 1080
L0 1080 Z"
fill="#050914"
opacity=".95"/>

<path d="
M1370 390
L1470 540
L1430 520
L1500 610
L1370 560
L1290 610
Z"
fill="#304d70"
opacity=".8"/>

</svg>
EOF

# =========================================================
# XFCE SESSION
# =========================================================
RUN cat > /root/.xsession <<'EOF'
#!/bin/sh

export HOME=/root
export USER=root
export LOGNAME=root

export XDG_CURRENT_DESKTOP=XFCE
export XDG_SESSION_DESKTOP=xfce
export XDG_CONFIG_HOME=/root/.config
export XDG_CACHE_HOME=/root/.cache

unset DBUS_SESSION_BUS_ADDRESS
unset XDG_RUNTIME_DIR

mkdir -p /root/.config
mkdir -p /root/.cache

exec dbus-run-session -- startxfce4
EOF

RUN chmod +x /root/.xsession

# =========================================================
# DARK XFCE THEME
# =========================================================
RUN cat > /root/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>

<channel name="xsettings" version="1.0">

  <property name="Net" type="empty">

    <property name="ThemeName"
              type="string"
              value="Greybird-dark"/>

    <property name="IconThemeName"
              type="string"
              value="Papirus-Dark"/>

    <property name="CursorThemeName"
              type="string"
              value="Adwaita"/>

    <property name="DoubleClickTime"
              type="int"
              value="400"/>

    <property name="DoubleClickDistance"
              type="int"
              value="5"/>

    <property name="EnableEventSounds"
              type="bool"
              value="false"/>

    <property name="EnableInputFeedbackSounds"
              type="bool"
              value="false"/>

  </property>

</channel>
EOF

# =========================================================
# XFWM WINDOWS
# =========================================================
RUN cat > /root/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>

<channel name="xfwm4" version="1.0">

  <property name="general" type="empty">

    <property name="theme"
              type="string"
              value="Default"/>

    <property name="use_compositing"
              type="bool"
              value="false"/>

    <property name="show_dock_shadow"
              type="bool"
              value="false"/>

    <property name="show_frame_shadow"
              type="bool"
              value="false"/>

    <property name="cycle_draw_frame"
              type="bool"
              value="false"/>

  </property>

</channel>
EOF

# =========================================================
# DESKTOP WALLPAPER
# =========================================================
RUN cat > /root/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>

<channel name="xfce4-desktop" version="1.0">

  <property name="backdrop" type="empty">

    <property name="screen0" type="empty">

      <property name="monitor0" type="empty">

        <property name="image-style"
                  type="int"
                  value="5"/>

        <property name="image-show"
                  type="bool"
                  value="true"/>

        <property name="last-image"
                  type="string"
                  value="/usr/share/backgrounds/rdp-dark.svg"/>

        <property name="color-style"
                  type="int"
                  value="0"/>

      </property>

    </property>

  </property>

</channel>
EOF

# =========================================================
# PLANK DOCK CONFIG
# =========================================================
RUN mkdir -p /root/.config/plank/dock1/launchers

RUN cat > /root/.config/plank/dock1/settings <<'EOF'
[PlankDockPreferences]
Alignment=center
AutoPinning=true
DockItems=terminal.dockitem;falkon.dockitem;thunar.dockitem;
HideMode=none
IconSize=48
ItemsAlignment=center
Position=bottom
Theme=Default
TooltipsEnabled=true
ZoomEnabled=true
ZoomPercent=130
EOF

RUN cat > /root/.config/plank/dock1/launchers/falkon.dockitem <<'EOF'
[PlankDockItemPreferences]
Launcher=file:///usr/share/applications/org.kde.falkon.desktop
EOF

RUN cat > /root/.config/plank/dock1/launchers/terminal.dockitem <<'EOF'
[PlankDockItemPreferences]
Launcher=file:///usr/share/applications/xfce4-terminal.desktop
EOF

RUN cat > /root/.config/plank/dock1/launchers/thunar.dockitem <<'EOF'
[PlankDockItemPreferences]
Launcher=file:///usr/share/applications/thunar.desktop
EOF

# =========================================================
# AUTOSTART PLANK
# =========================================================
RUN mkdir -p /root/.config/autostart

RUN cat > /root/.config/autostart/plank.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=Plank
Comment=Desktop Dock
Exec=plank
OnlyShowIn=XFCE;
X-GNOME-Autostart-enabled=true
EOF

# =========================================================
# FALKON DESKTOP ICON
# =========================================================
RUN cat > /root/Desktop/falkon.desktop <<'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Falkon
Comment=Web Browser
Exec=falkon
Icon=org.kde.falkon
Terminal=false
Categories=Network;WebBrowser;
EOF

# =========================================================
# TERMINAL DESKTOP ICON
# =========================================================
RUN cat > /root/Desktop/terminal.desktop <<'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Terminal
Exec=xfce4-terminal
Icon=utilities-terminal
Terminal=false
Categories=System;TerminalEmulator;
EOF

# =========================================================
# FILE MANAGER DESKTOP ICON
# =========================================================
RUN cat > /root/Desktop/files.desktop <<'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Files
Exec=thunar
Icon=system-file-manager
Terminal=false
Categories=System;FileManager;
EOF

RUN chmod +x /root/Desktop/*.desktop

# =========================================================
# START SCRIPT
# =========================================================
COPY start.sh /start.sh

RUN chmod +x /start.sh

EXPOSE 3389

USER root

CMD ["/start.sh"]
