#!/bin/bash
# ==========================================
# UNINSTALL SCRIPT XRAY_AIO (Refactored)
# ==========================================

RED='\e[1;31m'
GREEN='\e[1;32m'
YELLOW='\e[1;33m'
CYAN='\e[1;36m'
WHITE='\e[1;37m'
NC='\e[0m'
BASE_DIR="/root/AutoscriptXRAY"

if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}[ERROR] Jalankan script ini sebagai root!${NC}"
    exit 1
fi

clear
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}          ⚠️ UNINSTALL AUTOSCRIPTXRAY ⚠️      ${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n${NC}"
echo -e "${RED}PERINGATAN: Proses ini akan MENGHAPUS SEMUA DATA VPN,${NC}"
echo -e "${RED}termasuk akun user, konfigurasi, dan file sistem Xray!${NC}\n"

read -rp "❗ Yakin ingin menghapus seluruh sistem? [y/N]: " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo -e "\n${GREEN}Pembatalan berhasil. Sistem tetap aman.${NC}"
    exit 1
fi

echo -e "\n${GREEN}[INFO]${NC} Menghentikan seluruh layanan aktif..."
services=(nginx xray dropbear ws-dropbear ws-stunnel udp-custom udpgw stunnel4 wg-quick@wg0 zivpn)
for svc in "${services[@]}"; do
    if systemctl list-unit-files | grep -q "^${svc}"; then
        systemctl stop "$svc" >/dev/null 2>&1 || true
        systemctl disable "$svc" >/dev/null 2>&1 || true
    fi
done

echo -e "${GREEN}[INFO]${NC} Menghapus service systemd..."
rm -f /etc/systemd/system/{xray,dropbear,ws-dropbear,ws-stunnel,udp-custom,udpgw,zivpn,acme*}.service
rm -f /etc/systemd/system/acme*.timer
systemctl daemon-reload >/dev/null 2>&1
systemctl daemon-reexec >/dev/null 2>&1

echo -e "${GREEN}[INFO]${NC} Menghapus binary sistem..."
rm -f /usr/local/bin/{xray,ws-dropbear,ws-stunnel,udp-custom,badvpn-udpgw,zivpn}

echo -e "${GREEN}[INFO]${NC} Membersihkan direktori & konfigurasi..."
rm -rf /etc/{xray,v2ray,zivpn,wireguard,autoscriptvpn,udp-custom}
rm -f /etc/nginx/conf.d/xray.conf
rm -f /etc/default/dropbear /etc/issue.net /etc/profile.d/no-login.sh
rm -f /root/{domain,scdomain,log-install.txt}
rm -f /etc/log-create-ssh.log
rm -rf /root/accounts

echo -e "${GREEN}[INFO]${NC} Menghapus command menu terminal..."
binaries=(menu m-ssh m-vmess m-vless m-trojan m-ssws m-wg m-zivpn tools-menu backup.sh speedtest.sh domain.sh running.sh)
for bin in "${binaries[@]}"; do
    rm -f "/usr/bin/$bin"
done

echo -e "${GREEN}[INFO]${NC} Menghapus akun Trial..."
awk -F: '/^trial/ {print $1}' /etc/passwd | while read -r user; do
    userdel -f "$user" >/dev/null 2>&1 || true
done

echo -e "${GREEN}[INFO]${NC} Membersihkan Crontab & SSL ACME..."
rm -f /etc/cron.d/xray /etc/cron.d/autoscript
[[ -d ~/.acme.sh ]] && rm -rf ~/.acme.sh

echo -e "${GREEN}[INFO]${NC} Meng-uninstall paket VPN (Silent Mode)..."
export DEBIAN_FRONTEND=noninteractive
apt-get purge -qq -y nginx dropbear stunnel4 wireguard wireguard-tools qrencode speedtest-cli >/dev/null 2>&1 || true
apt-get autoremove -qq -y >/dev/null 2>&1
apt-get clean >/dev/null 2>&1

echo -e "${GREEN}[INFO]${NC} Membersihkan sampah sementara (Temp)..."
rm -rf /tmp/{xray,badvpn,xray.zip}

echo -e "${GREEN}[INFO]${NC} Menghapus master source repository..."
rm -rf "$BASE_DIR"

clear
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}      ✅ AUTOSCRIPTXRAY BERHASIL DIHAPUS      ${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n${NC}"
echo -e " ${WHITE}NGINX${NC}        : ${RED}REMOVED${NC}"
echo -e " ${WHITE}XRAY${NC}         : ${RED}REMOVED${NC}"
echo -e " ${WHITE}SSH WS${NC}       : ${RED}REMOVED${NC}"
echo -e " ${WHITE}WireGuard${NC}    : ${RED}REMOVED${NC}"
echo -e " ${WHITE}UDP CUSTOM${NC}   : ${RED}REMOVED${NC}"
echo -e " ${WHITE}UDP ZIVPN${NC}    : ${RED}REMOVED${NC}\n"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
echo -e "${YELLOW}💡 Sangat disarankan untuk mereboot VPS kamu sekarang.${NC}"
echo -e "Ketik perintah: ${GREEN}reboot${NC}\n"