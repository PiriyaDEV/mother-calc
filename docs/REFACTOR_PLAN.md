# Refactor Plan — Performance, Maintainability, State Management

## Status

| Phase | Status | Completed |
|---|---|---|
| Phase 1 — `bill_detail_screen.dart` + `group_detail_screen.dart` | ✅ **DONE** | 2026-07-06 |
| Phase 2 — In-place extractions (summary_tab, analytics_tab, home, friends, me) | ✅ **DONE** | analytics_tab ✅ 2026-07-06, summary_tab ✅ 2026-07-06, friends ✅ 2026-07-07, home ✅ 2026-07-07, me ✅ 2026-07-07 |
| Phase 3 — Cross-file consolidation (create-flow dedup + models split) | ⬜ Pending | — |
| Phase 4 — State management targeted fixes | ⬜ Pending | — |

### Phase 1 — What was done
- Extracted `bill_detail_screen.dart` (2571 lines → ~550 lines) into `lib/widgets/bill_detail/`: `stacked_avatars.dart`, `bill_summary_card.dart`, `member_tile.dart`, `item_tile.dart`, `pill_tab_bar.dart`, `items_tab.dart`, `members_tab.dart`, `item_form_sheet.dart`, `member_form_sheet.dart`, `index.dart`
- Extracted `group_detail_screen.dart` (1899 lines → ~175 lines) into `lib/widgets/group_detail/`: `empty_state.dart`, `group_tab_bar.dart`, `members_tab.dart`, `bills_tab.dart`, `group_summary_tab.dart`, `group_analytics_tab.dart`, `touchable_pie_chart.dart`, `manage_members_sheet.dart`, `index.dart`
- All concrete performance fixes applied: `ListView.builder` conversions, `billsEqual()` added to `bill_utils.dart` (with `updatedAt` comparison), `_expandedBillId` moved into `GroupSummaryTab` (Stateful), `_pieTouchedIndex` isolated in `TouchablePieChart`, `RepaintBoundary` wrapping on all list rows and the pie chart
- `flutter analyze` clean (zero new errors/warnings from Phase 1 changes)

---

Target repo: `kidtang` (Flutter app). This document is the source of truth for a four-phase refactor. Each phase is independently triggerable — reference "Phase N" and hand this file's section to a coding session to execute it. Do not attempt phases out of order within a screen/file (later phases sometimes assume earlier ones landed on the same file), but Phases 1-3 touch disjoint files and can technically run in any order relative to each other.

**State management verdict (applies to all phases): stay on Provider + ChangeNotifier.** It is the only state library in the app, and it already uses `context.select`/`Selector` consistently (20+ call sites) with narrow rebuild scopes and no `Consumer` wrapping large subtrees. There is no functional case for migrating to Riverpod/Bloc/GetX — Phase 4 applies targeted fixes within the existing architecture instead.

**No existing test suite covers any file in this plan.** Every phase's acceptance bar is: `flutter analyze` clean, plus a manual smoke test of the specific screens/flows that phase touches (listed per phase below).

---

## Phase 1 — `bill_detail_screen.dart` + `group_detail_screen.dart`

The two largest files in the app (2571 and 1899 lines), both already open/modified — highest priority.

### Directory layout
New dirs `lib/widgets/bill_detail/` and `lib/widgets/group_detail/`. Keep these separate from the existing flat `lib/widgets/*.dart` convention (which holds genuinely cross-screen shared widgets like `summary_tab.dart`, `member_avatar.dart`) — the classes extracted here are screen-owned, not reused elsewhere, and both screens have identically-named classes (`_CountTab`, `_MembersTab`) that would collide in naming/discoverability if dumped flat.

All extracted top-level classes must drop their leading underscore (Dart privacy is per-file). Small helpers used by exactly one consumer in the same new file may stay private.

### `bill_detail_screen.dart` extraction map (2571 → target ~550-650 lines)

| Class (current) | Target file |
|---|---|
| `_StackedAvatars` | `lib/widgets/bill_detail/stacked_avatars.dart` |
| `_BillSummaryCard` + `_SummaryRow` | `lib/widgets/bill_detail/bill_summary_card.dart` |
| `_MemberTile` | `lib/widgets/bill_detail/member_tile.dart` |
| `_ItemTile` (depends on `StackedAvatars`) | `lib/widgets/bill_detail/item_tile.dart` |
| `_PillTabBar` + `_CountTab` | `lib/widgets/bill_detail/pill_tab_bar.dart` |
| `_ItemsTab` (depends on `ItemTile`, `BillSummaryCard`) | `lib/widgets/bill_detail/items_tab.dart` |
| `_MembersTab` (depends on `MemberTile`) | `lib/widgets/bill_detail/members_tab.dart` |
| `_ItemFormSheet`/State | `lib/widgets/bill_detail/item_form_sheet.dart` |
| `_MemberFormSheet`/State | `lib/widgets/bill_detail/member_form_sheet.dart` |

Stays in `bill_detail_screen.dart`: `BillDetailScreen`/`_BillDetailScreenState` plus new small page-chrome widgets (see below) — not reusable, so keep local.

**Preserve as-is** (already correct, use as reference patterns): `context.select<BillsStore, Bill?>((s) => s.getById(widget.billId))` narrow selector; the memoized `_getCalc()` with identity/field-diff check; debounced `setState` for amount-field preview; `_MemberFormSheet`'s already-correct `ListView.builder` usage (friend/group-member pickers).

### `group_detail_screen.dart` extraction map (1899 → target ~230-300 lines)

| Class (current) | Target file | Note |
|---|---|---|
| `_EmptyState` | `lib/widgets/group_detail/empty_state.dart` | rename to `GroupDetailEmptyState` — used by 3 other extracted files, and a different shared `EmptyStateWidget` already exists elsewhere, don't merge |
| `_GroupTabBar` + `_CountTab` | `lib/widgets/group_detail/group_tab_bar.dart` | |
| `_MembersTab` | `lib/widgets/group_detail/members_tab.dart` | perf fix (below) |
| `_BillsTab` | `lib/widgets/group_detail/bills_tab.dart` | already `ListView.builder`, mechanical move only |
| `_GroupSummaryTab` | `lib/widgets/group_detail/group_summary_tab.dart` | **Stateless → Stateful** (below) |
| `_GroupAnalyticsTab`/State + `_HeroStatPill` | `lib/widgets/group_detail/group_analytics_tab.dart` | already-correct memoization pattern, reference for the fix below |
| `_TouchablePieChart`/State | `lib/widgets/group_detail/touchable_pie_chart.dart` | perf fix (below) |
| `_ManageMembersSheet`/State | `lib/widgets/group_detail/manage_members_sheet.dart` | mechanical move only |

Stays in `group_detail_screen.dart`: `GroupDetailScreen`/`_GroupDetailScreenState` only. Remove the `_expandedBillId` field and its `onToggle` wiring entirely (moves into `GroupSummaryTab`).

**Preserve as-is**: `context.select<GroupsStore, Group?>` and `context.select<BillsStore, List<Bill>>` narrow selectors; `_BillsTab`/`_GroupSummaryTab`'s existing `ListView.builder` usage; `_GroupAnalyticsTabState`'s `didUpdateWidget` + signature-check memoization pattern — this is the reference pattern to replicate for the fix below.

### Concrete performance fixes

1. **Eager lists → `.builder`**: `_ItemsTab` (bill_detail) and group's `_MembersTab` both build a plain `ListView(children: [...])` with an eager `...items.map(...).toList()` spread — convert both to `ListView.builder` using the same "index 0 is header/button, rest are rows" idiom `_BillsTab`/`_GroupSummaryTab` already use.
2. **`bill_detail_screen.dart`'s `_MembersTab`, friend-set memoization** (was lines 1003-1007): recomputes `friendsProvider.friends.map(...).whereType<String>().toSet()` on every build. Extend `_BillDetailScreenState`'s existing `_getCalc`-style identity-check cache with a new `_getFriendUserIds(friends)` following the same `identical()` pattern, and pass the memoized set down as a new required param on `MembersTab` (stays a pure `StatelessWidget`, no controller needed).
3. **`bill_detail_screen.dart`'s `_MembersTab`, O(n·m) lookup** (was lines 1064-1068): replaces per-member `calc.memberSummaries.firstWhere(...)` with a single `{for (final s in calc.memberSummaries) s.member.id: s}` map built once per build, then O(1) lookups.
4. **`group_detail_screen.dart`'s `_GroupSummaryTab`, totalAmount memoization** (was lines 671-706): convert from `StatelessWidget` to `StatefulWidget`, replicate `_GroupAnalyticsTabState`'s `initState`/`didUpdateWidget` + signature-check pattern (was lines 910-955) to cache `_totalAmount` and only recompute when bills actually change. While doing this, extract the currently-duplicated `_billsEqual` helper into a single shared `billsEqual()` function in `lib/utils/bill_utils.dart`, and strengthen it to also compare `updatedAt` per bill (the current check only compares item counts, so in-place price edits with the same item count don't retrigger recompute — a real correctness gap, not just perf).
5. **`_TouchablePieChart`, stop remapping all sections on touch** (was lines 1358-1497): currently recomputes `billTotal`/`pct`/`PieChartSectionData` for all displayed bills AND separately recomputes the same values again for the legend, both redone on every touch (`setState` only changes `_pieTouchedIndex`). Cache a `List<_PieSliceData>` in `initState`/`didUpdateWidget` (reuse `billsEqual`), have `build()` do one cheap `.map` over the cached slices varying only `radius`/`isTouched`, and have the legend consume the same cached slices instead of recomputing independently.
6. **`_expandedBillId` ownership move** (was `group_detail_screen.dart:30, 194-198`): remove from `_GroupDetailScreenState` entirely; `_GroupSummaryTabState` (per fix #4's Stateful conversion) owns it locally and toggles via its own `setState`. Net effect: expanding/collapsing a bill row in the Summary tab no longer rebuilds `_MembersTab`, `_BillsTab`, `_GroupAnalyticsTab` alongside it.

### Build-method decomposition

- `_ItemFormSheetState.build()` (~440 lines): split into `_ItemFormHeader` (pure), `_SplitModeToggle` (callback), `_MemberPickerList` (callback — must trigger parent `setState` on toggle/amount-edit), `_UnequalValidationBanner` (pure), `_PaidByPicker` (callback). Keep these file-private within `item_form_sheet.dart` — tightly coupled to the sheet's mutable fields, not meant for reuse.
- `_BillDetailScreenState.build()`: the 4 near-identical ~40-line action-button blocks (close bill / reopen / mark done / reopen) become one `_BillActionPill({label, icon, color, textColor, onTap})` widget class (a real widget, not a method, so Flutter can actually skip its rebuild) called 4x. Also extract `_BillHeaderTitle` and `_BillStatusBanner`. Keep these three local to `bill_detail_screen.dart` — page-specific chrome, not reusable.

### RepaintBoundary
Wrap each row returned from the new `ListView.builder` `itemBuilder`s (both screens' `ItemsTab`/`MembersTab`/`BillsTab`/`GroupSummaryTab`) in `RepaintBoundary`. Wrap `TouchablePieChart`'s inner `PieChart` widget in `RepaintBoundary` — it's the highest-frequency-repaint widget in either screen (receives `touchCallback` on every drag frame).

### Sequencing
Extract pure leaves first (no internal cross-deps), then widgets that depend on those leaves (tabs), then self-contained stateful form sheets, then rewire/shrink the host screen's `build()` last, verifying `flutter analyze` after each step. Finish `bill_detail_screen.dart` completely before starting `group_detail_screen.dart` — they share no code, so interleaving only increases review surface.

### Smoke test for this phase
Open a bill: add/edit/delete an item, add/edit a member (equal and unequal split), toggle paid status, close/reopen the bill. Open a group: switch all 4 tabs, expand/collapse a bill row in Summary, tap around the analytics pie chart, manage members (add/remove).

---

## Phase 2 — In-place extractions (zero external import changes)

Covers `lib/widgets/summary_tab.dart`, `lib/widgets/analytics_tab.dart`, `lib/screens/home_screen.dart`, `lib/screens/friends_screen.dart`, `lib/screens/me_screen.dart`. Grouped together because each file's public entry widget (`SummaryTab`, `AnalyticsTab`, `HomeScreen`, `FriendsScreen`, `MeScreen`) keeps its current file path and constructor — only file-private helper classes move, so **no other file in the repo needs an import edit**. Each file can be done independently, in any order, verified on its own.

### `lib/widgets/summary_tab.dart` (1805 → target ~150-180 lines)
New dir `lib/widgets/summary_tab/`. Extract: top-level `_pickSlipAndMarkPaid` fn → `slip_upload_helper.dart` (public `pickSlipAndMarkPaid`); `_HeroCard` → `hero_card.dart`; `_BillBreakdownCard`+`_BreakdownRow` → `bill_breakdown_card.dart`; `_MemberSelector` → `member_selector.dart`; `_SelectedMemberCard` → `selected_member_card.dart`; `_DebtSection`+`_DebtCard` → `debt_section.dart`; `_AllMembersSection`+`_SmallBadge` → `all_members_section.dart`. `SummaryTab`/`_SummaryTabState` (init/select-member state, `_computeMyDebts`, composing `build()`) stays in `summary_tab.dart`.

**Perf fix**: `allDebts = simplifyDebts(...)` currently runs on every build even when the "All Members" section is collapsed. Gate it behind `_allMembersExpanded`.

### `lib/widgets/analytics_tab.dart` (968 → target ~180-220 lines)
New dir `lib/widgets/analytics_tab/`. Extract: `_MemberTotal` → `member_total.dart`; `_GradientStatCard`+stats-row method → `stats_row.dart`; `_buildTopItemsCard` method → `top_items_card.dart`; `_BiggestSpenderCard` → `biggest_spender_card.dart`; `_FairnessCard`+`_FairnessPersonCol` → `fairness_card.dart`; inline "Items Per Member" grid block → `items_per_member_grid.dart`; `_SectionCard` → `section_card.dart`; inline "Member Spending Bars" block → `member_spending_list.dart`.

**Highest-value perf fix in this phase**: the pie-chart-building method currently lives on `_AnalyticsTabState`, with `_pieTouchedIndex` also on that state — so every chart touch/drag frame calls `setState` on the whole tab, re-running the member-totals/top-items sorts and rebuilding every other card. Promote it to its own `PieChartCard extends StatefulWidget` (new file `pie_chart_card.dart`) owning `_pieTouchedIndex` internally, taking only immutable `memberTotals`/`total` as input.

### `lib/screens/home_screen.dart` (1153 → target ~280-330 lines)
New dir `lib/widgets/home/`. **Preserve exactly, verbatim, do not rewrite to watch/select**: the `Selector2<BillsStore, GroupsStore, ...>` in `_HeroBalanceCard`, and the `Selector<BillsStore, List<Bill>>` in `_StatsGrid`/`_RecentBillsList` — these are the file's main perf strength. Extract: `_HeroPill` → `hero_pill.dart`; `_HeroBalanceCard` (keeps its Selector2) → `hero_balance_card.dart`; `_StatsGrid`+`_StatCard` (keeps its Selector) → `stats_grid.dart`; `_RecentBillsList` (keeps its Selector) → `recent_bills_list.dart`; `_QuickActionTile` → `quick_action_tile.dart`; `_CurrencyConfig`+`_RateData`+`_CurrencyCard`+the inline currency-rates UI block → new `CurrencyRatesSection` widget in `currency_rates_section.dart`. `_loadData`/`_loadRates`/rate-fetch state stays in `_HomeScreenState`.

**Perf fix**: the rates list currently does an O(n) `firstWhere` per rendered currency card, every rebuild. Merge config+rate into one object at fetch time in `_loadRates()` instead, so rendering needs zero lookup.

### `lib/screens/friends_screen.dart` (958 → target ~500-560 lines)
New dir `lib/widgets/friends/`. Extract: `_SectionHeader` → `friends_section_header.dart` (rename `FriendsSectionHeader` — a different `section_header.dart` already exists, don't collide); `_EmptyFriendsState` → `empty_friends_state.dart`; `_RoundedAvatar` → `rounded_avatar.dart`; `_FriendRow` → `friend_row.dart`; the inline "Add Friend Panel" block → new `AddFriendPanel` widget in `add_friend_panel.dart`; the inline "Pending Requests" block → new `PendingRequestsCard` widget in `pending_requests_card.dart`.

**Perf fix**: the add-friend `TextField.onChanged` calls `setState(() {})` on the entire `_FriendsScreenState` every keystroke just to toggle the send button's enabled state. Move that state into the new `AddFriendPanel` (own `StatefulWidget`) so keystrokes only rebuild the panel.

Already correct, don't touch here: the `ListView.builder` usage (has a justifying comment). Note: `friends_screen.dart`'s `context.select<FriendsStore, List>` for whole lists is addressed in Phase 4 (store-level caching fix), not here.

### `lib/screens/me_screen.dart` (1391 → target ~350-450 lines)
**Higher risk than the other four files in this phase** — most of its bulk is large instance *methods*, not already-separate classes, so this is method→widget conversion, not a pure move. Budget for manual QA of every edit-mode toggle after.

New dir `lib/widgets/me/`. Extract existing classes: `_ToastBanner` → `toast_banner.dart`; `_SettingsTile` → `settings_tile.dart`; `_LanguageDialog`+`_LangOption` → `language_dialog.dart`; `_ProfileFieldRow`+`_LowercaseFormatter` → `profile_field_row.dart`; `_PasswordField`/State → `password_field.dart`. Promote methods to widgets: `_buildAvatar`/`_buildInitialAvatar` → new `ProfileAvatar` widget in `profile_avatar.dart`; `_buildHeader` → new `ProfileHeader` widget in `profile_header.dart`; `_buildProfileTab` (mixes 3 unrelated concerns) → split into 3 new widgets `AccountSection`, `SecuritySection`, `SettingsSection` in `account_section.dart`/`security_section.dart`/`settings_section.dart`. Leave the sign-out button inline (small, screen-specific).

**Opportunistic one-liner**: change `context.select<AuthProvider, dynamic>` (profile select) to `context.select<AuthProvider, Profile?>` — zero behavior change, matches the already-correct typed pattern in `home_screen.dart`. Note: this file's provider consumption is otherwise already correctly narrow (`select`/`read`, not `watch`) — no further Phase 4 work needed here despite what an earlier draft of this plan assumed.

### Sequencing
By ascending risk: `analytics_tab.dart` → `summary_tab.dart` → `friends_screen.dart` → `home_screen.dart` → `me_screen.dart`.

### Smoke test for this phase
Bill summary tab: expand debts, switch selected member, mark paid. Analytics tab: touch/drag the pie chart, verify cards render. Home screen: pull to refresh, view currency rates, tap a stat card. Friends screen: type in add-friend field, send/accept/decline a request. Me screen: toggle every edit mode (name/username/promptpay/password), toggle dark mode, change language, upload avatar.

---

## Phase 3 — Cross-file consolidation

Touches more than one file's imports — do after Phase 2's pattern is proven, keep this diff isolated.

### Create-flow dedup
1. **Delete `lib/widgets/create_entity_sheet.dart` outright.** Confirmed dead code — no references anywhere else in the repo (`grep -rn "CreateEntitySheet\|EntityFormResult\|showCreateEntitySheet" lib` returns nothing outside the file itself). Re-run that grep immediately before deleting in case something changed.
2. Create `lib/widgets/shared/emoji_picker_grid.dart` (public `EmojiPickerGrid`) and `lib/widgets/shared/toggle_card.dart` (public `ToggleCard`) — sourced from `create_bill_screen.dart`'s copies (byte-identical to the deleted file's and to `create_group_screen.dart`'s emoji grid). Match whichever directory precedent Phase 1 set (`lib/widgets/shared/` subdir vs. flat) for consistency.
3. Also consolidate the backing constants, which are genuinely triplicated: `_kEmojiPresets` and `_kDefaultTags` exist verbatim in the deleted file, `create_bill_screen.dart`, and `create_group_screen.dart` — move both into the new shared emoji-grid file (as public `kEmojiPresets`/`kDefaultTags`) or a small `lib/widgets/shared/bill_form_constants.dart`. `_kCurrencies`/`_kRoundingOptions` stay in `create_bill_screen.dart` only (groups don't need them).
4. Update imports in `create_bill_screen.dart` and `create_group_screen.dart`, dropping their now-duplicate local copies.

### `lib/models/models.dart` split (797 lines, 13 classes, 23 importers)
All 23 importers use a plain unqualified `import '...models/models.dart';` — a barrel-preserving split is fully transparent to every caller. Split following this verified dependency order (a DAG, no cycles):

```
bill_settings.dart   → BillSettings          (no deps)
profile.dart         → Profile               (no deps)
bill_member.dart     → BillMember            (imports profile.dart)
bill_item.dart       → BillItem              (no deps)
bill.dart            → Bill                  (imports bill_settings, bill_member, bill_item)
group_member.dart    → GroupMember           (imports profile.dart)
group.dart           → Group                 (imports group_member.dart)
friend.dart          → Friend                (imports profile.dart)
notification.dart    → AppNotification       (no deps)
bill_calculation.dart → MemberItemShare, MemberSummary, BillCalculation, DebtTransaction
                                              (imports bill_member, bill_item — kept together, one cohesive concept)
```

`lib/models/models.dart` becomes a pure `export` barrel (matches the conditional-export pattern already used in `lib/services/line_web_platform.dart`):

```dart
export 'bill_settings.dart';
export 'profile.dart';
export 'bill_member.dart';
export 'bill_item.dart';
export 'bill.dart';
export 'group_member.dart';
export 'group.dart';
export 'friend.dart';
export 'notification.dart';
export 'bill_calculation.dart';
```

No changes needed in any of the 23 importing files.

### Sequencing
Create-flow dedup first (small, self-contained, quick win). Models split last (widest import fan-out, but lowest actual risk given the barrel — do it as its own clean, isolated diff).

### Smoke test for this phase
Create a new bill (verify emoji picker + VAT/service toggle still work), create a new group (verify emoji picker still works). Run `flutter analyze` and spot-check a few screens that consume models heavily (bill detail, group detail, friends) to confirm no import breakage.

---

## Phase 4 — State management targeted fixes (no framework migration)

Confirmed: stay on Provider/ChangeNotifier — no functional bottleneck justifies a Riverpod/Bloc migration. These are mechanical, targeted fixes.

### 1. `lib/main.dart:171-172` — narrow the root watch
`KidtangApp.build()` does `context.watch<AuthProvider>()`, but `lib/router.dart:56` already does `refreshListenable: authProvider` — routing reacts to auth changes independently of this widget's rebuild. The only field `build()` actually reads off `authProvider` is `lineWebLoginNeedsReturnToApp` (used to swap in `LineWebReturnScreen`). Replace with:
```dart
final needsLineReturn = context.select<AuthProvider, bool>(
  (a) => a.lineWebLoginNeedsReturnToApp,
);
```
and update the `builder` callback accordingly. This narrows the rebuild trigger from all of `AuthProvider`'s ~11 `notifyListeners()` sites down to the one that ever sets this flag (fires at most once per app lifetime, on iOS LINE-web-login handoff). Apply the same `select`-for-clarity treatment to `ThemeProvider` (`context.select<ThemeProvider, bool>((t) => t.isDark)`) for consistency, though it was already low-risk as a `watch`.

### 2. `lib/providers/auth_provider.dart` (836 lines) — compose, don't fragment
Keep it as a single `ChangeNotifier` — splitting into multiple registered notifiers (e.g. separate session/profile providers) would force `router.dart` and ~9 consumer files (`main.dart`, `router.dart`, `profile_screen.dart`, `login_screen.dart`, `main_shell.dart`, `onboarding_screen.dart`, `me_screen.dart`, `home_screen.dart`) to coordinate two listenables, for no measurable rebuild-cost win (every consumer already narrowly `select`s down to `.profile`/`.user`/specific getters).

Instead extract non-UI-facing mechanics into two new plain composed classes that `AuthProvider` delegates to, with **zero changes required at any external call site**:
- **`lib/services/profile_repository.dart`** (new, plain class) — raw Supabase profile CRUD: the DB-fetch portion of `_loadProfile`, `_ensureProfile`, the upsert portion of `updateProfile`/`completeOnboarding`, `isUsernameTaken`. `AuthProvider` retains `_profile` field ownership, `notifyListeners()`, and sibling-sync orchestration.
- **`lib/services/social_auth_service.dart`** (new, plain class) — Google/LINE sign-in mechanics: `GoogleSignIn` construction, `_handleGoogleAccount`, the mobile/web branching in `signInWithGoogle`, `signInWithLine`, `_completeLineWebLogin`, `_finishLineSignIn`, `_maybeStartHandoffPolling`, the `WidgetsBindingObserver` lifecycle glue. Exposes async methods returning results/errors; `AuthProvider` sets its own fields from the result and calls `notifyListeners()`.

`AuthProvider` (trimmed) keeps: `_init()`, the `onAuthStateChange` listener, `signOut()`, simple email sign-in/sign-up/OTP methods, all public getters, and `setSiblingProviders`/`_syncSiblings` exactly as-is. **Do not** switch sibling-provider wiring to `ProxyProvider` — evaluated and rejected, since the sibling actions (`GroupsStore.clear()`, `BillsStore.subscribeRealtime()`) are one-shot lifecycle transitions tied to specific events (login/logout), not continuously-derived state; a `ProxyProvider`'s `update` callback would fire on every one of `AuthProvider`'s notifies, requiring extra guard logic to avoid redundant calls.

**Execution order**: extract `ProfileRepository` first (lower risk), verify, then `SocialAuthService` (higher risk — touches Google/LINE SDKs, web OAuth redirects, iOS handoff polling). After both, confirm zero changes were needed in any of the 9 consumer files listed above — that's the acceptance check that composition truly preserved the external contract. Manually verify every sign-in path per the `verify` skill: email sign-in/sign-up/OTP, Google mobile, Google web, LINE mobile, LINE web (including iOS "return to app" screen), sign-out, session restore on cold start.

### 3. `lib/stores/friends_store.dart` — fix a real caching gap
`friends`/`pendingReceived` getters allocate a brand-new `List` on every property access with no caching. Since `List` has no `==` override, `context.select` on these in `friends_screen.dart` provides **zero dedup benefit** — behaves identically to `context.watch`. Concrete evidence: `loadFriends()` calls `notifyListeners()` with `_loading = true` *before* data changes, yet `friends_screen` still rebuilds because the selector sees a new (but content-identical) list object — this fires on every screen mount and every `sendFriendRequest`.

Fix by mirroring `BillsStore`'s existing `listEquals`-based cache-invalidation pattern (`lib/stores/bills_store.dart:59-84`): add `_cachedFriends`/`_cachedPendingReceived` fields, recompute-and-`listEquals`-compare inside a new `_invalidateCache()` called from the same existing mutation sites (`loadFriends`, `acceptFriendRequest`, `declineFriendRequest`, `removeFriend`, `clear`), keeping the same list reference when content is unchanged. Getter signatures stay unchanged — no changes needed in `friends_screen.dart` or `main_shell.dart`.

### 4. `lib/screens/friends_screen.dart` — isolate per-row rebuild
`_respondingId` (the row currently showing an accept/decline spinner) lives on `_FriendsScreenState` — setting it re-runs the entire `build()` (re-evaluating selects, rebuilding the whole list) when only one row's button state needs to change. Same anti-pattern as Phase 1's `_expandedBillId` fix, different screen. Extract each pending-request row into its own `_FriendRequestTile extends StatefulWidget` owning `_responding` locally. (`_showAdd` and the add-friend form fields are legitimately screen-level — they change the whole screen's layout — leave those as-is; the add-friend panel's own perf fix is covered in Phase 2.)

### Explicitly confirmed — no action needed
- **`me_screen.dart`**: already uses narrow `select`/`read` throughout (verified: zero `context.watch` calls in the file) — an earlier draft of this plan assumed otherwise; that assumption was stale.
- **`lib/stores/bills_store.dart`**: only 2 `notifyListeners()` call sites despite ~30 mutating methods, but this is not a real problem — `_invalidateCache()` already `listEquals`-compares every derived getter individually, so a mutation to one bill doesn't rebuild widgets watching an unrelated bill/group via `select`. This is the exact pattern item 3 above ports to `FriendsStore`.
- **`friends_screen.dart`'s whole-list `select`**: selecting full `friends`/`pendingReceived` lists (rather than counts, unlike `main_shell.dart`'s count-only selects) is correct here since the screen renders the full lists — no change needed beyond the caching fix in item 3.

### Sequencing
`main.dart` fix → `FriendsStore` caching → `friends_screen.dart` tile extraction → `AuthProvider` decomposition last (highest risk, do in isolation, full manual sign-in-flow verification before considering done).

### Smoke test for this phase
Full sign-in/sign-out cycle via every method (email, Google, LINE, on both mobile and web if testable). Friends screen: accept/decline a request, confirm only that row shows a spinner. Cold-start session restore.
