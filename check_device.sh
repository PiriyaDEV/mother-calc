#!/bin/zsh
# ─────────────────────────────────────────────
# check_device.sh — ตรวจสอบ iPhone ที่เชื่อมต่ออยู่
# ─────────────────────────────────────────────

echo "🔍 กำลังตรวจสอบอุปกรณ์ที่เชื่อมต่อ...\n"

# 1. Flutter devices
echo "📱 Flutter devices:"
flutter devices 2>&1
echo ""

# 2. Check specifically for physical iOS device
IPHONE=$(flutter devices 2>&1 | grep -E "iPhone|iPad" | grep -v "simulator\|Simulator\|mac-designed")

if [ -z "$IPHONE" ]; then
  echo "❌ ไม่พบ iPhone/iPad ที่เชื่อมต่อ"
  echo ""
  echo "💡 วิธีแก้:"
  echo "   1. เสียบสาย USB แล้วลองใหม่"
  echo "   2. Unlock iPhone แล้วกด 'Trust' ถ้ามี popup"
  echo "   3. ถ้า iPhone กำลัง Preparing — รอสักครู่แล้วลองใหม่"
  echo "   4. ลอง: flutter run -d mac-designed-for-ipad (รันบน Mac แทน)"
else
  echo "✅ พบอุปกรณ์:"
  echo "$IPHONE"
  echo ""
  # Check if device is busy/preparing
  BUSY=$(flutter devices 2>&1 | grep -i "busy\|preparing\|error")
  if [ -n "$BUSY" ]; then
    echo "⚠️  อุปกรณ์กำลัง Preparing หรือ Busy:"
    echo "$BUSY"
    echo ""
    echo "💡 รอสักครู่แล้วรัน script นี้ใหม่"
  else
    echo "🚀 อุปกรณ์พร้อมใช้งาน! รัน: flutter run"
  fi
fi

echo ""
echo "─────────────────────────────────────────────"
echo "📋 รายการ devices ทั้งหมด (รวม simulator):"
flutter devices 2>&1 | grep -v "^$\|No devices\|flutter devices"
