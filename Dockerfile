FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Multi-arch support block for Wine32
RUN dpkg --add-architecture i386

# आवश्यक पैकेजेस (डिफ़ॉल्ट उबंटू बेस पैकेजेस)
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
    wget \
    curl \
    bzip2 \
    ca-certificates \
    ssl-cert \
    wine \
    wine32:i386 \
    libnss3 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libdbus-1-3 \
    libgtk-3-0 \
    libx11-xcb1 \
    libasound2t64 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 🚨 OFFICIAL MOZILLA FIREFOX DEPLOYMENT (100% पक्का डाउनलोड और एक्सट्रेक्ट) 🚨
# यह सीधा मोज़िला के सर्वर से स्टेबल लिनक्स बाइनरी उठाएगा, जो कभी फेल नहीं होती
RUN mkdir -p /opt && \
    curl -Lo /tmp/firefox.tar.bz2 "https://download.mozilla.org/?product=firefox-latest-ssl&os=linux64&lang=en-US" && \
    tar -jxvf /tmp/firefox.tar.bz2 -C /opt/ && \
    ln -s /opt/firefox/firefox /usr/local/bin/firefox && \
    rm /tmp/firefox.tar.bz2

# ---- 🛠️ SAFE USER SETUP ---- #
RUN echo "ubuntu:ubuntu" | chpasswd && \
    usermod -aG sudo ubuntu && \
    echo "ubuntu ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Ubuntu 24.04 में रूटलेस Xorg चलाने की परमिशन
RUN echo "allowed_users=anybody" > /etc/X11/Xwrapper.config && \
    echo "needs_root_rights=no" >> /etc/X11/Xwrapper.config

# ⚡ SUPER SMOOTH & LOW LATENCY XRDP SETTINGS ⚡
RUN sed -i 's/crypt_level=high/crypt_level=low/' /etc/xrdp/xrdp.ini && \
    sed -i 's/security_layer=negotiate/security_layer=rdp/' /etc/xrdp/xrdp.ini && \
    sed -i 's/max_bpp=32/max_bpp=16/' /etc/xrdp/xrdp.ini && \
    sed -i 's/use_compression=yes/use_compression=yes/' /etc/xrdp/xrdp.ini && \
    sed -i 's/#tcp_send_buffer_size=32768/tcp_send_buffer_size=131072/' /etc/xrdp/xrdp.ini && \
    adduser xrdp ssl-cert

# Xorg डिफ़ॉल्ट सेट करना
RUN sed -i 's/errorsesman/xrdp\/xorg/g' /etc/xrdp/sesman.ini

# XFCE विज़ुअल एनिमेशन ऑफ करना
RUN mkdir -p /home/ubuntu/.config/xfce4/xfconf/xfce-perchannel-xml/ && \
    printf '<?xml version="1.0" encoding="UTF-8"?><channel name="xfwm4" version="1.0"><property name="general" type="empty"><property name="use_compositing" type="bool" value="false"/></property></channel>' > /home/ubuntu/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml

# XFCE डेस्कटॉप पर डायरेक्ट Browser का शॉर्टकट आइकॉन बनाना
RUN mkdir -p /home/ubuntu/Desktop && \
    printf '[Desktop Entry]\nVersion=1.0\nType=Application\nName=Firefox\nComment=Access the Internet\nExec=firefox --no-sandbox\nIcon=firefox\nTerminal=false\nCategories=Network;WebBrowser;\n' > /home/ubuntu/Desktop/firefox.desktop && \
    chmod +x /home/ubuntu/Desktop/firefox.desktop

# XFCE एनवायरनमेंट स्क्रिप्ट्स
RUN printf 'export XDG_CURRENT_DESKTOP=XFCE\nexport XDG_SESSION_DESKTOP=xfce\nunset DBUS_SESSION_BUS_ADDRESS\nunset XDG_RUNTIME_DIR\nstartxfce4\n' > /home/ubuntu/.xsession && \
    chmod +x /home/ubuntu/.xsession && \
    cp /home/ubuntu/.xsession /home/ubuntu/.xsessionrc && \
    chown -R ubuntu:ubuntu /home/ubuntu

COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 3389

CMD ["/start.sh"]
