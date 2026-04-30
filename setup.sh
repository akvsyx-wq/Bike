#!/bin/bash
# ============================================================
#  🚲 Bike Manager - سكريبت إعداد DigitalOcean Droplet
#  نظام: Ubuntu 20.04 / 22.04
# ============================================================

set -e
echo ""
echo "╔══════════════════════════════════════════╗"
echo "║   🚲 Bike Manager Server - Setup Script   ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# ===== 1. تحديث النظام =====
echo "⏳ [1/6] تحديث النظام..."
apt-get update -qq
apt-get upgrade -y -qq

# ===== 2. تثبيت Node.js 20 =====
echo "⏳ [2/6] تثبيت Node.js 20..."
if ! command -v node &> /dev/null; then
  curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
  apt-get install -y nodejs -qq
fi
echo "✅ Node.js $(node -v) | npm $(npm -v)"

# ===== 3. إعداد ملفات التطبيق =====
echo "⏳ [3/6] إعداد ملفات التطبيق..."
APP_DIR="/opt/bike-manager"
mkdir -p $APP_DIR
cd $APP_DIR

# نسخ الملفات إذا كانت موجودة في نفس المجلد
if [ -f "$(dirname "$0")/server.js" ]; then
  cp "$(dirname "$0")/server.js" $APP_DIR/
  cp "$(dirname "$0")/package.json" $APP_DIR/
  cp "$(dirname "$0")/index.html" $APP_DIR/
  echo "✅ تم نسخ الملفات إلى $APP_DIR"
else
  echo "⚠️  ضع ملفات server.js و index.html و package.json في: $APP_DIR"
fi

# ===== 4. تثبيت المكتبات =====
echo "⏳ [4/6] تثبيت المكتبات (npm install)..."
cd $APP_DIR
npm install --quiet
echo "✅ تم تثبيت المكتبات"

# ===== 5. إعداد PM2 (لإبقاء السيرفر يعمل) =====
echo "⏳ [5/6] إعداد PM2..."
npm install -g pm2 --quiet 2>/dev/null || true
pm2 stop bike-manager 2>/dev/null || true
pm2 delete bike-manager 2>/dev/null || true
pm2 start $APP_DIR/server.js --name "bike-manager" --watch false
pm2 save
pm2 startup systemd -u root --hp /root 2>/dev/null | tail -1 | bash 2>/dev/null || true
echo "✅ PM2 يعمل وسيبدأ تلقائياً عند إعادة التشغيل"

# ===== 6. فتح المنفذ في Firewall =====
echo "⏳ [6/6] إعداد Firewall..."
if command -v ufw &> /dev/null; then
  ufw allow 3000/tcp 2>/dev/null || true
  ufw allow 80/tcp 2>/dev/null || true
  ufw allow ssh 2>/dev/null || true
  echo "✅ تم فتح المنافذ: 3000, 80, 22"
fi

# ===== معلومات الإعداد النهائية =====
DROPLET_IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
echo ""
echo "╔══════════════════════════════════════════╗"
echo "║           ✅ اكتمل الإعداد بنجاح!         ║"
echo "╠══════════════════════════════════════════╣"
echo "║                                          ║"
echo "║  🌐 رابط التطبيق:                         ║"
echo "║     http://$DROPLET_IP:3000             ║"
echo "║                                          ║"
echo "║  📡 المزامنة تعمل تلقائياً لجميع         ║"
echo "║     المستخدمين عند فتح نفس الرابط        ║"
echo "║                                          ║"
echo "║  🔧 أوامر مفيدة:                          ║"
echo "║     pm2 status    - حالة السيرفر         ║"
echo "║     pm2 logs      - عرض السجلات          ║"
echo "║     pm2 restart bike-manager             ║"
echo "║                                          ║"
echo "╚══════════════════════════════════════════╝"
echo ""
