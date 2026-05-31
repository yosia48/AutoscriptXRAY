#!/bin/bash
# ==========================================
# Install Nginx Reverse Proxy (Refactored)
# ==========================================

GREEN='\e[0;32m'
RED='\e[0;31m'
NC='\e[0m'
BASE_DIR="/root/AutoscriptXRAY"

if [[ ! -d "$BASE_DIR" ]]; then
    echo -e "${RED}[ERROR] Folder repository $BASE_DIR tidak ditemukan!${NC}"
    exit 1
fi

clear
echo -e "${GREEN}▶️ Installing NGINX Reverse Proxy (Silent Mode)...${NC}"

# Silent Install Nginx
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq >/dev/null 2>&1
apt-get install -qq -y nginx curl wget >/dev/null 2>&1

# Hapus config default
rm -f /etc/nginx/sites-enabled/default
rm -f /etc/nginx/sites-available/default
mkdir -p /etc/nginx/conf.d

# Copy konfigurasi Nginx yang sudah dirombak
if [[ ! -f "$BASE_DIR/config/nginx.conf" ]]; then
    echo -e "${RED}[ERROR] File nginx.conf tidak ditemukan di $BASE_DIR/config!${NC}"
    exit 1
fi

cp "$BASE_DIR/config/nginx.conf" /etc/nginx/nginx.conf
chmod 644 /etc/nginx/nginx.conf

# Test & Enable
nginx -t >/dev/null 2>&1 || {
    echo -e "${RED}❌ Nginx config error! Cek kembali file nginx.conf${NC}"
    exit 1
}

systemctl enable nginx >/dev/null 2>&1
systemctl restart nginx >/dev/null 2>&1

if ! systemctl is-active --quiet nginx; then
    echo -e "${RED}[ERROR] NGINX gagal berjalan!${NC}"
    exit 1
fi

clear
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ NGINX INSTALLED SUCCESSFULLY${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "Main Config   : /etc/nginx/nginx.conf"
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"