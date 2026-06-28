# Kidtang - Bill Splitting App

แอปแบ่งค่าใช้จ่ายง่ายๆ กับเพื่อน · Built with Flutter + Supabase

---

## Requirements

| Tool | Version |
|------|---------|
| Flutter | 3.29.4+ |
| Dart | 3.7.2+ |
| Xcode | 26.4.1+ (for iOS) |
| CocoaPods | 1.16.2+ |
| iOS Deployment Target | 13.0+ |

---

## Setup

```bash
# 1. Install Flutter dependencies
flutter pub get

# 2. Install iOS CocoaPods
cd ios && pod install && cd ..
```

Make sure `.env` file exists at the project root (same level as `pubspec.yaml`):

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

---

## Running the App

### ⚡ One-Command Run (Recommended)

Does everything: kills Xcode, cleans, reinstalls pods, and runs on iPhone.

```bash
./run.sh
```

> **Why `--release` mode?** iOS 26 beta breaks Flutter's JIT engine used in debug/profile mode (white screen crash).
> Release mode uses AOT compilation and works correctly.
> See: https://github.com/flutter/flutter/issues/163984

---

### Run on iPhone (Manual)

```bash
# Run on connected iPhone (auto-detect)
flutter run -d ios

# Run on specific device by ID (Piriya's iPhone) — release mode required on iOS 26
flutter run --release -d 00008120-0010786C01EB401E
```

### Check Connected Devices

```bash
flutter devices
```

### Run on Other Platforms

```bash
# macOS
flutter run -d macos

# Chrome (Web)
flutter run -d chrome
```

---

## Hot Reload / Restart (while app is running)

| Key | Action |
|-----|--------|
| `r` | Hot Reload — apply changes instantly (keeps state) |
| `R` | Hot Restart — full restart (resets state) |
| `q` | Quit |
| `d` | Detach (leave app running on device) |

---

## Build Modes

```bash
# Debug (default) — must launch via flutter run on iOS 14+
flutter run -d ios

# Profile — performance testing, can launch from home screen
flutter run --profile -d ios

# Release — production build, can launch from home screen
flutter run --release -d ios
```

---

## Useful Commands

```bash
# Clean build cache
flutter clean

# Re-fetch packages after clean
flutter pub get

# Re-install CocoaPods after clean
cd ios && pod install && cd ..

# Analyze code
flutter analyze

# Check Flutter environment
flutter doctor
```

---

## Project Structure

```
lib/
├── main.dart               # Entry point
├── router.dart             # Navigation (GoRouter)
├── models/                 # Data models
├── providers/              # State management (Provider)
│   ├── auth_provider.dart
│   ├── bill_provider.dart
│   └── theme_provider.dart
├── screens/                # App screens
│   ├── login_screen.dart
│   ├── home_screen.dart
│   ├── bills_screen.dart
│   ├── groups_screen.dart
│   ├── friends_screen.dart
│   ├── me_screen.dart
│   ├── bill_detail_screen.dart
│   ├── group_detail_screen.dart
│   ├── notifications_screen.dart
│   └── profile_screen.dart
├── services/               # API / Supabase services
├── theme/                  # App theme & colors
├── utils/                  # Helper utilities
└── widgets/                # Reusable widgets
```

---

## Bundle ID

`com.kidtang.kidtangFlutter`

---

## Tech Stack

- **Flutter** — UI framework
- **Supabase** — Backend (Auth + Database)
- **GoRouter** — Navigation
- **Provider** — State management
- **Google Fonts** — NotoSansThai
- **flutter_dotenv** — Environment config
