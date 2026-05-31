#!/bin/bash
# ==========================================
# Setup SSH WebSocket + UDPGW (Refactored)
# ==========================================

GREEN='\e[0;32m'
RED='\e[0;31m'
NC='\e[0m'
BASE_DIR="/root/AutoscriptXRAY"
DEPS_VERSION="deps-v2"
RELEASE_URL="https://github.com/znandev/AutoscriptXRAY/releases/download/${DEPS_VERSION}"

clear
echo -e "${GREEN}▶️ Installing SSH + WebSocket Dependencies...${NC}"

if [[ ! -f "$BASE_DIR/config/issue.net" ]]; then
    echo -e "${RED}[ERROR] File issue.net tidak ditemukan!${NC}"
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update -qq >/dev/null 2>&1
apt-get install -qq -y openssh-server stunnel4 curl wget python3 screen git libtomcrypt1 libtommath1 psmisc >/dev/null 2>&1
mkdir -p /usr/local/bin

echo -e "${GREEN}[INFO] Installing Dropbear...${NC}"
apt-get remove -qq -y dropbear >/dev/null 2>&1 || true

cd /tmp || exit
wget -qO dropbear-bin.deb "${RELEASE_URL}/dropbear-bin_2019.78-2build1_amd64.deb" || { echo -e "${RED}[ERROR] Download dropbear-bin gagal!${NC}"; exit 1; }
wget -qO dropbear.deb "${RELEASE_URL}/dropbear_2019.78-2build1_all.deb" || { echo -e "${RED}[ERROR] Download dropbear gagal!${NC}"; exit 1; }
dpkg -i dropbear-bin.deb dropbear.deb >/dev/null 2>&1

# Hostkey Dropbear
mkdir -p /etc/dropbear
[[ ! -f /etc/dropbear/dropbear_rsa_host_key ]] && dropbearkey -t rsa -f /etc/dropbear/dropbear_rsa_host_key >/dev/null 2>&1
[[ ! -f /etc/dropbear/dropbear_ecdsa_host_key ]] && dropbearkey -t ecdsa -f /etc/dropbear/dropbear_ecdsa_host_key >/dev/null 2>&1

# Banner
cp "$BASE_DIR/config/issue.net" /etc/issue.net
chmod 644 /etc/issue.net

# Config Dropbear
cat > /etc/default/dropbear <<EOF
NO_START=0
DROPBEAR_PORT=109
DROPBEAR_EXTRA_ARGS="-p 143 -W 65536 -b /etc/issue.net"
DROPBEAR_RECEIVE_WINDOW=65536
EOF

cat > /etc/systemd/system/dropbear.service <<EOF
[Unit]
Description=Dropbear SSH Server
After=network.target

[Service]
ExecStart=/usr/sbin/dropbear -E -F -p 109 -p 143 -W 65536 -b /etc/issue.net
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# WS & Stunnel
cp "$BASE_DIR/sshws/ws-dropbear.py" /usr/local/bin/ws-dropbear
cp "$BASE_DIR/sshws/ws-dropbear.service" /etc/systemd/system/
chmod +x /usr/local/bin/ws-dropbear

cp "$BASE_DIR/sshws/ws-stunnel.py" /usr/local/bin/ws-stunnel
cp "$BASE_DIR/sshws/ws-stunnel.service" /etc/systemd/system/
chmod +x /usr/local/bin/ws-stunnel

# BadVPN UDPGW
echo -e "${GREEN}[INFO] Installing BadVPN UDPGW...${NC}"
wget -qO /usr/local/bin/badvpn-udpgw "${RELEASE_URL}/badvpn-udpgw" || { echo -e "${RED}[ERROR] Download BadVPN gagal!${NC}"; exit 1; }
chmod +x /usr/local/bin/badvpn-udpgw
cp "$BASE_DIR/sshws/udpgw.service" /etc/systemd/system/

# UDP Custom
echo -e "${GREEN}[INFO] Installing UDP Custom...${NC}"
wget -qO /usr/local/bin/udp-custom "${RELEASE_URL}/udp-custom-linux-amd64" || { echo -e "${RED}[ERROR] Download UDP Custom gagal!${NC}"; exit 1; }
chmod +x /usr/local/bin/udp-custom
mkdir -p /etc/udp-custom
cp "$BASE_DIR/config/udp-custom.json" /etc/udp-custom/config.json
cp "$BASE_DIR/sshws/udp-custom.service" /etc/systemd/system/

# Permissions & Services
chmod 644 /etc/systemd/system/*.service
systemctl daemon-reload >/dev/null 2>&1
for svc in ssh dropbear ws-dropbear ws-stunnel udpgw udp-custom; do
    systemctl enable $svc >/dev/null 2>&1
    systemctl restart $svc >/dev/null 2>&1
done

apt-mark hold dropbear >/dev/null 2>&1 || true

cat >> /root/log-install.txt <<EOF
━━━━━━━━━━━━━━━━━━━━━━
SSH PANEL
━━━━━━━━━━━━━━━━━━━━━━
OpenSSH             : 22
Dropbear            : 109,143
SSH Websocket       : 2082
SSH SSL Websocket   : 2096
BadVPN UDPGW        : 7300
Port UdpSSH         : 1-65535
━━━━━━━━━━━━━━━━━━━━━━
EOF

clear
echo -e "${GREEN}[ OK ] SSH + WS + UDPGW Installed Successfully${NC}\n"
echo -e "${GREEN}[INFO] Service Status:${NC}"
systemctl --no-pager --type=service | grep -E 'dropbear|ssh|ws|udpgw|udp'
echo ""