# TASK 01 — Home Screen

## 🎯 เป้าหมาย
แปลง `app/home/page.tsx` จาก Next.js เป็น Flutter
ให้ UI และ behavior เหมือนกันทุกจุด

**Next.js source:** `app/home/page.tsx` (369 lines)

---

## 📁 ไฟล์ที่แก้

| ไฟล์ | action |
|------|--------|
| `lib/screens/home_screen.dart` | ปรับ layout ทั้งหมด |

---

## 🔧 1. State (ตรงกับ Next.js lines 59–67)

```dart
List<Group> _groups = [];
List<Bill> _personalBills = [];
Map<String, List<Bill>> _groupBills = {};
bool _dataLoading = true;

// Currency
List<RateData> _rates = [];
bool _ratesLoading = true;
String _ratesUpdated = '';
```

**Data computed:**
```dart
// allBills = [...personalBills, ...groupBills.values.expand((b) => b)]
// grandTotal = allBills.fold(0.0, (s, b) => s + getBillTotal(b))
// totalItems = allBills.fold(0, (s, b) => s + (b.items?.length ?? 0))
// avgBill = allBills.isNotEmpty ? grandTotal / allBills.length : 0
// biggestBill = allBills.isEmpty ? null : allBills.reduce((a, b) => getBillTotal(a) > getBillTotal(b) ? a : b)
// recentBills = allBills.sortedByDesc(updated_at).take(3)
```

---

## 🔧 2. Hero Card (ตรงกับ Next.js lines 141–167)

```
┌─────────────────────────────────────────┐
│ สวัสดี, {firstName} 👋        [wallet]  │  gradient #286bfe → #6b8aff
│ ยอดรวมทั้งหมดของคุณ                     │
│                                         │
│ 12,345.00 บาท                           │  text-3xl bold
│ 2 กลุ่ม · 3 บิลส่วนตัว · 15 รายการ    │  text-xs opacity-70
└─────────────────────────────────────────┘
```
- gradient: `#286bfe` → `#6b8aff`, borderRadius 24
- wallet icon: 36px container, bg white/20, borderRadius 12
- loading state: spinner white
- firstName = displayName.split(' ')[0]
- displayName = user.userMetadata['full_name'] ?? email.split('@')[0] ?? 'คุณ'

---

## 🔧 3. Quick Actions — 3 buttons (ตรงกับ Next.js lines 170–201)

```
┌──────────┐ ┌──────────┐ ┌──────────┐
│ [people] │ │ [receipt]│ │ [add]    │
│  กลุ่ม   │ │   บิล    │ │  เพื่อน  │
│ X กลุ่ม  │ │  X บิล   │ │ จัดการ   │
└──────────┘ └──────────┘ └──────────┘
```

| ปุ่ม | icon | icon bg | icon color | card bg | navigate |
|------|------|---------|------------|---------|----------|
| กลุ่ม | IoPeopleOutline | purple-50 `#FAF5FF` | purple-500 `#A855F7` | white | /groups |
| บิล | IoReceiptOutline | white/20 | white | `#286bfe` | /bills |
| เพื่อน | IoAddOutline | green-50 `#F0FDF4` | green-500 `#22C55E` | white | /friends |

- icon container: 40px, borderRadius 12
- label: text-xs font-semibold
- sub: text-10 (groups.length / personalBills.length / "จัดการ")
- บิล card: bg `#286bfe`, text white, text/70 for sub

---

## 🔧 4. Currency Exchange Rates (ตรงกับ Next.js lines 204–262)

### Header
```
อัตราแลกเปลี่ยน                          [🔄]
อัปเดต HH:MM
```
- refresh button: 28px, bg gray-100, borderRadius 8
- loading → icon spin

### Horizontal Scroll Cards (ตรงกับ Next.js lines 222–261)
```
┌──────────────┐
│           🇺🇸 │  ← flag emoji bg, opacity 20%, absolute bottom-right
│ ↑ 0.12%      │  ← change (green=up, red=down), แสดงเฉพาะ change != 0
│ ฿33.50       │  bold
│ 1 USD        │  text-10 gray-400
│ ดอลลาร์สหรัฐ │  text-10 gray-500
└──────────────┘
```
- card: width 144px, bg white, border gray-100, borderRadius 16, padding 14
- flag: absolute -right-2 -bottom-2, text-6xl, opacity 20%
- loading: 5 skeleton cards (animate pulse)

**Currencies (ตรงกับ Next.js lines 36–47):**
```dart
const currencies = [
  {code: 'USD', name: 'ดอลลาร์สหรัฐ',      flag: '🇺🇸'},
  {code: 'EUR', name: 'ยูโร',               flag: '🇪🇺'},
  {code: 'JPY', name: 'เยนญี่ปุ่น',         flag: '🇯🇵'},
  {code: 'CNY', name: 'หยวนจีน',            flag: '🇨🇳'},
  {code: 'GBP', name: 'ปอนด์อังกฤษ',        flag: '🇬🇧'},
  {code: 'KRW', name: 'วอนเกาหลี',          flag: '🇰🇷'},
  {code: 'SGD', name: 'ดอลลาร์สิงคโปร์',    flag: '🇸🇬'},
  {code: 'AUD', name: 'ดอลลาร์ออสเตรเลีย',  flag: '🇦🇺'},
  {code: 'HKD', name: 'ดอลลาร์ฮ่องกง',      flag: '🇭🇰'},
  {code: 'MYR', name: 'ริงกิตมาเลเซีย',     flag: '🇲🇾'},
];
```

**Rate fetch (ตรงกับ Next.js lines 85–112):**
```dart
// GET https://open.er-api.com/v6/latest/THB
// rates[X] = how many X per 1 THB → invert: thbPerUnit = 1 / rates[X]
// JPY, KRW → toFixed(4), others → toFixed(2)
// Fallback rates (ถ้า fetch fail):
// USD:33.5, EUR:36.2, JPY:0.22, CNY:4.6, GBP:42.5
// KRW:0.025, SGD:24.8, AUD:21.5, HKD:4.3, MYR:7.2
// ratesUpdated = "ข้อมูลสำรอง" ถ้า fallback
```

---

## 🔧 5. Stats Section (ตรงกับ Next.js lines 271–281)

แสดงเฉพาะ `allBills.isNotEmpty`:

```
สถิติของคุณ
┌──────────────────┐ ┌──────────────────┐
│ [📈] เฉลี่ยต่อบิล│ │ [🧾] บิลทั้งหมด  │
│ 4,115.00 ฿       │ │ 3 บิล            │
└──────────────────┘ └──────────────────┘
┌──────────────────┐ ┌──────────────────┐
│ [🔥] รายการทั้งหมด│ │ [⭐] บิลใหญ่สุด  │
│ 15 รายการ        │ │ 12,345.00 ฿      │
└──────────────────┘ └──────────────────┘
```

**FactCard widget:**
```dart
// icon container: 36px, borderRadius 12
// label: text-10 gray-400
// value: text-sm bold gray-900
```

| card | icon | color | bg |
|------|------|-------|----|
| เฉลี่ยต่อบิล | IoTrendingUpOutline | `#286bfe` | blue-50 |
| บิลทั้งหมด | IoReceiptOutline | purple-500 | purple-50 |
| รายการทั้งหมด | IoFlameOutline | orange-500 | orange-50 |
| บิลใหญ่สุด | IoStarOutline | amber-500 | amber-50 |

---

## 🔧 6. Recent Bills (ตรงกับ Next.js lines 284–312)

แสดงเฉพาะ `recentBills.isNotEmpty`:

```
บิลล่าสุด                               [ดูทั้งหมด →]
─────────────────────────────────────────
[emoji 40px]  bill title                 1,234.00 ฿
              [status pill] X รายการ · d MMM
```
- card: bg white, border gray-100, borderRadius 16
- emoji container: 40px, bg blue-50, borderRadius 12
- title: text-sm font-semibold gray-900
- amount: text-sm bold `#286bfe`
- "ดูทั้งหมด": text-xs `#286bfe` font-semibold → navigate /bills
- กด card → navigate to bill detail

---

## 🔧 7. Biggest Bill Highlight (ตรงกับ Next.js lines 315–332)

แสดงเฉพาะ `biggestBill != null`:

```
┌─────────────────────────────────────────┐
│ ⭐ บิลที่ใหญ่ที่สุด                      │  text-xs gray-500 uppercase
│ [emoji 40px]  bill title                │
│               X รายการ                  │  text-xs gray-400
│                              12,345.00 ฿│  amber-500 bold
└─────────────────────────────────────────┘
```
- card: bg white, border gray-100, borderRadius 16
- emoji container: 40px, bg amber-50, borderRadius 12

---

## 🔧 8. Empty State (ตรงกับ Next.js lines 335–349)

แสดงเฉพาะ `allBills.isEmpty && !dataLoading`:

```
[receipt icon 28px]
ยังไม่มีบิล
สร้างบิลแรกหรือเข้าร่วมกลุ่มเพื่อเริ่มต้น
[สร้างบิล]  [สร้างกลุ่ม]
```
- icon container: 64px, bg blue-50, borderRadius 16
- ปุ่ม "สร้างบิล": bg `#286bfe`, text white, borderRadius 12
- ปุ่ม "สร้างกลุ่ม": bg gray-100, text gray-700, borderRadius 12

---

## ✅ Acceptance Criteria

- [ ] Hero card: gradient + firstName + grandTotal + stats row
- [ ] Hero: loading spinner ขณะ dataLoading
- [ ] Quick actions: 3 ปุ่ม navigate ได้ถูกต้อง
- [ ] Currency section: fetch จาก open.er-api.com
- [ ] Currency: fallback rates ถ้า fetch fail
- [ ] Currency: horizontal scroll cards + flag bg
- [ ] Currency: JPY/KRW แสดง 4 decimal, อื่นๆ 2 decimal
- [ ] Currency: refresh button + spin animation
- [ ] Stats: 4 FactCards (แสดงเฉพาะมีบิล)
- [ ] Recent bills: top 3 sorted by updated_at + BillStatusPill
- [ ] Biggest bill highlight card
- [ ] Empty state: 2 ปุ่ม navigate
