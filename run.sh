#!/bin/bash
# ─────────────────────────────────────────────────────────
#  run.sh — Kill & run Kidtang on iPhone
#  Usage: ./run.sh          (fast — uses build cache)
#         ./run.sh --clean  (full clean rebuild)
# ─────────────────────────────────────────────────────────

DEVICE_ID="00008120-0010786C01EB401E"
CLEAN=false

for arg in "$@"; do
  [[ "$arg" == "--clean" ]] && CLEAN=true
done

echo "▶ [1/7] Killing Xcode & flutter processes..."
pkill -x Xcode 2>/dev/null
pkill -f "flutter run" 2>/dev/null
sleep 2

if $CLEAN; then
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  CLEAN MODE — Before continuing, make sure:"
  echo "  1. iPhone is UNLOCKED and on home screen"
  echo "  2. Using a DATA cable (not charge-only)"
  echo "     → If no 'Trust This Computer?' popup ever appeared,"
  echo "       your cable is charge-only — swap it"
  echo "  3. Battery is NOT at 100% OR unplug from charger first,"
  echo "     then replug with just the Mac USB cable"
  echo "  4. Plugged directly into Mac (no USB hub)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  read -p "  Ready? Press Enter to continue..."
  echo ""

  echo "▶ [2/7] Cleaning Flutter build cache..."
  flutter clean

  echo "▶ [3/7] Fetching Flutter packages..."
  flutter pub get

  echo "▶ [4/7] Reinstalling CocoaPods..."
  cd ios && pod install && cd ..
else
  echo "   (skipping clean — run with --clean if you changed deps or hit a build error)"
fi

echo "▶ [5/7] Checking device is connected..."
if ! flutter devices | grep "$DEVICE_ID"; then
  echo ""
  echo "❌ Device not found! Try:"
  echo "   1. Unplug and replug the USB cable"
  echo "   2. Unlock your iPhone"
  echo "   3. Make sure it's a data cable (not charge-only)"
  echo "   4. Plug directly into Mac (no hub)"
  echo "   5. Run: system_profiler SPUSBDataType | grep -A5 iPhone"
  echo "      (if iPhone doesn't appear, cable has no data)"
  exit 1
fi

echo "▶ [6/7] Verifying iPhone is detectable for install..."
echo "   → Make sure iPhone screen is UNLOCKED before install starts"
echo "   → If prompted 'Trust This Computer?' on iPhone — tap Trust"
echo ""

echo "▶ [7/7] Running on iPhone in release mode..."
echo "   (release mode required — iOS 26 beta breaks Flutter debug/profile JIT)"
echo "   See: https://github.com/flutter/flutter/issues/163984"
echo ""
flutter run --release -d "$DEVICE_ID"
