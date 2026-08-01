FROM alpine:latest

# आवश्यक लाइटवेट पैकेजेस, XFCE4, XRDP और Firefox इंस्टॉल करना
RUN apk update && apk add --no-cache \
    xfce4 \
    xfce4-terminal \
    xvfb \
    xrdp \
    sudo \
    util-linux \
    dbus \
    linux-pam \
    bash \
    firefox \
    font-noto \
    && rm -rf /var/cache/apk/*

# ---- 🛠️ SAFE USER SETUP ---- #
RUN adduser -D -s /bin/bash alpine && \
    echo "alpine:alpine" | chpasswd && \
    addgroup alpine wheel && \
    echo "alpine ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# ⚡ SUPER SMOOTH & LOW LATENCY XRDP SETTINGS ⚡
RUN sed -i 's/crypt_level=high/crypt_level=low/' /etc/xrdp/xrdp.ini && \
    sed -i 's/security_layer=negotiate/security_layer=rdp/' /etc/xrdp/xrdp.ini && \
    sed -i 's/max_bpp=32/max_bpp=16/' /etc/xrdp/xrdp.ini && \
    sed -i 's/use_compression=yes/use_compression=yes/' /etc/xrdp/xrdp.ini && \
    sed -i 's/#tcp_send_buffer_size=32768/tcp_send_buffer_size=131072/' /etc/xrdp/xrdp.ini

# Xorg/Xvfb सेटिंग्स (Alpine के लिए बेस्ट)
RUN sed -i 's/errorsesman/xrdp\/xvfb/g' /etc/xrdp/sesman.ini

# XFCE विज़ुअल एनिमेशन ऑफ करना
RUN mkdir -p /home/alpine/.config/xfce4/xfconf/xfce-perchannel-xml/ && \
    printf '<?xml version="1.0" encoding="UTF-8"?><channel name="xfwm4" version="1.0"><property name="general" type="empty"><property name="use_compositing" type="bool" value="false"/></property></channel>' > /home/alpine/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml

# डेस्कटॉप पर Firefox का शॉर्टकट आइकॉन बनाना
RUN mkdir -p /home/alpine/Desktop && \
    printf '[Desktop Entry]\nVersion=1.0\nType=Application\nName=Firefox\nExec=firefox\nIcon=firefox\nTerminal=false\nCategories=Network;WebBrowser;\n' > /home/alpine/Desktop/firefox.desktop && \
    chmod +x /home/alpine/Desktop/firefox.desktop

# XFCE एनवायरनमेंट स्क्रिप्ट्स
RUN printf 'export XDG_CURRENT_DESKTOP=XFCE\nexport XDG_SESSION_DESKTOP=xfce\nunset DBUS_SESSION_BUS_ADDRESS\nunset XDG_RUNTIME_DIR\nstartxfce4\n' > /home/alpine/.xsession && \
    chmod +x /home/alpine/.xsession && \
    chown -R alpine:alpine /home/alpine

COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 3389

CMD ["/start.sh"]
