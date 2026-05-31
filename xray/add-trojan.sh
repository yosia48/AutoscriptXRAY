#!/bin/bash
# ==========================================
# ADD TROJAN ACCOUNT (Refactored)
# ==========================================

clear
CYAN='\e[1;36m'
GREEN='\e[1;32m'
YELLOW='\e[1;33m'
RED='\e[1;31m'
WHITE='\e[1;37m'
NC='\e[0m'

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${WHITE}        ADD TROJAN ACCOUNT        ${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Ambil informasi domain & port
domain=$(cat /etc/xray/domain)
tls="443"
grpc="443"

# Input & Validasi Username
read -rp "Username : " user
if [[ -z "$user" || ! "$user" =~ ^[a-zA-Z0-9_]+$ ]]; then
    echo -e "\n${RED}❌ Username tidak valid atau kosong! Gunakan huruf/angka.${NC}"
    exit 1
fi

# Cek user duplikat
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

# Inject konfigurasi Trojan WS & GRPC sekaligus
jq --arg uuid "$uuid" --arg user "$user" '
(.inbounds[] | select(.tag=="trojan-ws-tls").settings.clients) += [{"password":$uuid,"email":$user}] |
(.inbounds[] | select(.tag=="trojan-grpc").settings.clients) += [{"password":$uuid,"email":$user}]
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

# Live Refresh Xray
systemctl reload xray

# Simpan ke Database
echo "${user} ${exp} ${uuid}" >> /etc/xray/trojan.db

# Generate Link Trojan
trojanlink1="trojan://${uuid}@${domain}:${tls}?path=%2Ftrojan-ws&security=tls&type=ws&host=${domain}&sni=${domain}#${user}"
trojanlink2="trojan://${uuid}@${domain}:${grpc}?mode=gun&security=tls&type=grpc&serviceName=trojan-grpc&sni=${domain}#${user}"

clear
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}        XRAY TROJAN ACCOUNT        ${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "Remarks        : ${WHITE}${user}${NC}"
echo -e "Domain         : ${WHITE}${domain}${NC}"
echo -e "Wildcard       : ${WHITE}(bug.com).${domain}${NC}"
echo -e "Port TLS       : ${WHITE}${tls}${NC}"
echo -e "Port gRPC      : ${WHITE}${grpc}${NC}"
echo -e "Password       : ${WHITE}${uuid}${NC}"
echo -e "Network        : ws / grpc"
echo -e "Path           : /trojan-ws"
echo -e "ServiceName    : trojan-grpc"
echo -e "Expired On     : ${WHITE}${exp}${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "Link TLS       : \n${YELLOW}${trojanlink1}${NC}\n"
echo -e "Link gRPC      : \n${YELLOW}${trojanlink2}${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

read -n 1 -s -r -p "Tekan apa saja untuk kembali ke menu..."
m-trojan