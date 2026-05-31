#!/bin/bash
# ==========================================
# ADD SHADOWSOCKS WS ACCOUNT (Refactored)
# ==========================================

clear
CYAN='\e[1;36m'
GREEN='\e[1;32m'
YELLOW='\e[1;33m'
RED='\e[1;31m'
WHITE='\e[1;37m'
NC='\e[0m'

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${WHITE}      ADD SHADOWSOCKS ACCOUNT      ${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Ambil informasi domain & port
domain=$(cat /etc/xray/domain)
port_tls="443"
port_none="80"
port_grpc="443"

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

cipher="aes-128-gcm"
uuid=$(cat /proc/sys/kernel/random/uuid)
exp=$(date -d "$masaaktif days" +"%Y-%m-%d")
tmpfile=$(mktemp)

# Inject konfigurasi Shadowsocks TLS, Non-TLS, dan GRPC sekaligus
jq --arg uuid "$uuid" --arg user "$user" --arg method "$cipher" '
(.inbounds[] | select(.tag=="ssws-ws-tls").settings.clients) += [{"password":$uuid,"method":$method,"email":$user}] |
(.inbounds[] | select(.tag=="ssws-ws-nontls").settings.clients) += [{"password":$uuid,"method":$method,"email":$user}] |
(.inbounds[] | select(.tag=="ssws-grpc").settings.clients) += [{"password":$uuid,"method":$method,"email":$user}]
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
echo "${user} ${exp} ${uuid}" >> /etc/xray/ssws.db

# Encode Password & Generate Link
ss_base64=$(echo -n "${cipher}:${uuid}" | base64 -w 0)
sslink1="ss://${ss_base64}@${domain}:${port_tls}?plugin=xray-plugin%3Bpath%3D%2Fss-ws%3Bhost%3D${domain}%3Btls#${user}"
sslink2="ss://${ss_base64}@${domain}:${port_none}?plugin=xray-plugin%3Bpath%3D%2Fss-ws%3Bhost%3D${domain}#${user}"
sslink3="ss://${ss_base64}@${domain}:${port_grpc}?plugin=xray-plugin%3Bmode%3Dgun%3BserviceName%3Dss-grpc%3Bhost%3D${domain}%3Btls#${user}"

clear
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}        Shadowsocks ACCOUNT        ${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "Remarks       : ${WHITE}${user}${NC}"
echo -e "Domain        : ${WHITE}${domain}${NC}"
echo -e "Port TLS      : ${WHITE}${port_tls}${NC}"
echo -e "Port No TLS   : ${WHITE}${port_none}${NC}"
echo -e "Port gRPC     : ${WHITE}${port_grpc}${NC}"
echo -e "Password      : ${WHITE}${uuid}${NC}"
echo -e "Cipher        : ${WHITE}${cipher}${NC}"
echo -e "Network       : ws / grpc"
echo -e "Path          : /ss-ws"
echo -e "ServiceName   : ss-grpc"
echo -e "Expired On    : ${WHITE}${exp}${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "Link TLS      : \n${YELLOW}${sslink1}${NC}\n"
echo -e "Link None TLS : \n${YELLOW}${sslink2}${NC}\n"
echo -e "Link gRPC     : \n${YELLOW}${sslink3}${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo ""
echo "Database User : /etc/xray/ssws.db"
echo ""

read -n 1 -s -r -p "Press any key to back on menu"
m-ssws