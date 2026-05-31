#!/bin/bash
# ==========================================
# ADD VMESS ACCOUNT (Refactored)
# ==========================================

clear
CYAN='\e[1;36m'
GREEN='\e[1;32m'
YELLOW='\e[1;33m'
RED='\e[1;31m'
WHITE='\e[1;37m'
NC='\e[0m'

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${WHITE}        ADD VMESS ACCOUNT        ${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Ambil informasi domain & port
domain=$(cat /etc/xray/domain)
tls="443"
none="80"
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

# Inject konfigurasi dalam satu tarikan napas jq agar CPU ringan
jq --arg uuid "$uuid" --arg user "$user" '
(.inbounds[] | select(.tag=="vmess-ws-tls").settings.clients) += [{"id":$uuid,"alterId":0,"email":$user}] |
(.inbounds[] | select(.tag=="vmess-ws-nontls").settings.clients) += [{"id":$uuid,"alterId":0,"email":$user}] |
(.inbounds[] | select(.tag=="vmess-grpc").settings.clients) += [{"id":$uuid,"alterId":0,"email":$user}]
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

# Live Refresh Xray (Reload agar user lain tidak dc)
systemctl reload xray

# Simpan ke Database
echo "${user} ${exp} ${uuid}" >> /etc/xray/vmess.db

# Generate Data JSON VMess
vmess_json_tls=$(cat <<EOF
{
  "v":"2",
  "ps":"${user}",
  "add":"${domain}",
  "port":"${tls}",
  "id":"${uuid}",
  "aid":"0",
  "net":"ws",
  "type":"none",
  "host":"${domain}",
  "path":"/vmess",
  "tls":"tls",
  "sni":"${domain}"
}
EOF
)

vmess_json_none=$(cat <<EOF
{
  "v":"2",
  "ps":"${user}",
  "add":"${domain}",
  "port":"${none}",
  "id":"${uuid}",
  "aid":"0",
  "net":"ws",
  "type":"none",
  "host":"${domain}",
  "path":"/vmess",
  "tls":"none"
}
EOF
)

vmess_json_grpc=$(cat <<EOF
{
  "v":"2",
  "ps":"${user}",
  "add":"${domain}",
  "port":"${grpc}",
  "id":"${uuid}",
  "aid":"0",
  "net":"grpc",
  "type":"gun",
  "host":"${domain}",
  "path":"vmess-grpc",
  "tls":"tls",
  "sni":"${domain}"
}
EOF
)

# Encode Link ke Base64
vmesslink1="vmess://$(echo "$vmess_json_tls" | base64 -w 0)"
vmesslink2="vmess://$(echo "$vmess_json_none" | base64 -w 0)"
vmesslink3="vmess://$(echo "$vmess_json_grpc" | base64 -w 0)"

clear
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}        XRAY VMESS ACCOUNT        ${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "Remarks        : ${WHITE}${user}${NC}"
echo -e "Domain         : ${WHITE}${domain}${NC}"
echo -e "Wildcard       : ${WHITE}(bug.com).${domain}${NC}"
echo -e "Port TLS       : ${WHITE}${tls}${NC}"
echo -e "Port none TLS  : ${WHITE}${none}${NC}"
echo -e "Port gRPC      : ${WHITE}${grpc}${NC}"
echo -e "UUID           : ${WHITE}${uuid}${NC}"
echo -e "Alter ID       : 0"
echo -e "Encryption     : auto"
echo -e "Network        : ws / grpc"
echo -e "Path           : /vmess"
echo -e "ServiceName    : vmess-grpc"
echo -e "Expired On     : ${WHITE}${exp}${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "Link TLS       : \n${YELLOW}${vmesslink1}${NC}\n"
echo -e "Link none TLS  : \n${YELLOW}${vmesslink2}${NC}\n"
echo -e "Link gRPC      : \n${YELLOW}${vmesslink3}${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

read -n 1 -s -r -p "Tekan apa saja untuk kembali ke menu..."
m-vmess