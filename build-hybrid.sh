#!/bin/bash
# ==============================================
# 🚀 Bagaz-Bot Ultimate v3.1.7-ultimate Builder
# Compatible: OpenWrt HG680P / Termux Android
# Author: BAGASKARA Dev | msofyanz
# ==============================================

set -e

PKG="bagaz-bot-ultimate"
VER="3.1.7-ultimate"
ARCH="$(uname -m)"
DATE=$(date '+%Y%m%d-%H%M')
WORKDIR="/tmp/${PKG}_build"
OUTZIP="/tmp/${PKG}_${VER}_${ARCH}_${DATE}.zip"
GITHUB_REPO="msofyanz/bagaz-bot-ultimate"

echo "=== 🚧 Building $PKG v$VER ($ARCH) ==="
sleep 1

# 🔧 Persiapan direktori
rm -rf "$WORKDIR"
mkdir -p "$WORKDIR/usr/bin" "$WORKDIR/etc/init.d" "$WORKDIR/config"

# ==============================================
# 🧠 1. Skrip utama bot (Telegram)
# ==============================================
cat > "$WORKDIR/usr/bin/bagaz-bot" <<'BOT'
#!/bin/bash
LOG="/tmp/bagaz-bot.log"
TOKEN_FILE="/root/bagaz_token"
[ -f "$TOKEN_FILE" ] && TOKEN=$(cat "$TOKEN_FILE") || TOKEN="TOKEN_BELUM_DISET"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Bagaz-Bot Ultimate started" >> "$LOG"

while true; do
  CPU=$(grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {printf("%.1f%%",usage)}')
  MEM=$(free | awk '/Mem/{printf("%.1f%%", $3/$2*100)}')
  UPTIME=$(uptime -p)
  TEMP=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null | awk '{printf("%.1f°C",$1/1000)}')

  MSG="📡 *Bagaz-Bot Ultimate Monitor*\nCPU: $CPU\nMEM: $MEM\nTEMP: $TEMP\nUPTIME: $UPTIME"
  echo "$MSG" >> "$LOG"

  if [ "$TOKEN" != "TOKEN_BELUM_DISET" ]; then
    curl -s -X POST "https://api.telegram.org/bot${TOKEN}/sendMessage" \
      -d chat_id="@bagaz_bot_channel" \
      -d parse_mode="Markdown" \
      -d text="$MSG" >/dev/null
  fi

  sleep 60
done
BOT
chmod +x "$WORKDIR/usr/bin/bagaz-bot"

# ==============================================
# ⚙️ 2. Skrip init untuk OpenWrt
# ==============================================
cat > "$WORKDIR/etc/init.d/bagaz-bot" <<'INIT'
#!/bin/sh /etc/rc.common
START=99
STOP=10
USE_PROCD=1

start_service() {
  procd_open_instance
  procd_set_param command /usr/bin/bagaz-bot
  procd_close_instance
}
INIT
chmod +x "$WORKDIR/etc/init.d/bagaz-bot"

# ==============================================
# 🔩 3. File konfigurasi
# ==============================================
cat > "$WORKDIR/config/info.txt" <<EOF
Bagaz-Bot Ultimate v$VER
Build date: $DATE
Arch: $ARCH
EOF

# ==============================================
# 🧱 4. Zip otomatis
# ==============================================
echo "📦 Compressing files..."
cd "$WORKDIR"
zip -r "$OUTZIP" . >/dev/null
cd -

echo "✅ ZIP created: $OUTZIP"

# ==============================================
# 🚀 5. (Opsional) Upload ke GitHub Release
# ==============================================
if [ -f "/root/github_token" ]; then
  TOKEN=$(cat /root/github_token)
  echo "📤 Uploading to GitHub Releases..."
  curl -s -H "Authorization: token $TOKEN" \
    -H "Content-Type: application/zip" \
    --data-binary @"$OUTZIP" \
    "https://uploads.github.com/repos/${GITHUB_REPO}/releases/assets?name=$(basename $OUTZIP)" || true
  echo "✅ Upload completed (if release exists)"
else
  echo "⚠️ Token GitHub belum diset di /root/github_token, skip upload."
fi

echo "🎉 Done! Use this zip on OpenWrt or Termux."
