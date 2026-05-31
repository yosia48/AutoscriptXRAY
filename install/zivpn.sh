#!/bin/bash
# ==========================================
# ZNAND UDP ZIVPN INSTALLER (Refactored)
# ==========================================

clear
RED='\e[0;31m'
GREEN='\e[0;32m'
YELLOW='\e[1;33m'
CYAN='\e[0;36m'
NC='\e[0m'

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}             INSTALL UDP ZIVPN                ${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
sleep 1

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Please run as root!${NC}"
   exit 1
fi

echo -e "${YELLOW}[*] Menginstall dependensi (Silent Mode)...${NC}"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq >/dev/null 2>&1
apt-get install -qq -y wget curl openssl net-tools ufw iptables-persistent >/dev/null 2>&1

systemctl stop zivpn >/dev/null 2>&1 || true

echo -e "${YELLOW}[*] Mendownload ZIVPN binary...${NC}"
wget -qO /usr/local/bin/zivpn "https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-amd64" || { echo -e "${RED}Gagal mendownload binary!${NC}"; exit 1; }
chmod +x /usr/local/bin/zivpn

if ss -lunp 2>/dev/null | grep -q ":5667"; then
    echo -e "${RED}Port 5667 sudah digunakan oleh aplikasi lain!${NC}"
    exit 1
fi

echo -e "${YELLOW}[*] Menyiapkan environment ZIVPN...${NC}"
mkdir -p /etc/zivpn
touch /etc/zivpn/users.db
echo "zndev_reserve" > /etc/zivpn/users.db

openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 \
    -subj "/C=ID/ST=Jakarta/L=Jakarta/O=ZNAND/OU=UDP/CN=zivpn" \
    -keyout /etc/zivpn/zivpn.key -out /etc/zivpn/zivpn.crt >/dev/null 2>&1

USERS=$(awk '{print "\"" $1 "\""}' /etc/zivpn/users.db | paste -sd "," -)

cat > /etc/zivpn/config.json <<EOF
{
  "listen": ":5667",
  "cert": "/etc/zivpn/zivpn.crt",
  "key": "/etc/zivpn/zivpn.key",
  "obfs": "zivpn",
  "auth": {
    "mode": "passwords",
    "config": [ $USERS ]
  }
}
EOF

# System Optimization
sysctl -w net.core.rmem_max=16777216 >/dev/null 2>&1
sysctl -w net.core.wmem_max=16777216 >/dev/null 2>&1
grep -q "net.core.rmem_max" /etc/sysctl.conf || echo "net.core.rmem_max=16777216" >> /etc/sysctl.conf
grep -q "net.core.wmem_max" /etc/sysctl.conf || echo "net.core.wmem_max=16777216" >> /etc/sysctl.conf
sysctl -p >/dev/null 2>&1

cat > /etc/systemd/system/zivpn.service <<EOF
[Unit]
Description=zivpn VPN Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/zivpn
ExecStart=/usr/local/bin/zivpn server -c /etc/zivpn/config.json
Restart=always
RestartSec=3
Environment=ZIVPN_LOG_LEVEL=warning

[Install]
WantedBy=multi-user.target
EOF

echo -e "${YELLOW}[*] Setting iptables rules...${NC}"
iptables -t nat -C PREROUTING -p udp --dport 6000:19999 -j REDIRECT --to-ports 5667 2>/dev/null || \
iptables -t nat -A PREROUTING -p udp --dport 6000:19999 -j REDIRECT --to-ports 5667

netfilter-persistent save >/dev/null 2>&1

systemctl daemon-reload >/dev/null 2>&1
systemctl enable zivpn >/dev/null 2>&1
systemctl restart zivpn >/dev/null 2>&1

sleep 2
if systemctl is-active --quiet zivpn; then
    STATUS="${GREEN}RUNNING${NC}"
else
    STATUS="${RED}FAILED${NC}"
fi

clear
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}             ZIVPN INSTALLED                  ${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e " Service Status : $STATUS"
echo -e " UDP Port       : 5667"
echo -e " Config Path    : /etc/zivpn/config.json"
echo -e " Users DB       : /etc/zivpn/users.db"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n${NC}"