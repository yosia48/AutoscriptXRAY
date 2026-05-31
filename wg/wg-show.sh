#!/bin/bash
# ==========================================
# CEK AKUN AKTIF WIREGUARD (Refactored)
# ==========================================

clear
CYAN='\e[0;36m'
GREEN='\e[0;32m'
NC='\e[0m'

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}          DAFTAR AKUN AKTIF WIREGUARD         ${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n${NC}"

wg show wg0

echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
read -n 1 -s -r -p "Tekan apa saja untuk kembali ke menu..."
m-wg