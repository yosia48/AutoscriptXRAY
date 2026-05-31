#!/bin/bash
# ==========================================
# ADD ZIVPN USER (Refactored)
# ==========================================

DB="/etc/zivpn/users.db"
clear
RED='\e[1;31m'
GREEN='\e[1;32m'
YELLOW='\e[1;33m'
CYAN='\e[1;36m'
WHITE='\e[1;37m'
NC='\e[0m'

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}       ADD ZIVPN USER${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Input & Validasi User
read -rp "Username       : " user
if [[ -z "$user" ]]; then
    echo -e "${RED}Username cannot be empty!${NC}"
    exit 1
fi

if grep -wq "^$user" "$DB"; then
    echo -e "\n${RED}User '$user' already exists!${NC}"
    exit 1
fi

read -rp "Expired (days) : " days
if ! [[ "$days" =~ ^[0-9]+$ ]]; then
    echo -e "\n${RED}Invalid days format!${NC}"
    exit 1
fi

exp=$(date -d "$days days" +"%Y-%m-%d")

# Simpan User ke Database
echo "$user $exp" >> "$DB"

# Rebuild Config ZIVPN
bash /root/AutoscriptXRAY/udp/rebuild-config.sh

DOMAIN=$(cat /etc/xray/domain 2>/dev/null || curl -s ipv4.icanhazip.com)

clear
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}       ZIVPN ACCOUNT${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
printf " ${WHITE}Username${NC}    : %s\n" "$user"
printf " ${WHITE}Expired On${NC}  : %s\n" "$exp"
printf " ${WHITE}Host/IP${NC}     : %s\n" "$DOMAIN"
printf " ${WHITE}UDP Port${NC}    : 5667\n"
printf " ${WHITE}Password${NC}    : %s\n" "$user"
printf " ${WHITE}Protocol${NC}    : UDP\n"
printf " ${WHITE}OBFS${NC}        : zivpn\n"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "\n${YELLOW}📱 ZIVPN CLIENT CONFIG${NC}"
echo -e " Host      : ${DOMAIN}"
echo -e " Password  : ${user}"
echo -e " UDP Mode  : ON"
echo -e " TLS       : ON"
echo -e " OBFS      : zivpn"
echo ""

read -n 1 -s -r -p "Press any key to back menu..."
m-zivpn