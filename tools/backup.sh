#!/bin/bash
# ==========================================
# BACKUP & RESTORE TOOLS (Refactored)
# ==========================================

clear
GREEN='\e[1;32m'
YELLOW='\e[1;33m'
CYAN='\e[1;36m'
RED='\e[1;31m'
NC='\e[0m'

BACKUP_DIR="/root/backup-autoscript"
ZIP_FILE="/root/backup-autoscript.zip"

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}            🔄 BACKUP & RESTORE TOOLS          ${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}[1]${NC} Backup Data VPN"
echo -e "${GREEN}[2]${NC} Restore Data VPN"
echo -e "${GREEN}[x]${NC} Kembali ke Menu Tools"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
read -rp "👉 Pilih opsi: " opt

# Memastikan zip & unzip terpasang secara senyap
if ! command -v zip >/dev/null 2>&1 || ! command -v unzip >/dev/null 2>&1; then
    apt-get install zip unzip -y >/dev/null 2>&1
fi

case $opt in
1)
    echo -e "\n📦 Sedang mengumpulkan berkas data penting..."
    rm -rf "$BACKUP_DIR" "${ZIP_FILE}" >/dev/null 2>&1
    mkdir -p "$BACKUP_DIR/xray" "$BACKUP_DIR/zivpn" "$BACKUP_DIR/wireguard" "$BACKUP_DIR/accounts"

    # Menyalin data esensial saja (Bukan folder /usr/bin/* sistem OS!)
    [[ -f /etc/xray/config.json ]] && cp /etc/xray/config.json "$BACKUP_DIR/xray/"
    [[ -f /etc/xray/domain ]] && cp /etc/xray/domain "$BACKUP_DIR/xray/"
    [[ -f /etc/xray/vmess.db ]] && cp /etc/xray/*.db "$BACKUP_DIR/xray/"
    [[ -f /etc/zivpn/users.db ]] && cp /etc/zivpn/users.db "$BACKUP_DIR/zivpn/"
    [[ -f /etc/wireguard/wg0.conf ]] && cp /etc/wireguard/wg0.conf "$BACKUP_DIR/wireguard/"
    [[ -d /root/accounts ]] && cp -r /root/accounts/* "$BACKUP_DIR/accounts/" 2>/dev/null
    [[ -f /root/log-install.txt ]] && cp /root/log-install.txt "$BACKUP_DIR/"

    cd /root || exit
    zip -r backup-autoscript.zip backup-autoscript >/dev/null 2>&1
    rm -rf "$BACKUP_DIR"

    clear
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✅ PROSES BACKUP SELESAI Sempurna!${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "📁 Berkas Cadangan : ${YELLOW}${ZIP_FILE}${NC}"
    echo -e "💡 Amankan berkas ZIP ini ke PC/HP kamu untuk cadangan."
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    read -n 1 -s -r -p "Tekan apa saja untuk melanjutkan..."
    exec bash "$0"
    ;;
2)
    read -rp "🗂 Masukkan jalur tempat berkas ZIP cadangan disimpan (Contoh: /root/backup-autoscript.zip): " path
    if [[ -z "$path" ]]; then
        echo -e "\n${RED}❌ Jalur berkas tidak boleh kosong!${NC}"
        exit 1
    fi
    
    if [[ -f "$path" ]]; then
        echo -e "\n🔄 Memulai ekstraksi dan pemulihan sistem..."
        unzip -o "$path" -d /root/ >/dev/null 2>&1
        
        # Proses Restorasi data secara presisi ke jalurnya masing-masing
        mkdir -p /etc/xray /etc/zivpn /etc/wireguard /root/accounts
        
        [[ -f /root/backup-autoscript/xray/config.json ]] && cp /root/backup-autoscript/xray/config.json /etc/xray/
        [[ -f /root/backup-autoscript/xray/domain ]] && cp /root/backup-autoscript/xray/domain /etc/xray/
        [[ -f /root/backup-autoscript/xray/vmess.db ]] && cp /root/backup-autoscript/xray/*.db /etc/xray/ 2>/dev/null
        [[ -f /root/backup-autoscript/zivpn/users.db ]] && cp /root/backup-autoscript/zivpn/users.db /etc/zivpn/
        [[ -f /root/backup-autoscript/wireguard/wg0.conf ]] && cp /root/backup-autoscript/wireguard/wg0.conf /etc/wireguard/
        [[ -d /root/backup-autoscript/accounts ]] && cp -r /root/backup-autoscript/accounts/* /root/accounts/ 2>/dev/null
        [[ -f /root/backup-autoscript/log-install.txt ]] && cp /root/backup-autoscript/log-install.txt /root/
        
        rm -rf /root/backup-autoscript
        
        # Refresh seluruh layanan pendukung sistem VPN
        systemctl reload xray nginx >/dev/null 2>&1
        systemctl restart wg-quick@wg0 zivpn >/dev/null 2>&1
        
        echo -e "\n${GREEN}✅ Pemulihan data selesai dengan sukses! Seluruh layanan aktif kembali.${NC}\n"
    else
        echo -e "\n${RED}❌ Berkas ZIP cadangan tidak ditemukan di lokasi tersebut!${NC}\n"
    fi
    read -n 1 -s -r -p "Tekan apa saja untuk melanjutkan..."
    exec bash "$0"
    ;;
x)
    tools-menu
    ;;
*)
    echo -e "${RED}❌ Pilihan salah!${NC}"
    sleep 1
    exec bash "$0"
    ;;
esac