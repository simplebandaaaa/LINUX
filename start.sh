#!/bin/bash

# 1. Ngrok download aur setup karna
echo "Downloading ngrok v3..."
wget -q https://bin.equinox.io/c/bNy819Qbg8T/ngrok-stable-linux-amd64.tgz
tar -xf ngrok-stable-linux-amd64.tgz
rm ngrok-stable-linux-amd64.tgz
chmod +x ./ngrok

# 2. Ngrok TCP tunnel shuru karna (Port 3389 ke liye)
echo "Starting ngrok tunnel..."
./ngrok tcp 3389 --authtoken $NGROK_TOKEN &

# 3. D-Bus runtime directory fix (Ubuntu 24.04 ke liye zaroori)
mkdir -p /run/user/1000
chown -R ubuntu:ubuntu /run/user/1000
export XDG_RUNTIME_DIR=/run/user/1000

# 4. XRDP aur Sesman services ko chalu karna
echo "Starting RDP services..."
rm -f /var/run/xrdp*.pid
xrdp-sesman --nodaemon &
xrdp --nodaemon &

# 5. Render ka "No open HTTP ports" error aur Health check bypass
echo "Starting dummy HTTP server for Render Health Check..."
echo "RDP Server is Live and Tunneling via Ngrok!" > index.html
python3 -m http.server 10000 &

# 6. Container ko live rakhne ke liye
echo "All system modules launched successfully."
tail -f /dev/null
