#!/bin/bash
# ==========================================
# ADD VLESS ACCOUNT (Refactored)
# ==========================================

clear
CYAN='\e[1;36m'
GREEN='\e[1;32m'
YELLOW='\e[1;33m'
RED='\e[1;31m'
WHITE='\e[1;37m'
NC='\e[0m'

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${WHITE}        ADD VLESS ACCOUNT        ${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Ambil informasi domain & port
domain=$(cat /etc/xray/domain)
tls="443"
none="80"
grpc="443"

# Input validasi Username
read -rp "Username : " user
if [[ -z "$user" || ! "$user" =~ ^[a-zA-Z0-9_]+$ ]]; then
    echo -e "\n${RED}❌ Username tidak valid atau kosong! Gunakan huruf/angka.${NC}"
    exit 1
fi

# Cek user duplikat (hanya butuh 1x cek ringan)
if jq -e ".inbounds[].settings.clients[] | select(.email == \"$user\")" /etc/xray/config.json > /dev/null; then
    echo -e "\n${RED}❌ User '$user' sudah ada di database!${NC}"
    exit 1
fi

read -rp "Expired (days): " masaaktif
if ! [[ "$masaaktif" =~ ^[0-9]+$ ]]; then
    echo -e "\n${RED}❌ Format hari tidak valid! Harus berupa angka.${NC}"
    exit 1
fi

uuid=$(cat /proc/sys/kernel/random/uuid)
exp=$(date -d "$masaaktif days" +"%Y-%m-%d")
tmpfile=$(mktemp)

# Inject semua konfigurasi (TLS, NonTLS, GRPC) dalam satu tarikan napas jq agar CPU ringan
jq --arg uuid "$uuid" --arg user "$user" '
(.inbounds[] | select(.tag=="vless-ws-tls").settings.clients) += [{"id":$uuid,"email":$user}] |
(.inbounds[] | select(.tag=="vless-ws-nontls").settings.clients) += [{"id":$uuid,"email":$user}] |
(.inbounds[] | select(.tag=="vless-grpc").settings.clients) += [{"id":$uuid,"email":$user}]
' /etc/xray/config.json > "$tmpfile"

if [[ ! -s "$tmpfile" ]] || ! jq empty "$tmpfile" >/dev/null 2>&1; then
    echo -e "\n${RED}❌ Gagal membuat konfigurasi (JSON Invalid/Kosong).${NC}"
    rm -f "$tmpfile"
    exit 1
fi

# Proses Timpa & Validasi
cp /etc/xray/config.json /etc/xray/config.json.bak
mv "$tmpfile" /etc/xray/config.json

# Test Konfigurasi XRAY
if ! xray -test -config /etc/xray/config.json >/dev/null 2>&1; then
    echo -e "\n${RED}❌ Konfigurasi Error! Mengembalikan backup...${NC}"
    mv /etc/xray/config.json.bak /etc/xray/config.json
    exit 1
fi

# Live Refresh Xray (Reload, bukan Restart agar user lain tidak disconnect)
systemctl reload xray

# Simpan ke Database
echo "${user} ${exp} ${uuid}" >> /etc/xray/vless.db

# Generate Link
vlesslink1="vless://${uuid}@${domain}:${tls}?encryption=none&security=tls&sni=${domain}&type=ws&host=${domain}&path=%2Fvless#${user}"
vlesslink2="vless://${uuid}@${domain}:${none}?encryption=none&type=ws&host=${domain}&path=%2Fvless#${user}"
vlesslink3="vless://${uuid}@${domain}:${grpc}?mode=gun&security=tls&encryption=none&type=grpc&serviceName=vless-grpc&sni=${domain}#${user}"

clear
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}        XRAY VLESS ACCOUNT        ${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "Remarks        : ${WHITE}${user}${NC}"
echo -e "Domain         : ${WHITE}${domain}${NC}"
echo -e "Wildcard       : ${WHITE}(bug.com).${domain}${NC}"
echo -e "Port TLS       : ${WHITE}${tls}${NC}"
echo -e "Port none TLS  : ${WHITE}${none}${NC}"
echo -e "Port gRPC      : ${WHITE}${grpc}${NC}"
echo -e "UUID           : ${WHITE}${uuid}${NC}"
echo -e "Encryption     : none"
echo -e "Network        : ws / grpc"
echo -e "Path           : /vless"
echo -e "ServiceName    : vless-grpc"
echo -e "Expired On     : ${WHITE}${exp}${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "Link TLS       : \n${YELLOW}${vlesslink1}${NC}\n"
echo -e "Link none TLS  : \n${YELLOW}${vlesslink2}${NC}\n"
echo -e "Link gRPC      : \n${YELLOW}${vlesslink3}${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

read -n 1 -s -r -p "Tekan apa saja untuk kembali ke menu..."
m-vless