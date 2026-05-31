#!/bin/bash
# ==========================================
# RENEW TROJAN ACCOUNT (Refactored)
# ==========================================

clear
BLUE='\e[0;34m'
GREEN='\e[0;32m'
RED='\e[0;31m'
CYAN='\e[0;36m'
WHITE='\e[1;37m'
NC='\e[0m'
DB="/etc/xray/trojan.db"
TEMP="/tmp/renew.tmp"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "\E[44;1;39m            PERPANJANG AKUN TROJAN            \E[0m"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [[ ! -s "$DB" ]]; then
    echo -e "\n${RED}❌ Tidak ada user Trojan yang terdaftar!${NC}"
    read -n 1 -s -r -p "Tekan apa saja untuk kembali..."
    m-trojan
    exit 0
fi

echo -e "\n${CYAN}📋 Daftar User Trojan:${NC}\n"
printf "${WHITE} %-5s %-18s %-15s${NC}\n" "NO" "USERNAME" "EXPIRED"
echo -e "${CYAN}----------------------------------------------${NC}"

NO=1
while read -r user exp uuid; do
    [[ -z "$user" ]] && continue
    printf " %-5s %-18s %-15s\n" "$NO" "$user" "$exp"
    ((NO++))
done < "$DB"

echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
read -rp "👉 Masukkan username yang ingin diperpanjang: " target_user

if [[ -z "$target_user" ]]; then
    echo -e "\n${RED}❌ Username tidak boleh kosong!${NC}"
    exit 1
fi

if ! grep -qw "^$target_user " "$DB"; then
    echo -e "\n${RED}❌ User '$target_user' tidak ditemukan!${NC}"
    sleep 2
    exec "$0"
fi

read -rp "👉 Tambahkan masa aktif (hari): " days
if ! [[ "$days" =~ ^[0-9]+$ ]]; then
    echo -e "\n${RED}❌ Jumlah hari harus berupa angka!${NC}"
    exit 1
fi

old_exp=$(grep "^$target_user " "$DB" | awk '{print $2}')
today=$(date +%s)
old_exp_ts=$(date -d "$old_exp" +%s)

if [[ $old_exp_ts -lt $today ]]; then
    new_exp=$(date -d "$days days" +"%Y-%m-%d")
else
    new_exp=$(date -d "$old_exp +$days days" +"%Y-%m-%d")
fi

awk -v user="$target_user" -v exp="$new_exp" '{
    if ($1 == user) { print $1, exp, $3 } else { print }
}' "$DB" > "$TEMP"
mv "$TEMP" "$DB"

clear
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "\E[44;1;39m          AKUN BERHASIL DIPERPANJANG          \E[0m"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "\n User       : ${GREEN}$target_user${NC}"
echo -e " Sisa Awal  : ${RED}$old_exp${NC}"
echo -e " Expired    : ${GREEN}$new_exp${NC}"
echo -e " Ditambah   : ${YELLOW}$days Hari${NC}\n"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

read -n 1 -s -r -p "Tekan apa saja untuk kembali..."
m-trojan