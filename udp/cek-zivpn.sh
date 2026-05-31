#!/bin/bash
# ==========================================
# CHECK ZIVPN USER (Refactored)
# ==========================================

clear
RED='\e[0;31m'
GREEN='\e[0;32m'
YELLOW='\e[1;33m'
CYAN='\e[0;36m'
WHITE='\e[1;37m'
NC='\e[0m'
DB="/etc/zivpn/users.db"

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}                 ZIVPN MEMBER${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

if [[ ! -s "$DB" ]]; then
    echo -e "${RED}❌ Tidak ada user ZIVPN yang terdaftar!${NC}\n"
    read -n 1 -s -r -p "Tekan apa saja untuk kembali..."
    m-zivpn
    exit 0
fi

printf "${WHITE} %-5s %-20s %-15s %-10s${NC}\n" "NO" "USERNAME" "EXPIRED" "STATUS"
echo -e "${CYAN}----------------------------------------------${NC}"

NO=1
while read -r user exp; do
    [[ -z "$user" ]] && continue
    
    exp_ts=$(date -d "$exp" +%s 2>/dev/null)
    now_ts=$(date +%s)
    
    if [[ $now_ts -gt $exp_ts ]]; then
        STATUS="${RED}EXPIRED${NC}"
    else
        STATUS="${GREEN}ACTIVE${NC}"
    fi
    
    printf " %-5s %-20s %-15s %-10b\n" "$NO" "$user" "$exp" "$STATUS"
    ((NO++))
done < "$DB"

echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
TOTAL=$(grep -vc '^$' "$DB")
echo -e "${WHITE}Total Users Terdaftar${NC} : ${GREEN}${TOTAL}${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

read -n 1 -s -r -p "Press any key to back menu..."
m-zivpn