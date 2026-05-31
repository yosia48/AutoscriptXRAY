#!/bin/bash
# ==========================================
# REBUILD CONFIG ZIVPN (Refactored)
# ==========================================

DB="/etc/zivpn/users.db"
CONFIG="/etc/zivpn/config.json"

# Mengambil kolom pertama (username) dari DB, lalu format jadi array JSON string
USERS=$(awk '{print "\"" $1 "\""}' "$DB" 2>/dev/null | paste -sd "," -)

# Proteksi Crash: Jika file DB hilang atau kosong, gunakan akun cadangan
if [[ -z "$USERS" ]]; then
    USERS='"zndev_reserve"'
fi

cat > "$CONFIG" <<EOF
{
  "listen": ":5667",
  "cert": "/etc/zivpn/zivpn.crt",
  "key": "/etc/zivpn/zivpn.key",
  "obfs": "zivpn",
  "auth": {
    "mode": "passwords",
    "config": [ $USERS ]
  }
}
EOF

# ZIVPN memang butuh restart total untuk membaca user baru
systemctl restart zivpn >/dev/null 2>&1