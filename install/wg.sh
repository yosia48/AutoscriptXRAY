#!/bin/bash
# ==========================================
# Install WireGuard (Refactored)
# ==========================================

GREEN='\e[0;32m'
RED='\e[0;31m'
NC='\e[0m'

echo -e "${GREEN}▶️ Memulai instalasi WireGuard (Silent Mode)...${NC}"

export DEBIAN_FRONTEND=noninteractive
apt-get update -qq >/dev/null 2>&1
apt-get install -qq -y wireguard wireguard-tools qrencode resolvconf >/dev/null 2>&1

mkdir -p /etc/wireguard
cd /etc/wireguard || exit

privkey=$(wg genkey)
pubkey=$(echo "$privkey" | wg pubkey)

echo "$privkey" > private.key
echo "$pubkey" > public.key
chmod 600 private.key
chmod 644 public.key

interface=$(ip route | grep default | awk '{print $5}' | head -n1)
if [[ -z "$interface" ]]; then
    echo -e "${RED}[ERROR] Gagal mendeteksi network interface!${NC}"
    exit 1
fi

cat > wg0.conf <<EOF
[Interface]
Address = 10.66.66.1/24
ListenPort = 51820
PrivateKey = $privkey
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -A FORWARD -o wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o $interface -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -D FORWARD -o wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o $interface -j MASQUERADE
SaveConfig = true
EOF

cat > /etc/sysctl.d/30-wg.conf <<EOF
net.ipv4.ip_forward=1
EOF
sysctl --system >/dev/null 2>&1

wg-quick strip wg0 >/dev/null 2>&1 || {
    echo -e "${RED}[ERROR] Konfigurasi WireGuard tidak valid!${NC}"
    exit 1
}

systemctl enable wg-quick@wg0 >/dev/null 2>&1
systemctl start wg-quick@wg0 >/dev/null 2>&1

sleep 1

if ! systemctl is-active --quiet wg-quick@wg0; then
    echo -e "${RED}[ERROR] WireGuard gagal dijalankan!${NC}"
    exit 1
fi

touch /root/log-install.txt
grep -q "WireGuard" /root/log-install.txt || echo "WireGuard           : 51820" >> /root/log-install.txt

echo -e "${GREEN}✅ WireGuard berhasil di-install & aktif di port 51820!${NC}\n"