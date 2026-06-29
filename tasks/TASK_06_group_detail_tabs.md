# TASK 06 — Group Detail Screen (4 Tabs)

## 🎯 เป้าหมาย
แปลง `app/groups/[id]/page.tsx` จาก Next.js เป็น Flutter
ให้ UI และ behavior เหมือนกันทุกจุด

**Next.js source:** `app/groups/[id]/page.tsx` (746 lines)

---

## 📁 ไฟล์ที่แก้

| ไฟล์ | action |
|------|--------|
| `lib/screens/group_detail_screen.dart` | ปรับ layout ทั้งหมด |

> หมายเหตุ: ใช้ `CreateEntitySheet`, `ConfirmDialog`, `BillStatusPill`, `SummaryTab` จาก TASK 02 และ 04

---

## 🔧 1. State (ตรงกับ Next.js lines 51–62)

```dart
String _tab = 'bills'; // default tab = bills (ตรงกับ Next.js line 51)
Group? _group;
List<Bill> _bills = [];
List<GroupMember> _members = [];
bool _dataLoading = true;
bool _creating = false;
bool _notFound = false;
Bill? _editingBill;
Bill? _confirmDeleteBill;
bool _showGroupSettings = false;
bool _confirmDeleteGroup = false;
```

---

## 🔧 2. Header (ตรงกับ Next.js lines 185–252)

### Layout
```
[←]  [emoji] group name
              description (ถ้ามี, text-xs gray-400)    [⚙️]
─────────────────────────────────────────────────────────
[สมาชิก(N)] [บิล(N)] [สรุป] [วิเคราะห์]
```

### ปุ่ม ⚙️ (gear)
- กด → เปิด CreateEntitySheet (type=group, mode=edit, initialData=group)
- onSave → `updateGroup(id, {name, description, emoji, tags})` → update local state
- onDelete → ปิด sheet + เปิด confirmDeleteGroup dialog

### Tab Bar (ตรงกับ Next.js lines 216–251)
```dart
const tabs = [
  {'id': 'members', 'label': 'สมาชิก', 'icon': Icons.people_outline},
  {'id': 'bills',   'label': 'บิล',    'icon': Icons.receipt_outlined},
  {'id': 'summary', 'label': 'สรุป',   'icon': Icons.bar_chart},
  {'id': 'analytics','label':'วิเคราะห์','icon': Icons.analytics_outlined},
];
```
- Container: gray bg `#F3F4F6`, borderRadius 16, padding 4
- Active: white bg, blue text `#4366f4`, shadow
- Count badge บน "สมาชิก" = `acceptedMembers.length` (ตรงกับ Next.js line 230)
- Count badge บน "บิล" = `bills.length` (ตรงกับ Next.js line 239)

---

## 🔧 3. Members Tab (ตรงกับ Next.js lines 349–439)

### ปุ่ม "จัดการสมาชิก" (full width, blue)
- กด → navigate to `/groups/{id}/members`

### Pending Invites Banner (ตรงกับ Next.js lines 373–396)
แสดงเฉพาะ `pending.length > 0`:
```
┌─────────────────────────────────────────┐
│ รอตอบรับ X คน                           │  amber-600, font-semibold
│ [avatar 28px] ชื่อ                      │
│ [avatar 28px] ชื่อ                      │
└─────────────────────────────────────────┘
```
- bg: amber-50 `#FFFBEB`, border: amber-100 `#FDE68A`
- avatar: amber-200 bg, initial letter amber-700

### Member List (accepted, ตรงกับ Next.js lines 407–436)
แต่ละ row:
```
[avatar 36px]  display_name                [เจ้าของ]
               @username                   [สมาชิก]
```
- Avatar: ถ้ามี avatar_url → แสดงรูป, ถ้าไม่มี → initial letter บน bg `#4366f4`
- Role badge:
  - owner: bg purple-50 `#FAF5FF`, text purple-500 `#A855F7`, text "เจ้าของ"
  - member: bg gray-100, text gray-500, text "สมาชิก"

### Empty State (ตรงกับ Next.js lines 399–405)
```
[icon 24px]
ยังไม่มีสมาชิก
```
- icon container: 56px, bg gray-100, borderRadius 16

---

## 🔧 4. Bills Tab (ตรงกับ Next.js lines 441–543)

### ปุ่ม "สร้างบิลใหม่" (full width, blue)
- กด → เปิด CreateEntitySheet (type=bill, mode=create)
- onSave → `createBill({title, emoji, tags, settings, group_id})` → navigate to bill detail

### Empty State (ตรงกับ Next.js lines 471–485)
```
┌─────────────────────────────────────────┐
│ [receipt icon]  สร้างบิลแรกของกลุ่ม    │  dashed border
│                 แตะเพื่อเริ่มหารค่าใช้จ่าย│
│                                      [+]│
└─────────────────────────────────────────┘
```
- border: dashed, gray-200
- icon container: 40px, bg blue-50, borderRadius 12

### Bill List (ตรงกับ Next.js lines 488–540)
แต่ละ row:
```
[emoji/icon 40px]  bill title                    [⚙️][🗑️][→]
                   [status pill] date  [tag] [tag] +N
```
- กด row → navigate to bill detail
- ⚙️ → เปิด CreateEntitySheet (type=bill, mode=edit, initialData=bill)
- 🗑️ → เปิด ConfirmDialog: title `ลบบิล "{title}"?`, description "การกระทำนี้ไม่สามารถย้อนกลับได้", confirmLabel "ลบบิล", danger=true
- Tags: แสดงสูงสุด 2 tags + "+N" ถ้าเกิน (ตรงกับ Next.js lines 509–519)
- Date format: `d MMM yyyy` (th-TH locale)

---

## 🔧 5. Group Summary Tab (ตรงกับ Next.js lines 545–632)

### Empty State
```
[bar chart icon]
ยังไม่มีบิลในกลุ่ม
สร้างบิลก่อนเพื่อดูสรุป
```

### Hero Card (ตรงกับ Next.js lines 571–577)
```
┌─────────────────────────────────────────┐
│ ยอดรวมทั้งกลุ่ม                         │  gradient #4366f4 → #6b8aff
│ 12,345.00 บาท                           │  text-3xl bold
│ 3 บิล                                   │  text-xs opacity-70
└─────────────────────────────────────────┘
```
- totalAmount = sum ของ item.price ทุก item ในทุก bill

### Per-Bill Collapsible List (ตรงกับ Next.js lines 580–629)
```dart
// default expanded = bills.length == 1 ? bills[0].id : null
```

แต่ละ bill row:
```
[emoji/icon 36px]  bill title                    1,234.00 บาท  [▼/▲]
                   X รายการ · Y คน
```
- กด → toggle expand
- Expanded: แสดง `SummaryTab` widget (จาก TASK 04) ใต้ row
  - ใช้ `bill.members` และ `bill.items` ที่ load มาแล้ว
  - `currentUserId` = current user id

---

## 🔧 6. Group Analytics Tab (ตรงกับ Next.js lines 634–736)

### Empty State
```
[analytics icon]
ยังไม่มีข้อมูลวิเคราะห์
สร้างบิลและเพิ่มรายการก่อน
```

### Stats Row — 3 cards (ตรงกับ Next.js lines 660–669)
```
┌──────────┐ ┌──────────┐ ┌──────────┐
│ บิลทั้งหมด│ │รายการทั้งหมด│ │ เฉลี่ย/บิล│
│ 3        │ │ 15       │ │ 4,115    │
│ บิล      │ │ รายการ   │ │ บาท      │
└──────────┘ └──────────┘ └──────────┘
```
- bg: gray-50 `#F9FAFB`, borderRadius 16
- value color: blue `#4366f4` / purple `#A855F7` / emerald `#10B981`
- label: text-10, gray-400
- value: text-xl, bold

**Data:**
```dart
// allItems = bills.expand((b) => b.items ?? []).toList()
// totalAmount = allItems.fold(0.0, (s, i) => s + i.price)
// avgPerBill = bills.isNotEmpty ? totalAmount / bills.length : 0
```

### Top Items List (ตรงกับ Next.js lines 672–700)
หัวข้อ: "รายการราคาสูงสุด"

```dart
// topItems = allItems.sortedByDesc(price).take(5)
// pct = totalAmount > 0 ? (item.price / totalAmount) * 100 : 0
```

แต่ละ row (มี divider ระหว่าง rows):
```
1  ข้าวผัดกุ้ง                          500.00 บาท
   [████████████████████░░░░░░░░░░░░░░░░]  ← #4366f4 solid
```
- rank: text-xs bold gray-400, width 16px
- bar: height 6px, bg gray-200, fill `#4366f4`

### Recent Bills List (ตรงกับ Next.js lines 703–733)
หัวข้อ: "บิลล่าสุด"

```dart
// sort by updated_at desc, take 5
```

แต่ละ bill card:
```
bill title                              1,234.00 บาท
[████████████████████░░░░░░░░░░░░░░░░]  ← gradient blue
1 ม.ค. 2568 · 42.3% ของทั้งหมด
```
- bar: gradient `#4366f4` → `#6b8aff`, height 6px
- date + pct: text-10, gray-400

---

## 🔧 7. Confirm Delete Group (ตรงกับ Next.js lines 306–315)

```dart
// title: 'ลบกลุ่ม "{group.name}"?'
// description: "บิลทั้งหมดในกลุ่มจะถูกลบด้วย ไม่สามารถย้อนกลับได้"
// confirmLabel: "ลบกลุ่ม"
// danger: true
// onConfirm → deleteGroup(group.id) → navigate back to home
```

---

## ✅ Acceptance Criteria

- [ ] Default tab = "บิล" (ตรงกับ Next.js)
- [ ] Tab bar 4 แท็บ + count badges (สมาชิก/บิล)
- [ ] Members tab: pending banner (amber) + accepted list + role badges
- [ ] ปุ่ม "จัดการสมาชิก" navigate ได้
- [ ] Bills tab: สร้าง/แก้ไข/ลบบิลได้
- [ ] Bills tab: empty state dashed border
- [ ] Bills tab: tags แสดงสูงสุด 2 + "+N"
- [ ] Group Summary: hero card gradient + totalAmount
- [ ] Group Summary: per-bill collapsible + SummaryTab expand
- [ ] Group Analytics: stats 3 cards (สี blue/purple/emerald)
- [ ] Group Analytics: top items list + progress bar
- [ ] Group Analytics: recent bills + gradient bar + date + %
- [ ] Edit group ได้ (name/emoji/description/tags)
- [ ] Delete group → confirm → navigate home
