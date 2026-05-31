#!/bin/bash
# ==========================================
# CREATE SSH ACCOUNT (Refactored)
# ==========================================

clear
CYAN='\e[1;36m'
GREEN='\e[1;32m'
YELLOW='\e[1;33m'
RED='\e[1;31m'
NC='\e[0m'

DOMAIN=$(cat /etc/xray/domain 2>/dev/null)
IP=$(curl -s ipv4.icanhazip.com)
[[ -z "$DOMAIN" ]] && DOMAIN="$IP"

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}     CREATE SSH ACCOUNT     ${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Input & Validasi User
read -rp "Username      : " user
if id "$user" &>/dev/null; then
    echo -e "\n${RED}[ ERROR ] User '$user' already exists!${NC}\n"
    exit 1
fi

read -rs -p "Password      : " pass
echo ""

# Input & Validasi Hari
read -rp "Expired Days  : " days
if ! [[ "$days" =~ ^[0-9]+$ ]]; then
    echo -e "\n${RED}[ ERROR ] Invalid expiration days!${NC}\n"
    exit 1
fi

EXP=$(date -d "$days days" +%Y-%m-%d)

# Proses Create User
useradd -e "$EXP" -m -s /bin/false "$user" || {
    echo -e "\n${RED}[ERROR] Failed to create user!${NC}\n"
    exit 1
}

echo "$user:$pass" | chpasswd || {
    echo -e "\n${RED}[ERROR] Failed to set password!${NC}\n"
    exit 1
}

# Simpan Data Akun
mkdir -p /root/accounts
ACCOUNT_FILE="/root/accounts/${user}.txt"

cat > "$ACCOUNT_FILE" <<EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SSH ACCOUNT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Username : $user
Password : $pass
Expired  : $EXP
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Domain   : $DOMAIN
IP VPS   : $IP
OpenSSH  : 22
Dropbear : 109,143
SSH WS   : 2082
SSH WSS  : 2096
UdpSSH   : 1-65535
BadVPN   : 7300
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SSH UDP CUSTOM
$DOMAIN:1-65535@$user:$pass
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SSH WS
$DOMAIN:2082@$user:$pass
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SSH WSS
$DOMAIN:2096@$user:$pass
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Payload WS
GET / HTTP/1.1[crlf]Host: $DOMAIN[crlf]Upgrade: websocket[crlf]Connection: Upgrade[crlf][crlf]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Payload Enhanced
GET / HTTP/1.1[crlf]Host: [host][crlf][crlf]PATCH / HTTP/1.1[crlf]Host: $DOMAIN[crlf]Upgrade: websocket[crlf]Connection: Upgrade[crlf][crlf][split]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF

clear
cat "$ACCOUNT_FILE"
echo -e "\n${YELLOW}Saved To: ${ACCOUNT_FILE}${NC}"
echo ""

read -n 1 -s -r -p "Tekan apa saja untuk kembali ke menu..."
m-ssh