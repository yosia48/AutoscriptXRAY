#!/bin/bash
# ==========================================
# CEK LOGIN VLESS USER (Refactored)
# ==========================================

clear
BLUE='\e[0;34m'
GREEN='\e[0;32m'
RED='\e[0;31m'
CYAN='\e[0;36m'
WHITE='\e[1;37m'
NC='\e[0m'

LOG="/var/log/xray/access.log"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "\E[44;1;39m             CEK LOGIN VLESS USER             \E[0m"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

if [[ ! -f "$LOG" ]]; then
    echo -e "${RED}❌ File log Xray tidak ditemukan!${NC}"
    read -n 1 -s -r -p "Tekan apa saja untuk kembali..."
    m-vless
    exit 0
fi

printf "${CYAN}%-20s %-20s${NC}\n" "USERNAME" "IP CLIENT"
echo -e "${BLUE}----------------------------------------------${NC}"

active_log=$(tail -n 10000 "$LOG" | grep -w "accepted" | grep -iE 'email:.*')

if [[ -z "$active_log" ]]; then
    echo -e "${RED}Belum ada user Vless yang online / terekam.${NC}"
else
    users=$(echo "$active_log" | awk -F'email: ' '{print $2}' | awk '{print $1}' | sort -u)
    
    for user in $users; do
        if grep -qw "^${user}" /etc/xray/vless.db 2>/dev/null; then
            ips=$(echo "$active_log" | grep "email: ${user}" | awk '{print $3}' | cut -d: -f1 | sort -u | grep -v "127.0.0.1")
            
            for ip in $ips; do
                printf "${GREEN}%-20s${NC} %-20s\n" "$user" "$ip"
            done
        fi
    done
fi

echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
read -n 1 -s -r -p "Tekan apa saja untuk kembali ke menu..."
m-vless