#!/bin/bash
# ==========================================
# TRIAL ZIVPN USER (Refactored)
# ==========================================

DB="/etc/zivpn/users.db"
clear
RED='\e[0;31m'
GREEN='\e[0;32m'
YELLOW='\e[1;33m'
CYAN='\e[0;36m'
WHITE='\e[1;37m'
NC='\e[0m'

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}             TRIAL ZIVPN USER                 ${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

USER="trial$(tr -dc a-z0-9 </dev/urandom | head -c4)"
while grep -qw "^$USER" "$DB"; do
    USER="trial$(tr -dc a-z0-9 </dev/urandom | head -c4)"
done

DAYS=1
EXP=$(date -d "$DAYS days" +"%Y-%m-%d")

echo "$USER $EXP" >> "$DB"

# Rebuild config ZIVPN 
bash /root/AutoscriptXRAY/udp/rebuild-config.sh

DOMAIN=$(cat /etc/xray/domain 2>/dev/null || curl -s ipv4.icanhazip.com)

clear
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}             TRIAL ZIVPN ACCOUNT              ${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n${NC}"

printf " ${WHITE}Username${NC}    : %s\n" "$USER"
printf " ${WHITE}Password${NC}    : %s\n" "$USER"
printf " ${WHITE}Host/IP${NC}     : %s\n" "$DOMAIN"
printf " ${WHITE}UDP Port${NC}    : 5667\n"
printf " ${WHITE}Protocol${NC}    : UDP\n"
printf " ${WHITE}OBFS${NC}        : zivpn\n"
printf " ${WHITE}Expired On${NC}  : %s (1 Hari)\n" "$EXP"

echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
echo -e "${YELLOW}📱 ZIVPN CLIENT CONFIG${NC}\n"
echo -e " Host      : ${DOMAIN}"
echo -e " Password  : ${USER}"
echo -e " UDP Mode  : ON"
echo -e " TLS       : ON"
echo -e " OBFS      : zivpn"
echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

read -n 1 -s -r -p "Press any key to back menu..."
m-zivpn