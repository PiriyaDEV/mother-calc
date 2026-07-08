# UI/UX Audit & Modernization — Kidtang

> **Last updated:** 2026-07-07  
> **Auditor:** Senior Flutter UI/UX Engineer  
> **Scope:** All screens, widgets, theme, i18n, accessibility, performance  
> **Status:** Implementation in progress

---

## Table of Contents

1. [Audit Summary](#audit-summary)
2. [Issues — High Priority](#issues--high-priority)
3. [Issues — Medium Priority](#issues--medium-priority)
4. [Issues — Low Priority](#issues--low-priority)
5. [Implementation Plan](#implementation-plan)
6. [Progress Tracker](#progress-tracker)

---

## Audit Summary

| Category | Issues Found |
|---|---|
| 🔴 High Priority | 8 |
| 🟡 Medium Priority | 9 |
| 🟢 Low Priority | 4 |
| **Total** | **21** |

**Estimated total effort:** ~5 hours  
**Breaking changes:** None — all fixes are purely UI/UX layer  
**Business logic changes:** None

---

## Issues — High Priority

---

### H-01 · `GestureDetector` on interactive containers — no ripple feedback

| Field | Value |
|---|---|
| **Files** | `groups_screen.dart` (add button, line 85), `me_screen.dart` (sign-out button, line 399), `shared_bill_card.dart` (line 23), `shared_group_card.dart` |
| **Problem** | `GestureDetector` wraps tappable containers but provides zero visual feedback on tap. |
| **Why it hurts UX** | No ink/ripple = feels broken. Material Design and iOS HIG both require visual tap confirmation. Users tap twice thinking the first tap didn't register. |
| **Fix** | Replace `GestureDetector` + `Container` with `Material(color: Colors.transparent)` + `InkWell` with matching `borderRadius`. The `InkWell` must be inside the `Material` to clip the ripple correctly. |
| **Priority** | 🔴 High |
| **Effort** | Low — 30 min |

---

### H-02 · `SharedBillCard` status badge only shows 2 states — `pending_payment` missing

| Field | Value |
|---|---|
| **File** | `lib/widgets/shared/shared_bill_card.dart` (lines 155–183) |
| **Problem** | Badge only checks `isCompleted` (green) vs. everything else (amber). Bills in `pending_payment` look identical to `draft` bills. |
| **Why it hurts UX** | Users cannot distinguish "waiting for payment" from "still being edited" — critical for the bill lifecycle (`draft → pending_payment → completed`). |
| **Fix** | Add a third state: `bill.isPendingPayment` → blue/indigo badge with a clock icon. Use `bill.status` directly for the three-way branch. Add `bill_status_pending` i18n key (already exists in JSON). |
| **Priority** | 🔴 High |
| **Effort** | Low — 20 min |

---

### H-03 · `HeroBalanceCard` pills have hardcoded Thai strings

| Field | Value |
|---|---|
| **File** | `lib/widgets/home/hero_balance_card.dart` (lines 115–128) |
| **Problem** | `'$groupsCount กลุ่ม'`, `'$totalBills บิล'`, `'$totalItems รายการ'` are hardcoded Thai. |
| **Why it hurts UX** | Breaks English locale entirely. The most prominent widget on the home screen ignores the bilingual system. |
| **Fix** | Add i18n keys `home_pill_groups`, `home_pill_bills`, `home_pill_items` with `{count}` placeholder to both JSON files. Use `l.t('home_pill_groups').replaceFirst('{count}', '$groupsCount')`. |
| **Priority** | 🔴 High |
| **Effort** | Low — 20 min |

---

### H-04 · `GroupsScreen` subtitle hardcoded Thai

| Field | Value |
|---|---|
| **File** | `lib/screens/group/groups_screen.dart` (line 72) |
| **Problem** | `'${provider.groups.length} กลุ่มทั้งหมด'` bypasses the i18n system. |
| **Fix** | Add `groups_count` key (`"{count} กลุ่มทั้งหมด"` / `"{count} groups total"`) to both JSON files and use `l.t('groups_count').replaceFirst('{count}', ...)`. |
| **Priority** | 🔴 High |
| **Effort** | Low — 10 min |

---

### H-05 · `MeScreen` sign-out button — no `Semantics`, no ripple, no minimum tap area

| Field | Value |
|---|---|
| **File** | `lib/screens/me/me_screen.dart` (line 399) |
| **Problem** | Destructive action (sign out) uses `GestureDetector` with no accessibility label, no ripple, and no enforced minimum tap area. |
| **Why it hurts UX** | Screen readers cannot identify the button. No visual feedback on tap. Accessibility failure on a destructive action. |
| **Fix** | Wrap with `Semantics(label: 'Sign out', button: true)` + use `Material`/`InkWell`. Ensure `minHeight: 48` via `ConstrainedBox` or `SizedBox`. |
| **Priority** | 🔴 High |
| **Effort** | Low — 15 min |

---

### H-06 · `MeScreen` logout dialog duplicates `ConfirmDialog` widget

| Field | Value |
|---|---|
| **File** | `lib/screens/me/me_screen.dart` (lines 225–247) |
| **Problem** | An inline `AlertDialog` is built manually with custom styling, while `lib/widgets/shared/confirm_dialog.dart` already exists for exactly this purpose. |
| **Why it hurts UX** | Inconsistent dialog appearance. The custom `ConfirmDialog` has proper dark/light theming; the inline one doesn't adapt correctly. |
| **Fix** | Replace the inline `AlertDialog` with the existing `ConfirmDialog` widget. |
| **Priority** | 🔴 High |
| **Effort** | Low — 15 min |

---

### H-07 · `MeScreen` username validation errors are hardcoded Thai (not i18n)

| Field | Value |
|---|---|
| **File** | `lib/screens/me/me_screen.dart` (lines 121, 132) |
| **Problem** | `'username ต้องเป็นตัวอักษรภาษาอังกฤษ...'` and `'username นี้ถูกใช้งานแล้ว'` are hardcoded strings. |
| **Fix** | Add `me_username_invalid` and `me_username_taken` keys to both JSON files. Use `l.t('me_username_invalid')` and `l.t('me_username_taken')`. |
| **Priority** | 🔴 High |
| **Effort** | Low — 10 min |

---

### H-08 · `ProfileHeader` uses `context.read` for locale inside `build()`

| Field | Value |
|---|---|
| **File** | `lib/widgets/me/profile_header.dart` (line 75) |
| **Problem** | `context.read<LocaleProvider>()` inside `build()` won't trigger a rebuild when the locale changes. The fallback display name will be stale after a locale switch. |
| **Fix** | Change to `context.watch<LocaleProvider>()` or pass the translated fallback string as a constructor parameter from `MeScreen`. |
| **Priority** | 🔴 High |
| **Effort** | Low — 5 min |

---

## Issues — Medium Priority

---

### M-01 · `SharedBillCard` currency symbol hardcoded as `฿`

| Field | Value |
|---|---|
| **File** | `lib/widgets/shared/shared_bill_card.dart` (line 141) |
| **Problem** | `'฿${formatNumber(total)}'` ignores `bill.settings.currency`. The app supports multi-currency but the card always shows THB. |
| **Fix** | Use `formatCurrency(total, bill.settings.currency)` from `bill_utils.dart` which already handles currency formatting. |
| **Priority** | 🟡 Medium |
| **Effort** | Low — 10 min |

---

### M-02 · `HeroBalanceCard` loading state uses `CircularProgressIndicator` — inconsistent with skeleton system

| Field | Value |
|---|---|
| **File** | `lib/widgets/home/hero_balance_card.dart` (lines 92–98) |
| **Problem** | A 24×24 spinner appears inside the card during background data refresh. The app has a full skeleton system (`skeleton_loader.dart`) that should be used instead. |
| **Why it hurts UX** | Jarring visual inconsistency — the rest of the app uses shimmer skeletons, not spinners. |
| **Fix** | Replace `CircularProgressIndicator` with a white semi-transparent shimmer placeholder box matching the amount text dimensions (matches `HomeScreenSkeleton` lines 454–461). No spinner anywhere in the app. |
| **Priority** | 🟡 Medium |
| **Effort** | Low — 15 min |

---

### M-03 · `LoginScreen` feature pills have hardcoded Thai strings

| Field | Value |
|---|---|
| **File** | `lib/screens/shared/login_screen.dart` (lines 295–299) |
| **Problem** | `'💸 หารบิล'`, `'👥 จัดกลุ่ม'`, `'📊 สรุปยอด'` are hardcoded Thai. |
| **Fix** | Add `login_pill_split`, `login_pill_groups`, `login_pill_stats` to both JSON files. |
| **Priority** | 🟡 Medium |
| **Effort** | Low — 15 min |

---

### M-04 · `LoginScreen` app name uses `notoSansThai` instead of `anuphan`

| Field | Value |
|---|---|
| **File** | `lib/screens/shared/login_screen.dart` (line 267) |
| **Problem** | Per AGENTS.md: `anuphan` is for headings/display text. The app name `'Kidtang'` is the most prominent display text on the login screen but uses body font. |
| **Fix** | Change `GoogleFonts.notoSansThai(...)` → `GoogleFonts.anuphan(...)` for the app name text. |
| **Priority** | 🟡 Medium |
| **Effort** | Trivial — 5 min |

---

### M-05 · `GroupsScreen` add button uses `GestureDetector` — no ripple, no `Semantics`

| Field | Value |
|---|---|
| **File** | `lib/screens/group/groups_screen.dart` (lines 85–107) |
| **Problem** | Primary CTA button (add group) has no ink feedback and no accessibility label. |
| **Fix** | Wrap with `Semantics(label: 'Create group', button: true)` + `Material(color: Colors.transparent, borderRadius: ...)` + `InkWell`. |
| **Priority** | 🟡 Medium |
| **Effort** | Low — 10 min |

---

### M-06 · `BillCardSkeleton` border radius mismatches `SharedBillCard`

| Field | Value |
|---|---|
| **Files** | `lib/widgets/shared/skeleton_loader.dart` (line 157) vs `lib/widgets/shared/shared_bill_card.dart` (line 29) |
| **Problem** | Skeleton uses `AppRadii.lg`; real card uses `AppRadii.md`. Causes a visual "pop" when content loads in. |
| **Fix** | Align both to `AppRadii.md`. |
| **Priority** | 🟡 Medium |
| **Effort** | Trivial — 5 min |

---

### M-07 · `MeScreen._buildBody` uses `context.read` for `ThemeProvider` and `LocaleProvider`

| Field | Value |
|---|---|
| **File** | `lib/screens/me/me_screen.dart` (lines 322–323) |
| **Problem** | `context.read<ThemeProvider>()` and `context.read<LocaleProvider>()` in `_buildBody` (called from `build()`) means theme/locale changes won't trigger a rebuild of the settings section. |
| **Fix** | Use `context.watch` or `context.select` for these providers. |
| **Priority** | 🟡 Medium |
| **Effort** | Low — 10 min |

---

### M-08 · `ProfileHeader` gradient looks like a tappable button

| Field | Value |
|---|---|
| **File** | `lib/widgets/me/profile_header.dart` (lines 53–56) |
| **Problem** | The profile header card uses `AppGradients.primaryButtonLight/Dark` — the same gradient as CTA action buttons. Users may try to tap it expecting an action. |
| **Fix** | Use a dedicated profile card gradient. Suggested: a slightly desaturated version of the primary gradient, or a solid surface color with a subtle border and the avatar as the visual anchor. |
| **Priority** | 🟡 Medium |
| **Effort** | Low — 20 min |

---

### M-09 · `SkeletonBox(width: double.infinity)` inside `Row` without `Expanded`

| Field | Value |
|---|---|
| **File** | `lib/widgets/shared/skeleton_loader.dart` (lines 172, 221, 754, 916, etc.) |
| **Problem** | `SkeletonBox(width: double.infinity, ...)` used as a direct `Row` child without `Expanded` can cause layout overflow on certain screen sizes. |
| **Fix** | Wrap all `SkeletonBox(width: double.infinity)` instances that are direct `Row` children in `Expanded(child: SkeletonBox(...))`. |
| **Priority** | 🟡 Medium |
| **Effort** | Low — 15 min |

---

## Issues — Low Priority

---

### L-01 · `LoginScreen` has dead `_deg()` helper function

| Field | Value |
|---|---|
| **File** | `lib/screens/shared/login_screen.dart` (line 708) |
| **Problem** | `double _deg(double deg)` is unused (marked `// ignore: unused_element`). Dead code from a removed feature. |
| **Fix** | Remove the function. |
| **Priority** | 🟢 Low |
| **Effort** | Trivial — 2 min |

---

### L-02 · `LoginScreen` has ~200 lines of commented-out code

| Field | Value |
|---|---|
| **File** | `lib/screens/shared/login_screen.dart` |
| **Problem** | Large blocks of commented-out code (LINE button, iOS install banner, `_InstallStep` widget) clutter the file and confuse future maintainers. |
| **Fix** | Remove all commented-out code. If LINE login is planned, track it in a task file. |
| **Priority** | 🟢 Low |
| **Effort** | Low — 10 min |

---

### L-03 · `HeroPill` touch target below 44px minimum

| Field | Value |
|---|---|
| **File** | `lib/widgets/home/hero_balance_card.dart` (line 150) |
| **Problem** | `padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6)` gives ~28px height. If `HeroPill` ever becomes tappable, it's below the 44px minimum. |
| **Fix** | Increase vertical padding to `EdgeInsets.symmetric(horizontal: 10, vertical: 8)` for better readability. |
| **Priority** | 🟢 Low |
| **Effort** | Trivial — 5 min |

---

### L-04 · `GroupsScreen` uses `context.read` for group content — won't rebuild on content changes

| Field | Value |
|---|---|
| **File** | `lib/screens/group/groups_screen.dart` (line 37) |
| **Problem** | `context.read<GroupsStore>()` is used for `provider.groups` but `context.select` only watches `.length`. If a group's name/emoji changes without changing the list length, the card won't update. |
| **Fix** | Use `context.watch<GroupsStore>()` or a more granular `context.select` that includes a content hash. |
| **Priority** | 🟢 Low |
| **Effort** | Low — 10 min |

---

## Implementation Plan

### Phase 1 — Critical Fixes (~2 hours)

- [ ] **H-01** Replace `GestureDetector` → `Material`+`InkWell` on all interactive containers (`shared_bill_card.dart`, `shared_group_card.dart`, `me_screen.dart` sign-out)
- [ ] **H-02** Fix `SharedBillCard` to show 3-state status badge (draft / pending_payment / completed)
- [ ] **H-05** Add `Semantics` + `InkWell` + min 48px height to `MeScreen` sign-out button
- [ ] **H-06** Replace inline `AlertDialog` in `MeScreen` with existing `ConfirmDialog` widget
- [ ] **H-08** Fix `ProfileHeader` `context.read` → `context.watch` for locale
- [ ] **M-07** Fix `MeScreen._buildBody` `context.read` → `context.watch` for theme/locale

### Phase 2 — i18n & Consistency Fixes (~1.5 hours)

- [ ] **H-03** Fix `HeroBalanceCard` pills: add `home_pill_groups/bills/items` i18n keys + use them
- [ ] **H-04** Fix `GroupsScreen` subtitle: add `groups_count` i18n key + use it
- [ ] **H-07** Fix `MeScreen` username errors: add `me_username_invalid` + `me_username_taken` i18n keys
- [ ] **M-03** Fix `LoginScreen` feature pills: add `login_pill_split/groups/stats` i18n keys
- [ ] **M-04** Fix `LoginScreen` app name font: `notoSansThai` → `anuphan`
- [ ] **M-01** Fix `SharedBillCard` currency: `'฿${formatNumber(total)}'` → `formatCurrency(total, bill.settings.currency)`

### Phase 3 — Visual Polish (~1 hour)

- [ ] **M-02** Fix `HeroBalanceCard` loading: `CircularProgressIndicator` → white shimmer placeholder box
- [ ] **M-05** Fix `GroupsScreen` add button: `GestureDetector` → `Material`+`InkWell` + `Semantics`
- [ ] **M-08** Fix `ProfileHeader` gradient: use dedicated card gradient instead of button gradient
- [ ] **M-06** Align `BillCardSkeleton` border radius with `SharedBillCard` (`AppRadii.lg` → `AppRadii.md`)
- [ ] **M-09** Fix `SkeletonBox(width: double.infinity)` in `Row` — wrap in `Expanded`

### Phase 4 — Cleanup (~30 min)

- [ ] **L-02** Remove ~200 lines of commented-out code from `LoginScreen`
- [ ] **L-01** Remove dead `_deg()` function from `LoginScreen`
- [ ] **L-04** Fix `GroupsScreen` `context.read` → `context.watch` for group content reactivity
- [ ] **L-03** Increase `HeroPill` vertical padding for better readability

---

## Progress Tracker

| Issue | Status | Phase | File |
|---|---|---|---|
| H-01 GestureDetector → InkWell | ⬜ Pending | 1 | `shared_bill_card.dart`, `shared_group_card.dart`, `me_screen.dart` |
| H-02 3-state status badge | ⬜ Pending | 1 | `shared_bill_card.dart` |
| H-03 HeroBalanceCard i18n pills | ⬜ Pending | 2 | `hero_balance_card.dart` |
| H-04 GroupsScreen subtitle i18n | ⬜ Pending | 2 | `groups_screen.dart` |
| H-05 Sign-out Semantics + InkWell | ⬜ Pending | 1 | `me_screen.dart` |
| H-06 Use ConfirmDialog for logout | ⬜ Pending | 1 | `me_screen.dart` |
| H-07 Username error i18n | ⬜ Pending | 2 | `me_screen.dart` |
| H-08 ProfileHeader context.watch | ⬜ Pending | 1 | `profile_header.dart` |
| M-01 Currency formatCurrency | ⬜ Pending | 2 | `shared_bill_card.dart` |
| M-02 No spinner → shimmer box | ⬜ Pending | 3 | `hero_balance_card.dart` |
| M-03 LoginScreen pills i18n | ⬜ Pending | 2 | `login_screen.dart` |
| M-04 App name font anuphan | ⬜ Pending | 2 | `login_screen.dart` |
| M-05 GroupsScreen add btn InkWell | ⬜ Pending | 3 | `groups_screen.dart` |
| M-06 BillCardSkeleton radius | ⬜ Pending | 3 | `skeleton_loader.dart` |
| M-07 MeScreen context.watch | ⬜ Pending | 1 | `me_screen.dart` |
| M-08 ProfileHeader gradient | ⬜ Pending | 3 | `profile_header.dart` |
| M-09 SkeletonBox Expanded | ⬜ Pending | 3 | `skeleton_loader.dart` |
| L-01 Remove _deg() | ⬜ Pending | 4 | `login_screen.dart` |
| L-02 Remove commented code | ⬜ Pending | 4 | `login_screen.dart` |
| L-03 HeroPill padding | ⬜ Pending | 4 | `hero_balance_card.dart` |
| L-04 GroupsScreen context.watch | ⬜ Pending | 4 | `groups_screen.dart` |
