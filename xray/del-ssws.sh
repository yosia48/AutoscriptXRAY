#!/bin/bash
# ==========================================
# DELETE SHADOWSOCKS ACCOUNT (Refactored)
# ==========================================

clear
BLUE='\e[0;34m'
GREEN='\e[0;32m'
RED='\e[0;31m'
CYAN='\e[0;36m'
NC='\e[0m'
CONFIG="/etc/xray/config.json"
DB="/etc/xray/ssws.db"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "\E[44;1;39m          DELETE SHADOWSOCKS ACCOUNT          \E[0m"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "\n${CYAN}📋 List User Shadowsocks:${NC}\n"

users=$(jq -r '.inbounds[] | select(.tag=="ssws-ws-tls") | .settings.clients[].email' "$CONFIG" 2>/dev/null)

if [[ -z "$users" || "$users" == "null" ]]; then
    echo -e "${RED}❌ Tidak ada user Shadowsocks yang terdaftar!${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    read -n 1 -s -r -p "Tekan apa saja untuk kembali..."
    m-ssws
    exit 0
fi

num=1
for user in $users; do
    printf "${GREEN}[%s]${NC} %s\n" "$num" "$user"
    ((num++))
done

echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
read -rp "👉 Masukkan username yang ingin dihapus: " target_user

if [[ -z "$target_user" ]]; then
    echo -e "\n${RED}❌ Username tidak boleh kosong!${NC}"
    exit 1
fi

if ! echo "$users" | grep -qw "$target_user"; then
    echo -e "\n${RED}❌ User '$target_user' tidak ditemukan dalam daftar!${NC}"
    sleep 2
    exec "$0"
fi

tmpfile=$(mktemp)
jq --arg user "$target_user" '
(.inbounds[] | select(.tag=="ssws-ws-tls").settings.clients) |= map(select(.email != $user)) |
(.inbounds[] | select(.tag=="ssws-ws-nontls").settings.clients) |= map(select(.email != $user)) |
(.inbounds[] | select(.tag=="ssws-grpc").settings.clients) |= map(select(.email != $user))
' "$CONFIG" > "$tmpfile"

if [[ -s "$tmpfile" ]] && jq empty "$tmpfile" >/dev/null 2>&1; then
    cp "$CONFIG" "${CONFIG}.bak"
    mv "$tmpfile" "$CONFIG"
    
    sed -i "/^${target_user} /d" "$DB"
    systemctl reload xray
    
    echo -e "\n${GREEN}✅ User Shadowsocks '${target_user}' berhasil dihapus secara permanen!${NC}\n"
else
    echo -e "\n${RED}❌ Terjadi kesalahan saat memproses JSON!${NC}"
    rm -f "$tmpfile"
    exit 1
fi

read -n 1 -s -r -p "Tekan apa saja untuk kembali ke menu..."
m-ssws