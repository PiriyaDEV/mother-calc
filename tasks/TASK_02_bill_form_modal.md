# TASK 02 — Bill / Group Form Sheet (CreateEntityModal → Flutter)

## 🎯 เป้าหมาย
แปลง `CreateEntityModal.tsx` จาก Next.js เป็น Flutter bottom sheet
ให้ UI และ behavior เหมือนกันทุกจุด

---

## 📁 ไฟล์ที่สร้าง/แก้

| ไฟล์ | action |
|------|--------|
| `lib/widgets/create_entity_sheet.dart` | สร้างใหม่ |
| `lib/widgets/bill_status_pill.dart` | สร้างใหม่ |
| `lib/widgets/confirm_dialog.dart` | สร้างใหม่ |
| `lib/screens/bills_screen.dart` | เพิ่ม edit/delete + BillStatusPill |
| `lib/screens/groups_screen.dart` | เพิ่ม edit/delete |

---

## 🔧 1. `create_entity_sheet.dart`

### Data model (ตรงกับ `EntityFormData` ใน Next.js)
```dart
class EntityFormData {
  final String name;
  final String? emoji;
  final String description;
  final List<String> tags;
  final BillSettings? settings; // bill only
}

class BillSettings {
  final bool isVat;
  final double vat;        // default 7
  final bool isService;
  final double serviceCharge; // default 10
  final String currency;   // default "THB"
  final String roundingMode; // "none"|"nearest"|"up"|"down"
}
```

### Constants (ตรงกับ Next.js `EMOJI_PRESETS` และ `DEFAULT_TAGS`)
```dart
const kEmojiPresets = [
  '🍜','🍕','🍺','🎉','✈️','🏖️','🎂','🛒','🏠','💊',
  '🎮','🎵','🚗','⚽','📚','💼','🌮','🍣','🥗','🍔',
  '🍦','☕','🍷','🎁','🏋️','🎬','🛫','🏕️','🎯','💰',
];

const kDefaultTags = [
  'อาหาร','เที่ยว','ปาร์ตี้','ช้อปปิ้ง','ที่พัก',
  'เดินทาง','บันเทิง','สุขภาพ','การศึกษา','อื่นๆ',
];

const kCurrencies = [
  {'code':'THB','flag':'🇹🇭','symbol':'฿','label':'บาท'},
  {'code':'USD','flag':'🇺🇸','symbol':'\$','label':'USD'},
  {'code':'EUR','flag':'🇪🇺','symbol':'€','label':'EUR'},
  {'code':'JPY','flag':'🇯🇵','symbol':'¥','label':'JPY'},
  {'code':'SGD','flag':'🇸🇬','symbol':'S\$','label':'SGD'},
  {'code':'GBP','flag':'🇬🇧','symbol':'£','label':'GBP'},
  {'code':'CNY','flag':'🇨🇳','symbol':'¥','label':'CNY'},
  {'code':'KRW','flag':'🇰🇷','symbol':'₩','label':'KRW'},
];

const kRoundingOptions = [
  {'value':'none','label':'ไม่ปัด'},
  {'value':'nearest','label':'ใกล้สุด'},
  {'value':'up','label':'ขึ้น'},
  {'value':'down','label':'ลง'},
];
```

### Layout (เหมือน Next.js ทุก section)

```
┌─────────────────────────────────┐
│ [X]  สร้างบิลใหม่               │  ← header
├─────────────────────────────────┤
│ [💰]  ชื่อบิล *                 │  ← emoji button + name field
│       placeholder: "เช่น ข้าวเย็น"│
├─────────────────────────────────┤
│ คำอธิบาย (ไม่บังคับ)            │  ← description field
├─────────────────────────────────┤
│ แท็ก                            │
│ [อาหาร] [เที่ยว] [ปาร์ตี้] ...  │  ← preset chips (toggle)
│ [___เพิ่มแท็กเอง___] [+]        │  ← custom tag input
├─────────────────────────────────┤
│ ── ตั้งค่าบิล ──  (bill only)   │
│ [VAT toggle] [Service toggle]   │  ← 2-column grid
│ สกุลเงิน: [🇹🇭฿] [🇺🇸$] ...    │  ← 2-column grid, 8 currencies
│ การปัดเศษ: [ไม่ปัด][ใกล้][ขึ้น][ลง]│  ← 4-column grid
├─────────────────────────────────┤
│ [    สร้างบิล    ]              │  ← submit button (blue)
│ [    ลบบิลนี้    ]              │  ← delete button (red border, edit only)
└─────────────────────────────────┘
```

### Emoji Picker Popup
- กด emoji button → แสดง popup (Overlay หรือ Stack)
- Grid 8 คอลัมน์, max height 192px, scrollable
- ปุ่มแรก: "✕" (clear emoji)
- Selected emoji: ring สีน้ำเงิน `ring-2 ring-[#4366f4]`
- กดเลือก → ปิด popup + set emoji

### VAT / Service Card (2-column grid)
```
┌──────────────┐ ┌──────────────┐
│ VAT  [toggle]│ │Service[toggle]│
│ [7___] %     │ │ [10__] %     │
│ (ถ้า off:    │ │ (ถ้า off:    │
│  "ปิดอยู่") │ │  "ปิดอยู่") │
└──────────────┘ └──────────────┘
```
- Toggle on → แสดง number input (default 7% / 10%)
- Toggle off → แสดง text "ปิดอยู่"

### Currency Grid (2-column, 8 items)
- Selected: blue bg + white text + checkmark icon
- Unselected: gray bg

### Rounding Grid (4-column)
- Selected: blue bg + white text
- Options: ไม่ปัด / ใกล้สุด / ขึ้น / ลง

### Behavior
- `type = "bill"` → แสดง settings section
- `type = "group"` → ซ่อน settings section
- `mode = "edit"` → pre-fill ข้อมูล + title "แก้ไขบิล" + แสดงปุ่มลบ
- `mode = "create"` → title "สร้างบิลใหม่" + ซ่อนปุ่มลบ
- ปุ่ม submit disabled ถ้า name ว่าง
- Loading state: "กำลังสร้าง..." / "กำลังบันทึก..."

---

## 🔧 2. `bill_status_pill.dart`

ตรงกับ `BillStatusPill.tsx` ใน Next.js:

```dart
// status = "draft" → สีเทา, text "ร่าง"
// status = "completed" → สีเขียว, text "เสร็จแล้ว"

Widget buildStatusPill(String status) {
  if (status == 'completed') {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Color(0xFFD1FAE5), // emerald-100
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text('เสร็จแล้ว',
        style: TextStyle(fontSize: 10, color: Color(0xFF059669), fontWeight: FontWeight.w600)),
    );
  }
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: Color(0xFFF3F4F6), // gray-100
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text('ร่าง',
      style: TextStyle(fontSize: 10, color: Color(0xFF6B7280), fontWeight: FontWeight.w500)),
  );
}
```

---

## 🔧 3. `confirm_dialog.dart`

```dart
// ใช้ showDialog + AlertDialog
// danger=true → confirm button สีแดง
// danger=false → confirm button สีน้ำเงิน

Future<bool?> showConfirmDialog(BuildContext context, {
  required String title,
  required String description,
  required String confirmLabel,
  bool danger = false,
})
```

---

## 🔧 4. Bills Screen — เพิ่ม

ใน bill card row เพิ่ม:
- `BillStatusPill(bill.status)` ใต้ชื่อบิล
- Tags chips (สูงสุด 2 tags + "+N" ถ้าเกิน)
- ปุ่ม gear icon → `showCreateEntitySheet(type:'bill', mode:'edit', initialData: bill)`
- ปุ่ม trash icon → `showConfirmDialog` → `deleteBill(bill.id)`

---

## 🔧 5. Groups Screen — เพิ่ม

เหมือน Bills Screen แต่ใช้ `type:'group'`

---

## ✅ Acceptance Criteria

- [ ] Emoji picker popup แสดง grid 8 คอลัมน์ + ปุ่ม clear
- [ ] Tags preset chips toggle ได้ + เพิ่ม custom tag ได้
- [ ] VAT toggle → แสดง/ซ่อน % input (default 7%)
- [ ] Service toggle → แสดง/ซ่อน % input (default 10%)
- [ ] Currency grid 8 ตัว เลือกได้ 1 ตัว
- [ ] Rounding 4 ตัว เลือกได้ 1 ตัว
- [ ] mode=edit pre-fill ข้อมูลเดิมครบ
- [ ] ปุ่มลบแสดงเฉพาะ mode=edit
- [ ] BillStatusPill สีถูกต้อง (draft=gray, completed=green)
- [ ] Bills screen มี gear + trash icon ต่อ row
- [ ] Groups screen มี gear + trash icon ต่อ row
