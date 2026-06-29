# 📋 Flutter Migration Tasks
## kidtang (Flutter) ← mother-calc (Next.js)

ทุก task ถูก map กับ source code จาก Next.js โดยตรง
แต่ละ task มี line reference ชัดเจน ทำได้ทีละ task โดยไม่ต้องรอ task อื่น

---

## 🗂️ Task List

| Task | หัวข้อ | ไฟล์ Flutter | Next.js Source | สถานะ |
|------|--------|-------------|----------------|-------|
| [TASK 01](./TASK_01_home_screen.md) | Home Screen | `lib/screens/home_screen.dart` | `app/home/page.tsx` | ⬜ |
| [TASK 02](./TASK_02_bill_form_modal.md) | Bill Form Modal + Groups Screen | `lib/widgets/create_entity_sheet.dart` + `lib/screens/groups_screen.dart` | `components/ui/CreateEntityModal.tsx` + `app/groups/page.tsx` | ⬜ |
| [TASK 03](./TASK_03_bill_detail_members_items.md) | Bill Detail: Members + Items Tabs | `lib/screens/bill_detail_screen.dart` | `app/app/page.tsx` | ⬜ |
| [TASK 04](./TASK_04_summary_tab.md) | Bill Detail: Summary Tab | `lib/widgets/summary_tab.dart` | `components/summary/SummaryPage.tsx` | ⬜ |
| [TASK 05](./TASK_05_analytics_tab.md) | Bill Detail: Analytics Tab | `lib/widgets/analytics_tab.dart` | `components/summary/AnalyticsPage.tsx` | ⬜ |
| [TASK 06](./TASK_06_group_detail_tabs.md) | Group Detail (4 Tabs) | `lib/screens/group_detail_screen.dart` | `app/groups/[id]/page.tsx` | ⬜ |
| [TASK 07](./TASK_07_friends_notifications.md) | Friends + Notifications Screens | `lib/screens/friends_screen.dart` + `lib/screens/notifications_screen.dart` | `app/friends/page.tsx` + `app/notifications/page.tsx` | ⬜ |
| [TASK 08](./TASK_08_me_profile_screen.md) | Me / Profile Screen | `lib/screens/me_screen.dart` | `app/me/page.tsx` | ⬜ |

---

## 📌 แนะนำลำดับการทำ

```
TASK 02 → TASK 03 → TASK 04 → TASK 05 → TASK 06 → TASK 01 → TASK 07 → TASK 08
```

**เหตุผล:**
- **TASK 02** ก่อน เพราะ `CreateEntitySheet` ถูกใช้ใน TASK 03, 06
- **TASK 03** ก่อน เพราะ bill detail เป็น core screen
- **TASK 04 + 05** ต่อจาก 03 เพราะเป็น tab ใน bill detail
- **TASK 06** ใช้ `SummaryTab` จาก TASK 04
- **TASK 01, 07, 08** ทำได้อิสระหลังจาก core เสร็จ

---

## 🎨 Design Tokens (ใช้ทุก task)

```dart
// Primary blue
const kPrimary = Color(0xFF4366F4);      // #4366f4 (bill detail, notifications)
const kPrimaryAlt = Color(0xFF286BFE);   // #286bfe (home, friends)
const kPrimaryLight = Color(0xFF6B8AFF); // #6b8aff (gradient end)

// Backgrounds
const kBgPage = Color(0xFFF4F6FB);       // #f4f6fb
const kBgCard = Colors.white;
const kBgGray50 = Color(0xFFF9FAFB);     // gray-50

// Text
const kTextPrimary = Color(0xFF111827);  // gray-900
const kTextSecondary = Color(0xFF6B7280); // gray-500
const kTextMuted = Color(0xFF9CA3AF);    // gray-400

// Status colors
const kGreen = Color(0xFF10B981);        // emerald-500
const kAmber = Color(0xFFF59E0B);        // amber-500
const kRed = Color(0xFFEF4444);          // red-500
const kPurple = Color(0xFFA855F7);       // purple-500
```

---

## 📦 Dependencies ที่อาจต้องเพิ่ม

```yaml
# pubspec.yaml
dependencies:
  image_picker: ^1.0.0      # TASK 08: avatar upload
  http: ^1.0.0              # TASK 01: currency fetch
  intl: ^0.19.0             # ทุก task: date format th-TH
```

---

## 🔄 วิธีใช้

1. เปิด task ที่ต้องการทำ เช่น `TASK_02_bill_form_modal.md`
2. บอก AI: **"ทำ TASK 02 ตาม spec ใน tasks/TASK_02_bill_form_modal.md"**
3. AI จะอ่าน spec และ implement ตาม Next.js line references
4. ตรวจสอบ Acceptance Criteria ✅ ก่อน mark เสร็จ
5. ทำ task ถัดไป

---

## ⚠️ หมายเหตุสำคัญ

- ทุก task มี **line reference** ชัดเจน เช่น `(ตรงกับ Next.js lines 56–78)`
- สีทุกสีมี **hex code** ระบุไว้แล้ว ไม่ต้องเดา
- Layout ใช้ **ASCII diagram** แสดง structure
- Logic ใช้ **Dart pseudocode** อธิบาย behavior
