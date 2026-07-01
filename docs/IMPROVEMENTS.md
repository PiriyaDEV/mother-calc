# Kidtang — Feature Improvements & Enhancements

> Logical next-step features to improve user experience.
> Ordered by user impact: 🔴 High → 🟡 Medium → 🟢 Nice-to-have

---

## 🔴 IMP-01 — Real-Time Collaborative Bill Editing

**Why:** When two people are at a restaurant adding items to the same bill simultaneously, neither sees the other's changes without a manual pull-to-refresh. This is the core use case of the app.

**How:** Add Supabase Realtime subscriptions in `BillProvider`:

```dart
// lib/providers/bill_provider.dart
late RealtimeChannel? _billChannel;

void subscribeToRealtime(String billId) {
  _billChannel = _supabase
    .channel('bill:$billId')
    .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'bill_items',
      filter: PostgresChangeFilter(
        type: FilterType.eq, column: 'bill_id', value: billId,
      ),
      callback: (_) => _refreshItems(),
    )
    .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'bill_members',
      filter: PostgresChangeFilter(
        type: FilterType.eq, column: 'bill_id', value: billId,
      ),
      callback: (_) => _refreshMembers(),
    )
    .subscribe();
}

@override
void dispose() {
  _billChannel?.unsubscribe();
  super.dispose();
}
```

**DB change needed:** None — Supabase Realtime works on existing tables once enabled in the Supabase dashboard (Replication → Tables).

---

## 🔴 IMP-02 — Share Bill Summary as Image

**Why:** The #1 action after splitting a bill is sending the breakdown to the group chat (LINE, WhatsApp). Currently users must screenshot manually.

**How:** Add a "Share" button to `SummaryTab` using `screenshot` + `share_plus` packages:

```yaml
# pubspec.yaml
dependencies:
  screenshot: ^3.0.0
  share_plus: ^10.0.0
```

```dart
// In SummaryTab — wrap the hero card + breakdown in a ScreenshotController:
final _screenshotController = ScreenshotController();

Screenshot(
  controller: _screenshotController,
  child: _BillShareCard(calc: calc, bill: bill, members: members),
),

// Share button:
FilledButton.icon(
  icon: const Icon(Icons.share_rounded),
  label: const Text('แชร์สรุปบิล'),
  onPressed: () async {
    final image = await _screenshotController.capture();
    if (image == null) return;
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/bill_summary.png')..writeAsBytesSync(image);
    await Share.shareXFiles([XFile(file.path)], text: 'สรุปบิล: ${bill.title}');
  },
),
```

---

## 🔴 IMP-03 — Optimistic UI (Offline-Friendly Interactions)

**Why:** The app is used at restaurants with poor connectivity. Every add-item / toggle-paid action currently freezes the UI waiting for a Supabase round-trip (~300–800ms). Optimistic updates make the app feel instant.

**How:** Apply the optimistic pattern to `BillProvider.addItem()`:

```dart
Future<void> addItem({required String name, required double price, ...}) async {
  // 1. Immediately update local state with a temp ID
  final tempId = const Uuid().v4();
  final optimisticItem = BillItem(id: tempId, name: name, price: price, ...);
  _items = [..._items, optimisticItem];
  notifyListeners();

  try {
    // 2. Persist to Supabase
    final data = await _supabase.from('bill_items').insert({...}).select().single();
    // 3. Replace temp item with the real DB row
    _items = _items.map((i) => i.id == tempId ? BillItem.fromJson(data) : i).toList();
  } catch (e) {
    // 4. Roll back on failure and show a snackbar
    _items = _items.where((i) => i.id != tempId).toList();
    _error = 'เพิ่มรายการไม่สำเร็จ';
  }
  notifyListeners();
}
```

Apply the same pattern to `editItem()`, `deleteItem()`, `addMember()`, and `toggleMemberPaid()`.

---

## 🔴 IMP-04 — Bill Invite Link (Join Without Friend Request)

**Why:** The current flow requires the bill owner to add members manually by username or from their friends list. For one-time splits with strangers (e.g., a trip with new acquaintances), this is too much friction.

**How:**

1. Add an `invite_token` column to bills:
```sql
alter table public.bills
  add column if not exists invite_token text unique default gen_random_uuid()::text;

create index if not exists bills_invite_token_idx on public.bills(invite_token);
```

2. Add a deep link route in `router.dart`:
```dart
GoRoute(
  path: '/join/:token',
  builder: (context, state) => JoinBillScreen(token: state.pathParameters['token']!),
),
```

3. In `JoinBillScreen`, look up the bill by token and add the current user as a `bill_member`.

4. Add a "Copy Invite Link" button to `BillDetailScreen`:
```dart
IconButton(
  icon: const Icon(Icons.link_rounded),
  onPressed: () {
    Clipboard.setData(ClipboardData(
      text: 'https://kidtang.app/join/${bill.inviteToken}',
    ));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('คัดลอกลิงก์แล้ว')),
    );
  },
),
```

---

## 🟡 IMP-05 — Group Balance Dashboard Tab

**Why:** `computeGroupSummary()` already calculates simplified debts across all group bills, but this data is never shown in the UI. Users have no way to see their net balance within a group.

**How:** Add a "Balance" tab to `GroupDetailScreen`:

```dart
// lib/widgets/group_balance_tab.dart
class GroupBalanceTab extends StatelessWidget {
  final GroupsProvider groupsProvider;

  @override
  Widget build(BuildContext context) {
    final debts = groupsProvider.computeGroupSummary();
    final members = groupsProvider.currentMembers;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Net balance per member (bar chart or list)
        _NetBalanceCard(members: members, debts: debts),
        const SizedBox(height: 12),
        // Simplified settlement transactions
        _SettlementList(debts: debts, members: members),
      ],
    );
  }
}
```

Also surface the current user's net balance as a badge on the Groups tab icon.

---

## 🟡 IMP-06 — Monthly Spending Summary on Home Screen

**Why:** The Home screen currently shows a list of recent bills with no aggregate insight. Users want to know "how much did I spend this month?" at a glance.

**How:** Add a summary card above the recent bills list in `HomeScreen`:

```dart
// Compute from BillsListProvider data (no extra API call needed):
double _monthlyTotal(List<Bill> bills) {
  final now = DateTime.now();
  return bills
    .where((b) => b.createdAt.year == now.year && b.createdAt.month == now.month)
    .fold(0.0, (sum, b) {
      final calc = calculateBill(b);
      final myMember = b.members.firstWhereOrNull((m) => m.userId == currentUserId);
      if (myMember == null) return sum;
      final mySummary = calc.memberSummaries.firstWhereOrNull((s) => s.member.id == myMember.id);
      return sum + (mySummary?.total ?? 0);
    });
}
```

Display as a gradient card: "เดือนนี้คุณใช้ไป ฿X,XXX"

---

## 🟡 IMP-07 — Bill Comments / Activity Log

**Why:** Members need a way to communicate within a bill — e.g., "I already paid you in cash", "Can you add the parking fee?". This also serves as an audit trail.

**DB change:**
```sql
create table public.bill_comments (
  id         uuid primary key default uuid_generate_v4(),
  bill_id    uuid not null references public.bills(id) on delete cascade,
  user_id    uuid not null references public.profiles(id) on delete cascade,
  body       text not null check (char_length(body) <= 500),
  created_at timestamptz not null default now()
);

create index bill_comments_bill_id_idx on public.bill_comments(bill_id);

alter table public.bill_comments enable row level security;

create policy "bill_comments_select" on public.bill_comments
  for select using (public.can_access_bill(bill_id));

create policy "bill_comments_insert" on public.bill_comments
  for insert to authenticated with check (
    auth.uid() = user_id and public.can_access_bill(bill_id)
  );
```

**UI:** Add a "Comments" tab (5th tab) to `BillDetailScreen` with a simple chat-style list and a text input at the bottom.

---

## 🟡 IMP-08 — Bill Templates (Recurring Bills)

**Why:** Many users split the same bills repeatedly — monthly rent, weekly groceries, regular team lunches. Recreating the same bill from scratch every time is tedious.

**DB change:**
```sql
create table public.bill_templates (
  id         uuid primary key default uuid_generate_v4(),
  owner_id   uuid not null references public.profiles(id) on delete cascade,
  title      text not null,
  emoji      text,
  settings   jsonb not null default '{}',
  item_names text[] not null default '{}',  -- suggested item names
  created_at timestamptz not null default now()
);
```

**UI:** Add a "Use Template" option in the create bill sheet. After creating a bill from a template, the items are pre-populated with the template's item names (prices left blank for the user to fill in).

---

## 🟡 IMP-09 — PromptPay Slip OCR Verification

**Why:** The slip upload flow in `SummaryTab` already picks an image and shows a confirmation dialog, but the slip is never stored or verified. Adding basic OCR to extract the transfer amount would let the app auto-confirm payment and reduce disputes.

**How:** Use a Supabase Edge Function + Google Vision API:

```typescript
// supabase/functions/verify-slip/index.ts
// 1. Receive base64 image
// 2. Call Google Vision API for text detection
// 3. Extract amount using regex: /(\d{1,3}(?:,\d{3})*(?:\.\d{2})?) บาท/
// 4. Return { amount: number, confidence: number }
```

```dart
// In _pickSlipAndMarkPaid():
final result = await _supabase.functions.invoke('verify-slip', body: {'image': base64Image});
final detectedAmount = result.data['amount'] as double?;
if (detectedAmount != null && (detectedAmount - expectedAmount).abs() > 1.0) {
  // Show warning: "ยอดในสลิป (฿X) ไม่ตรงกับยอดที่ต้องชำระ (฿Y)"
}
```

---

## 🟢 IMP-10 — Multi-Currency with Exchange Rates

**Why:** `BillSettings.currency` is already stored per-bill, but there's no exchange rate conversion. For international trips, users want to see amounts in their home currency.

**How:**

1. Cache exchange rates in `AppConfigService` (fetch once per day from a free API like `exchangerate-api.com`):
```dart
Future<Map<String, double>> getExchangeRates(String base) async {
  final cached = _prefs.getString('exchange_rates_$base');
  if (cached != null && _isFresh(cached)) return jsonDecode(cached);
  final response = await http.get(Uri.parse('https://api.exchangerate-api.com/v4/latest/$base'));
  // cache and return rates
}
```

2. Add a "Convert to THB" toggle in `BillDetailScreen` that multiplies all amounts by the stored rate.

---

## 🟢 IMP-11 — Push Notification for Bill Invite & Payment

**Why:** The push notification infrastructure (`PushNotificationService`, `send-push` Edge Function) is already in place. Extend it to cover more events:

| Event | Notification |
|---|---|
| Someone adds you to a bill | "🧾 [Name] เพิ่มคุณในบิล [Title]" |
| A bill member marks themselves as paid | "✅ [Name] จ่ายแล้ว — [Bill Title]" |
| Bill is marked as completed | "🎉 บิล [Title] เสร็จสิ้นแล้ว" |
| Friend request accepted | "👋 [Name] ยอมรับคำขอเป็นเพื่อนแล้ว" |

Add a DB trigger for each event that calls the `send-push` Edge Function via `pg_net` or `supabase_functions`.

---

## 🟢 IMP-12 — Swipe-to-Delete on Bill Items & Members

**Why:** Currently deleting an item requires a long-press context menu or an edit mode. Swipe-to-delete is a more intuitive mobile pattern.

**How:** Wrap item tiles in `Dismissible`:

```dart
Dismissible(
  key: Key(item.id),
  direction: DismissDirection.endToStart,
  background: Container(
    alignment: Alignment.centerRight,
    padding: const EdgeInsets.only(right: 16),
    color: Colors.red,
    child: const Icon(Icons.delete_rounded, color: Colors.white),
  ),
  confirmDismiss: (_) => showConfirmDialog(context, 'ลบรายการนี้?'),
  onDismissed: (_) => billProvider.deleteItem(item.id),
  child: _ItemTile(item: item, ...),
),
```

---

## Summary

| ID | Feature | Impact | Effort |
|----|---------|--------|--------|
| IMP-01 | Real-time collaborative editing | 🔴 High | Medium |
| IMP-02 | Share bill as image | 🔴 High | Low |
| IMP-03 | Optimistic UI | 🔴 High | Medium |
| IMP-04 | Bill invite link | 🔴 High | Medium |
| IMP-05 | Group balance dashboard | 🟡 Medium | Low |
| IMP-06 | Monthly spending summary | 🟡 Medium | Low |
| IMP-07 | Bill comments / activity log | 🟡 Medium | Medium |
| IMP-08 | Bill templates | 🟡 Medium | Medium |
| IMP-09 | Slip OCR verification | 🟡 Medium | High |
| IMP-10 | Multi-currency exchange rates | 🟢 Low | Medium |
| IMP-11 | Extended push notifications | 🟢 Low | Low |
| IMP-12 | Swipe-to-delete | 🟢 Low | Low |
