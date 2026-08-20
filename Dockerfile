FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Multi-arch support block for Wine32
RUN dpkg --add-architecture i386

# Firefox के लिए Mozilla PPA
RUN apt-get update && apt-get install -y --no-install-recommends software-properties-common gnupg2 && \
    add-apt-repository -y ppa:mozillateam/ppa && \
    printf 'Package: firefox*\nPin: release o=LP-PPA-mozillateam\nPin-Priority: 1001\n' > /etc/apt/preferences.d/mozilla-firefox

# आवश्यक पैकेजेस (केवल Xorgxrdp - TightVNC को पूरी तरह हटा दिया है ताकि कोई कन्फ्यूजन न हो)
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
    ssl-cert \
    wine \
    wine32:i386 \
    firefox && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# ---- 🛠️ SAFE USER SETUP ---- #
RUN echo "ubuntu:ubuntu" | chpasswd && \
    usermod -aG sudo ubuntu && \
    echo "ubuntu ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Ubuntu 24.04 में रूटलेस Xorg चलाने की परमिशन देना
RUN echo "allowed_users=anybody" > /etc/X11/Xwrapper.config && \
    echo "needs_root_rights=no" >> /etc/X11/Xwrapper.config

# ⚡ SUPER SMOOTH & LIGHTWEIGHT XRDP SETTINGS ⚡
# Xorg (Xorgxrdp) को डिफ़ॉल्ट बनाना और नेटवर्क बफ़र्स को ऑप्टिमाइज़ करना
RUN sed -i 's/crypt_level=high/crypt_level=low/' /etc/xrdp/xrdp.ini && \
    sed -i 's/security_layer=negotiate/security_layer=rdp/' /etc/xrdp/xrdp.ini && \
    sed -i 's/max_bpp=32/max_bpp=16/' /etc/xrdp/xrdp.ini && \
    sed -i 's/use_compression=yes/use_compression=yes/' /etc/xrdp/xrdp.ini && \
    sed -i 's/#tcp_send_buffer_size=32768/tcp_send_buffer_size=131072/' /etc/xrdp/xrdp.ini && \
    adduser xrdp ssl-cert

# Xvnc/VNC को पूरी तरह ब्लॉक करके Xorg को पहला (डिफ़ॉल्ट) ऑप्शन सेट करना
RUN sed -i 's/errorsesman/xrdp\/xorg/g' /etc/xrdp/sesman.ini

# XFCE विज़ुअल एनिमेशन (Compositing) ऑफ करना ताकि लैग न हो
RUN mkdir -p /home/ubuntu/.config/xfce4/xfconf/xfce-perchannel-xml/ && \
    printf '<?xml version="1.0" encoding="UTF-8"?><channel name="xfwm4" version="1.0"><property name="general" type="empty"><property name="use_compositing" type="bool" value="false"/></property></channel>' > /home/ubuntu/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml

# XFCE एनवायरनमेंट स्क्रिप्ट्स (सिर्फ Xorg के लिए)
RUN printf 'export XDG_CURRENT_DESKTOP=XFCE\nexport XDG_SESSION_DESKTOP=xfce\nunset DBUS_SESSION_BUS_ADDRESS\nunset XDG_RUNTIME_DIR\nstartxfce4\n' > /home/ubuntu/.xsession && \
    chmod +x /home/ubuntu/.xsession && \
    cp /home/ubuntu/.xsession /home/ubuntu/.xsessionrc && \
    chown -R ubuntu:ubuntu /home/ubuntu

COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 3389

CMD ["/start.sh"]
