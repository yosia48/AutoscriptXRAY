#!/bin/bash
# ==========================================
# SPEEDTEST VPS (Refactored)
# ==========================================

GREEN='\e[1;32m'
CYAN='\e[1;36m'
YELLOW='\e[1;33m'
RED='\e[1;31m'
NC='\e[0m'

clear
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}               🌐 SPEEDTEST VPS               ${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if ! command -v speedtest &> /dev/null && ! command -v speedtest-cli &> /dev/null; then
    echo -e "${YELLOW}⚠️  Aplikasi penguji belum terpasang, memasang modul pendukung...${NC}"
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq >/dev/null 2>&1
    apt-get install speedtest-cli -qq -y >/dev/null 2>&1
fi

echo -e "${CYAN}🚀 Sedang mengukur performa jaringan VPS... Mohon tunggu...${NC}\n"

if command -v speedtest-cli &> /dev/null; then
    speedtest-cli --simple
elif command -v speedtest &> /dev/null; then
    speedtest --simple
else
    echo -e "${RED}❌ Gagal mengeksekusi pengujian jaringan!${NC}"
fi

echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✔️  Pengujian selesai dengan sukses.${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

read -n 1 -s -r -p "Tekan apa saja untuk kembali..."
tools-menu