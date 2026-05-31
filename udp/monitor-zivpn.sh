#!/bin/bash
# ==========================================
# MONITOR ONLINE ZIVPN USER (Refactored)
# ==========================================

clear
RED='\e[0;31m'
GREEN='\e[0;32m'
CYAN='\e[0;36m'
WHITE='\e[1;37m'
NC='\e[0m'
LOG_FILE="/tmp/zivpn-monitor.log"

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}             ONLINE ZIVPN USER                ${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n${NC}"

if ! systemctl is-active --quiet zivpn; then
    echo -e "${RED}❌ ZIVPN service is not running!${NC}\n"
    read -n 1 -s -r -p "Tekan apa saja untuk kembali..."
    m-zivpn
    exit 1
fi

# Meredam error dari perintah 'ss'
ss -unap 2>/dev/null | grep -w "zivpn" | awk '{print $5}' | cut -d':' -f1 | sort -u > "$LOG_FILE"

TOTAL=$(wc -l < "$LOG_FILE")

if [[ $TOTAL -eq 0 ]]; then
    echo -e "${RED}❌ Tidak ada user ZIVPN yang online!${NC}\n"
    rm -f "$LOG_FILE"
    read -n 1 -s -r -p "Tekan apa saja untuk kembali..."
    m-zivpn
    exit 0
fi

printf "${WHITE} %-5s %-25s${NC}\n" "NO" "IP ADDRESS"
echo -e "${CYAN}----------------------------------------------${NC}"

NO=1
while read -r ip; do
    [[ -z "$ip" ]] && continue
    printf " %-5s %-25s\n" "$NO" "$ip"
    ((NO++))
done < "$LOG_FILE"

echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${WHITE}Total Online${NC} : ${GREEN}${TOTAL} User${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

rm -f "$LOG_FILE"
read -n 1 -s -r -p "Tekan apa saja untuk kembali ke menu..."
m-zivpn