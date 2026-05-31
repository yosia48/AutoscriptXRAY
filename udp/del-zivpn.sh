#!/bin/bash
# ==========================================
# DELETE ZIVPN USER (Refactored)
# ==========================================

clear
RED='\e[1;31m'
GREEN='\e[1;32m'
YELLOW='\e[1;33m'
CYAN='\e[1;36m'
WHITE='\e[1;37m'
NC='\e[0m'
DB="/etc/zivpn/users.db"

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}       DELETE ZIVPN USER${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n${NC}"

if [[ ! -s "$DB" ]]; then
    echo -e "${RED}❌ Tidak ada user ZIVPN yang terdaftar!${NC}\n"
    read -n 1 -s -r -p "Tekan apa saja untuk kembali..."
    m-zivpn
    exit 0
fi

printf "${WHITE} %-4s %-18s %-15s${NC}\n" "NO" "USERNAME" "EXPIRED"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

NO=1
while read -r user exp; do
    [[ -z "$user" ]] && continue
    printf " %-4s %-18s %-15s\n" "$NO" "$user" "$exp"
    ((NO++))
done < "$DB"

echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
read -rp "👉 Masukkan username yang ingin dihapus: " target_user

if [[ -z "$target_user" ]]; then
    echo -e "\n${RED}❌ Username tidak boleh kosong!${NC}"
    exit 1
fi

if ! grep -wq "^$target_user" "$DB"; then
    echo -e "\n${RED}❌ User '$target_user' tidak ditemukan!${NC}"
    sleep 2
    exec "$0"
fi

# Eksekusi Penghapusan
sed -i "/^$target_user /d" "$DB"

# Rebuild config ZIVPN tanpa restart total
bash /root/AutoscriptXRAY/udp/rebuild-config.sh

clear
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}       DELETE SUCCESS${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n${NC}"
echo -e " ${WHITE}Username${NC} : $target_user"
echo -e " ${WHITE}Status${NC}   : Deleted Successfully\n"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

read -n 1 -s -r -p "Tekan apa saja untuk kembali ke menu..."
m-zivpn