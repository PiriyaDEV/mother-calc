# TASK 05 — Bill Detail: Analytics Tab

## 🎯 เป้าหมาย
แปลง `AnalyticsPage.tsx` จาก Next.js เป็น Flutter widget
ให้ UI และ logic เหมือนกันทุกจุด

**Next.js source:** `components/summary/AnalyticsPage.tsx` (291 lines)

---

## 📁 ไฟล์ที่สร้าง/แก้

| ไฟล์ | action |
|------|--------|
| `lib/widgets/analytics_tab.dart` | สร้างใหม่ |

> หมายเหตุ: `calculateBill` และ `getTotalEmoji` ถูกสร้างใน TASK 04 แล้ว

---

## 🔧 Layout ทั้งหมด (ตรงกับ Next.js ทุก section)

### Empty State (ตรงกับ Next.js lines 43–51)
```
📊
เพิ่มสมาชิกและรายการก่อน
Analytics จะแสดงเมื่อมีข้อมูล
```
- แสดงเมื่อ `items.isEmpty || members.isEmpty`

---

### 1. Stats Row — 3 cards (ตรงกับ Next.js lines 56–78)

```
┌──────────┐ ┌──────────┐ ┌──────────┐
│ 🧾       │ │ 👥       │ │ 💰       │
│ 5        │ │ 3        │ │ 412      │
│ รายการ   │ │ คน       │ │ บาท      │
│รายการทั้งหมด│ │ สมาชิก  │ │ เฉลี่ย/คน│
└──────────┘ └──────────┘ └──────────┘
```

**StatCard widget:**
```dart
// color = "blue"   → gradient from-blue-50 to-indigo-50, border blue-100
// color = "purple" → gradient from-purple-50 to-violet-50, border purple-100
// color = "green"  → gradient from-emerald-50 to-teal-50, border emerald-100

// Flutter colors:
const kStatBlueFrom   = Color(0xFFEFF6FF); // blue-50
const kStatBlueTo     = Color(0xFFEEF2FF); // indigo-50
const kStatPurpleFrom = Color(0xFFFAF5FF); // purple-50
const kStatPurpleTo   = Color(0xFFF5F3FF); // violet-50
const kStatGreenFrom  = Color(0xFFECFDF5); // emerald-50
const kStatGreenTo    = Color(0xFFF0FDFA); // teal-50
```

Layout ใน card:
```
emoji (text-xl)
value (text-lg, bold, gray-900)
sub   (text-10, gray-500)   ← "รายการ" / "คน" / "บาท"
label (text-10, gray-400)   ← "รายการทั้งหมด" / "สมาชิก" / "เฉลี่ย/คน"
```

**Data:**
```dart
// card 1: emoji="🧾", value=items.length.toString(), sub="รายการ", label="รายการทั้งหมด", color=blue
// card 2: emoji="👥", value=members.length.toString(), sub="คน", label="สมาชิก", color=purple
// card 3: emoji=getTotalEmoji(avgPerPerson), value=formatNumber(avgPerPerson,0), sub="บาท", label="เฉลี่ย/คน", color=green
// avgPerPerson = members.isNotEmpty ? calc.total / members.length : 0
```

---

### 2. Biggest Spender Card (ตรงกับ Next.js lines 81–102)

```
┌─────────────────────────────────────────┐
│ 🏆 จ่ายเยอะสุด                          │  amber-600, uppercase
│ [avatar 40px]  ชื่อ                     │
│                3 รายการ                 │  gray-500
│                              1,234 บาท  │  amber-600, bold
│                              42% ของบิล │  gray-400
└─────────────────────────────────────────┘
```

**Colors:**
```dart
// bg: gradient from-amber-50 to-orange-50
const kAmber50  = Color(0xFFFFFBEB);
const kOrange50 = Color(0xFFFFF7ED);
const kAmberBorder = Color(0xFFFDE68A); // amber-100
const kAmber600 = Color(0xFFD97706);
```

**Data:**
```dart
// biggestPayer = memberTotals[0] (sorted desc by total)
// memberTotals = calc.memberSummaries.map((s) => {member, total, itemCount: s.items.length}).sortedByDesc(total)
// % ของบิล = calc.total > 0 ? (biggestPayer.total / calc.total * 100).round() : 0
```

---

### 3. Member Spending Bar Chart (ตรงกับ Next.js lines 104–143)

หัวข้อ: `💸 ค่าใช้จ่ายแต่ละคน`

แต่ละ row:
```
🥇  ชื่อ1                    1,234 บาท (42%)
    [████████████████████░░░░░░░░░░░░░░░░]  ← member.color
🥈  ชื่อ2                      800 บาท (27%)
    [████████████░░░░░░░░░░░░░░░░░░░░░░░░]
🥉  ชื่อ3                      600 บาท (20%)
    [█████████░░░░░░░░░░░░░░░░░░░░░░░░░░░]
[avatar 16px] ชื่อ4            334 บาท (11%)
    [█████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░]
```

**Logic:**
```dart
// rank 0 → "🥇", rank 1 → "🥈", rank 2 → "🥉", rank >= 3 → MemberAvatar(size:16)
// pct = maxMemberTotal > 0 ? (total / maxMemberTotal) * 100 : 0
// billPct = calc.total > 0 ? (total / calc.total * 100).round() : 0
// bar color = member.color (hex string → Color)
// bar height = 8px (h-2), bg = gray-200
```

---

### 4. Top Items Bar Chart (ตรงกับ Next.js lines 145–186)

หัวข้อ: `🔥 รายการแพงสุด`

```dart
// topItems = items.sortedByDesc(price).take(5)
```

แต่ละ row:
```
🥇  ข้าวผัดกุ้ง (max-width 140px)    500 บาท (3 คน)
    [████████████████████████████████░░░░]  ← gradient blue
🥈  ต้มยำทะเล                         350 บาท (2 คน)
    [██████████████████████░░░░░░░░░░░░░░]
4.  ไข่เจียว                           80 บาท (1 คน)
    [█████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░]
```

**Logic:**
```dart
// rank 0 → "🥇", rank 1 → "🥈", rank 2 → "🥉", rank >= 3 → "${rank+1}."
// pct = maxItemPrice > 0 ? (item.price / maxItemPrice) * 100 : 0
// sharedCount = item.shares.keys.length
// bar: gradient #4366f4 → #6b8aff, height 6px (h-1.5)
```

---

### 5. Fairness Section (ตรงกับ Next.js lines 188–239)

แสดงเฉพาะ `memberTotals.length >= 2`

```
⚖️ ความเท่าเทียม
─────────────────────────────────────────
จ่ายน้อยสุด    [emoji]    จ่ายเยอะสุด
  ชื่อ3          😊          ชื่อ1
  600 บาท       1.5x       1,234 บาท
─────────────────────────────────────────
เฉลี่ยต่อคน  678 บาท
```

**Fairness emoji logic (ตรงกับ Next.js lines 206–212):**
```dart
double ratio = biggestPayer.total / (smallestPayer.total > 0 ? smallestPayer.total : 1);
String fairnessEmoji;
if (ratio > 3.0) {
  fairnessEmoji = "😬";
} else if (ratio > 1.5) {
  fairnessEmoji = "🤔";
} else {
  fairnessEmoji = "😊";
}
String ratioText = "${ratio.toStringAsFixed(1)}x";
```

**Colors:**
```dart
// จ่ายน้อยสุด amount: color #10b981 (emerald-500)
// จ่ายเยอะสุด amount: color #F59E0B (amber-500)
// ratio text: gray-400, text-10
// เฉลี่ยต่อคน value: gray-600, font-semibold
```

---

### 6. Items Per Member Grid (ตรงกับ Next.js lines 241–260)

หัวข้อ: `📋 รายการต่อคน`

```
┌──────────────────┐ ┌──────────────────┐
│ [avatar 24px]    │ │ [avatar 24px]    │
│ ชื่อ1            │ │ ชื่อ2            │
│ 3 รายการ         │ │ 2 รายการ         │
└──────────────────┘ └──────────────────┘
```

**Layout:**
```dart
// 2-column GridView
// แต่ละ cell: bg white, borderRadius 12, padding horizontal 12 vertical 8
// Row: MemberAvatar(size:24) + Column(ชื่อ text-xs + "X รายการ" text-10 gray-400)
```

---

## ✅ Acceptance Criteria

- [ ] Empty state แสดงเมื่อ items หรือ members ว่าง
- [ ] Stats 3 cards: สี gradient ถูกต้อง (blue/purple/green)
- [ ] Stats values: items.length, members.length, avgPerPerson ถูกต้อง
- [ ] Biggest spender card: amber gradient + ชื่อ + itemCount + total + %
- [ ] Member bar chart: rank emoji 🥇🥈🥉 + avatar สำหรับ rank 4+
- [ ] Member bar: width = (total/maxTotal)*100%, color = member.color
- [ ] Top items: top 5 sorted by price desc
- [ ] Top items bar: gradient blue, width = (price/maxPrice)*100%
- [ ] Fairness emoji: 😬 (>3x), 🤔 (>1.5x), 😊 (else)
- [ ] Fairness ratio text: "X.Xx"
- [ ] Items per member: 2-column grid
