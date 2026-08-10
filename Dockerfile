FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Multi-arch support block for Wine32
RUN dpkg --add-architecture i386

# Firefox के लिए Mozilla PPA जोड़ना (Snap से बचने के लिए)
RUN apt-get update && apt-get install -y --no-install-recommends software-properties-common gnupg2 && \
    add-apt-repository -y ppa:mozillateam/ppa && \
    printf 'Package: firefox*\nPin: release o=LP-PPA-mozillateam\nPin-Priority: 1001\n' > /etc/apt/preferences.d/mozilla-firefox

# Update and install packages (dbus-user-session को यहाँ जोड़ा गया है)
RUN apt-get update && apt-get install -y --no-install-recommends \
    xrdp \
    xorgxrdp \
    xfce4 \
    xfce4-goodies \
    xorg \
    dbus-x11 \
    dbus-user-session \
    sudo \
    curl \
    wget \
    nano \
    net-tools \
    ssl-cert \
    polkitd \
    pulseaudio \
    pulseaudio-utils \
    wine \
    wine32:i386 \
    firefox && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# ---- 🛠️ USER SETUP FIX ---- #
RUN echo "ubuntu:ubuntu" | chpasswd && \
    usermod -aG sudo ubuntu && \
    echo "ubuntu ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
# ---------------------------- #

# Configure Xwrapper
RUN echo "allowed_users=anybody" > /etc/X11/Xwrapper.config && \
    echo "needs_root_rights=no" >> /etc/X11/Xwrapper.config

# Generate machine-id for dbus
RUN mkdir -p /var/run/dbus && dbus-uuidgen > /var/lib/dbus/machine-id

# Optimize XRDP Configuration
RUN sed -i 's/crypt_level=high/crypt_level=low/' /etc/xrdp/xrdp.ini && \
    sed -i 's/security_layer=negotiate/security_layer=rdp/' /etc/xrdp/xrdp.ini && \
    sed -i 's/max_bpp=32/max_bpp=24/' /etc/xrdp/xrdp.ini

# Ensure XFCE starts safely for the user (Black Screen को हमेशा के लिए फिक्स करने के लिए बदलाव)
RUN mkdir -p /home/ubuntu && \
    printf 'unset DBUS_SESSION_BUS_ADDRESS\nunset XDG_RUNTIME_DIR\nexport XDG_SESSION_TYPE=x11\nxfce4-session\n' > /home/ubuntu/.xsession && \
    chown -R ubuntu:ubuntu /home/ubuntu

# Add xrdp user to ssl-cert group
RUN adduser xrdp ssl-cert

COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 3389

CMD ["/start.sh"]
