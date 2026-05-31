#!/bin/bash
# ==========================================
# GANTI DOMAIN XRAY (Refactored)
# ==========================================

clear
CYAN='\e[1;36m'
GREEN='\e[1;32m'
YELLOW='\e[1;33m'
RED='\e[1;31m'
NC='\e[0m'

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}               🌐 GANTI DOMAIN XRAY           ${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

read -rp "📌 Masukkan domain baru: " new_domain

if [[ -z "$new_domain" ]]; then
    echo -e "\n${RED}❌ Domain tidak boleh kosong!${NC}\n"
    exit 1
fi

# Simpan data domain baru ke sistem
echo "$new_domain" > /etc/xray/domain

# Melakukan live reload penyegaran konfigurasi
systemctl reload xray nginx >/dev/null 2>&1

echo -e "\n${GREEN}✅ Data catatan domain berhasil diubah!${NC}"
echo -e "🌐 Domain Baru : ${CYAN}$new_domain${NC}"
echo -e "${YELLOW}⚠️  PENTING: Jangan lupa jalankan ulang instalasi sertifikat SSL (install/xray.sh)${NC}"
echo -e "${YELLOW}   agar sertifikat SSL domain baru kamu diterbitkan oleh LetsEncrypt!${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

read -n 1 -s -r -p "Tekan apa saja untuk kembali..."
tools-menu