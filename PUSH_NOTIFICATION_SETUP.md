# Push Notification Setup Guide

โค้ดทั้งหมดพร้อมแล้ว — ต้องทำขั้นตอนเหล่านี้เพื่อ activate

---

## สิ่งที่ต้องมีก่อนเริ่ม

- [ ] Firebase account (ฟรี)
- [ ] Apple Developer account ($99/ปี) — จำเป็นสำหรับ iOS push
- [ ] Supabase project (มีอยู่แล้ว)
- [ ] Flutter + FlutterFire CLI installed

---

## Step 1 — สร้าง Firebase Project

1. ไปที่ https://console.firebase.google.com
2. คลิก **Add project** → ตั้งชื่อ เช่น `kidtang`
3. Google Analytics → เปิดหรือปิดก็ได้ → **Create project**

---

## Step 2 — เพิ่ม Android App ใน Firebase

1. ใน Firebase console → **Add app** → เลือก Android
2. **Android package name**: `com.kidtang.kidtang_flutter`
3. คลิก **Register app**
4. ดาวน์โหลด `google-services.json`
5. วางไฟล์ที่: `android/app/google-services.json`
6. ข้ามขั้นตอน Add SDK (เราเพิ่มใน pubspec.yaml แล้ว)

---

## Step 3 — เพิ่ม iOS App ใน Firebase

1. ใน Firebase console → **Add app** → เลือก iOS
2. **iOS bundle ID**: `com.kidtang.kidtangFlutter`
   - ตรวจสอบจาก Xcode: เปิด `ios/Runner.xcworkspace` → Runner target → Bundle Identifier
3. คลิก **Register app**
4. ดาวน์โหลด `GoogleService-Info.plist`
5. วางไฟล์ที่: `ios/Runner/GoogleService-Info.plist`
   - ต้องเพิ่มผ่าน Xcode ด้วย: ลากไฟล์เข้า Runner folder ใน Xcode → เลือก "Copy items if needed"

---

## Step 4 — ตั้งค่า APNs (iOS Push)

### 4a. สร้าง APNs Key ใน Apple Developer

1. ไปที่ https://developer.apple.com → **Certificates, IDs & Profiles**
2. **Keys** → **+** (เพิ่ม key ใหม่)
3. ตั้งชื่อ เช่น `Kidtang APNs`
4. เลือก **Apple Push Notifications service (APNs)**
5. **Continue** → **Register** → **Download** (ดาวน์โหลดได้ครั้งเดียว!)
6. จดบันทึก:
   - **Key ID** (10 ตัวอักษร)
   - **Team ID** (ด้านบนขวาของหน้า)
   - ไฟล์ `.p8` ที่ดาวน์โหลด

### 4b. อัปโหลด APNs Key ไปที่ Firebase

1. Firebase console → **Project Settings** (⚙️) → **Cloud Messaging**
2. เลื่อนหา **Apple app configuration**
3. คลิก **Upload** ใต้ APNs Authentication Key
4. อัปโหลดไฟล์ `.p8` + Key ID + Team ID

---

## Step 5 — Run FlutterFire Configure

```bash
# Install FlutterFire CLI (ถ้ายังไม่มี)
dart pub global activate flutterfire_cli

# รันใน root ของ project
flutterfire configure
```

- เลือก Firebase project ที่เพิ่งสร้าง
- เลือก platforms: **android, ios**
- คำสั่งนี้จะ **overwrite** `lib/firebase_options.dart` ด้วยค่าจริง

---

## Step 6 — ตั้งค่า Supabase Database

### 6a. รัน SQL Migration

ใน Supabase dashboard → **SQL Editor** → รันไฟล์:

```
supabase/migrations/20240701000000_add_fcm_token_and_push_trigger.sql
```

> หมายเหตุ: ถ้า `pg_net` extension ไม่ทำงาน ให้ไปที่ **Database → Extensions** → เปิด **pg_net**

### 6b. ตั้งค่า app settings (ให้ trigger เรียก Edge Function ได้)

รันใน SQL Editor (แทนค่าจริงก่อน):

```sql
-- แทน YOUR_PROJECT_REF ด้วย project ref จาก Supabase URL
-- เช่น ถ้า URL คือ https://abcdef.supabase.co → ref คือ abcdef
ALTER DATABASE postgres
  SET app.supabase_url = 'https://YOUR_PROJECT_REF.supabase.co';

-- แทน YOUR_SERVICE_ROLE_KEY จาก Project Settings → API → service_role key
ALTER DATABASE postgres
  SET app.service_role_key = 'YOUR_SERVICE_ROLE_KEY';
```

---

## Step 7 — สร้าง Firebase Service Account Key

ใช้สำหรับให้ Supabase Edge Function เรียก FCM API

1. Firebase console → **Project Settings** (⚙️) → **Service accounts**
2. คลิก **Generate new private key** → **Generate key**
3. ดาวน์โหลด JSON file (เก็บปลอดภัย! อย่า commit เข้า git)

---

## Step 8 — เพิ่ม Secret ใน Supabase

ใน Supabase dashboard → **Edge Functions** → **Secrets**

เพิ่ม secret ชื่อ:
```
FIREBASE_SERVICE_ACCOUNT
```
Value: วาง **ทั้งหมด** ของ JSON ที่ดาวน์โหลดในขั้น 7 (เป็น JSON string เดียว)

---

## Step 9 — Deploy Edge Function

```bash
# Install Supabase CLI (ถ้ายังไม่มี)
brew install supabase/tap/supabase

# Login
supabase login

# Link กับ project
supabase link --project-ref YOUR_PROJECT_REF

# Deploy
supabase functions deploy send-push
```

---

## Step 10 — รัน Flutter App

```bash
flutter pub get
flutter run
```

แอปจะ:
1. ขอ permission notification จาก user
2. บันทึก FCM token ลง `profiles.fcm_token` หลัง login
3. รับ push notification เมื่อมี group invite, friend request เข้ามา

---

## ทดสอบ Push Notification

หลัง setup ครบ ทดสอบโดย insert row ลงใน `notifications` table ตรงๆ ผ่าน SQL Editor:

```sql
INSERT INTO notifications (user_id, type, data, read)
VALUES (
  'YOUR_USER_ID',  -- จาก auth.users หรือ profiles
  'group_invite',
  '{"group_name": "test group", "invited_by_display_name": "Piriya"}',
  false
);
```

ถ้าตั้งค่าถูกต้อง → push จะเด้งบน device ภายใน 2-3 วินาที

---

## Notification Types ที่รองรับ

| Type | Trigger | Push Message |
|------|---------|-------------|
| `group_invite` | เชิญเข้ากลุ่ม | "X เชิญคุณเข้าร่วมกลุ่ม Y" |
| `friend_request` | ส่งคำขอเพื่อน | "X ส่งคำขอเป็นเพื่อน" |
| `friend_accepted` | ยอมรับคำขอ | "X ยอมรับคำขอเป็นเพื่อนของคุณแล้ว" |
| `bill_paid` | จ่ายบิล | "X จ่ายเงินในบิล Y แล้ว" |
| `bill_completed` | บิลครบ | "สมาชิกทุกคนจ่ายเงินครบในบิล Y แล้ว" |

> **bill_paid / bill_completed**: ต้องเพิ่ม code ใน `bill_provider.dart` เพื่อ insert notification row เมื่อมีการจ่ายบิล — push จะทำงานอัตโนมัติหลังจากนั้น

---

## ไฟล์ที่ถูกเพิ่ม/แก้ไข

| ไฟล์ | การเปลี่ยนแปลง |
|-----|--------------|
| `pubspec.yaml` | เพิ่ม `firebase_core`, `firebase_messaging`, `flutter_local_notifications` |
| `lib/firebase_options.dart` | **placeholder** — ถูก overwrite โดย `flutterfire configure` |
| `lib/services/push_notification_service.dart` | FCM init, token save/clear, foreground notification display |
| `lib/main.dart` | Firebase.initializeApp + PushNotificationService.initialize |
| `lib/providers/auth_provider.dart` | saveToken() หลัง login, clearToken() ก่อน logout |
| `android/settings.gradle.kts` | เพิ่ม google-services plugin |
| `android/app/build.gradle.kts` | apply google-services plugin |
| `ios/Runner/AppDelegate.swift` | FirebaseApp.configure() |
| `supabase/functions/send-push/index.ts` | Edge Function ส่ง FCM push |
| `supabase/migrations/...add_fcm_token...sql` | fcm_token column + DB trigger |
