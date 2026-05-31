#!/bin/bash
# ==========================================
# STATUS LAYANAN AKTIF (Refactored)
# ==========================================

NC='\e[0m'
GREEN='\e[1;32m'
RED='\e[1;31m'
YELLOW='\e[1;33m'
CYAN='\e[1;36m'
WHITE='\e[1;37m'

clear
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}            📡 STATUS LAYANAN AKTIF           ${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
printf "${WHITE} %-20s : %s${NC}\n" "NAMA LAYANAN" "STATUS OPERASIONAL"
echo -e "${YELLOW}----------------------------------------------${NC}"

services=(
    "ssh"
    "dropbear"
    "ws-dropbear"
    "ws-stunnel"
    "xray"
    "nginx"
    "stunnel4"
    "wg-quick@wg0"
    "zivpn"
    "udp-custom"
    "udpgw"
)

for svc in "${services[@]}"; do
    if systemctl is-active --quiet "$svc" 2>/dev/null; then
        status="${GREEN}🟢 ONLINE${NC}"
    else
        status="${RED}🔴 OFFLINE${NC}"
    fi
    printf " %-20s : %b\n" "$svc" "$status"
done

echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
read -n 1 -r -p "⏎ Tekan sembarang tombol untuk kembali..."
tools-menu