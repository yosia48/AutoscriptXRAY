#!/bin/bash
# ==========================================
# RENEW ZIVPN USER (Refactored)
# ==========================================

clear
RED='\e[1;31m'
GREEN='\e[1;32m'
YELLOW='\e[1;33m'
CYAN='\e[1;36m'
WHITE='\e[1;37m'
NC='\e[0m'
DB="/etc/zivpn/users.db"
TEMP="/tmp/zivpn-renew.tmp"

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}       RENEW ZIVPN USER${NC}"
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
read -rp "👉 Input Username : " target_user

if [[ -z "$target_user" ]]; then
    echo -e "\n${RED}❌ Username tidak boleh kosong!${NC}"
    exit 1
fi

if ! grep -wq "^$target_user" "$DB"; then
    echo -e "\n${RED}❌ User '$target_user' tidak ditemukan!${NC}"
    sleep 2
    exec "$0"
fi

read -rp "👉 Extend Days   : " days
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

# Update Database
awk -v user="$target_user" -v exp="$new_exp" '{
    if ($1 == user) { print $1, exp } else { print }
}' "$DB" > "$TEMP"
mv "$TEMP" "$DB"

# ZIVPN butuh rebuild config karena sistem kerjanya beda dengan Xray
bash /root/AutoscriptXRAY/udp/rebuild-config.sh

clear
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}        RENEW SUCCESS${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n${NC}"
echo -e " ${WHITE}Username${NC}    : $target_user"
echo -e " ${WHITE}Old Expired${NC} : ${RED}$old_exp${NC}"
echo -e " ${WHITE}New Expired${NC} : ${GREEN}$new_exp${NC}"
echo -e " ${WHITE}Extended${NC}    : ${YELLOW}$days Days${NC}\n"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

read -n 1 -s -r -p "Press any key to back menu..."
m-zivpn