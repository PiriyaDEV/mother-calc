# 🔍 Deep Gap Analysis — Next.js (Original) vs Flutter (Current)

> เปรียบเทียบ UI/UX และ Feature ระหว่าง Next.js branch `main` (ต้นฉบับ) กับ Flutter app ปัจจุบัน  
> วันที่วิเคราะห์: 29 มิ.ย. 2569

---

## 📋 สรุปภาพรวม

| หมวด | Next.js (ต้นฉบับ) | Flutter (ปัจจุบัน) | สถานะ |
|------|-------------------|-------------------|-------|
| Bill Detail — Tabs | 4 tabs: สมาชิก / รายการ / สรุป / วิเคราะห์ | 3 tabs: รายการ / สมาชิก / สรุป | ❌ ขาด Analytics tab |
| Bill Header | Sticky header + pill tabs (rounded-2xl) | SliverAppBar + TabBar (underline) | ⚠️ UI ต่างกัน |
| Bill Status | ปุ่ม "ปิดบิล" / "เปิดใหม่" อยู่ใน header | อยู่ใน bottom sheet menu | ⚠️ UX ต่างกัน |
| Completed Banner | Banner สีเขียวใต้ header | ไม่มี | ❌ ขาด |
| Item Form — Paid By | Selector ใน modal (required) | มีใน bottom sheet | ✅ มี |
| Item Form — Split Mode | Toggle หารเท่า/หารไม่เท่า ใน modal | มีใน bottom sheet | ✅ มี |
| Item List — Per-person preview | แสดง ฿X/คน inline ใน modal | แสดงเป็น chip | ⚠️ UI ต่างกัน |
| Summary — Hero card | Gradient card + total + SC/VAT info | ไม่มี hero card | ❌ ขาด |
| Summary — Member selector | Horizontal scroll pill selector | ไม่มี (แสดงทุกคนพร้อมกัน) | ❌ ขาด |
| Summary — Per-member debt | แสดง "ต้องโอนให้ใคร" per-payer | แสดงรวมทั้งหมด | ⚠️ Logic ต่างกัน |
| Summary — PromptPay QR | QR code inline ใน debt card | มี QR แต่ใน summary tab | ⚠️ ตำแหน่งต่างกัน |
| Summary — Payment progress bar | Progress bar ใน hero card (completed only) | ไม่มี | ❌ ขาด |
| Summary — "สรุปทุกคน" section | Collapsible section | แสดงตลอด | ⚠️ UX ต่างกัน |
| Analytics Tab | AnalyticsPage component | ไม่มีเลย | ❌ ขาด |
| Member — Color picker | 10 สี inline ใน add/edit form | มีใน bottom sheet | ✅ มี |
| Member — PromptPay field | Inline ใน add/edit form | มีใน bottom sheet | ✅ มี |
| Member — is_external badge | แสดง "ภายนอก" badge | ไม่มี badge | ❌ ขาด |
| Member — @username display | แสดง @username ถ้า linked profile | ไม่มี | ❌ ขาด |
| Bill Settings — Title/Emoji/Tags | CreateEntityModal (full modal) | Bottom sheet (ไม่มี tags) | ⚠️ ขาด tags |
| Home — Currency Exchange | ไม่มีใน Next.js | มีใน Flutter ✅ | ✅ Flutter เพิ่มเอง |
| Home — Stats cards | ไม่มีใน Next.js | มีใน Flutter ✅ | ✅ Flutter เพิ่มเอง |
| Friends — Add by username | ✅ มี | ✅ มี | ✅ |
| Friends — Pending requests badge | BottomNav badge | ✅ มี | ✅ |
| Notifications | ✅ มี | ✅ มี | ✅ |
| Groups | ✅ มี | ✅ มี | ✅ |
| Dark mode | ✅ มี | ✅ มี | ✅ |

---

## 🔴 Feature ที่หายไปทั้งหมด (Missing Features)

### 1. Analytics Tab (วิเคราะห์)
**Next.js:** มี tab ที่ 4 ชื่อ "วิเคราะห์" (`AnalyticsPage` component)  
**Flutter:** มีแค่ 3 tabs ไม่มี Analytics เลย  
**ผลกระทบ:** ผู้ใช้ไม่สามารถดูการวิเคราะห์บิลได้

### 2. Summary Hero Card
**Next.js:** มี gradient card สีน้ำเงิน แสดง:
- ยอดรวมทั้งสิ้น (ตัวใหญ่)
- SC% และ VAT% ที่ใช้
- Payment progress bar (เฉพาะ completed bill)
- จำนวนคนที่จ่ายแล้ว X/Y คน

**Flutter:** ไม่มี hero card ใน Summary tab — แสดงแค่ list ของ member cards

### 3. Member Selector ใน Summary
**Next.js:** มี horizontal scroll pill selector ให้เลือกดูสรุปของสมาชิกแต่ละคน  
- กด pill ของใคร → แสดง debt ของคนนั้นโดยเฉพาะ
- Highlight "คุณ" (current user)
- แสดง ✅ ถ้าคนนั้นจ่ายแล้ว

**Flutter:** ไม่มี selector — แสดงทุกคนพร้อมกันใน list

### 4. Per-Payer Debt View
**Next.js:** ใน Summary แสดง "ฉันต้องโอนให้" โดยคำนวณจาก `paid_by` ของแต่ละ item  
- แสดง: [from avatar] → [to avatar] + ชื่อ + จำนวนเงิน
- มี QR button ถ้า to มี promptpay
- มี "จ่ายแล้ว" toggle (เฉพาะ completed)

**Flutter:** Summary tab แสดงแค่ยอดรวมต่อคน ไม่มี debt arrow view

### 5. Completed Bill Banner
**Next.js:** มี banner สีเขียวใต้ header เมื่อบิลปิดแล้ว:
> "บิลนี้ปิดแล้ว — ดูได้อย่างเดียว ไม่สามารถแก้ไขได้"

**Flutter:** ไม่มี banner นี้ (มีแค่ `BillStatusPill` เล็กๆ)

### 6. Bill Tags
**Next.js:** `CreateEntityModal` มี field สำหรับ tags  
**Flutter:** Settings sheet ไม่มี tags field

### 7. is_external Badge บน Member
**Next.js:** แสดง badge "ภายนอก" สำหรับ member ที่ `is_external = true`  
**Flutter:** ไม่มี badge นี้

### 8. @username Display บน Member
**Next.js:** ถ้า member มี linked profile จะแสดง `@username` สีน้ำเงิน  
**Flutter:** ไม่มี

### 9. Payment Progress Bar
**Next.js:** ใน hero card ของ Summary (เฉพาะ completed bill) มี progress bar แสดง X/Y คนจ่ายแล้ว  
**Flutter:** ไม่มี

---

## 🟡 UI/UX ที่ต่างกัน (Different but Exists)

### 1. Bill Detail Header & Tabs

| | Next.js | Flutter |
|---|---|---|
| Header style | Sticky header + back button + title + emoji + status badge + settings icon + complete/reopen button | SliverAppBar + title + more_vert menu |
| Tab style | Pill tabs (rounded-2xl, bg-gray-100) | Underline TabBar |
| Tab order | สมาชิก → รายการ → สรุป → วิเคราะห์ | รายการ → สมาชิก → สรุป |
| Complete/Reopen | ปุ่มอยู่ใน header ตลอดเวลา | ซ่อนอยู่ใน bottom sheet menu |
| Settings | ปุ่ม gear icon ใน header | อยู่ใน bottom sheet menu |

**ผลกระทบ:** ใน Next.js ผู้ใช้เห็นปุ่ม "ปิดบิล" ทันทีโดยไม่ต้องกด menu — UX ดีกว่า

### 2. Item List Card

| | Next.js | Flutter |
|---|---|---|
| Member display | Stacked avatars (overlap) + "X คน · ฿Y/คน" | Colored chips พร้อมชื่อและราคา |
| Paid by | Avatar เล็กๆ ข้างชื่อ item | "จ่ายโดย" + avatar ด้านขวา |
| Edit/Delete | ปุ่ม pencil + trash แยกกัน | กด tile เพื่อ edit (ไม่มีปุ่ม delete แยก) |
| Unequal badge | ข้อความ "หารไม่เท่า" สีเทา | Badge สีเหลือง "หารไม่เท่า" |

### 3. Member List Card

| | Next.js | Flutter |
|---|---|---|
| Edit mode | Inline expand (ไม่ต้องเปิด modal) | Bottom sheet modal |
| Color picker | Inline ใน expanded row | ใน bottom sheet |
| PromptPay | Inline ใน expanded row | ใน bottom sheet |
| Delete | ปุ่ม trash ใน row | ปุ่ม trash ใน bottom sheet |

### 4. Add Item Button Style

| | Next.js | Flutter |
|---|---|---|
| Style | Full-width solid blue button (rounded-2xl) | Dashed border container สีน้ำเงินอ่อน |
| Position | Sticky top | Top of list |

### 5. Summary — "สรุปทุกคน" Section

| | Next.js | Flutter |
|---|---|---|
| Default state | Collapsed (กด expand ได้) | แสดงตลอด |
| Debt arrows | แสดงใน collapsed section | ไม่มี debt arrows |
| Per-member items | แสดงใน expanded section | แสดงตลอด |

### 6. Item Form Modal vs Bottom Sheet

| | Next.js | Flutter |
|---|---|---|
| Container | Full modal (center screen) | Bottom sheet (slide up) |
| Paid by selector | Pill buttons แนวนอน | Dropdown/selector |
| Split mode | Toggle buttons (หารเท่า/หารไม่เท่า) | Toggle buttons |
| Member selection | Checkbox list + "เลือกทั้งหมด/ล้าง" | Checkbox list |
| Per-person preview | แสดง ฿X ใน member row ทันที | แสดงเป็น chip |

---

## 🟢 Feature ที่ Flutter เพิ่มเองเกิน Next.js (Flutter Extras)

### 1. Currency Exchange Rates (Home Screen)
- แสดงอัตราแลกเปลี่ยน 10 สกุลเงิน (USD, EUR, JPY, CNY, GBP, KRW, SGD, AUD, HKD, MYR)
- ดึงข้อมูลจาก `open.er-api.com` แบบ real-time
- มี fallback rates
- มีปุ่ม refresh
- แสดงเป็น horizontal scroll cards พร้อม flag emoji

### 2. Stats Cards (Home Screen)
- เฉลี่ยต่อบิล
- บิลทั้งหมด
- รายการทั้งหมด
- บิลใหญ่สุด (พร้อม highlight card)

### 3. Recent Bills Section (Home Screen)
- แสดง 3 บิลล่าสุด
- มีปุ่ม "ดูทั้งหมด"

---

## 📐 Color & Design System Differences

| | Next.js | Flutter |
|---|---|---|
| Primary color | `#4366f4` (bill page), `#286bfe` (friends/home) | `AppColors.primary = #286BFE` |
| Background | `bg-white` / `bg-[#f4f6fb]` | `AppColors.bgLight = #F4F6FB` |
| Card style | `rounded-2xl` (16px) | `BorderRadius.circular(12-16)` |
| Tab style | Pill (rounded-2xl, filled) | Underline indicator |
| Spacing | Tailwind utility classes | Manual EdgeInsets |
| Font | System font (Tailwind default) | `GoogleFonts.notoSansThai` |

---

## 🎯 Priority Fix List (เรียงตามความสำคัญ)

### 🔴 Critical (ต้องทำก่อน)

1. **เพิ่ม Analytics Tab** — สร้าง `_AnalyticsTab` ใน `BillDetailScreen`
2. **ย้ายปุ่ม "ปิดบิล"/"เปิดใหม่" ออกมาใน header** — ไม่ซ่อนใน menu
3. **เพิ่ม Summary Hero Card** — gradient card + total + SC/VAT + progress bar
4. **เพิ่ม Member Selector ใน Summary** — horizontal scroll pills
5. **เพิ่ม Per-Payer Debt View** — "ต้องโอนให้ใคร" section

### 🟡 Important (ทำต่อ)

6. **เพิ่ม Completed Bill Banner** — banner สีเขียวใต้ header
7. **เปลี่ยน Tab style** — จาก underline เป็น pill tabs
8. **เปลี่ยน Tab order** — สมาชิก → รายการ → สรุป → วิเคราะห์
9. **เพิ่ม is_external badge** บน member cards
10. **เพิ่ม @username display** บน member cards
11. **เพิ่ม Tags field** ใน bill settings

### 🟢 Nice to Have

12. **เปลี่ยน Item card** — stacked avatars แทน chips
13. **เพิ่ม "สรุปทุกคน" collapsible section** ใน Summary
14. **เพิ่ม debt arrows** ใน "สรุปทุกคน"
15. **Inline edit member** แทน bottom sheet

---

## 📁 Files ที่ต้องแก้ไข

| File | การเปลี่ยนแปลง |
|------|----------------|
| `lib/screens/bill_detail_screen.dart` | เพิ่ม Analytics tab, ย้ายปุ่ม complete/reopen, เปลี่ยน tab style/order, เพิ่ม completed banner |
| `lib/screens/bill_detail_screen.dart` (_SummaryTab) | เพิ่ม hero card, member selector, per-payer debt view, progress bar |
| `lib/screens/bill_detail_screen.dart` (_MembersTab) | เพิ่ม is_external badge, @username display |
| `lib/screens/bill_detail_screen.dart` (_ItemTile) | เปลี่ยนเป็น stacked avatars |
| `lib/providers/bill_provider.dart` | ตรวจสอบ toggleMemberPaid, completeBill, reopenBill |
| `lib/models/models.dart` | ตรวจสอบ is_external, tags fields |

---

*Generated by deep analysis of Next.js source at `https://github.com/PiriyaDEV/kidtang` branch `main`*
