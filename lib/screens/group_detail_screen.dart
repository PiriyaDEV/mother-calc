import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../providers/groups_provider.dart';
import '../theme/app_theme.dart';
import '../utils/bill_utils.dart';
import '../widgets/member_avatar.dart';

class GroupDetailScreen extends StatefulWidget {
  final String groupId;
  const GroupDetailScreen({super.key, required this.groupId});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GroupsProvider>().loadGroupDetail(widget.groupId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<GroupsProvider>();
    final group = provider.currentGroup;

    if (provider.detailLoading) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
        body: const Center(
          child: CircularProgressIndicator(
              color: AppColors.primary, strokeWidth: 2),
        ),
      );
    }

    if (group == null) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Text('ไม่พบกลุ่ม', style: GoogleFonts.notoSansThai()),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            pinned: true,
            backgroundColor: isDark
                ? AppColors.bgDark.withOpacity(0.95)
                : Colors.white.withOpacity(0.95),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded),
              onPressed: () => context.pop(),
            ),
            title: Row(
              children: [
                Text(
                  group.emoji ?? '👥',
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 8),
                Text(
                  group.name,
                  style: GoogleFonts.notoSansThai(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
              ],
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight,
                indicatorColor: AppColors.primary,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor:
                    isDark ? AppColors.borderDark : AppColors.borderLight,
                labelStyle: GoogleFonts.notoSansThai(
                    fontSize: 13, fontWeight: FontWeight.w600),
                unselectedLabelStyle:
                    GoogleFonts.notoSansThai(fontSize: 13),
                tabs: const [
                  Tab(text: 'สมาชิก'),
                  Tab(text: 'บิล'),
                  Tab(text: 'สรุป'),
                  Tab(text: 'วิเคราะห์'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _MembersTab(group: group, provider: provider),
            _BillsTab(group: group, provider: provider),
            _SummaryTab(group: group, provider: provider),
            _AnalyticsTab(group: group, provider: provider),
          ],
        ),
      ),
    );
  }
}

// ── Members Tab ────────────────────────────────────────────────
class _MembersTab extends StatelessWidget {
  final Group group;
  final GroupsProvider provider;
  const _MembersTab({required this.group, required this.provider});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isOwner = group.ownerId == currentUserId;

    final accepted =
        group.members.where((m) => m.role != 'pending').toList();
    final pending =
        group.members.where((m) => m.role == 'pending').toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (isOwner)
          GestureDetector(
            onTap: () => _showInviteSheet(context),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_add_outlined,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'เชิญสมาชิก',
                    style: GoogleFonts.notoSansThai(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),

        // Accepted members
        Text(
          'สมาชิก (${accepted.length})',
          style: GoogleFonts.notoSansThai(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.textTertiaryDark
                : AppColors.textTertiaryLight,
          ),
        ),
        const SizedBox(height: 8),
        ...accepted.map((m) => _MemberTile(
              member: m,
              isOwner: isOwner && m.userId != group.ownerId,
              onRemove: isOwner && m.userId != group.ownerId
                  ? () async {
                      final err = await provider.removeMember(
                          group.id, m.id);
                      if (err != null && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content:
                              Text(err, style: GoogleFonts.notoSansThai()),
                          backgroundColor: AppColors.red,
                          behavior: SnackBarBehavior.floating,
                        ));
                      }
                    }
                  : null,
            )),

        // Pending members
        if (pending.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'รอการตอบรับ (${pending.length})',
            style: GoogleFonts.notoSansThai(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiaryLight,
            ),
          ),
          const SizedBox(height: 8),
          ...pending.map((m) => _MemberTile(
                member: m,
                isPending: true,
                isOwner: isOwner,
                onRemove: isOwner
                    ? () async {
                        await provider.removeMember(group.id, m.id);
                      }
                    : null,
              )),
        ],
      ],
    );
  }

  void _showInviteSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _InviteSheet(
        onInvite: (username) async {
          return await provider.inviteMember(group.id, username);
        },
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final GroupMember member;
  final bool isPending;
  final bool isOwner;
  final VoidCallback? onRemove;

  const _MemberTile({
    required this.member,
    this.isPending = false,
    this.isOwner = false,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = member.profile;
    final name =
        profile?.displayName ?? profile?.username ?? 'ผู้ใช้';
    final username = profile?.username;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Row(
        children: [
          MemberAvatar(
            name: name,
            color: isPending ? AppColors.amber : AppColors.primary,
            size: 40,
            avatarUrl: profile?.avatarUrl,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.notoSansThai(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                if (username != null)
                  Text(
                    '@$username',
                    style: GoogleFonts.notoSansThai(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                    ),
                  ),
              ],
            ),
          ),
          if (member.role == 'owner')
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'เจ้าของ',
                style: GoogleFonts.notoSansThai(
                  fontSize: 11,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else if (isPending)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'รอตอบรับ',
                style: GoogleFonts.notoSansThai(
                  fontSize: 11,
                  color: AppColors.amber,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (onRemove != null) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.remove_circle_outline,
                  color: AppColors.red, size: 20),
            ),
          ],
        ],
      ),
    );
  }
}

class _InviteSheet extends StatefulWidget {
  final Future<String?> Function(String username) onInvite;
  const _InviteSheet({required this.onInvite});

  @override
  State<_InviteSheet> createState() => _InviteSheetState();
}

class _InviteSheetState extends State<_InviteSheet> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _invite() async {
    final username = _ctrl.text.trim().replaceAll('@', '');
    if (username.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });
    final err = await widget.onInvite(username);
    if (mounted) {
      setState(() {
        _loading = false;
        if (err != null) {
          _error = err;
        } else {
          _success = 'ส่งคำเชิญแล้ว!';
          _ctrl.clear();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'เชิญสมาชิก',
              style: GoogleFonts.notoSansThai(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ctrl,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: '@username',
                prefixIcon: Icon(Icons.alternate_email_rounded,
                    color: AppColors.primary, size: 20),
              ),
              onSubmitted: (_) => _invite(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!,
                  style: GoogleFonts.notoSansThai(
                      fontSize: 13, color: AppColors.red)),
            ],
            if (_success != null) ...[
              const SizedBox(height: 10),
              Text(_success!,
                  style: GoogleFonts.notoSansThai(
                      fontSize: 13, color: AppColors.emerald)),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : _invite,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text('ส่งคำเชิญ',
                      style: GoogleFonts.notoSansThai(
                          fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bills Tab ──────────────────────────────────────────────────
class _BillsTab extends StatelessWidget {
  final Group group;
  final GroupsProvider provider;
  const _BillsTab({required this.group, required this.provider});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bills = provider.currentGroupBills;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GestureDetector(
          onTap: () => _showCreateBillSheet(context),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_rounded,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'สร้างบิลใหม่',
                  style: GoogleFonts.notoSansThai(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (bills.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Column(
                children: [
                  const Text('🧾', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 12),
                  Text(
                    'ยังไม่มีบิลในกลุ่มนี้',
                    style: GoogleFonts.notoSansThai(
                      fontSize: 14,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...bills.map((bill) => _GroupBillTile(
                bill: bill,
                onTap: () => context.push('/bill/${bill.id}'),
                onDelete: () async {
                  final err = await provider.deleteGroupBill(bill.id);
                  if (err != null && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content:
                          Text(err, style: GoogleFonts.notoSansThai()),
                      backgroundColor: AppColors.red,
                      behavior: SnackBarBehavior.floating,
                    ));
                  }
                },
              )),
      ],
    );
  }

  void _showCreateBillSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CreateGroupBillSheet(
        onSave: (title, emoji) async {
          final bill = await provider.createGroupBill(
            groupId: group.id,
            title: title,
            emoji: emoji,
          );
          if (bill != null && ctx.mounted) {
            Navigator.pop(ctx);
            context.push('/bills/${bill.id}');
          }
        },
      ),
    );
  }
}

class _GroupBillTile extends StatelessWidget {
  final Bill bill;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _GroupBillTile({
    required this.bill,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total =
        bill.items.fold(0.0, (s, i) => s + i.price);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  bill.emoji ?? '🧾',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bill.title,
                    style: GoogleFonts.notoSansThai(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  Text(
                    '${formatNumber(total)} ${bill.settings.currency}',
                    style: GoogleFonts.notoSansThai(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: bill.isCompleted
                    ? AppColors.emerald.withOpacity(0.1)
                    : AppColors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                bill.isCompleted ? 'ปิดแล้ว' : 'กำลังดำเนิน',
                style: GoogleFonts.notoSansThai(
                  fontSize: 11,
                  color: bill.isCompleted
                      ? AppColors.emerald
                      : AppColors.amber,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.red, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateGroupBillSheet extends StatefulWidget {
  final Future<void> Function(String title, String? emoji) onSave;
  const _CreateGroupBillSheet({required this.onSave});

  @override
  State<_CreateGroupBillSheet> createState() => _CreateGroupBillSheetState();
}

class _CreateGroupBillSheetState extends State<_CreateGroupBillSheet> {
  final _ctrl = TextEditingController();
  String? _emoji;
  bool _loading = false;

  final List<String> _emojis = [
    '🧾', '🍕', '🍜', '🍣', '☕', '🍺', '🛒', '🎉',
    '✈️', '🏨', '🎮', '🎵', '💊', '⛽', '🎁', '🏋️',
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'สร้างบิลใหม่',
              style: GoogleFonts.notoSansThai(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _emojis.map((e) {
                final selected = _emoji == e;
                return GestureDetector(
                  onTap: () => setState(() => _emoji = e),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary.withOpacity(0.15)
                          : (isDark
                              ? AppColors.bgDark
                              : const Color(0xFFF9FAFB)),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : (isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight),
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(e, style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ctrl,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'ชื่อบิล'),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : _save,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text('สร้างบิล',
                      style: GoogleFonts.notoSansThai(
                          fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final title = _ctrl.text.trim();
    if (title.isEmpty) return;
    setState(() => _loading = true);
    await widget.onSave(title, _emoji);
    if (mounted) setState(() => _loading = false);
  }
}

// ── Summary Tab ────────────────────────────────────────────────
class _SummaryTab extends StatelessWidget {
  final Group group;
  final GroupsProvider provider;
  const _SummaryTab({required this.group, required this.provider});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final debts = provider.computeGroupSummary();

    // Build member lookup from group members
    final memberMap = <String, GroupMember>{};
    for (final m in group.members) {
      memberMap[m.userId] = m;
    }

    if (debts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('✅', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              'ไม่มีหนี้ค้างชำระ',
              style: GoogleFonts.notoSansThai(
                fontSize: 15,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'สรุปหนี้ในกลุ่ม',
          style: GoogleFonts.notoSansThai(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'การชำระเงินที่เหมาะสมที่สุด',
          style: GoogleFonts.notoSansThai(
            fontSize: 12,
            color: isDark
                ? AppColors.textTertiaryDark
                : AppColors.textTertiaryLight,
          ),
        ),
        const SizedBox(height: 16),
        ...debts.map((debt) {
          final from = memberMap[debt.fromId];
          final to = memberMap[debt.toId];
          final fromName = from?.profile?.displayName ??
              from?.profile?.username ??
              debt.fromId.substring(0, 6);
          final toName = to?.profile?.displayName ??
              to?.profile?.username ??
              debt.toId.substring(0, 6);

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color:
                      isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            child: Row(
              children: [
                MemberAvatar(
                  name: fromName,
                  color: AppColors.red,
                  size: 36,
                  avatarUrl: from?.profile?.avatarUrl,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fromName,
                        style: GoogleFonts.notoSansThai(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                      Text(
                        'จ่ายให้ $toName',
                        style: GoogleFonts.notoSansThai(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textTertiaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${formatNumber(debt.amount)} ฿',
                  style: GoogleFonts.notoSansThai(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.red,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded,
                    color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                MemberAvatar(
                  name: toName,
                  color: AppColors.emerald,
                  size: 36,
                  avatarUrl: to?.profile?.avatarUrl,
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ── Analytics Tab ──────────────────────────────────────────────
class _AnalyticsTab extends StatelessWidget {
  final Group group;
  final GroupsProvider provider;
  const _AnalyticsTab({required this.group, required this.provider});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bills = provider.currentGroupBills;

    // Compute spend per member
    final Map<String, double> memberSpend = {};
    double totalSpend = 0;

    for (final bill in bills) {
      for (final item in bill.items) {
        final totalShares =
            item.shares.values.fold(0.0, (s, v) => s + v);
        if (totalShares == 0) continue;
        for (final entry in item.shares.entries) {
          final share = entry.value / totalShares * item.price;
          memberSpend[entry.key] =
              (memberSpend[entry.key] ?? 0) + share;
          totalSpend += share;
        }
      }
    }

    // Top items
    final Map<String, double> itemTotals = {};
    for (final bill in bills) {
      for (final item in bill.items) {
        itemTotals[item.name] =
            (itemTotals[item.name] ?? 0) + item.price;
      }
    }
    final topItems = itemTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final memberMap = <String, GroupMember>{};
    for (final m in group.members) {
      memberMap[m.userId] = m;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Stats cards
        Row(
          children: [
            Expanded(
              child: _StatCard(
                emoji: '🧾',
                label: 'บิลทั้งหมด',
                value: '${bills.length}',
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                emoji: '💰',
                label: 'ยอดรวม',
                value: '${formatNumber(totalSpend)} ฿',
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                emoji: '👥',
                label: 'สมาชิก',
                value: '${group.members.length}',
                isDark: isDark,
              ),
            ),
            Expanded(child: Container()),
          ],
        ),
        const SizedBox(height: 20),

        // Spend per member
        if (memberSpend.isNotEmpty) ...[
          Text(
            'ยอดใช้จ่ายต่อสมาชิก',
            style: GoogleFonts.notoSansThai(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          ...memberSpend.entries.map((entry) {
            final member = memberMap[entry.key];
            final name = member?.profile?.displayName ??
                member?.profile?.username ??
                entry.key.substring(0, 6);
            final pct = totalSpend > 0 ? entry.value / totalSpend : 0.0;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      MemberAvatar(
                        name: name,
                        color: AppColors.primary,
                        size: 32,
                        avatarUrl: member?.profile?.avatarUrl,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          name,
                          style: GoogleFonts.notoSansThai(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                      ),
                      Text(
                        '${formatNumber(entry.value)} ฿',
                        style: GoogleFonts.notoSansThai(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct.toDouble(),
                      backgroundColor: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primary),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 20),
        ],

        // Top items
        if (topItems.isNotEmpty) ...[
          Text(
            'รายการยอดนิยม',
            style: GoogleFonts.notoSansThai(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          ...topItems.take(5).map((entry) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.key,
                        style: GoogleFonts.notoSansThai(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                    ),
                    Text(
                      '${formatNumber(entry.value)} ฿',
                      style: GoogleFonts.notoSansThai(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final bool isDark;

  const _StatCard({
    required this.emoji,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.notoSansThai(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.notoSansThai(
              fontSize: 12,
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
