# TASK 09 — Nice to Have: Item Card Stacked Avatars + Summary Collapsible + Debt Arrows + Inline Member Edit

## 🎯 เป้าหมาย
ปรับปรุง UI ที่เหลือจาก GAP_ANALYSIS หมวด 🟢 Nice to Have ให้ตรงกับ Next.js ต้นฉบับ

**Next.js source references:**
- `app/app/page.tsx` — ItemPage, MemberPage
- `components/summary/SummaryPage.tsx` — All Members section

---

## 📁 ไฟล์ที่แก้

| ไฟล์ | action |
|------|--------|
| `lib/screens/bill_detail_screen.dart` | แก้ Item card + Member inline edit |
| `lib/widgets/summary_tab.dart` | แก้ All Members section (collapsible + debt arrows) |

---

## 🔧 1. Item Card — Stacked Avatars (แทน chips)

**ปัจจุบัน:** แสดง member เป็น colored chips พร้อมชื่อและราคา  
**เป้าหมาย:** แสดงเป็น stacked avatars (overlap) + "X คน · ฿Y/คน"

### Layout ใหม่ (ตรงกับ Next.js `ItemPage.tsx`)

```
[emoji]  ชื่อรายการ                    ฿250.00
         [👤][👤][👤]+1  3 คน · ฿83/คน
         จ่ายโดย: [👤] ชื่อ            [✏️][🗑️]
```

### Stacked Avatars Widget

```dart
// แสดง avatar ซ้อนกัน overlap 8px
// แสดงสูงสุด 3 avatar แรก
// ถ้ามีมากกว่า 3 → แสดง "+N" circle สีเทา
// แต่ละ avatar: circle 24px, bg = member.color, initial letter สีขาว
// border: 2px white (เพื่อให้เห็น overlap)

Widget _buildStackedAvatars(List<BillMember> members) {
  const maxShow = 3;
  final shown = members.take(maxShow).toList();
  final extra = members.length - maxShow;

  return SizedBox(
    width: 24.0 + (shown.length - 1) * 16.0 + (extra > 0 ? 20.0 : 0),
    height: 24,
    child: Stack(
      children: [
        ...shown.asMap().entries.map((e) => Positioned(
          left: e.key * 16.0,
          child: _MemberCircle(member: e.value, size: 24),
        )),
        if (extra > 0)
          Positioned(
            left: shown.length * 16.0,
            child: _ExtraCircle(count: extra, size: 24),
          ),
      ],
    ),
  );
}
```

### Per-person amount text

```dart
// equalSplit: ฿{price / members.length} ต่อคน
// unequalSplit: แสดงแค่ "X คน" (ไม่แสดง per-person)
final isEqual = item.shares.values.every((v) => v == 1.0);
final perPerson = isEqual && item.shares.isNotEmpty
    ? item.price / item.shares.length
    : null;

// Text: "${item.shares.length} คน${perPerson != null ? ' · ฿${perPerson.toStringAsFixed(0)}/คน' : ''}"
```

### Paid By display

```dart
// แสดง avatar 20px + "จ่ายโดย: {name}"
// ถ้าไม่มี paid_by → ไม่แสดง
```

---

## 🔧 2. Summary Tab — "สรุปทุกคน" Collapsible Section

**ปัจจุบัน:** แสดงตลอด (ไม่ collapsible)  
**เป้าหมาย:** collapsed by default, กด header เพื่อ expand

### Layout (ตรงกับ Next.js `SummaryPage.tsx` lines 516–703)

```
สรุปทุกคน                              [▼/▲]
─────────────────────────────────────────────
(เมื่อ expand)

ใครโอนให้ใคร
[from avatar] ชื่อ → [to avatar] ชื่อ    250 บาท  [✓]
[from avatar] ชื่อ → [to avatar] ชื่อ    100 บาท  [✓]

─────────────────────────────────────────────

[avatar 36px]  ชื่อ  [ภายนอก][คุณ][จ่ายแล้ว]
               พร้อมเพย์: 0812345678
                                    1,234 บาท  [QR]
  ├── ข้าวผัด                        83.33 บาท
  └── ต้มยำ                         166.67 บาท
  [จ่ายแล้ว ✓]  (isCompleted only)
```

### State

```dart
bool _allMembersExpanded = false; // default collapsed
```

### Header Widget

```dart
GestureDetector(
  onTap: () => setState(() => _allMembersExpanded = !_allMembersExpanded),
  child: Row(
    children: [
      Text('สรุปทุกคน', style: bold gray-900),
      Spacer(),
      Icon(_allMembersExpanded
          ? Icons.keyboard_arrow_up_rounded
          : Icons.keyboard_arrow_down_rounded,
          color: gray-400),
    ],
  ),
)
```

### Debt Arrows Overview (ตรงกับ Next.js lines 519–560)

```dart
// แสดงเฉพาะเมื่อ _allMembersExpanded = true
// ใช้ simplifyDebtsPerItem(memberSummaries, members, null) → allDebts
// แสดงทุก debt (ไม่ filter by currentUser)

// แต่ละ row:
Row(
  children: [
    _MemberCircle(member: from, size: 28),
    Icon(Icons.arrow_forward_rounded, size: 14, color: gray-400),
    _MemberCircle(member: to, size: 28),
    SizedBox(width: 8),
    Expanded(child: Text('${from.name} → ${to.name}')),
    Text('฿${amount.toStringAsFixed(2)}'),
    // ถ้า paid: checkmark icon สีเขียว + line-through amount
  ],
)
```

### Per-member breakdown (ตรงกับ Next.js lines 563–703)

```dart
// แสดงทุก member ใน memberSummaries
// แต่ละ member card:
// - Header: avatar 36px + ชื่อ + badges (ภายนอก, คุณ, จ่ายแล้ว)
// - promptpay row (ถ้ามี)
// - ยอดรวม + QR button (ถ้ามี promptpay)
// - item breakdown list (ชื่อ item + amount)
// - "จ่ายแล้ว" toggle (isCompleted only)
```

---

## 🔧 3. Member Inline Edit (แทน Bottom Sheet)

**ปัจจุบัน:** กด ✏️ → เปิด MemberFormSheet (bottom sheet)  
**เป้าหมาย:** กด ✏️ → expand inline ใน row เดิม (ไม่ต้องเปิด modal)

### Layout (ตรงกับ Next.js `MemberPage.tsx`)

```
[●avatar]  ชื่อ                    [✓][✗]
           พร้อมเพย์: 0812345678
           [ภายนอก] [คุณ]
─────────────────────────────────────────
ชื่อสมาชิก
[___________________]

สีประจำตัว
[●][●][●][●][●][●][●][●][●][●]

พร้อมเพย์ (ไม่บังคับ)
[___________________]
```

### State

```dart
// ใน _MembersTab state:
String? _editingMemberId; // null = ไม่มีใครกำลัง edit

// กด ✏️ → _editingMemberId = member.id
// กด ✗ → _editingMemberId = null
// กด ✓ → save → _editingMemberId = null
```

### Inline Edit Widget

```dart
// ถ้า member.id == _editingMemberId → แสดง expanded form
// ถ้าไม่ → แสดง normal row

AnimatedCrossFade(
  firstChild: _buildMemberRow(member),
  secondChild: _buildMemberEditForm(member),
  crossFadeState: _editingMemberId == member.id
      ? CrossFadeState.showSecond
      : CrossFadeState.showFirst,
  duration: Duration(milliseconds: 200),
)
```

### Save Logic

```dart
// กด ✓ → updateMember(billId, memberId, {name, color, promptpay})
// ถ้า success → _editingMemberId = null + _showSuccess
// ถ้า error → _showError
```

---

## 🔧 4. Colors Reference

```dart
// ใช้ร่วมกับ TASK 03 + 04
const kMemberColors = [
  '#ef4444', '#f97316', '#eab308', '#22c55e', '#14b8a6',
  '#3b82f6', '#8b5cf6', '#ec4899', '#6b7280', '#1a1d2e',
];
```

---

## ✅ Acceptance Criteria

### Item Card
- [ ] Stacked avatars (overlap 8px, max 3 + "+N")
- [ ] Per-person amount แสดงเฉพาะ equal split
- [ ] "จ่ายโดย: {name}" + avatar 20px

### Summary Collapsible
- [ ] "สรุปทุกคน" collapsed by default
- [ ] กด header → expand/collapse พร้อม animation
- [ ] Debt arrows overview แสดงเมื่อ expand
- [ ] Paid debt: line-through + checkmark icon
- [ ] Per-member breakdown แสดงเมื่อ expand

### Member Inline Edit
- [ ] กด ✏️ → expand inline form (ไม่เปิด bottom sheet)
- [ ] กด ✗ → collapse กลับ
- [ ] กด ✓ → save + collapse
- [ ] เปิด edit ของคนใหม่ → ปิด edit ของคนเก่าอัตโนมัติ
- [ ] AnimatedCrossFade duration 200ms

---

## 📌 หมายเหตุ

- TASK 09 ทำได้อิสระหลังจาก TASK 03 และ TASK 04 เสร็จแล้ว
- ไม่ต้องแก้ logic การคำนวณ (ใช้ `calculateBill` และ `simplifyDebtsPerItem` จาก TASK 04)
- `MemberFormSheet` ยังคงใช้ได้สำหรับ "เพิ่มสมาชิก" (add mode) — แก้เฉพาะ edit mode
