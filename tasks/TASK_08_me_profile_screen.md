# TASK 08 — Me / Profile Screen

## 🎯 เป้าหมาย
แปลง `app/me/page.tsx` จาก Next.js เป็น Flutter
ให้ UI และ behavior เหมือนกันทุกจุด

**Next.js source:** `app/me/page.tsx` (316 lines)

---

## 📁 ไฟล์ที่แก้

| ไฟล์ | action |
|------|--------|
| `lib/screens/me_screen.dart` | ปรับ layout ทั้งหมด |
| `lib/screens/profile_screen.dart` | ตรวจสอบ / merge ถ้าซ้ำ |
| `lib/providers/auth_provider.dart` | ตรวจสอบ methods ครบ |

---

## 🔧 1. State (ตรงกับ Next.js lines 27–45)

```dart
Profile? _profile;
bool _dataLoading = true;
bool _editingName = false;
bool _editingUsername = false;
bool _editingPassword = false;
bool _editingPromptpay = false;
String _nameVal = '';
String _usernameVal = '';
String _promptpayVal = '';
String _newPassword = '';
String _confirmPassword = '';
bool _saving = false;
bool _uploadingAvatar = false;
String? _error;
String? _success;
```

---

## 🔧 2. Page Title + Theme Toggle (ตรงกับ Next.js lines 166–175)

```
สวัสดี!, คุณ {display_name}          [🌙/☀️]
```
- title: text-xl bold gray-900
- theme toggle button: 36px, borderRadius 12, gray-500
  - dark mode → แสดง ☀️ (IoSunnyOutline)
  - light mode → แสดง 🌙 (IoMoonOutline)
  - กด → toggleTheme (ThemeProvider)

---

## 🔧 3. Toast Messages (ตรงกับ Next.js lines 177–178)

```dart
// success: bg green-50 #F0FDF4, border green-200, text green-700, borderRadius 16
// error: bg red-50 #FEF2F2, border red-200, text red-600, borderRadius 16
// success auto-dismiss หลัง 3 วินาที
```

---

## 🔧 4. Avatar Card (ตรงกับ Next.js lines 181–208)

```
┌─────────────────────────────────────────┐
│           [avatar 80px]                 │
│              [📷 button]                │
│           display_name                  │
│           @username                     │
│           email                         │
└─────────────────────────────────────────┘
```

- card: bg white, border gray-100, borderRadius 16, padding vertical 24
- avatar: 80px, borderRadius 16, bg `#4366f4`
  - ถ้ามี avatar_url → แสดงรูป
  - ถ้าไม่มี → `IoPersonOutline` size 32, white
  - uploading overlay: black/40, spinner white
- 📷 button: 28px, bg `#4366f4`, borderRadius 12, absolute bottom-right (-6px, -6px)
  - กด → เปิด image picker (image_picker package)
  - รูปที่เลือก → resize เป็น max 256px → save as base64 → `upsertProfile({avatar_url: base64})`
  - disabled เมื่อ `_uploadingAvatar`
- display_name: text-base bold gray-900
- @username: text-xs gray-400
- email: text-xs gray-400

---

## 🔧 5. Profile Fields Card (ตรงกับ Next.js lines 211–282)

Card เดียว มี divider ระหว่าง rows:

### Row: ชื่อที่แสดง (ตรงกับ Next.js lines 213–232)
```
ชื่อที่แสดง                              [✏️]
{display_name}
```
**Editing mode:**
```
ชื่อที่แสดง                              [✓][✗]
[input field with blue underline]
```
- input: bg transparent, border-bottom `#4366f4`, text-sm
- ✓ button: 32px, bg `#4366f4`, white icon, borderRadius 12
- ✗ button: 32px, gray-400, borderRadius 12
- กด Enter → handleSaveName()
- handleSaveName: `upsertProfile({display_name})` + `updateDisplayName()`

### Row: Username (ตรงกับ Next.js lines 235–257)
```
Username                                  [✏️]
@{username}
```
**Editing mode:**
```
Username                                  [✓][✗]
@ [input lowercase]
```
- input: lowercase only (`toLowerCase()`)
- validation: `isValidUsername` → ตัวอักษร a-z, 0-9, _ (3-30 ตัว)
- ถ้า username เปลี่ยน → check `isUsernameTaken()` ก่อน save
- error: "username ต้องเป็นตัวอักษรภาษาอังกฤษ ตัวเลข หรือ _ (3-30 ตัว)"
- error: "username นี้ถูกใช้งานแล้ว"

### Row: พร้อมเพย์ (ตรงกับ Next.js lines 260–281)
```
พร้อมเพย์ (ใช้เป็น default ในบิล)        [✏️]
📱 {promptpay}  หรือ  "ยังไม่ได้ตั้งค่า" (gray-400)
```
**Editing mode:**
```
พร้อมเพย์ (ใช้เป็น default ในบิล)        [✓][✗]
[input: เบอร์โทร หรือ เลขบัตรประชาชน]
```
- save: `upsertProfile({promptpay: val || null})`

---

## 🔧 6. Change Password Card (ตรงกับ Next.js lines 285–305)

แสดงเฉพาะ `!isGoogleUser` (provider != "google"):

```
เปลี่ยนรหัสผ่าน                           [✏️/✗]
```
**Editing mode (expanded):**
```
[รหัสผ่านใหม่ (password)]
[ยืนยันรหัสผ่านใหม่ (password)]
[บันทึก]
```
- inputs: bg gray-50, border gray-200, borderRadius 12, text-sm
- ปุ่ม "บันทึก": full width, bg `#4366f4`, text white, borderRadius 12
- validation:
  - `newPassword.length < 6` → error "รหัสผ่านต้องมีอย่างน้อย 6 ตัว"
  - `newPassword != confirmPassword` → error "รหัสผ่านไม่ตรงกัน"
- saving text: "กำลังบันทึก..."

---

## 🔧 7. Sign Out Button (ตรงกับ Next.js lines 308–310)

```
[→ ออกจากระบบ]
```
- full width, bg white, border red-100 `#FEE2E2`, text red-500, borderRadius 16
- icon: `IoLogOutOutline` size 18
- กด → `signOut()` → navigate to login

---

## 🔧 8. isValidUsername Logic

```dart
bool isValidUsername(String username) {
  final regex = RegExp(r'^[a-z0-9_]{3,30}$');
  return regex.hasMatch(username);
}
```

---

## ✅ Acceptance Criteria

- [ ] Page title: "สวัสดี!, คุณ {name}" + theme toggle button
- [ ] Toast: success (green, auto-dismiss 3s) + error (red)
- [ ] Avatar card: รูป/initial + 📷 button + name + @username + email
- [ ] Avatar upload: image picker → resize 256px → base64 → save
- [ ] Field: ชื่อที่แสดง — view/edit mode + save + cancel
- [ ] Field: Username — view/edit mode + lowercase + validation + duplicate check
- [ ] Field: พร้อมเพย์ — view/edit mode + save null ถ้าว่าง
- [ ] Change password card: แสดงเฉพาะ non-Google user
- [ ] Password: validation (min 6, match) + save
- [ ] Sign out → navigate to login
- [ ] Dark mode toggle ทำงานได้
