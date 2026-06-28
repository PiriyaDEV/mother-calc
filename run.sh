#!/bin/bash
# ─────────────────────────────────────────────────────────
#  run.sh — Kill, clean, reinstall & run Kidtang on iPhone
#  Usage: ./run.sh
# ─────────────────────────────────────────────────────────

DEVICE_ID="00008120-0010786C01EB401E"

echo "▶ [1/6] Killing Xcode & flutter processes..."
pkill -x Xcode 2>/dev/null
pkill -f "flutter run" 2>/dev/null
sleep 2

echo "▶ [2/6] Cleaning Flutter build cache..."
flutter clean

echo "▶ [3/6] Fetching Flutter packages..."
flutter pub get

echo "▶ [4/6] Reinstalling CocoaPods..."
cd ios && pod install && cd ..

echo "▶ [5/6] Checking device is connected..."
flutter devices | grep "$DEVICE_ID" || { echo "❌ Device not found! Check USB connection."; exit 1; }

echo "▶ [6/6] Running on iPhone in release mode..."
echo "   (release mode required — iOS 26 beta breaks Flutter debug/profile JIT)"
echo "   See: https://github.com/flutter/flutter/issues/163984"
echo ""
flutter run --release -d "$DEVICE_ID"
