#!/bin/bash
# ==========================================
# DELETE VMESS ACCOUNT (Refactored)
# ==========================================

clear
BLUE='\e[0;34m'
GREEN='\e[0;32m'
RED='\e[0;31m'
CYAN='\e[0;36m'
NC='\e[0m'
CONFIG="/etc/xray/config.json"
DB="/etc/xray/vmess.db"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "\E[44;1;39m             DELETE VMESS ACCOUNT             \E[0m"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "\n${CYAN}📋 List User VMess:${NC}\n"

# Ambil daftar user dari JSON (Lebih aman dari DB karena ini sumber aslinya)
users=$(jq -r '.inbounds[] | select(.tag=="vmess-ws-tls") | .settings.clients[].email' "$CONFIG" 2>/dev/null)

if [[ -z "$users" || "$users" == "null" ]]; then
    echo -e "${RED}❌ Tidak ada user VMess yang terdaftar!${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    read -n 1 -s -r -p "Tekan apa saja untuk kembali..."
    m-vmess
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

# Pengecekan apakah user yang diinput benar-benar ada
if ! echo "$users" | grep -qw "$target_user"; then
    echo -e "\n${RED}❌ User '$target_user' tidak ditemukan dalam daftar!${NC}"
    sleep 2
    exec "$0"
fi

# Proses Penghapusan menggunakan jq
tmpfile=$(mktemp)
jq --arg user "$target_user" '
(.inbounds[] | select(.tag=="vmess-ws-tls").settings.clients) |= map(select(.email != $user)) |
(.inbounds[] | select(.tag=="vmess-ws-nontls").settings.clients) |= map(select(.email != $user)) |
(.inbounds[] | select(.tag=="vmess-grpc").settings.clients) |= map(select(.email != $user))
' "$CONFIG" > "$tmpfile"

if [[ -s "$tmpfile" ]] && jq empty "$tmpfile" >/dev/null 2>&1; then
    cp "$CONFIG" "${CONFIG}.bak"
    mv "$tmpfile" "$CONFIG"
    
    # Hapus juga dari Database TXT
    sed -i "/^${target_user} /d" "$DB"
    
    # Live Refresh
    systemctl reload xray
    
    echo -e "\n${GREEN}✅ User VMess '${target_user}' berhasil dihapus secara permanen!${NC}\n"
else
    echo -e "\n${RED}❌ Terjadi kesalahan saat memproses JSON!${NC}"
    rm -f "$tmpfile"
    exit 1
fi

read -n 1 -s -r -p "Tekan apa saja untuk kembali ke menu..."
m-vmess