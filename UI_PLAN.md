# Kidtang UI/UX Redesign Plan

> Inspired by Duolingo-level UX quality. Color palette unchanged (#4366F4 primary + existing AppColors). Run each section as an independent update task.

---

## S1 · Global Design System & Shared Components
**Scope:** `lib/theme/app_theme.dart` · new `lib/widgets/empty_state.dart` · new `lib/widgets/section_header.dart`
**Run this first — all other sections depend on it.**

### Spacing & Radius Tokens (add to AppColors)
| Token | Value | Use |
|---|---|---|
| `kSpaceXS` | 4px | icon gaps |
| `kSpaceSM` | 8px | tight item spacing |
| `kSpaceMD` | 12px | intra-card |
| `kSpaceLG` | 16px | page margins |
| `kSpaceXL` | 24px | section gaps |
| `kSpace2XL` | 32px | hero padding |
| `kRadiusSM` | 8px | pills, badges |
| `kRadiusMD` | 12px | buttons, text fields |
| `kRadiusLG` | 16px | standard cards |
| `kRadiusXL` | 20px | large cards |
| `kRadius2XL` | 28px | hero cards |

### Shadow Tokens (add to AppColors)
```dart
static const shadowSubtle = [BoxShadow(color: Color(0x0A000000), blurRadius: 4,  offset: Offset(0,1))];
static const shadowCard   = [BoxShadow(color: Color(0x144366F4), blurRadius: 12, offset: Offset(0,4))];
static const shadowFloat  = [BoxShadow(color: Color(0x1F4366F4), blurRadius: 24, offset: Offset(0,8))];
```

### EmptyStateWidget (new `lib/widgets/empty_state.dart`)
Props: `emoji`, `title`, `subtitle`, `ctaLabel?`, `onCta?()`
- Emoji: `Text(fontSize: 64)` centered
- Title: 18px w700 textPrimary
- Subtitle: 14px textSecondary centered, max-width 240px
- CTA: 48px height, radius 14px, primary blue, full-width — only if `ctaLabel` provided

### SectionHeaderWidget (new `lib/widgets/section_header.dart`)
Props: `label`, `trailingCount?`, `trailingWidget?`
- Label: 11px ALL CAPS, letterSpacing 0.8, textTertiary
- Trailing count: 11px badge pill, blue-faint bg

### Pill Tab Bar Pattern (reusable)
Replace all `TabBar` (underline indicator) with a custom `_PillTabBar` widget:
- Container: bgLight rounded rect, radius 12px, 4px padding, border borderLight
- Active tab: white card, primaryBlue text/icon, shadowSubtle, AnimatedContainer 200ms
- Each tab: icon 18px + label 13px, inside 36px height pill

---

## S2 · Home Screen
**File:** `lib/screens/home_screen.dart`
**Status:** Hero card already improved. Quick actions, section labels, currency cards, recent bills need work.

### Current issues
- Quick action grid uses plain grey containers — no personality or color differentiation
- No section labels chunking the page ("อัตราแลกเปลี่ยน", "บิลล่าสุด")
- Currency cards lack trend visual
- Recent bill rows have no member avatar strip

### Planned changes

**Quick Actions Grid**
Each action gets a unique gradient color pair:
- สร้างบิล: `#4366F4 → #6B8AF7`
- เพิ่มกลุ่ม: `#10B981 → #34D399`
- สแกน QR: `#8B5CF6 → #A78BFA`
- ดูสรุป: `#F59E0B → #FCD34D`

Icon container: 52×52px, radius 16px, gradient bg, icon 26px white, label 12px w600 below.
Card: white bg, radius 18px, shadowCard, padding 16px.

**Section Labels**
- Add `SectionHeaderWidget(label: 'อัตราแลกเปลี่ยน')` before currency section
- Add `SectionHeaderWidget(label: 'บิลล่าสุด', trailingWidget: TextButton('ดูทั้งหมด'))` before recent bills

**Currency Cards**
- Add subtle directional arrow icon for rate trend (static/visual only)
- Card min-height 72px, flag emoji 28px

**Recent Bill Rows**
- Add 2–3 overlapping 22px member avatar circles on right side
- Show group name as blue pill below bill name

---

## S3 · Bills Screen
**File:** `lib/screens/bills_screen.dart`
**Status:** Default Material TabBar. Bill cards are functional but flat.

### Current issues
- TabBar uses Material underline indicator (looks dated)
- `_BillListCard` is flat: no left accent stripe, amount doesn't stand out
- Date section headers are plain Text rows
- Empty states are text-only

### Planned changes

**Tab Bar → Pill Tabs**
Replace `TabBar` with custom pill tabs using `AnimatedContainer`:
- Active: white pill, primaryBlue text, shadowSubtle
- Inactive: transparent bg, textSecondary
- Smooth 200ms transition on tap

**Bill Cards**
- Left 4px stripe: primary blue (active) / green (completed) — radius on left side only
- Bill name: 15px w600
- Amount: 18px w700 textPrimary, right-aligned
- Group name badge pill (blue-faint bg) below bill name
- "N รายการ · N คน" meta line: 12px textTertiary
- Card: white bg, radius 16px, shadowCard, 16px padding

**Section Date Headers**
Replace plain text with `SectionHeaderWidget`

**Empty States**
Replace with `EmptyStateWidget`:
- กำลังดำเนินการ: `emoji: '🧾', title: 'ยังไม่มีบิล', subtitle: 'กดปุ่ม + เพื่อสร้างบิลแรก', ctaLabel: 'สร้างบิล'`
- เสร็จแล้ว: `emoji: '✅', title: 'ยังไม่มีบิลที่เสร็จ', subtitle: 'บิลที่ชำระครบแล้วจะปรากฏที่นี่'`

---

## S4 · Bill Detail Screen
**File:** `lib/screens/bill_detail_screen.dart` · `lib/widgets/summary_tab.dart`
**Status:** Analytics charts already added. Tab bar, items, summary need work.

### Current issues
- Tab bar uses Material underline — inconsistent with other screens
- Items list cards are flat, payer not color-coded, amount doesn't stand out
- Summary tab: owe amount is buried, no hero treatment for the most important number
- QR button in summary is small

### Planned changes

**Tab Bar → Scrollable Icon+Label Pill Tabs**
- receipt_long (รายการ) / people (สมาชิก) / summarize (สรุป) / bar_chart (วิเคราะห์)
- Active: primary bg, white text/icon, radius 20px

**Items Tab Cards**
- Payer circle: 32px, memberColor bg, initial letter white w700 12px
- Item name: 14px w500 textPrimary
- Amount: 16px w700 textPrimary, right-aligned
- "หาร N คน": 11px textTertiary below
- Card: white bg, radius 14px, shadowSubtle, 12px padding

**Members Tab**
- 40px avatar, name 15px w600, "ยอดรวม ฿XXX" blue right-aligned

**Summary Tab Hero**
- Large 32px w800 owe/owed amount at the top
- "คุณเป็นหนี้ทั้งหมด" / "ยอดเงินที่คนอื่นค้างคุณ" label: 12px ALL CAPS above
- Debt cards: QR button green pill (40px height) prominently right side
- "ชำระแล้ว" state: green checkmark badge, strikethrough amount

---

## S5 · Groups Screen
**File:** `lib/screens/groups_screen.dart`
**Status:** Group tiles already improved (overlapping avatars, gradient icon, pending badge). Header and empty state remain.

### Current issues
- Header "กลุ่ม" is plain text with a small + icon button
- Empty state is minimal (emoji + text + TextButton)

### Planned changes

**Header**
- Count badge pill next to title
- Create button: full labeled pill "สร้างกลุ่ม" with + icon, 36px height, primary bg

**Empty State**
```dart
EmptyStateWidget(
  emoji: '👥',
  title: 'ยังไม่มีกลุ่ม',
  subtitle: 'สร้างกลุ่มและเชิญเพื่อนมาหารค่าใช้จ่ายด้วยกัน',
  ctaLabel: 'สร้างกลุ่มแรก',
  onCta: _showCreateGroupSheet,
)
```

---

## S6 · Group Detail Screen
**File:** `lib/screens/group_detail_screen.dart`
**Status:** Analytics charts added. Hero header, pill tabs, bills list need work.

### Current issues
- Group header is a plain Row — no visual presence for group identity
- Tab bar uses underline style
- Bills list uses same flat card style as before S3

### Planned changes

**Group Hero Header**
- Blue-faint gradient bg: `#EEF1FE → #F4F6FB`, 24px padding
- Group emoji in 56px white circle (radius 20, shadowCard)
- Group name: 20px w700 below emoji, centered
- "N สมาชิก · N บิล": 13px textSecondary
- Centered overlapping member avatar strip below

**Tab Bar → Pill Tabs**
- receipt_long (บิล) / people_outline (สมาชิก) / bar_chart (วิเคราะห์)
- Same pill pattern as S3/S4

**Bills List**
Apply same improved bill card from S3 (left stripe, amount bold, meta row)

---

## S7 · Friends Screen
**File:** `lib/screens/friends_screen.dart`
**Status:** Toggle-based add panel. Functional but cluttered layout.

### Current issues
- Add-friend panel is inside the scroll view (toggle), causes layout shift
- Pending requests have no visual priority treatment
- Friend cards are text-heavy, action buttons small
- Empty state is plain Text

### Planned changes

**Sticky Search/Add Bar** (outside ListView, always visible)
- Text field at top of screen, outside scroll
- Placeholder: "@username — ค้นหาเพื่อน"
- Send icon appears on right when text.length > 0
- Inline success/error feedback, same field
- Style: white bg, radius 12px, search icon left

**Pending Requests Section**
- Amber-tinted container: `#FFFBEB bg, #FDE68A border`, radius 16px
- Header: "คำขอเพื่อน (N)" in amber w600 text

**Friend Cards**
- Avatar 40px, name 15px w600, "@username" 12px textSecondary below
- Kebab (⋯) menu button right → pop menu: "ลบเพื่อน"

**Empty State**
```dart
EmptyStateWidget(
  emoji: '🤝',
  title: 'ยังไม่มีเพื่อน',
  subtitle: 'ค้นหาด้วย @username เพื่อเพิ่มเพื่อนใหม่',
)
```

---

## S8 · Me / Profile Screen
**File:** `lib/screens/me_screen.dart`
**Status:** Avatar card + inline edit fields + sign out. Lacks visual hierarchy.

### Current issues
- Profile hero area is plain white card — no visual distinction
- Settings cards have no labeled grouping
- Inline edit fields feel cramped when open
- Theme toggle is a small Switch

### Planned changes

**Profile Hero Card**
- Gradient bg: `#4366F4 → #6B8AF7`, radius 24px, 32px padding
- Avatar: 80px circle, white border 3px, shadowFloat
- Display name: 20px w700 white
- "@username": 14px white 70% opacity
- Edit avatar button: small 28px white circle, edit icon, bottom-right of avatar

**Settings Section Labels**
Add `SectionHeaderWidget` above each card group:
- "บัญชี" before profile fields
- "ความปลอดภัย" before password card
- "การตั้งค่า" before theme toggle

**Theme Toggle Row**
Upgrade to full card row:
- Icon ☀️/🌙 left (24px)
- "โหมดสีเข้ม" label 15px w500
- Styled Toggle Switch right (primary blue when on)
- 52px height, full row tappable

**Sign Out**
Keep red border/text, add `Color(0xFFFEF2F2)` fill

---

## S9 · Notifications Screen
**File:** `lib/screens/notifications_screen.dart`
**Status:** Simple list of group invitations. Minimal treatment.

### Current issues
- No visual type-coding for notification types
- Accept/Decline buttons are small inline text
- No empty state
- No unread count in header

### Planned changes

**Header**
- "แจ้งเตือน" title + count badge pill if unread > 0
- "ล้างทั้งหมด" TextButton trailing if notifications exist

**Notification Cards**
- Left 8px colored dot: amber (invitation) / blue (system)
- Group emoji circle 40px left
- Title 14px w600, subtitle 13px textSecondary, timestamp 11px textTertiary right-aligned
- Card: white bg, radius 14px, shadowSubtle, 16px padding

**Accept/Decline Actions**
Two full-width buttons below card content:
- Accept: green bg, "รับคำเชิญ", 40px height, radius 10px
- Decline: border-only neutral, "ปฏิเสธ", same height

**Empty State**
```dart
EmptyStateWidget(
  emoji: '🔔',
  title: 'ไม่มีการแจ้งเตือน',
  subtitle: 'คำเชิญกลุ่มและการอัพเดตจะปรากฏที่นี่',
)
```

---

## S10 · Login & Onboarding
**Files:** `lib/screens/login_screen.dart` · `lib/screens/onboarding_screen.dart`
**Status:** Login already well-designed (animation, gradient blobs, social buttons). Light touch only.

### Current issues (minor)
- Feature pill copy is generic
- No visual separator between feature pills and login buttons
- Onboarding page dots are default style

### Planned changes

**Login Screen**
- Feature pill copy (more benefit-led):
  - "ตั้งชื่อรายการ เพิ่มคน หารได้ทันที"
  - "สแกน QR พร้อมเพย์ ชำระได้เลย"
  - "ดูสถิติการใช้จ่ายของกลุ่ม"
- Add `Divider(height: 32)` between feature pills and login button group
- Small "v1.0" muted text at very bottom

**Onboarding Page Dots**
- Active: 24×8px rounded rect, primary blue
- Inactive: 8×8px circle, borderLight
- `AnimatedContainer` width/color transition 200ms

---

## Implementation Order

| Priority | Section | Impact | Effort |
|---|---|---|---|
| 1 | S1 · Global Design System | High | Medium |
| 2 | S3 · Bills Screen | High | Medium |
| 3 | S2 · Home Screen | High | Medium |
| 4 | S4 · Bill Detail | High | High |
| 5 | S6 · Group Detail | Medium | Medium |
| 6 | S7 · Friends | Medium | Medium |
| 7 | S8 · Me/Profile | Medium | Low |
| 8 | S5 · Groups | Medium | Low |
| 9 | S9 · Notifications | Medium | Low |
| 10 | S10 · Login/Onboard | Low | Very Low |
