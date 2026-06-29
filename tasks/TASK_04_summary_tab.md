# TASK 04 — Bill Detail: Summary Tab

## 🎯 เป้าหมาย
แปลง `SummaryPage.tsx` จาก Next.js เป็น Flutter widget
ให้ UI และ logic เหมือนกันทุกจุด

**Next.js source:** `components/summary/SummaryPage.tsx` (726 lines)

---

## 📁 ไฟล์ที่สร้าง/แก้

| ไฟล์ | action |
|------|--------|
| `lib/widgets/summary_tab.dart` | สร้างใหม่ |
| `lib/utils/bill_utils.dart` | เพิ่ม `calculateBill`, `simplifyDebtsPerItem`, `getTotalEmoji` |
| `lib/providers/bill_provider.dart` | เพิ่ม `toggleMemberPaid(billId, memberId, currentPaidIds)` |
| `pubspec.yaml` | เพิ่ม `qr_flutter: ^4.1.0` |

---

## 🔧 1. PromptPay QR Logic (ตรงกับ Next.js lines 27–65)

### `generatePromptPayPayload(String target, double amount) → String`

```dart
// ตรวจ format:
// phone: /^0\d{9}$/ → targetTag = "01", แปลง "0812345678" → "66812345678"
// nationalId: /^\d{13}$/ → targetTag = "02"

// TLV helper: tag(2) + len(2, zero-padded) + value
String tlv(String tag, String value) {
  final len = value.length.toString().padLeft(2, '0');
  return '$tag$len$value';
}

// merchantInfo = tlv("00","01") + tlv("01","A000000677010111") + tlv(targetTag, targetFormatted)
// payload = tlv("00","01") + tlv("01","12") + tlv("29", merchantInfo)
//         + tlv("53","764") + (amount>0 ? tlv("54", amount.toStringAsFixed(2)) : "")
//         + tlv("58","TH") + tlv("62", tlv("07","KIDTANG"))

// CRC-16/CCITT:
// withCrc = payload + "6304"
// crc = 0xFFFF, XOR each char << 8, 8 rounds
// append (crc & 0xFFFF).toRadixString(16).toUpperCase().padLeft(4,'0')
```

### PromptPayQR Widget
```dart
// ใช้ package qr_flutter
QrImageView(
  data: generatePromptPayPayload(promptpay, amount),
  version: QrVersions.auto,
  size: 180,
  backgroundColor: Colors.white,
)
// ใต้ QR: "สแกนโอนให้ {name}" + promptpay number
```

---

## 🔧 2. `calculateBill` (ตรงกับ `lib/utils.ts`)

```dart
class MemberItemSummary {
  final BillItem item;
  final double amount; // after VAT/SC multiplier
}

class MemberSummary {
  final BillMember member;
  final double total;
  final List<MemberItemSummary> items;
}

class BillCalcResult {
  final double subtotal;    // sum of item prices
  final double serviceAmount;
  final double vatAmount;
  final double tipAmount;
  final double discountAmount;
  final double total;
  final List<MemberSummary> memberSummaries;
}

BillCalcResult calculateBill(Bill bill) {
  // 1. subtotal = sum(item.price for item in items)
  // 2. serviceAmount = isService ? subtotal * serviceCharge/100 : 0
  // 3. vatAmount = isVat ? (subtotal + serviceAmount) * vat/100 : 0
  // 4. total = subtotal + serviceAmount + vatAmount
  // 5. multiplier = subtotal > 0 ? total / subtotal : 1
  // 6. For each member:
  //    - items = items where member.id in item.shares
  //    - amount per item = (shares[member.id] / sum(shares.values)) * item.price * multiplier
  //    - total = sum(amounts)
}
```

### `simplifyDebtsPerItem` (ตรงกับ Next.js)
```dart
// Input: memberSummaries, members, currentUserId (null = all)
// Output: List<DebtTransaction> {from, to, amount}
// Logic: สำหรับแต่ละ item ที่มี paid_by:
//   member ที่ไม่ใช่ payer แต่มี share → owes payer
//   group by (from, to) แล้ว sum amount
//   filter amount > 0.005
```

### `getTotalEmoji(double amount) → String`
```dart
// amount < 100  → "🤏"
// amount < 500  → "💸"
// amount < 1000 → "💰"
// amount < 3000 → "🤑"
// else          → "🏦"
```

---

## 🔧 3. Summary Tab Widget Layout

### Empty State (members.length == 0)
```
เพิ่มสมาชิกและรายการก่อน
```

### Hero Card (ตรงกับ Next.js lines 217–251)
```
┌─────────────────────────────────────────┐
│ ยอดรวมทั้งสิ้น                          │  gradient #4366f4 → #6b8aff
│ 1,234.00 บาท  💰                        │  text-3xl bold
│ รวม Service Charge 10%  (ถ้ามี)         │  text-xs opacity-70
│ รวม VAT 7%  (ถ้ามี)                     │
│ ─────────────────────────────────────── │  (isCompleted only)
│ สถานะการชำระ              2/3 คน        │
│ [████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░] │  progress bar white/20
│ ✅ ทุกคนจ่ายแล้ว!  (ถ้า allPaid)       │
└─────────────────────────────────────────┘
```

### Bill Breakdown Card (ตรงกับ Next.js lines 254–274)
```
รายละเอียดบิล
─────────────────────────────────────────
ยอดรวมสินค้า              ฿1,000.00
Service Charge (10%)       ฿100.00   (ถ้ามี)
VAT (7%)                   ฿77.00    (ถ้ามี)
─────────────────────────────────────────
รวมทั้งสิ้น               ฿1,177.00  (bold)
```
- bg: `#F9FAFB` (gray-50), borderRadius 16

### Member Selector (horizontal scroll, ตรงกับ Next.js lines 277–321)
```
ดูสรุปของ
[👤 ชื่อ1 คุณ] [👤 ชื่อ2 ✓] [👤 ชื่อ3]
```
- Selected: blue bg `#4366f4` + white text
- Paid (not selected): emerald-50 bg + emerald border + green text + ✓ icon
- Unselected: gray-100 bg
- "คุณ" badge: ถ้า member.user_id == currentUserId

### Selected Member Detail Card (ตรงกับ Next.js lines 324–384)
```
┌─────────────────────────────────────────┐
│ [avatar 44px]  ชื่อ  [ภายนอก] [คุณ]   │
│                พร้อมเพย์: 0812345678    │
│                              1,234 บาท  │
│                              💰 ส่วนของฉัน│
├─────────────────────────────────────────┤
│ รายการที่สั่ง                           │
│ ข้าวผัด                      83.33 บาท │
│ ต้มยำ                        166.67 บาท│
│ ─────────────────────────────────────── │
│ รวม (รวม VAT/SC)             250.00 บาท│
└─────────────────────────────────────────┘
```

### Debt Arrows for Selected Member (ตรงกับ Next.js lines 387–484)
หัวข้อ: "ฉันต้องโอนให้" (ถ้า currentUser) หรือ "{ชื่อ} ต้องโอนให้"

แต่ละ debt card:
```
┌─────────────────────────────────────────┐
│ [from avatar] → [to avatar]  ชื่อ to   │
│                พร้อมเพย์: 0812345678    │
│                              250 บาท [QR]│
├─────────────────────────────────────────┤  (isCompleted only)
│ ○ ยังไม่ได้จ่าย    [จ่ายแล้ว ✓]       │
│ (ถ้า paid: ✓ จ่ายแล้ว  [ยกเลิก])      │
└─────────────────────────────────────────┘
```
- Paid state: emerald-50 bg + emerald border, amount line-through
- QR button: กด → expand PromptPayQR widget ใต้ card
- "จ่ายแล้ว" button: เฉพาะ isCompleted → `toggleMemberPaid(billId, from.id, paidIds)`

### No Debts Message
```
✅  คุณไม่ต้องโอนให้ใคร
```
- bg: emerald-50, text: emerald-700

### All Members Section (collapsible, ตรงกับ Next.js lines 516–703)
- Header: "สรุปทุกคน" + chevron toggle
- กด expand → แสดง:

**Debt Arrows Overview:**
```
ใครโอนให้ใคร
[from avatar] ชื่อ → [to avatar] ชื่อ    250 บาท  [✓]
```
- Paid: line-through + emerald checkmark

**Per-member breakdown:**
```
[avatar 36px]  ชื่อ  [ภายนอก][คุณ][จ่ายแล้ว]
               พร้อมเพย์: xxx
                              1,234 บาท  [QR]
├── ข้าวผัด                   83.33 บาท
└── ต้มยำ                    166.67 บาท
[จ่ายแล้ว toggle]  (isCompleted only)
```

---

## 🔧 4. Colors Reference

```dart
// Emerald
const kEmerald50  = Color(0xFFECFDF5);
const kEmerald100 = Color(0xFFD1FAE5);
const kEmerald200 = Color(0xFFA7F3D0);
const kEmerald400 = Color(0xFF34D399);
const kEmerald500 = Color(0xFF10B981);
const kEmerald600 = Color(0xFF059669);
const kEmerald700 = Color(0xFF065F46);

// Blue
const kBlue400 = Color(0xFF4366f4);
const kBlue500 = Color(0xFF6b8aff);
```

---

## ✅ Acceptance Criteria

- [ ] Hero card gradient + total + emoji ถูกต้อง
- [ ] Service/VAT แสดงเฉพาะเมื่อ isService/isVat = true
- [ ] Payment progress bar แสดงเฉพาะ isCompleted
- [ ] Bill breakdown rows ถูกต้อง (subtotal, SC, VAT, total)
- [ ] Member selector horizontal scroll + 3 states (selected/paid/default)
- [ ] Selected member card: items breakdown + total
- [ ] Debt arrows: from → to + amount
- [ ] QR button expand/collapse PromptPayQR
- [ ] "จ่ายแล้ว" toggle ทำงานเฉพาะ isCompleted
- [ ] All members section collapsible
- [ ] PromptPay QR generate ถูกต้อง (CRC-16)
- [ ] Empty state เมื่อไม่มี members
