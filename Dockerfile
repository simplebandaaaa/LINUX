FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# =========================================================
# PACKAGES
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
    xfdesktop4 \
    thunar \
    dbus-x11 \
    dbus-user-session \
    sudo \
    procps \
    iproute2 \
    net-tools \
    curl \
    wget \
    ca-certificates \
    ssl-cert \
    falkon \
    plank \
    papirus-icon-theme \
    greybird-gtk-theme \
    adwaita-icon-theme \
    fonts-dejavu \
    fonts-liberation \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# =========================================================
# RDP USER
# =========================================================
RUN useradd \
    -m \
    -s /bin/bash \
    -G sudo \
    rdpuser \
    && echo 'rdpuser:rdp123' | chpasswd \
    && echo 'rdpuser ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/rdpuser \
    && chmod 440 /etc/sudoers.d/rdpuser

# =========================================================
# XRDP USER / RUNTIME DIRECTORIES
# =========================================================
RUN adduser xrdp ssl-cert || true

RUN mkdir -p \
    /run/xrdp \
    /run/dbus \
    /tmp/.X11-unix \
    /usr/share/backgrounds \
    /home/rdpuser/Desktop \
    /home/rdpuser/.config \
    /home/rdpuser/.cache \
    /home/rdpuser/.local/share \
    /home/rdpuser/.config/xfce4 \
    /home/rdpuser/.config/xfce4/xfconf \
    /home/rdpuser/.config/xfce4/xfconf/xfce-perchannel-xml \
    /home/rdpuser/.config/autostart \
    /home/rdpuser/.config/plank \
    /home/rdpuser/.config/plank/dock1 \
    /home/rdpuser/.config/plank/dock1/launchers

RUN chmod 1777 /tmp/.X11-unix && \
    chown -R rdpuser:rdpuser /home/rdpuser && \
    chown xrdp:xrdp /run/xrdp

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
# DARK WALLPAPER
# =========================================================
RUN cat > /usr/share/backgrounds/rdp-dark.svg <<'EOF'
<svg xmlns="http://www.w3.org/2000/svg"
     width="1920"
     height="1080"
     viewBox="0 0 1920 1080">

<defs>
  <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0%" stop-color="#050914"/>
    <stop offset="55%" stop-color="#10243e"/>
    <stop offset="100%" stop-color="#03050a"/>
  </linearGradient>

  <linearGradient id="mountain" x1="0" y1="0" x2="1" y2="1">
    <stop offset="0%" stop-color="#29476b"/>
    <stop offset="100%" stop-color="#050914"/>
  </linearGradient>

  <radialGradient id="moon">
    <stop offset="0%" stop-color="#ffffff" stop-opacity=".95"/>
    <stop offset="100%" stop-color="#ffffff" stop-opacity="0"/>
  </radialGradient>
</defs>

<rect width="1920" height="1080" fill="url(#sky)"/>

<circle cx="1510" cy="220" r="180" fill="url(#moon)"/>
<circle cx="1510" cy="220" r="58" fill="#e6efff"/>

<g fill="#ffffff" opacity=".8">
  <circle cx="180" cy="160" r="2"/>
  <circle cx="330" cy="260" r="2"/>
  <circle cx="510" cy="120" r="2"/>
  <circle cx="690" cy="210" r="2"/>
  <circle cx="850" cy="100" r="2"/>
  <circle cx="1040" cy="230" r="2"/>
  <circle cx="1230" cy="120" r="2"/>
  <circle cx="1740" cy="160" r="2"/>
  <circle cx="1830" cy="330" r="2"/>
</g>

<path d="M0 850 L220 650 L360 760 L560 500 L720 720 L960 430 L1120 690 L1370 390 L1560 620 L1770 470 L1920 650 L1920 1080 L0 1080Z"
      fill="url(#mountain)"/>

<path d="M0 930 L260 760 L430 840 L650 670 L820 810 L1060 610 L1250 790 L1480 570 L1670 760 L1920 640 L1920 1080 L0 1080Z"
      fill="#03060d"
      opacity=".96"/>

<path d="M1370 390 L1470 540 L1435 515 L1500 610 L1370 560 L1290 610Z"
      fill="#496786"
      opacity=".8"/>
</svg>
EOF

# =========================================================
# XRDP STARTWM
# =========================================================
RUN cat > /etc/xrdp/startwm.sh <<'EOF'
#!/bin/sh

unset DBUS_SESSION_BUS_ADDRESS
unset XDG_RUNTIME_DIR

export HOME=/home/rdpuser
export USER=rdpuser
export LOGNAME=rdpuser

export XDG_CURRENT_DESKTOP=XFCE
export XDG_SESSION_DESKTOP=xfce
export XDG_CONFIG_HOME=/home/rdpuser/.config
export XDG_CACHE_HOME=/home/rdpuser/.cache

if [ -r /etc/profile ]; then
    . /etc/profile
fi

exec dbus-run-session -- startxfce4
EOF

RUN chmod +x /etc/xrdp/startwm.sh

# =========================================================
# XFCE SETTINGS
# =========================================================
RUN cat > /home/rdpuser/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml <<'EOF'
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
# XFWM PERFORMANCE
# =========================================================
RUN cat > /home/rdpuser/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml <<'EOF'
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

  </property>
</channel>
EOF

# =========================================================
# XFCE WALLPAPER
# =========================================================
RUN cat > /home/rdpuser/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>

<channel name="xfce4-desktop" version="1.0">

  <property name="backdrop" type="empty">

    <property name="screen0" type="empty">

      <property name="monitor0" type="empty">

        <property name="image-style"
                  type="int"
                  value="5"/>

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
# PLANK DOCK
# =========================================================
RUN cat > /home/rdpuser/.config/plank/dock1/settings <<'EOF'
[PlankDockPreferences]
Alignment=center
AutoPinning=true
DockItems=terminal.dockitem;thunar.dockitem;falkon.dockitem;
HideMode=none
IconSize=48
ItemsAlignment=center
Position=bottom
Theme=Default
TooltipsEnabled=true
ZoomEnabled=true
ZoomPercent=130
EOF

RUN cat > /home/rdpuser/.config/plank/dock1/launchers/terminal.dockitem <<'EOF'
[PlankDockItemPreferences]
Launcher=file:///usr/share/applications/xfce4-terminal.desktop
EOF

RUN cat > /home/rdpuser/.config/plank/dock1/launchers/thunar.dockitem <<'EOF'
[PlankDockItemPreferences]
Launcher=file:///usr/share/applications/thunar.desktop
EOF

RUN cat > /home/rdpuser/.config/plank/dock1/launchers/falkon.dockitem <<'EOF'
[PlankDockItemPreferences]
Launcher=file:///usr/share/applications/org.kde.falkon.desktop
EOF

# =========================================================
# PLANK AUTOSTART
# =========================================================
RUN cat > /home/rdpuser/.config/autostart/plank.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=Plank
Exec=plank
OnlyShowIn=XFCE;
X-GNOME-Autostart-enabled=true
EOF

# =========================================================
# DESKTOP SHORTCUTS
# =========================================================
RUN cat > /home/rdpuser/Desktop/falkon.desktop <<'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Falkon
Comment=Lightweight Web Browser
Exec=falkon
Icon=org.kde.falkon
Terminal=false
Categories=Network;WebBrowser;
EOF

RUN cat > /home/rdpuser/Desktop/terminal.desktop <<'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Terminal
Exec=xfce4-terminal
Icon=utilities-terminal
Terminal=false
Categories=System;TerminalEmulator;
EOF

RUN cat > /home/rdpuser/Desktop/files.desktop <<'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Files
Exec=thunar
Icon=system-file-manager
Terminal=false
Categories=System;FileManager;
EOF

RUN chmod +x /home/rdpuser/Desktop/*.desktop && \
    chown -R rdpuser:rdpuser /home/rdpuser

# =========================================================
# START SCRIPT
# =========================================================
COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 3389

CMD ["/start.sh"]
