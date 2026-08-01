FROM fedora:latest

# आवश्यक पैकेजेस और XFCE डेस्कटॉप एनवायरनमेंट इंस्टॉल करना (DNF5 Compatible)
RUN dnf update -y && \
    dnf install -y @xfce-desktop-environment \
    xrdp \
    xorg-x11-server-Xorg \
    xorg-x11-xinit \
    dbus-x11 \
    sudo \
    wget \
    curl \
    bzip2 \
    ca-certificates \
    wine \
    firefox && \
    dnf clean all

# ---- 🛠️ SAFE USER SETUP ---- #
RUN useradd -m -s /bin/bash fedora && \
    echo "fedora:fedora" | chpasswd && \
    usermod -aG wheel fedora && \
    echo "fedora ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Fedora में रूटलेस Xorg चलाने की परमिशन
RUN mkdir -p /etc/X11/ && \
    echo "allowed_users=anybody" > /etc/X11/Xwrapper.config && \
    echo "needs_root_rights=no" >> /etc/X11/Xwrapper.config

# ⚡ SUPER SMOOTH & LOW LATENCY XRDP SETTINGS ⚡
RUN sed -i 's/crypt_level=high/crypt_level=low/' /etc/xrdp/xrdp.ini && \
    sed -i 's/security_layer=negotiate/security_layer=rdp/' /etc/xrdp/xrdp.ini && \
    sed -i 's/max_bpp=32/max_bpp=16/' /etc/xrdp/xrdp.ini && \
    sed -i 's/use_compression=yes/use_compression=yes/' /etc/xrdp/xrdp.ini && \
    sed -i 's/#tcp_send_buffer_size=32768/tcp_send_buffer_size=131072/' /etc/xrdp/xrdp.ini

# Xorg को डिफ़ॉल्ट सेट करना
RUN sed -i 's/errorsesman/xrdp\/xorg/g' /etc/xrdp/sesman.ini

# XFCE विज़ुअल एनिमेशन ऑफ करना (ताकि RDP बिल्कुल न अटके)
RUN mkdir -p /home/fedora/.config/xfce4/xfconf/xfce-perchannel-xml/ && \
    printf '<?xml version="1.0" encoding="UTF-8"?><channel name="xfwm4" version="1.0"><property name="general" type="empty"><property name="use_compositing" type="bool" value="false"/></property></channel>' > /home/fedora/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml

# XFCE डेस्कटॉप पर Firefox का शॉर्टकट आइकॉन बनाना
RUN mkdir -p /home/fedora/Desktop && \
    printf '[Desktop Entry]\nVersion=1.0\nType=Application\nName=Firefox\nComment=Access the Internet\nExec=firefox\nIcon=firefox\nTerminal=false\nCategories=Network;WebBrowser;\n' > /home/fedora/Desktop/firefox.desktop && \
    chmod +x /home/fedora/Desktop/firefox.desktop

# XFCE एनवायरनमेंट स्क्रिप्ट्स
RUN printf 'export XDG_CURRENT_DESKTOP=XFCE\nexport XDG_SESSION_DESKTOP=xfce\nunset DBUS_SESSION_BUS_ADDRESS\nunset XDG_RUNTIME_DIR\nstartxfce4\n' > /home/fedora/.xsession && \
    chmod +x /home/fedora/.xsession && \
    cp /home/fedora/.xsession /home/fedora/.xsessionrc && \
    chown -R fedora:fedora /home/fedora

COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 3389

CMD ["/start.sh"]
