# Kidtang — Bug Fixes & Refactors

> Issues that are broken, incorrect, or will cause data loss / security problems.
> Ordered by priority: 🔴 High → 🟡 Medium → 🟢 Low

---

## 🔴 FIX-01 — `customShares` Not Persisted to Supabase

**File:** `lib/providers/bill_provider.dart` → `addItem()` / `editItem()`

**Problem:** When a user creates an unequal-split item, `customShares` is applied only in-memory via `.copyWith(customShares: customShares)`. The Supabase insert never includes the custom shares. Closing and reopening the bill loses all custom split data.

**Fix:**

1. Add a `custom_shares` column to the DB:
```sql
alter table public.bill_items
  add column if not exists custom_shares jsonb not null default '{}';
```

2. Include it in the insert/update:
```dart
// addItem()
final data = await _supabase.from('bill_items').insert({
  'bill_id': _bill!.id,
  'name': name,
  'price': price,
  'member_ids': memberIds,
  if (paidBy != null) 'paid_by': paidBy,
  if (customShares.isNotEmpty) 'custom_shares': customShares, // ← ADD THIS
}).select().single();
final item = BillItem.fromJson(data); // no more .copyWith() needed

// editItem()
final updates = <String, dynamic>{
  'name': name,
  'price': price,
  'member_ids': memberIds,
  if (paidBy != null) 'paid_by': paidBy,
  'custom_shares': customShares, // ← ADD THIS
};
```

3. Update `BillItem.fromJson()` to read `custom_shares` from the DB response.

---

## 🔴 FIX-02 — `BillsListProvider` Only Loads Owner's Bills

**File:** `lib/providers/bills_list_provider.dart` → `loadBills()`

**Problem:** The query filters `.eq('owner_id', user.id)`. Bills that belong to a group where the user is a member (but not the bill owner) are never shown. The home screen and bills screen appear empty for non-owners.

**Fix — Option A (recommended): Use an RPC**
```sql
-- supabase/migrations/add_my_bills_rpc.sql
create or replace function public.get_my_bills(p_user_id uuid)
returns setof public.bills language sql security definer stable as $$
  select b.* from public.bills b
  where b.owner_id = p_user_id
  union
  select b.* from public.bills b
  inner join public.group_members gm
    on gm.group_id = b.group_id
    and gm.user_id = p_user_id
    and gm.status = 'accepted'
  where b.group_id is not null;
$$;
```

```dart
// In loadBills():
final data = await _supabase
    .rpc('get_my_bills', params: {'p_user_id': user.id})
    .select('*, bill_members(*), bill_items(*)')
    .order('updated_at', ascending: false);
```

---

## 🔴 FIX-03 — `pending_payment` Status Not in DB Constraint

**File:** `supabase/schema.sql` (bills table) + `lib/models/models.dart`

**Problem:** The DB constraint is `check (status in ('draft', 'completed'))` but the Dart model uses `'pending_payment'` as a third status. Any attempt to save `pending_payment` to the DB will throw a constraint violation.

**Fix:**
```sql
-- In schema.sql, update the check constraint:
alter table public.bills
  drop constraint if exists bills_status_check;

alter table public.bills
  add constraint bills_status_check
  check (status in ('draft', 'pending_payment', 'completed'));
```

---

## 🔴 FIX-04 — `AuthProvider` Timing Hacks (Race Conditions)

**File:** `lib/providers/auth_provider.dart`

**Problem:** Two `Future.delayed` calls are used as safety nets:
- `_init()` has a 300ms delay fallback
- `_completeLineWebLogin()` has an 800ms delay

These are band-aids over a real initialization race between `onAuthStateChange` and `setSiblingProviders()`.

**Fix:** Use a `Completer` to guarantee siblings are set before `_init()` proceeds:

```dart
final _siblingsReady = Completer<void>();

void setSiblingProviders({...}) {
  // ... assign siblings ...
  if (!_siblingsReady.isCompleted) _siblingsReady.complete();
}

Future<void> _init() async {
  await _siblingsReady.future; // wait until siblings are wired
  // ... rest of init, no Future.delayed needed ...
}
```

Also call `setSiblingProviders()` **before** `AuthProvider` is added to the `MultiProvider` tree, or use `ProxyProvider` to wire dependencies declaratively.

---

## 🔴 FIX-05 — Fake-Email Pattern for Social Auth (Security)

**File:** `lib/providers/auth_provider.dart` → `_signInWithLine()`, `_signInWithGoogle()`

**Problem:** LINE and Google logins construct a deterministic fake email (`line_<userId>@kidtang.app`) and call `signUp` with a hardcoded password. This:
- Exposes a predictable account takeover vector (anyone who knows a user's LINE ID can attempt to sign in)
- Breaks if Supabase enables email enumeration protection
- Creates orphaned auth users if the profile insert fails

**Fix:** Use Supabase's custom OIDC or an Edge Function to exchange the social token for a Supabase session without a fake email:

```typescript
// supabase/functions/social-auth/index.ts
// Receives { provider: 'line', access_token: '...' }
// Verifies token with LINE API, then uses admin client to upsert user
const { data } = await supabaseAdmin.auth.admin.createUser({
  email: lineProfile.email ?? `line_${lineProfile.userId}@noemail.invalid`,
  user_metadata: { display_name: lineProfile.displayName, avatar_url: lineProfile.pictureUrl },
  email_confirm: true,
});
// Return a custom JWT or magic link
```

---

## 🟡 FIX-06 — `GroupsProvider` Dual Responsibility & Stale Detail State

**File:** `lib/providers/groups_provider.dart`

**Problem:** `GroupsProvider` holds both the groups list and the currently-viewed group detail. Navigating from Group A → Group B → back to Group A shows Group B's data briefly while Group A reloads.

**Fix:** Extract group detail into a separate `GroupDetailProvider` (or `ChangeNotifier`) that is scoped to the `GroupDetailScreen` route:

```dart
// In router.dart, provide GroupDetailProvider only for the detail route:
GoRoute(
  path: '/groups/:id',
  builder: (context, state) => ChangeNotifierProvider(
    create: (_) => GroupDetailProvider(groupId: state.pathParameters['id']!),
    child: const GroupDetailScreen(),
  ),
),
```

---

## 🟡 FIX-07 — `GroupsProvider.createGroup()` Duplicate Profile Upsert

**File:** `lib/providers/groups_provider.dart` → `createGroup()`

**Problem:** `createGroup()` manually upserts the profile row as a guard. The same logic exists in `AuthProvider._ensureProfile()`. This duplication means two different code paths can create profiles with different field values.

**Fix:** Remove the upsert from `createGroup()` entirely. The `handle_new_user` DB trigger and `AuthProvider._ensureProfile()` are the single source of truth. If the profile is missing at group creation time, it's a bug in the auth flow that should be fixed there.

---

## 🟡 FIX-08 — `BillItem.shares` Ambiguous Return Type

**File:** `lib/models/models.dart` → `BillItem.shares` getter

**Problem:** `shares` returns fractional weights (e.g., `0.5`) for equal splits but absolute amounts (e.g., `150.0`) for unequal splits. Callers must know the split mode to interpret the values, which is a leaky abstraction that causes silent calculation errors.

**Fix:**
```dart
// Replace the single ambiguous getter with two explicit ones:
Map<String, double> get equalWeights {
  if (memberIds.isEmpty) return {};
  final w = 1.0 / memberIds.length;
  return {for (final id in memberIds) id: w};
}

// Keep customShares as-is (absolute amounts)
// Remove the old `shares` getter entirely
// Update all callers in bill_utils.dart to use the correct getter
```

---

## 🟡 FIX-09 — `bill_detail_screen.dart` 2,648-Line Monolith

**File:** `lib/screens/bill_detail_screen.dart`

**Problem:** The file contains the screen scaffold, 4 tab widgets, item form sheet, member form sheet, and helper widgets — all as private classes. Impossible to unit-test individual components.

**Fix:** Extract into the existing `lib/widgets/` pattern:

| New file | Extracted classes |
|---|---|
| `lib/widgets/members_tab.dart` | `_MembersTab`, `_MemberTile` |
| `lib/widgets/items_tab.dart` | `_ItemsTab`, `_ItemTile`, `_BillSummaryCard` |
| `lib/widgets/bill_settings_sheet.dart` | `_BillSettingsSheet` |

Note: `lib/widgets/item_form_sheet.dart` already exists — the `_ItemFormSheet` inside `bill_detail_screen.dart` is a duplicate. Consolidate into the existing file.

---

## 🟡 FIX-10 — Router `pending_payment` State Not Handled

**File:** `lib/router.dart`

**Problem:** The router redirect logic has 6 conditional branches. The `pending_payment` bill status is referenced in Dart but has no dedicated route or redirect handling, so bills in that state fall through to the default case.

**Fix:** Add explicit handling and simplify with a state enum:

```dart
enum _AuthState { loading, unauthenticated, needsOnboarding, ready }

_AuthState _resolveState(AuthProvider auth) {
  if (auth.loading) return _AuthState.loading;
  if (!auth.isLoggedIn) return _AuthState.unauthenticated;
  if (auth.needsOnboarding) return _AuthState.needsOnboarding;
  return _AuthState.ready;
}
```

---

## 🟢 FIX-11 — Hardcoded Color Constants in `summary_tab.dart`

**File:** `lib/widgets/summary_tab.dart`

**Problem:** 8 private color constants duplicate values already defined in `AppColors`.

**Fix:**
```dart
// Remove these private constants:
// const _kEmerald50, _kEmerald100, _kEmerald200, _kEmerald500, _kEmerald600, _kEmerald700
// const _kBlue400, _kBlue500

// Replace usages with:
AppColors.primary        // was _kBlue400
AppColors.emerald        // was _kEmerald500
// Add missing shades to AppColors if needed
```

---

## 🟢 FIX-12 — `_DebtEdge` Duplicates `DebtTransaction`

**File:** `lib/providers/groups_provider.dart`

**Problem:** The private `_DebtEdge` class at the bottom of `groups_provider.dart` is conceptually identical to `DebtTransaction` in `models.dart`, but uses `fromId`/`toId` strings instead of `BillMember` objects.

**Fix:** Move `computeGroupSummary()` to `bill_utils.dart` and have it return `List<DebtTransaction>`. Delete `_DebtEdge`.

---

## 🟢 FIX-13 — `updateProfile()` Silent Side-Effect on `bill_members`

**File:** `lib/providers/auth_provider.dart` → `updateProfile()`

**Problem:** `updateProfile()` silently updates all `bill_members` rows with the new display name. If this second Supabase call fails, the profile is updated but bill member names are stale — with no error surfaced to the user.

**Fix:** Wrap in its own try/catch and surface the error, or move the sync to a Supabase DB trigger:

```sql
-- Trigger: sync display_name to bill_members on profile update
create or replace function public.sync_bill_member_names()
returns trigger language plpgsql as $$
begin
  update public.bill_members
  set name = new.display_name
  where user_id = new.id and is_external = false;
  return new;
end;
$$;

create trigger profiles_sync_names
  after update of display_name on public.profiles
  for each row execute procedure public.sync_bill_member_names();
```
