#!/bin/bash
# ==========================================
# Setup Xray Core + Nginx (Refactored)
# ==========================================

GREEN='\e[0;32m'
RED='\e[0;31m'
NC='\e[0m'
BASE_DIR="/root/AutoscriptXRAY"

clear
echo -e "${GREEN}▶️ Installing Xray Core...${NC}"

if ! command -v nginx >/dev/null 2>&1; then
    echo -e "${RED}[ERROR] NGINX belum terinstall! Jalankan install/nginx.sh terlebih dahulu.${NC}"
    exit 1
fi

if [[ ! -f "$BASE_DIR/config/xray.json" || ! -f "$BASE_DIR/config/xray.conf" ]]; then
    echo -e "${RED}[ERROR] File konfigurasi xray (json/conf) tidak ditemukan di $BASE_DIR!${NC}"
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update -qq >/dev/null 2>&1
apt-get install -qq -y curl wget socat cron jq unzip gnupg coreutils lsof qrencode ca-certificates psmisc >/dev/null 2>&1

mkdir -p /etc/xray /var/log/xray /usr/local/bin /tmp/xray

echo -e "${GREEN}⬇️ Downloading Xray Core...${NC}"
wget -qO /tmp/xray.zip "https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip" || { echo -e "${RED}[ERROR] Gagal download Xray Core!${NC}"; exit 1; }
unzip -qo /tmp/xray.zip -d /tmp/xray
install -m 755 /tmp/xray/xray /usr/local/bin/xray
rm -rf /tmp/xray /tmp/xray.zip

if [[ ! -f /root/domain ]]; then
    echo -e "${RED}[ERROR] File /root/domain tidak ditemukan!${NC}"
    exit 1
fi
domain=$(cat /root/domain)
echo "$domain" > /etc/xray/domain

systemctl enable cron >/dev/null 2>&1
systemctl restart cron >/dev/null 2>&1

# Install ACME & SSL
if [ ! -f ~/.acme.sh/acme.sh ]; then
    echo -e "${GREEN}🔐 Menginstall acme.sh...${NC}"
    curl -sS https://get.acme.sh | sh -s email=admin@$domain >/dev/null 2>&1
fi
chmod +x ~/.acme.sh/acme.sh
~/.acme.sh/acme.sh --set-default-ca --server letsencrypt >/dev/null 2>&1
~/.acme.sh/acme.sh --register-account -m admin@$domain >/dev/null 2>&1 || true

echo -e "${GREEN}🛑 Freeing Port 80...${NC}"
systemctl stop nginx >/dev/null 2>&1 || true
fuser -k 80/tcp >/dev/null 2>&1 || true

echo -e "${GREEN}🚀 Issuing SSL Certificate...${NC}"
~/.acme.sh/acme.sh --issue -d "$domain" --standalone --keylength ec-256 --force >/dev/null 2>&1 || {
    echo -e "${RED}[ERROR] Gagal mendapatkan SSL certificate!${NC}"
    exit 1
}

~/.acme.sh/acme.sh --install-cert -d "$domain" --ecc --key-file /etc/xray/private.key --fullchain-file /etc/xray/cert.crt >/dev/null 2>&1 || {
    echo -e "${RED}[ERROR] Gagal memasang certificate!${NC}"
    exit 1
}

chmod 600 /etc/xray/private.key
chmod 644 /etc/xray/cert.crt

# XRAY Config
cp "$BASE_DIR/config/xray.json" /etc/xray/config.json
cp "$BASE_DIR/config/xray.conf" /etc/nginx/conf.d/xray.conf
chmod 644 /etc/xray/config.json
chmod 644 /etc/nginx/conf.d/xray.conf

cat > /etc/systemd/system/xray.service <<EOF
[Unit]
Description=Xray Service
Documentation=https://xray.dev/
After=network.target nss-lookup.target

[Service]
User=root
NoNewPrivileges=true
ExecStart=/usr/local/bin/xray -config /etc/xray/config.json
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

echo -e "${GREEN}🧪 Testing Configs...${NC}" 
nginx -t >/dev/null 2>&1 || { echo -e "${RED}[ERROR] Invalid NGINX config!${NC}"; exit 1; }
xray -test -config /etc/xray/config.json >/dev/null 2>&1 || { echo -e "${RED}[ERROR] Invalid XRAY config!${NC}"; exit 1; }

systemctl daemon-reload >/dev/null 2>&1
systemctl enable xray >/dev/null 2>&1
systemctl restart xray >/dev/null 2>&1
systemctl restart nginx >/dev/null 2>&1

sleep 2 
if ! systemctl is-active --quiet xray; then echo -e "${RED}[ERROR] XRAY gagal berjalan!${NC}"; exit 1; fi 
if ! systemctl is-active --quiet nginx; then echo -e "${RED}[ERROR] NGINX gagal berjalan!${NC}"; exit 1; fi

cat >> /root/log-install.txt <<EOF
━━━━━━━━━━━━━━━━━━━━━━
XRAY PANEL
━━━━━━━━━━━━━━━━━━━━━━
XRAY VMess TLS      : 443
XRAY VMess None TLS : 80
XRAY VMess gRPC     : 443
XRAY VLESS TLS      : 443
XRAY VLESS None TLS : 80
XRAY VLESS gRPC     : 443
XRAY Trojan TLS     : 443
XRAY Trojan gRPC    : 443
XRAY SS WS TLS      : 443
XRAY SS WS None TLS : 80
XRAY SS WS gRPC     : 443
━━━━━━━━━━━━━━━━━━━━━━
EOF

clear
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ XRAY INSTALLED SUCCESSFULLY${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "Domain        : ${domain}"
echo -e "XRAY Config   : /etc/xray/config.json"
echo -e "NGINX Config  : /etc/nginx/conf.d/xray.conf"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n${NC}"