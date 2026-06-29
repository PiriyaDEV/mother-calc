# TASK 07 — Friends Screen + Notifications Screen

## 🎯 เป้าหมาย
แปลง 2 หน้าจาก Next.js เป็น Flutter ให้ UI และ behavior เหมือนกันทุกจุด

**Next.js sources:**
- `app/friends/page.tsx` (301 lines)
- `app/notifications/page.tsx` (181 lines)

---

## 📁 ไฟล์ที่แก้

| ไฟล์ | action |
|------|--------|
| `lib/screens/friends_screen.dart` | ปรับ layout ทั้งหมด |
| `lib/screens/notifications_screen.dart` | ปรับ layout ทั้งหมด |
| `lib/providers/friends_provider.dart` | ตรวจสอบ methods ครบ |
| `lib/providers/notifications_provider.dart` | ตรวจสอบ methods ครบ |

---

## ─────────────────────────────────────────
## PART A: Friends Screen
## ─────────────────────────────────────────

### State (ตรงกับ Next.js lines 55–67)
```dart
List<Friend> _friends = [];
List<Friend> _requests = [];
bool _dataLoading = true;
bool _showAdd = false;
String _addUsername = '';
bool _addLoading = false;
String _addError = '';
String _addSuccess = '';
String? _respondingId;
```

---

### Header (ตรงกับ Next.js lines 141–155)
```
เพื่อน                              [+ เพิ่มเพื่อน]
X เพื่อน · Y คำขอใหม่  (ถ้า requests > 0)
```
- bg: `#F4F6FB` (ตรงกับ Next.js `bg-[#f4f6fb]`)
- title: text-xl bold gray-900
- subtitle: text-xs gray-400
- ปุ่ม "เพิ่มเพื่อน": bg `#286bfe`, icon `IoPersonAddOutline`, text-xs font-semibold, borderRadius 12

---

### Add Friend Panel (ตรงกับ Next.js lines 158–195)
แสดงเมื่อ `_showAdd = true` (inline card, ไม่ใช่ modal):

```
┌─────────────────────────────────────────┐
│ เพิ่มเพื่อนใหม่                    [X]  │
│ [🔍 @username_______________] [ส่ง]     │
│ (error: red bg)                         │
│ (success: green bg + ✓)                 │
└─────────────────────────────────────────┘
```
- bg: white, border: gray-100, borderRadius 16
- input: bg gray-50, border gray-100, borderRadius 12, pl-8 (icon left)
- search icon: `IoSearchOutline` size 14, gray-400, absolute left
- ปุ่ม "ส่ง": bg `#286bfe`, disabled ถ้า addUsername ว่าง
- error: bg red-50, text red-500, borderRadius 12
- success: bg green-50, text green-600, icon `IoCheckmarkOutline`

**Logic:**
```dart
// ลบ "@" prefix ออกจาก input อัตโนมัติ
// กด Enter → handleSendRequest()
// handleSendRequest → sendFriendRequest(username)
//   success → addSuccess = "ส่งคำขอเป็นเพื่อนไปยัง @{username} แล้ว!" + clear input
//   error → addError = result.error
```

---

### Pending Requests Section (ตรงกับ Next.js lines 204–243)
แสดงเฉพาะ `requests.length > 0`:

```
คำขอเป็นเพื่อน  [N]  ← badge blue
─────────────────────────────────────────
[avatar 40px]  display_name              [✓][✗]
               @username
```
- card: bg white, border blue-100 `#DBEAFE`, borderRadius 16
- avatar: 40px, borderRadius 16, bg `#286bfe`, initial letter
  - ถ้ามี avatar_url → แสดงรูป
- badge: bg `#286bfe`, text white, text-10, borderRadius full
- ✓ button: 32px, bg `#286bfe`, white icon, borderRadius 12
- ✗ button: 32px, bg gray-100, gray-500 icon, borderRadius 12
- disabled ทั้งคู่เมื่อ `respondingId == req.id`

**Logic:**
```dart
// handleAccept → acceptFriendRequest(friend.id) → remove from requests → reload
// handleDecline → declineFriendRequest(friend.id) → remove from requests
```

---

### Friends List (ตรงกับ Next.js lines 246–293)

**Empty State:**
```
[people icon 28px]
ยังไม่มีเพื่อน
เพิ่มเพื่อนด้วย @username เพื่อเพิ่มเข้ากลุ่มได้
[เพิ่มเพื่อนคนแรก]
```
- icon container: 64px, bg blue-50 `#EFF6FF`, borderRadius 16
- icon color: `#286bfe`
- ปุ่ม: bg `#286bfe`, text white, borderRadius 12

**Friend Row:**
```
[avatar 40px]  display_name              [เพื่อน ✓] [🗑️]
               @username
```
- card: bg white, border gray-100, borderRadius 16
- avatar: 40px, borderRadius 16, bg `#286bfe`
- "เพื่อน" badge: bg green-50 `#F0FDF4`, text green-600 `#16A34A`, icon `IoPersonOutline`, borderRadius 8
- 🗑️ button: 28px, bg gray-100, hover → red-50 + red-500, borderRadius 8

**Logic:**
```dart
// getFriendProfile: friend.requester_id == myId ? friend.addressee : friend.requester
// handleRemove → removeFriend(friend.id) → remove from list
```

---

## ─────────────────────────────────────────
## PART B: Notifications Screen
## ─────────────────────────────────────────

### Header (ตรงกับ Next.js lines 75–101)
```
[←]  การแจ้งเตือน  [N]              [✓✓ อ่านทั้งหมด]
```
- bg: white/80 + backdrop blur, border-b gray-100
- ← กด → navigate to home
- badge [N]: bg `#4366f4`, text white, text-xs bold, borderRadius full
  - แสดงเฉพาะ `unreadCount > 0`
- "อ่านทั้งหมด": text `#4366f4`, icon `IoCheckmarkDone`, text-xs
  - แสดงเฉพาะ `unreadCount > 0`
  - กด → `markAllNotificationsRead()` → set all read=true

---

### Empty State (ตรงกับ Next.js lines 104–110)
```
[bell icon 24px]
ไม่มีการแจ้งเตือน
```
- icon container: 56px, bg gray-100, borderRadius 16

---

### Notification List (ตรงกับ Next.js lines 112–176)

แต่ละ notification card:
```
┌─────────────────────────────────────────┐  ← unread: blue-50 bg + blue-100 border
│ [avatar 40px]  {ชื่อ} เชิญคุณเข้าร่วมกลุ่ม {กลุ่ม}  [●]
│                1 ม.ค. 2568 10:30
│                [ยอมรับ]  [ปฏิเสธ]  ← เฉพาะ unread + type=group_invite
└─────────────────────────────────────────┘
```

**States:**
- Unread: bg blue-50 `#EFF6FF`, border blue-100 `#DBEAFE`
- Read: bg white, border gray-100

**Avatar:**
- 40px, borderRadius 12, bg `#4366f4`
- initial = `(notif.data.invited_by_display_name ?? notif.data.invited_by_username).slice(0,1).toUpperCase()`

**Text:**
- `{invited_by_display_name ?? "@{invited_by_username}"}` (bold) + " เชิญคุณเข้าร่วมกลุ่ม " + `{group_name}` (bold blue `#4366f4`)
- date: text-xs gray-400, format `d MMM yyyy HH:mm` (th-TH)

**Unread dot:** 8px circle, bg `#4366f4`, top-right

**Action buttons (unread + type=group_invite):**
```
[ยอมรับ]  [ปฏิเสธ]
```
- ยอมรับ: flex-1, bg `#4366f4`, text white, borderRadius 12
- ปฏิเสธ: flex-1, bg gray-100, text gray-600, borderRadius 12
- disabled ทั้งคู่เมื่อ `respondingId == notif.id`
- loading text: "กำลังดำเนินการ..."

**Logic:**
```dart
// กด card (ถ้า unread) → markNotificationRead(notif.id) → set read=true
// handleRespond(notif, "accepted"):
//   markNotificationRead(notif.id)
//   respondToGroupInvite(notif.data.group_member_id, true)
//   set read=true
//   navigate to /groups/{notif.data.group_id}
// handleRespond(notif, "declined"):
//   markNotificationRead(notif.id)
//   respondToGroupInvite(notif.data.group_member_id, false)
//   set read=true
```

---

## ✅ Acceptance Criteria

### Friends Screen
- [ ] Header: title + subtitle (X เพื่อน · Y คำขอ)
- [ ] ปุ่ม "เพิ่มเพื่อน" → toggle add panel
- [ ] Add panel: input + ส่ง + error/success messages
- [ ] Input: ลบ "@" prefix อัตโนมัติ
- [ ] Pending requests section: แสดงเฉพาะมี requests
- [ ] Accept/Decline buttons + loading state
- [ ] Friends list: empty state + ปุ่ม "เพิ่มเพื่อนคนแรก"
- [ ] Friend row: avatar + name + @username + "เพื่อน" badge + ลบ
- [ ] Remove friend → ลบออกจาก list ทันที

### Notifications Screen
- [ ] Header: ← + title + unread badge + "อ่านทั้งหมด"
- [ ] Empty state: bell icon + text
- [ ] Notification card: unread = blue bg, read = white bg
- [ ] Unread dot แสดงเฉพาะ unread
- [ ] Text: ชื่อ bold + group_name bold blue
- [ ] Date format th-TH
- [ ] Action buttons แสดงเฉพาะ unread + type=group_invite
- [ ] ยอมรับ → navigate to group
- [ ] กด card → mark as read
- [ ] "อ่านทั้งหมด" → mark all read
