#!/bin/bash
# ==========================================
# SETUP SCRIPT XRAY_AIO (Refactored)
# XRAY + WireGuard + UDP ZIVPN
# ==========================================

cd "$(dirname "$0")" || exit
clear

# ================= COLOR =================
RED='\e[1;31m'
GREEN='\e[1;32m'
YELLOW='\e[1;33m'
BLUE='\e[1;34m'
CYAN='\e[1;36m'
WHITE='\e[1;37m'
NC='\e[0m'

# ================= FUNCTION =================
info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

start_time=$(date +%s)
echo "" > /root/log-install.txt

# ================= CHECK ROOT & VIRTUALIZATION =================
if [ "${EUID}" -ne 0 ]; then
    error "Script harus dijalankan sebagai root (sudo -i)."
    exit 1
fi

if [ "$(systemd-detect-virt)" == "openvz" ]; then
    error "OpenVZ tidak didukung oleh XRAY. Silakan gunakan VPS dengan KVM/VMWare."
    exit 1
fi

# ================= FIX /etc/hosts & TIMEZONE =================
localip=$(hostname -I | awk '{print $1}')
hostname=$(hostname)
if ! grep -qw "$hostname" /etc/hosts; then
    echo "$localip $hostname" >> /etc/hosts
fi

ln -fs /usr/share/zoneinfo/Asia/Jakarta /etc/localtime

# ================= CREATE REQUIRED FOLDERS =================
mkdir -p /etc/xray /etc/v2ray /var/lib
for file in domain scdomain; do
    touch "/etc/xray/$file" "/etc/v2ray/$file" "/root/$file"
done
touch /var/lib/ipvps.conf

# ================= UPDATE & INSTALL PACKAGE =================
info "Memperbarui sistem & memasang dependensi (Silent Mode)..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq >/dev/null 2>&1
apt-get install -qq -y curl wget git screen unzip bzip2 gzip coreutils python3 python3-pip iptables iptables-persistent netfilter-persistent vnstat openssl ufw jq psmisc zip >/dev/null 2>&1

kernelver=$(uname -r)
headerpkg="linux-headers-$kernelver"
if ! dpkg -s "$headerpkg" >/dev/null 2>&1; then
    info "Memasang $headerpkg..."
    apt-get install -qq -y "$headerpkg" >/dev/null 2>&1
fi

# ================= DOMAIN SETUP =================
clear
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}                 DOMAIN SETUP                 ${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

read -rp "👉 Masukkan domain VPS kamu : " domain
while [[ -z "$domain" ]]; do
    warn "Domain tidak boleh kosong!"
    read -rp "👉 Masukkan domain VPS kamu : " domain
done

echo "$domain" > /root/domain
for dfile in domain scdomain; do
    echo "$domain" > "/etc/xray/$dfile"
    echo "$domain" > "/etc/v2ray/$dfile"
    echo "$domain" > "/root/$dfile"
done
echo "IP=$domain" > /var/lib/ipvps.conf

echo -e "\n${GREEN}✅ Domain berhasil diset: ${WHITE}$domain${NC}\n"
sleep 2
clear

# ================= RUN INSTALLER =================
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}            MEMULAI INSTALASI INTI            ${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n${NC}"

info "Installing NGINX Reverse Proxy..."
bash install/nginx.sh || exit 1

info "Installing XRAY Core..."
bash install/xray.sh || exit 1

info "Installing SSH Websocket & UDPGW..."
bash install/ssh.sh || exit 1

info "Installing WireGuard..."
bash install/wg.sh || exit 1

info "Installing UDP ZIVPN..."
bash install/zivpn.sh || exit 1

# ================= COPY MENU & RUNTIME =================
info "Menyalin command menu ke sistem..."
cp -f ssh/m-ssh /usr/bin/
cp -f xray/m-vmess /usr/bin/
cp -f xray/m-vless /usr/bin/
cp -f xray/m-trojan /usr/bin/
cp -f xray/m-ssws /usr/bin/
cp -f wg/m-wg /usr/bin/
cp -f udp/m-zivpn /usr/bin/
cp -f tools/tools-menu /usr/bin/
cp -f tools/backup.sh /usr/bin/
cp -f tools/speedtest.sh /usr/bin/
cp -f tools/domain.sh /usr/bin/
cp -f tools/running.sh /usr/bin/
cp -f menu.sh /usr/bin/menu

chmod +x /usr/bin/menu /usr/bin/m-* /usr/bin/tools-menu /usr/bin/*.sh

info "Menyalin runtime engine ke /etc/autoscriptvpn/..."
mkdir -p /etc/autoscriptvpn/{ssh,xray,wg,udp,tools}
cp -r ssh/* /etc/autoscriptvpn/ssh/
cp -r xray/* /etc/autoscriptvpn/xray/
cp -r wg/* /etc/autoscriptvpn/wg/
cp -r udp/* /etc/autoscriptvpn/udp/
cp -r tools/* /etc/autoscriptvpn/tools/
chmod +x /etc/autoscriptvpn/*/*.sh

# ================= AUTO MENU LOGIN =================
# Ditulis ulang dengan (>) bukan (>>) agar tidak menumpuk kalau diinstall ulang
cat > /root/.profile <<-EOF
if [ "\$BASH" ]; then
    if [ -f ~/.bashrc ]; then
        . ~/.bashrc
    fi
fi
clear
menu
EOF
chmod 644 /root/.profile

# ================= CLEAN FILE =================
rm -f cf ins-xray.sh

# ================= FINISH =================
end_time=$(date +%s)
elapsed=$((end_time - start_time))

clear
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}             INSTALLATION DONE                ${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n${NC}"
echo -e " ${WHITE}SSH WS${NC}       : ${GREEN}INSTALLED${NC}"
echo -e " ${WHITE}XRAY${NC}         : ${GREEN}INSTALLED${NC}"
echo -e " ${WHITE}WireGuard${NC}    : ${GREEN}INSTALLED${NC}"
echo -e " ${WHITE}UDP ZIVPN${NC}    : ${GREEN}INSTALLED${NC}\n"
echo -e " ${WHITE}Waktu Instalasi${NC} : $((elapsed / 60)) menit $((elapsed % 60)) detik\n"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
echo -e "${YELLOW}♻️ VPS akan reboot otomatis dalam 10 detik...${NC}"
sleep 10
reboot