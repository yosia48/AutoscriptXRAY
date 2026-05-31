#!/bin/bash
# ==========================================
# ADD WIREGUARD ACCOUNT (Refactored)
# ==========================================

clear
CYAN='\e[1;36m'
GREEN='\e[1;32m'
YELLOW='\e[1;33m'
RED='\e[1;31m'
WHITE='\e[1;37m'
NC='\e[0m'

[[ -f /etc/wireguard/wg0.conf ]] || {
    echo -e "${RED}❌ WireGuard is not installed!${NC}"
    exit 1
}

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${WHITE}        ADD WIREGUARD ACCOUNT      ${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Input & Validasi User
read -p "Masukkan nama user: " user
if [[ -z "$user" || ! "$user" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo -e "\n${RED}❌ Nama user tidak valid! Gunakan alfabet/angka/strip.${NC}"
    exit 1
fi

if grep -q "^# $user$" /etc/wireguard/wg0.conf; then
    echo -e "\n${RED}❌ User WireGuard '$user' sudah ada!${NC}"
    exit 1
fi

# Generate Keys
priv_key=$(wg genkey)
pub_key=$(echo "$priv_key" | wg pubkey)
psk=$(wg genpsk)

# Kalkulasi IP berikutnya otomatis
last_ip=$(grep "^AllowedIPs = 10\.66\.66\." /etc/wireguard/wg0.conf | tail -n1 | awk '{print $3}' | cut -d'.' -f4 | cut -d'/' -f1)
[[ -z "$last_ip" ]] && last_ip=1
next_ip=$((last_ip + 1))

if (( next_ip > 254 )); then
    echo -e "\n${RED}❌ IP Pool WireGuard sudah penuh!${NC}"
    exit 1
fi

client_ip="10.66.66.${next_ip}/32"
mkdir -p /etc/wireguard/clients
client_config="/etc/wireguard/clients/$user.conf"

# Deteksi IP Server
server_ip=$(curl -s --max-time 5 ifconfig.me)
[[ -z "$server_ip" ]] && {
    echo -e "\n${RED}❌ Gagal mendapatkan IP Public Server!${NC}"
    exit 1
}

server_port=$(grep ListenPort /etc/wireguard/wg0.conf | awk '{print $3}')
server_pubkey=$(wg show wg0 public-key)

# Tulis konfigurasi baru ke server
echo -e "\n# $user\n[Peer]\nPublicKey = $pub_key\nPresharedKey = $psk\nAllowedIPs = $client_ip" >> /etc/wireguard/wg0.conf

# Buat berkas config untuk Client
cat > "$client_config" <<EOF
[Interface]
PrivateKey = $priv_key
Address = $client_ip
DNS = 1.1.1.1

[Peer]
PublicKey = $server_pubkey
PresharedKey = $psk
Endpoint = $server_ip:$server_port
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
EOF

# Membuat Gambar QR Code
qrencode -o "/etc/wireguard/clients/${user}.png" < "$client_config"

# Validasi Struktur Akhir Server
if ! wg-quick strip wg0 >/dev/null 2>&1; then
    echo -e "\n${RED}❌ Konfigurasi WireGuard server korup/gagal!${NC}"
    exit 1
fi

# Restart Layanan WireGuard
systemctl restart wg-quick@wg0
sleep 1

clear
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Akun WireGuard '$user' Berhasil Dibuat!${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "📄 Config:\n"
cat "$client_config"
echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "📷 QR Code (scan via WireGuard app):"
qrencode -t ansiutf8 < "$client_config"
echo ""

read -n 1 -s -r -p "Tekan apa saja untuk kembali ke menu..."
m-wg