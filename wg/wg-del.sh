#!/bin/bash
# ==========================================
# DELETE WIREGUARD ACCOUNT (Refactored)
# ==========================================

clear
CYAN='\e[1;36m'
GREEN='\e[1;32m'
YELLOW='\e[1;33m'
RED='\e[1;31m'
NC='\e[0m'
WG_CONF="/etc/wireguard/wg0.conf"

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}    DELETE WIREGUARD USER${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Tampilkan Daftar User WireGuard
echo -e "\n${YELLOW}📋 List User WireGuard:${NC}\n"
users=$(grep "^# " "$WG_CONF" | grep -v "wg0" | sed 's/# //g')

if [[ -z "$users" ]]; then
    echo -e "${RED}❌ Tidak ada user WireGuard yang terdaftar!${NC}"
    echo ""
    read -n 1 -s -r -p "Tekan apa saja untuk kembali..."
    m-wg
    exit 0
fi

num=1
for user in $users; do
    printf "${GREEN}[%s]${NC} %s\n" "$num" "$user"
    ((num++))
done

echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
read -rp "👉 Masukkan username yang ingin dihapus: " target_user

if [[ -z "$target_user" ]]; then
    echo -e "\n${RED}❌ Username tidak boleh kosong!${NC}"
    exit 1
fi

# Validasi apakah user ada di file config
if ! grep -q "^# $target_user$" "$WG_CONF"; then
    echo -e "\n${RED}❌ User '$target_user' tidak ditemukan!${NC}"
    sleep 2
    exec "$0"
fi

# Proses hapus 4 baris config yang mengikutinya
sed -i "/^# $target_user$/,/^AllowedIPs/d" "$WG_CONF"
rm -f "/etc/wireguard/clients/${target_user}.conf" "/etc/wireguard/clients/${target_user}.png"

systemctl restart wg-quick@wg0

echo -e "\n${GREEN}✅ Akun WireGuard '$target_user' berhasil dihapus secara permanen!${NC}\n"

read -n 1 -s -r -p "Tekan apa saja untuk kembali ke menu..."
m-wg