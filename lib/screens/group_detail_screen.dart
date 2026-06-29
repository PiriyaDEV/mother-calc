import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../providers/bill_provider.dart';
import '../providers/groups_provider.dart';
import '../theme/app_theme.dart';
import '../utils/bill_utils.dart';
import '../widgets/bill_status_pill.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/create_entity_sheet.dart';
import '../widgets/member_avatar.dart';
import '../widgets/summary_tab.dart';

// ── Lightweight BillProvider wrapper for SummaryTab ───────────
class _BillProviderWrapper extends BillProvider {
  final List<BillMember> _m;
  final List<BillItem> _i;

  _BillProviderWrapper({required List<BillMember> members, required List<BillItem> items})
      : _m = members,
        _i = items;

  @override
  List<BillMember> get members => _m;

  @override
  List<BillItem> get items => _i;
}

// ─────────────────────────────────────────────────────────────
class GroupDetailScreen extends StatefulWidget {
  final String groupId;
  const GroupDetailScreen({super.key, required this.groupId});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  String _tab = 'bills'; // default = bills (ตรงกับ Next.js)
  String? _expandedBillId; // for group summary collapsible

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GroupsProvider>().loadGroupDetail(widget.groupId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gp = context.watch<GroupsProvider>();
    final group = gp.currentGroup;
    final bills = gp.currentGroupBills;

    if (gp.detailLoading) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
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
          child: Text('ไม่พบกลุ่ม', style: GoogleFonts.notoSansThai(fontSize: 16)),
        ),
      );
    }

    final acceptedMembers = group.members.where((m) => m.isAccepted).toList();
    final pendingMembers = group.members.where((m) => m.isPending).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            pinned: true,
            expandedHeight: 0,
            backgroundColor: isDark
                ? AppColors.bgDark.withValues(alpha: 0.95)
                : Colors.white.withValues(alpha: 0.95),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded),
              onPressed: () => context.pop(),
            ),
            title: Row(
              children: [
                Text(group.emoji ?? '👥', style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        group.name,
                        style: GoogleFonts.notoSansThai(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (group.description != null &&
                          group.description!.isNotEmpty)
                        Text(
                          group.description!,
                          style: GoogleFonts.notoSansThai(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.textTertiaryDark
                                : const Color(0xFF9CA3AF),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => _showEditGroup(context, group, gp),
              ),
              const SizedBox(width: 4),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: _GroupTabBar(
                currentTab: _tab,
                isDark: isDark,
                acceptedCount: acceptedMembers.length,
                billsCount: bills.length,
                onTabChanged: (t) => setState(() => _tab = t),
              ),
            ),
          ),
        ],
        body: _buildTabBody(context, group, bills, acceptedMembers, pendingMembers, isDark, gp),
      ),
    );
  }

  Widget _buildTabBody(
    BuildContext context,
    Group group,
    List<Bill> bills,
    List<GroupMember> acceptedMembers,
    List<GroupMember> pendingMembers,
    bool isDark,
    GroupsProvider gp,
  ) {
    switch (_tab) {
      case 'members':
        return _MembersTab(
          group: group,
          acceptedMembers: acceptedMembers,
          pendingMembers: pendingMembers,
          isDark: isDark,
        );
      case 'bills':
        return _BillsTab(
          group: group,
          bills: bills,
          isDark: isDark,
          gp: gp,
        );
      case 'summary':
        return _GroupSummaryTab(
          bills: bills,
          isDark: isDark,
          expandedBillId: _expandedBillId,
          onToggle: (id) => setState(() {
            _expandedBillId = _expandedBillId == id ? null : id;
          }),
        );
      case 'analytics':
        return _GroupAnalyticsTab(bills: bills, isDark: isDark);
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Edit Group Sheet ─────────────────────────────────────────
  Future<void> _showEditGroup(
      BuildContext context, Group group, GroupsProvider gp) async {
    final result = await showCreateEntitySheet(
      context,
      type: 'group',
      mode: 'edit',
      initialData: EntityFormResult(
        name: group.name,
        emoji: group.emoji,
        description: group.description ?? '',
        tags: group.tags,
      ),
      onDelete: () async {
        // Will be handled after sheet closes
      },
    );

    if (!mounted) return;

    if (result != null) {
      // Check if this was a delete action (result name == '__delete__')
      await gp.updateGroup(
        groupId: group.id,
        name: result.name,
        emoji: result.emoji,
      );
      // Also update description/tags via supabase directly
      try {
        await Supabase.instance.client.from('groups').update({
          'description': result.description,
          'tags': result.tags,
        }).eq('id', group.id);
        if (mounted) {
          await gp.loadGroupDetail(group.id);
        }
      } catch (_) {}
    }
  }

}

// ── Tab Bar ───────────────────────────────────────────────────
class _GroupTabBar extends StatelessWidget {
  final String currentTab;
  final bool isDark;
  final int acceptedCount;
  final int billsCount;
  final ValueChanged<String> onTabChanged;

  const _GroupTabBar({
    required this.currentTab,
    required this.isDark,
    required this.acceptedCount,
    required this.billsCount,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _TabDef(id: 'members', label: 'สมาชิก', count: acceptedCount),
      _TabDef(id: 'bills', label: 'บิล', count: billsCount),
      const _TabDef(id: 'summary', label: 'สรุป', count: null),
      const _TabDef(id: 'analytics', label: 'วิเคราะห์', count: null),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: tabs.map((tab) {
          final isActive = currentTab == tab.id;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTabChanged(tab.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isActive
                      ? (isDark ? const Color(0xFF374151) : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          )
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tab.label,
                      style: GoogleFonts.notoSansThai(
                        fontSize: 12,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.normal,
                        color: isActive
                            ? AppColors.primary
                            : (isDark
                                ? AppColors.textTertiaryDark
                                : const Color(0xFF6B7280)),
                      ),
                    ),
                    if (tab.count != null) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : (isDark
                                  ? const Color(0xFF374151)
                                  : const Color(0xFFE5E7EB)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${tab.count}',
                          style: GoogleFonts.notoSansThai(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isActive
                                ? AppColors.primary
                                : (isDark
                                    ? AppColors.textTertiaryDark
                                    : const Color(0xFF6B7280)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TabDef {
  final String id;
  final String label;
  final int? count;
  const _TabDef({required this.id, required this.label, this.count});
}

// ── Members Tab ───────────────────────────────────────────────
class _MembersTab extends StatelessWidget {
  final Group group;
  final List<GroupMember> acceptedMembers;
  final List<GroupMember> pendingMembers;
  final bool isDark;

  const _MembersTab({
    required this.group,
    required this.acceptedMembers,
    required this.pendingMembers,
    required this.isDark,
  });

  void _showManageMembersSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ManageMembersSheet(
        group: group,
        acceptedMembers: acceptedMembers,
        isDark: isDark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── จัดการสมาชิก button ──
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showManageMembersSheet(context),
            icon: const Icon(Icons.people_outline, size: 18),
            label: Text(
              'จัดการสมาชิก',
              style: GoogleFonts.notoSansThai(
                  fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ── Pending Invites Banner ──
        if (pendingMembers.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'รอตอบรับ ${pendingMembers.length} คน',
                  style: GoogleFonts.notoSansThai(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFD97706),
                  ),
                ),
                const SizedBox(height: 8),
                ...pendingMembers.map((m) {
                  final name = m.profile?.displayName ??
                      m.profile?.username ??
                      'ผู้ใช้';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFDE68A),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              name.isNotEmpty
                                  ? name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFB45309),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          name,
                          style: GoogleFonts.notoSansThai(
                            fontSize: 13,
                            color: const Color(0xFFD97706),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // ── Accepted Members List ──
        if (acceptedMembers.isEmpty)
          _EmptyState(
            icon: Icons.people_outline,
            label: 'ยังไม่มีสมาชิก',
            isDark: isDark,
          )
        else
          ...acceptedMembers.map((m) {
            final name = m.profile?.displayName ??
                m.profile?.username ??
                'ผู้ใช้';
            final username = m.profile?.username;
            final avatarUrl = m.profile?.avatarUrl;
            final isOwner = m.role == 'owner';

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
              child: Row(
                children: [
                  // Avatar
                  MemberAvatar(
                    name: name,
                    color: AppColors.primary,
                    size: 36,
                    avatarUrl: avatarUrl,
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
                  // Role badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isOwner
                          ? const Color(0xFFFAF5FF)
                          : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isOwner ? 'เจ้าของ' : 'สมาชิก',
                      style: GoogleFonts.notoSansThai(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isOwner
                            ? const Color(0xFFA855F7)
                            : const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}

// ── Bills Tab ─────────────────────────────────────────────────
class _BillsTab extends StatelessWidget {
  final Group group;
  final List<Bill> bills;
  final bool isDark;
  final GroupsProvider gp;

  const _BillsTab({
    required this.group,
    required this.bills,
    required this.isDark,
    required this.gp,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── สร้างบิลใหม่ button ──
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _createBill(context),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(
              'สร้างบิลใหม่',
              style: GoogleFonts.notoSansThai(
                  fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ── Empty State ──
        if (bills.isEmpty)
          GestureDetector(
            onTap: () => _createBill(context),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? AppColors.borderDark
                      : const Color(0xFFE5E7EB),
                  style: BorderStyle.solid,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.receipt_outlined,
                        color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'สร้างบิลแรกของกลุ่ม',
                          style: GoogleFonts.notoSansThai(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                        Text(
                          'แตะเพื่อเริ่มหารค่าใช้จ่าย',
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
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    child: const Icon(Icons.add_rounded,
                        color: Colors.white, size: 18),
                  ),
                ],
              ),
            ),
          )
        else
          ...bills.map((bill) => _BillRow(
                bill: bill,
                isDark: isDark,
                gp: gp,
                groupId: group.id,
              )),
      ],
    );
  }

  Future<void> _createBill(BuildContext context) async {
    final result = await showCreateEntitySheet(
      context,
      type: 'bill',
      mode: 'create',
    );
    if (result == null) return;
    final newBill = await gp.createGroupBill(
      groupId: group.id,
      title: result.name,
      emoji: result.emoji,
      tags: result.tags,
    );
    if (newBill != null && context.mounted) {
      context.push('/bills/${newBill.id}');
    }
  }
}

class _BillRow extends StatelessWidget {
  final Bill bill;
  final bool isDark;
  final GroupsProvider gp;
  final String groupId;

  const _BillRow({
    required this.bill,
    required this.isDark,
    required this.gp,
    required this.groupId,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = bill.updatedAt != null
        ? DateFormat('d MMM yyyy', 'th').format(bill.updatedAt!)
        : '';
    final visibleTags = bill.tags.take(2).toList();
    final extraTags = bill.tags.length > 2 ? bill.tags.length - 2 : 0;

    // Compute total from bill items
    final calc = calculateBill(bill);
    final totalStr = calc.total > 0
        ? formatNumber(calc.total)
        : null;
    final memberCount = bill.members.length;

    return GestureDetector(
      onTap: () async {
        await context.push('/bills/${bill.id}');
        // Refresh group bills after returning from bill detail
        if (context.mounted) {
          gp.loadGroupDetail(groupId);
        }
      },
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
            // Emoji / icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF374151)
                    : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  bill.emoji ?? '🧾',
                  style: const TextStyle(fontSize: 20),
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
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      BillStatusPill(status: bill.status),
                      if (dateStr.isNotEmpty)
                        Text(
                          dateStr,
                          style: GoogleFonts.notoSansThai(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiaryLight,
                          ),
                        ),
                      // Member count badge
                      if (memberCount > 0)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.people_outline_rounded,
                              size: 11,
                              color: isDark
                                  ? AppColors.textTertiaryDark
                                  : AppColors.textTertiaryLight,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '$memberCount คน',
                              style: GoogleFonts.notoSansThai(
                                fontSize: 11,
                                color: isDark
                                    ? AppColors.textTertiaryDark
                                    : AppColors.textTertiaryLight,
                              ),
                            ),
                          ],
                        ),
                      ...visibleTags.map((tag) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF374151)
                                  : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '#$tag',
                              style: GoogleFonts.notoSansThai(
                                fontSize: 10,
                                color: isDark
                                    ? AppColors.textTertiaryDark
                                    : AppColors.textTertiaryLight,
                              ),
                            ),
                          )),
                      if (extraTags > 0)
                        Text(
                          '+$extraTags',
                          style: GoogleFonts.notoSansThai(
                            fontSize: 10,
                            color: isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiaryLight,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // Right side: total + actions
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (totalStr != null)
                  Text(
                    '฿$totalStr',
                    style: GoogleFonts.notoSansThai(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Edit
                    GestureDetector(
                      onTap: () => _editBill(context),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          Icons.settings_outlined,
                          size: 18,
                          color: isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textTertiaryLight,
                        ),
                      ),
                    ),
                    // Delete
                    GestureDetector(
                      onTap: () => _deleteBill(context),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(Icons.delete_outline_rounded,
                            size: 18, color: AppColors.red),
                      ),
                    ),
                    // Navigate
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editBill(BuildContext context) async {
    final result = await showCreateEntitySheet(
      context,
      type: 'bill',
      mode: 'edit',
      initialData: EntityFormResult(
        name: bill.title,
        emoji: bill.emoji,
        tags: bill.tags,
        settings: bill.settings,
      ),
    );
    if (result == null) return;
    try {
      await Supabase.instance.client.from('bills').update({
        'title': result.name,
        'emoji': result.emoji,
        'tags': result.tags,
      }).eq('id', bill.id);
      await gp.loadGroupDetail(groupId);
    } catch (_) {}
  }

  Future<void> _deleteBill(BuildContext context) async {
    final ok = await showConfirmDialog(
      context,
      title: 'ลบบิล "${bill.title}"?',
      description: 'การกระทำนี้ไม่สามารถย้อนกลับได้',
      confirmLabel: 'ลบบิล',
      danger: true,
    );
    if (ok == true) {
      await gp.deleteGroupBill(bill.id);
    }
  }
}

// ── Group Summary Tab ─────────────────────────────────────────
class _GroupSummaryTab extends StatelessWidget {
  final List<Bill> bills;
  final bool isDark;
  final String? expandedBillId;
  final ValueChanged<String> onToggle;

  const _GroupSummaryTab({
    required this.bills,
    required this.isDark,
    required this.expandedBillId,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (bills.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _EmptyState(
              icon: Icons.bar_chart_rounded,
              label: 'ยังไม่มีบิลในกลุ่ม',
              sub: 'สร้างบิลก่อนเพื่อดูสรุป',
              isDark: isDark,
            ),
          ],
        ),
      );
    }

    // totalAmount = sum of all item prices across all bills
    final totalAmount = bills.fold<double>(
      0,
      (sum, b) => sum + b.items.fold<double>(0, (s, i) => s + i.price),
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Hero Card ──
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4366f4), Color(0xFF6b8aff)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ยอดรวมทั้งกลุ่ม',
                style: GoogleFonts.notoSansThai(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${formatNumber(totalAmount)} บาท',
                style: GoogleFonts.notoSansThai(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${bills.length} บิล',
                style: GoogleFonts.notoSansThai(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Per-Bill Collapsible ──
        ...bills.map((bill) {
          final billTotal =
              bill.items.fold<double>(0, (s, i) => s + i.price);
          final isExpanded = expandedBillId == bill.id;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isDark
                      ? AppColors.borderDark
                      : AppColors.borderLight),
            ),
            child: Column(
              children: [
                // Row header
                GestureDetector(
                  onTap: () => onToggle(bill.id),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF374151)
                                : const Color(0xFFF3F4F6),
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
                                '${bill.items.length} รายการ · ${bill.members.length} คน',
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
                          '${formatNumber(billTotal)} บาท',
                          style: GoogleFonts.notoSansThai(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 20,
                          color: isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textTertiaryLight,
                        ),
                      ],
                    ),
                  ),
                ),
                // Expanded: SummaryTab
                if (isExpanded) ...[
                  Divider(
                    height: 1,
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                  ),
                  ChangeNotifierProvider<BillProvider>(
                    create: (_) => _BillProviderWrapper(
                      members: bill.members,
                      items: bill.items,
                    ),
                    child: Builder(
                      builder: (ctx) {
                        final bp = ctx.watch<BillProvider>();
                        final calc = calculateBill(bill.copyWith(
                          members: bp.members,
                          items: bp.items,
                        ));
                        return SizedBox(
                          height: 500,
                          child: SummaryTab(
                            bill: bill,
                            billProvider: bp,
                            calc: calc,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ── Group Analytics Tab ───────────────────────────────────────
class _GroupAnalyticsTab extends StatelessWidget {
  final List<Bill> bills;
  final bool isDark;

  const _GroupAnalyticsTab({required this.bills, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final allItems =
        bills.expand((b) => b.items).toList();

    if (allItems.isEmpty) {
      return Center(
        child: _EmptyState(
          icon: Icons.analytics_outlined,
          label: 'ยังไม่มีข้อมูลวิเคราะห์',
          sub: 'สร้างบิลและเพิ่มรายการก่อน',
          isDark: isDark,
        ),
      );
    }

    final totalAmount =
        allItems.fold<double>(0, (s, i) => s + i.price);
    final avgPerBill =
        bills.isNotEmpty ? totalAmount / bills.length : 0.0;

    // Top items sorted by price desc
    final sortedItems = List<BillItem>.from(allItems)
      ..sort((a, b) => b.price.compareTo(a.price));
    final topItems = sortedItems.take(5).toList();

    // Recent bills sorted by updatedAt desc
    final recentBills = List<Bill>.from(bills)
      ..sort((a, b) {
        final at = a.updatedAt ?? DateTime(2000);
        final bt = b.updatedAt ?? DateTime(2000);
        return bt.compareTo(at);
      });
    final recentTop = recentBills.take(5).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Stats Row ──
        Row(
          children: [
            Expanded(
              child: _AnalyticsStatCard(
                label: 'บิลทั้งหมด',
                value: '${bills.length}',
                sub: 'บิล',
                valueColor: const Color(0xFF4366f4),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _AnalyticsStatCard(
                label: 'รายการทั้งหมด',
                value: '${allItems.length}',
                sub: 'รายการ',
                valueColor: const Color(0xFFA855F7),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _AnalyticsStatCard(
                label: 'เฉลี่ย/บิล',
                value: formatNumber(avgPerBill),
                sub: 'บาท',
                valueColor: const Color(0xFF10B981),
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Top Items ──
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'รายการราคาสูงสุด',
                style: GoogleFonts.notoSansThai(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 12),
              ...topItems.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                final pct =
                    totalAmount > 0 ? item.price / totalAmount : 0.0;
                final isLast = idx == topItems.length - 1;

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 20,
                            child: Text(
                              '${idx + 1}',
                              style: GoogleFonts.notoSansThai(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppColors.textTertiaryDark
                                    : const Color(0xFF9CA3AF),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.name,
                                        style: GoogleFonts.notoSansThai(
                                          fontSize: 13,
                                          color: isDark
                                              ? AppColors.textPrimaryDark
                                              : AppColors.textPrimaryLight,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      '${formatNumber(item.price)} บาท',
                                      style: GoogleFonts.notoSansThai(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? AppColors.textPrimaryDark
                                            : AppColors.textPrimaryLight,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: LinearProgressIndicator(
                                    value: pct.clamp(0.0, 1.0),
                                    backgroundColor: isDark
                                        ? const Color(0xFF374151)
                                        : const Color(0xFFE5E7EB),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                            Color(0xFF4366f4)),
                                    minHeight: 6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Divider(
                        height: 1,
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                      ),
                  ],
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Recent Bills ──
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'บิลล่าสุด',
                style: GoogleFonts.notoSansThai(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 12),
              ...recentTop.map((bill) {
                final billTotal =
                    bill.items.fold<double>(0, (s, i) => s + i.price);
                final pct =
                    totalAmount > 0 ? billTotal / totalAmount : 0.0;
                final dateStr = bill.updatedAt != null
                    ? DateFormat('d MMM yyyy', 'th')
                        .format(bill.updatedAt!)
                    : '';
                final pctStr =
                    '${(pct * 100).toStringAsFixed(1)}% ของทั้งหมด';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              bill.title,
                              style: GoogleFonts.notoSansThai(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${formatNumber(billTotal)} บาท',
                            style: GoogleFonts.notoSansThai(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF374151)
                                : const Color(0xFFE5E7EB),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: pct.clamp(0.0, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF4366f4),
                                    Color(0xFF6b8aff)
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$dateStr · $pctStr',
                        style: GoogleFonts.notoSansThai(
                          fontSize: 10,
                          color: isDark
                              ? AppColors.textTertiaryDark
                              : const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Analytics Stat Card ───────────────────────────────────────
class _AnalyticsStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color valueColor;
  final bool isDark;

  const _AnalyticsStatCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.valueColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.notoSansThai(
              fontSize: 10,
              color: isDark
                  ? AppColors.textTertiaryDark
                  : const Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.notoSansThai(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
          Text(
            sub,
            style: GoogleFonts.notoSansThai(
              fontSize: 10,
              color: isDark
                  ? AppColors.textTertiaryDark
                  : const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Manage Members Sheet ──────────────────────────────────────
class _ManageMembersSheet extends StatefulWidget {
  final Group group;
  final List<GroupMember> acceptedMembers;
  final bool isDark;

  const _ManageMembersSheet({
    required this.group,
    required this.acceptedMembers,
    required this.isDark,
  });

  @override
  State<_ManageMembersSheet> createState() => _ManageMembersSheetState();
}

class _ManageMembersSheetState extends State<_ManageMembersSheet> {
  final _usernameCtrl = TextEditingController();
  bool _inviting = false;
  String? _inviteError;
  String? _inviteSuccess;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    super.dispose();
  }

  Future<void> _invite() async {
    final username = _usernameCtrl.text.trim();
    if (username.isEmpty) return;
    setState(() {
      _inviting = true;
      _inviteError = null;
      _inviteSuccess = null;
    });
    final gp = context.read<GroupsProvider>();
    final err = await gp.inviteMember(widget.group.id, username);
    if (!mounted) return;
    setState(() {
      _inviting = false;
      if (err != null) {
        _inviteError = err;
      } else {
        _inviteSuccess = 'ส่งคำเชิญให้ @$username แล้ว';
        _usernameCtrl.clear();
      }
    });
  }

  Future<void> _remove(GroupMember member) async {
    final name = member.profile?.displayName ??
        member.profile?.username ??
        'สมาชิก';
    final ok = await showConfirmDialog(
      context,
      title: 'นำ $name ออกจากกลุ่ม?',
      description: 'สมาชิกจะถูกลบออกจากกลุ่มนี้',
      confirmLabel: 'นำออก',
      danger: true,
    );
    if (ok != true || !mounted) return;
    final gp = context.read<GroupsProvider>();
    await gp.removeMember(widget.group.id, member.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final currentUserId =
        Supabase.instance.client.auth.currentUser?.id;

    return Container(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
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
              'จัดการสมาชิก',
              style: GoogleFonts.notoSansThai(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 20),

            // ── Invite section ──
            Text(
              'เชิญสมาชิกใหม่',
              style: GoogleFonts.notoSansThai(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _usernameCtrl,
                    decoration: InputDecoration(
                      hintText: 'username (ไม่ต้องใส่ @)',
                      hintStyle: GoogleFonts.notoSansThai(fontSize: 13),
                      prefixText: '@',
                    ),
                    onSubmitted: (_) => _invite(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _inviting ? null : _invite,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                  child: _inviting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          'เชิญ',
                          style: GoogleFonts.notoSansThai(
                              fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                ),
              ],
            ),
            if (_inviteError != null) ...[
              const SizedBox(height: 6),
              Text(
                _inviteError!,
                style: GoogleFonts.notoSansThai(
                    fontSize: 12, color: AppColors.red),
              ),
            ],
            if (_inviteSuccess != null) ...[
              const SizedBox(height: 6),
              Text(
                _inviteSuccess!,
                style: GoogleFonts.notoSansThai(
                    fontSize: 12, color: AppColors.emerald),
              ),
            ],
            const SizedBox(height: 20),

            // ── Current members ──
            Text(
              'สมาชิกปัจจุบัน (${widget.acceptedMembers.length} คน)',
              style: GoogleFonts.notoSansThai(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 8),
            ...widget.acceptedMembers.map((m) {
              final name = m.profile?.displayName ??
                  m.profile?.username ??
                  'ผู้ใช้';
              final username = m.profile?.username;
              final avatarUrl = m.profile?.avatarUrl;
              final isOwner = m.role == 'owner';
              final isMe = m.userId == currentUserId;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1F2937)
                      : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                  ),
                ),
                child: Row(
                  children: [
                    MemberAvatar(
                      name: name,
                      color: AppColors.primary,
                      size: 32,
                      avatarUrl: avatarUrl,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                name,
                                style: GoogleFonts.notoSansThai(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimaryLight,
                                ),
                              ),
                              if (isMe) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    'คุณ',
                                    style: GoogleFonts.notoSansThai(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (username != null)
                            Text(
                              '@$username',
                              style: GoogleFonts.notoSansThai(
                                fontSize: 11,
                                color: isDark
                                    ? AppColors.textTertiaryDark
                                    : AppColors.textTertiaryLight,
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Role badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: isOwner
                            ? const Color(0xFFFAF5FF)
                            : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isOwner ? 'เจ้าของ' : 'สมาชิก',
                        style: GoogleFonts.notoSansThai(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isOwner
                              ? const Color(0xFFA855F7)
                              : const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                    // Remove button (not for owner, not for self)
                    if (!isOwner && !isMe) ...[
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => _remove(m),
                        child: const Icon(
                          Icons.person_remove_outlined,
                          size: 18,
                          color: AppColors.red,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? sub;
  final bool isDark;

  const _EmptyState({
    required this.icon,
    required this.label,
    this.sub,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF374151)
                : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            size: 24,
            color: isDark
                ? AppColors.textTertiaryDark
                : AppColors.textTertiaryLight,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: GoogleFonts.notoSansThai(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        if (sub != null) ...[
          const SizedBox(height: 4),
          Text(
            sub!,
            style: GoogleFonts.notoSansThai(
              fontSize: 12,
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiaryLight,
            ),
          ),
        ],
      ],
    );
  }
}
