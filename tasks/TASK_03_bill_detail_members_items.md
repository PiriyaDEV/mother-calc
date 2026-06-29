# TASK 03 — Bill Detail Screen: Header + Tab Bar + Members Tab + Items Tab

## 🎯 เป้าหมาย
แปลง `app/app/page.tsx` + `MemberPage.tsx` + `ItemPage.tsx` + `ItemFormModal.tsx`
จาก Next.js เป็น Flutter ใน `bill_detail_screen.dart`

---

## 📁 ไฟล์ที่สร้าง/แก้

| ไฟล์ | action |
|------|--------|
| `lib/screens/bill_detail_screen.dart` | ปรับ layout ทั้งหมด |
| `lib/widgets/item_form_sheet.dart` | สร้างใหม่ (ItemFormModal) |
| `lib/widgets/member_form_sheet.dart` | สร้างใหม่ (add/edit member) |

---

## 🔧 1. Header (ตรงกับ Next.js `app/app/page.tsx` lines 162–253)

### Layout
```
[←]  [emoji] bill title  [ปิดบิล / เปิดใหม่]  [⚙️]
─────────────────────────────────────────────────
[สมาชิก(N)] [รายการ(N)] [สรุป] [วิเคราะห์]
```

### ปุ่ม "ปิดบิล" (draft → completed)
- สีเขียว `bg-emerald-500`, text "ปิดบิล", icon lock-closed
- กด → confirm dialog: title "ปิดบิลนี้?", description "หลังจากปิดแล้ว จะไม่สามารถแก้ไขสมาชิกหรือรายการได้ แต่ยังสามารถทำเครื่องหมายว่าจ่ายแล้วได้", confirmLabel "ปิดบิล"
- หลัง confirm → `completeBill(billId)` → update status → switch tab to "สรุป"

### ปุ่ม "เปิดใหม่" (completed → draft)
- สีเทา `bg-gray-100`, text "เปิดใหม่", icon lock-open
- กด → confirm dialog: title "เปิดบิลใหม่?", description "บิลจะกลับมาแก้ไขได้อีกครั้ง", confirmLabel "เปิดใหม่"
- หลัง confirm → `reopenBill(billId)` → update status

### ปุ่ม ⚙️ (gear)
- แสดงเฉพาะ: `isOwner && !isCompleted`
- กด → เปิด CreateEntitySheet (mode=edit, type=bill)

### Badge "ปิดแล้ว" ใน title
- แสดงเฉพาะ isCompleted
- สีเขียว, icon lock-closed, text "ปิดแล้ว"

### Tab Bar (pill style)
```dart
// 4 tabs
const tabs = [
  {'id': 'members', 'label': 'สมาชิก', 'icon': Icons.people_outline},
  {'id': 'items',   'label': 'รายการ', 'icon': Icons.receipt_outlined},
  {'id': 'summary', 'label': 'สรุป',   'icon': Icons.bar_chart},
  {'id': 'analytics','label':'วิเคราะห์','icon': Icons.analytics_outlined},
];
```
- Container: gray bg `#F3F4F6`, borderRadius 16, padding 4
- Active: white bg, blue text `#4366f4`, shadow
- Inactive: gray text `#6B7280`
- Count badge บน "สมาชิก" (members.length) และ "รายการ" (items.length)
  - Active badge: `bg-blue-50 text-[#4366f4]`
  - Inactive badge: `bg-gray-200 text-gray-500`

### Completed Banner (ใต้ header)
```
🔒  บิลนี้ปิดแล้ว — ดูได้อย่างเดียว ไม่สามารถแก้ไขได้
```
- bg: `#ECFDF5` (emerald-50), border: `#A7F3D0` (emerald-200)
- text: `#065F46` (emerald-700), font-medium

---

## 🔧 2. Members Tab (ตรงกับ `MemberPage.tsx`)

### Add Member Form (ซ่อนถ้า readOnly=true)
```
ชื่อสมาชิก *
[___________________]

สีประจำตัว
[●][●][●][●][●][●][●][●][●][●]  ← 10 circles

พร้อมเพย์ (ไม่บังคับ)
[___________________]

[  เพิ่มสมาชิก  ]
```

**10 สีที่ใช้ (ตรงกับ Next.js):**
```dart
const kMemberColors = [
  '#ef4444', // red
  '#f97316', // orange
  '#eab308', // yellow
  '#22c55e', // green
  '#14b8a6', // teal
  '#3b82f6', // blue
  '#8b5cf6', // violet
  '#ec4899', // pink
  '#6b7280', // gray
  '#1a1d2e', // dark
];
```
- Default color = สีแรกที่ยังไม่ถูกใช้ใน members list
- Selected color: border 2px สีนั้น + checkmark icon ตรงกลาง

### Member List
แต่ละ row:
```
[●avatar]  ชื่อ                    [✏️] [🗑️]
           พร้อมเพย์: 0812345678
           [ภายนอก] [คุณ]
```
- Avatar: circle 36px, bg = member.color, initial letter สีขาว
- Badge "ภายนอก": gray bg, text "ภายนอก" (ถ้า is_external=true)
- Badge "คุณ": blue bg, text "คุณ" (ถ้า user_id = currentUserId)
- ปุ่ม ✏️ → เปิด MemberFormSheet (edit mode, pre-fill ข้อมูล)
- ปุ่ม 🗑️ → confirm dialog → deleteMember

### MemberFormSheet (edit)
- เหมือน add form แต่ pre-fill ชื่อ + สี + promptpay
- ปุ่ม "บันทึก"

---

## 🔧 3. Items Tab (ตรงกับ `ItemPage.tsx`)

### Total Banner (top)
```
┌─────────────────────────────────────────┐
│  ยอดรวม  ฿1,234.00   •  5 รายการ       │  ← gradient blue
└─────────────────────────────────────────┘
```
- Gradient `#4366f4` → `#6b8aff`, text white

### Item List
แต่ละ row:
```
[emoji/icon]  ชื่อรายการ              ฿250.00
              [👤][👤][👤]  paid: [👤]  [✏️][🗑️]
```
- Avatar stack: แสดง member avatars ที่แชร์ item (overlap 8px)
- paid_by: แสดง avatar ของคนที่จ่าย + "จ่ายโดย: ชื่อ"
- ถ้า readOnly: ซ่อนปุ่ม ✏️ 🗑️

### FAB / ปุ่ม "เพิ่มรายการ"
- ซ่อนถ้า readOnly=true
- สีน้ำเงิน, full width หรือ FAB

---

## 🔧 4. ItemFormSheet (ตรงกับ `ItemFormModal.tsx` ทุกบรรทัด)

### Layout
```
[X]  เพิ่มรายการ / แก้ไขรายการ
─────────────────────────────────
ชื่อรายการ
[___________________]

ราคารวม (บาท)
[___________________]

ใครจ่ายไปก่อน *
[👤 ชื่อ1] [👤 ชื่อ2] [👤 ชื่อ3]  ← chip selector

วิธีหาร
[  หารเท่า  ] [  หารไม่เท่า  ]  ← toggle

เลือกสมาชิก          [เลือกทั้งหมด] [ล้าง]
[✓ ชื่อ1  ฿83.33]   ← equal mode: แสดง per-person
[✓ ชื่อ2  ฿83.33]
[  ชื่อ3         ]

(unequal mode: แสดง input ข้างๆ)
[✓ ชื่อ1] [___83.33___]
[✓ ชื่อ2] [___83.33___]
รวม ฿166.66 / ฿250.00  ← running total

[  เพิ่มรายการ  ] [X]
```

### Logic (ตรงกับ Next.js `ItemFormModal.tsx`)

**paid_by selector:**
- แสดงทุก member เป็น chip
- Selected: blue border + blue bg + checkmark icon แทน avatar
- Default = members[0].id

**Split mode toggle:**
- "หารเท่า" / "หารไม่เท่า"
- Active: blue bg + white text
- Inactive: gray bg

**Equal mode:**
- แสดง per-person amount ข้างๆ ชื่อ: `฿{price / selectedCount}`
- shares = `{memberId: 1}` สำหรับทุกคนที่เลือก

**Unequal mode:**
- แสดง number input ข้างๆ แต่ละ member
- Running total: `รวม ฿X / ฿Y`
- shares = `{memberId: amount}` (raw amount, ไม่ใช่ weight)

**Validation (ตรงกับ Next.js):**
```dart
// ชื่อว่าง → error "กรุณาใส่ชื่อรายการ"
// ราคา <= 0 → error "กรุณาใส่ราคา"
// ไม่เลือก member → error "เลือกสมาชิกอย่างน้อย 1 คน"
// unequal: |unequalTotal - price| > 0.01 →
//   error "ยอดรวมต้องเท่ากับ ฿X (ตอนนี้ ฿Y)"
```

**buildShares:**
```dart
// equal: {id: 1} for each selected
// unequal: {id: amount} for each selected
```

**Edit mode:**
- pre-fill name, price, paid_by
- ตรวจ shares: ถ้าทุก value = 1 → equal mode
- ถ้าไม่ → unequal mode, แปลง weight → amount:
  `amount = (weight / totalWeight) * price`

---

## ✅ Acceptance Criteria

- [ ] Tab bar 4 แท็บ สลับได้ + count badges
- [ ] Header: ปุ่ม ⚙️ แสดงเฉพาะ owner + draft
- [ ] ปุ่ม "ปิดบิล" → confirm → completeBill → switch to สรุป tab
- [ ] ปุ่ม "เปิดใหม่" → confirm → reopenBill
- [ ] Completed banner แสดงเมื่อ status=completed
- [ ] Members tab: color picker 10 สี + default = สีที่ยังไม่ใช้
- [ ] เพิ่ม/แก้ไข/ลบ member ได้
- [ ] Items tab: total banner gradient
- [ ] เพิ่ม/แก้ไข/ลบ item ได้
- [ ] ItemFormSheet: paid_by selector ทำงาน
- [ ] Equal split: per-person amount แสดงถูกต้อง
- [ ] Unequal split: running total + validate = price
- [ ] readOnly=true ซ่อนปุ่ม add/edit/delete ทั้งหมด
