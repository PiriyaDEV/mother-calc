import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../providers/bill_provider.dart';
import '../providers/bills_list_provider.dart';
import '../providers/friends_provider.dart';
import '../providers/groups_provider.dart';
import '../theme/app_theme.dart';
import '../utils/bill_utils.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/create_entity_sheet.dart';
import '../widgets/member_avatar.dart';
import '../widgets/analytics_tab.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/summary_tab.dart';

class BillDetailScreen extends StatefulWidget {
  final String billId;
  const BillDetailScreen({super.key, required this.billId});

  @override
  State<BillDetailScreen> createState() => _BillDetailScreenState();
}

class _BillDetailScreenState extends State<BillDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final bp = context.read<BillProvider>();
      // Listen for bill changes and sync BillsListProvider
      bp.addListener(_syncBillsListProvider);
      await bp.loadBill(widget.billId);
      // Auto-add current user as first member if bill is new (no members yet)
      if (bp.members.isEmpty && bp.bill != null && bp.bill!.isDraft) {
        await bp.autoAddCurrentUser();
      }
      // Load group detail if this bill belongs to a group (ensures member picker works)
      if (!mounted) return;
      final groupId = bp.bill?.groupId;
      if (groupId != null) {
        final gp = context.read<GroupsProvider>();
        if (gp.currentGroup?.id != groupId) {
          await gp.loadGroupDetail(groupId);
        }
      }
    });
  }

  void _syncBillsListProvider() {
    if (!mounted) return;
    final bp = context.read<BillProvider>();
    final bill = bp.bill;
    if (bill != null) {
      context.read<BillsListProvider>().updateBill(bill);
    }
  }

  @override
  void dispose() {
    // Remove the sync listener to avoid memory leaks
    context.read<BillProvider>().removeListener(_syncBillsListProvider);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final billProvider = context.watch<BillProvider>();
    final bill = billProvider.bill;

    if (billProvider.loading) {
      return Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppGradients.backgroundDark : AppGradients.backgroundLight,
        ),
        child: const Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
          ),
        ),
      );
    }

    if (bill == null) {
      return Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppGradients.backgroundDark : AppGradients.backgroundLight,
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded),
              onPressed: () => context.pop(),
            ),
          ),
          body: Center(
            child: Text(
              'ไม่พบบิล',
              style: GoogleFonts.notoSansThai(fontSize: 16),
            ),
          ),
        ),
      );
    }

    final calc = calculateBill(bill.copyWith(
      members: billProvider.members,
      items: billProvider.items,
    ));

    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isOwner = bill.ownerId == currentUserId;
    final isCompleted = bill.isCompleted;
    final isPendingPayment = bill.isPendingPayment;
    final isDraft = bill.isDraft;
    final members = billProvider.members;
    final items = billProvider.items;

    return Container(
      decoration: BoxDecoration(
        gradient: isDark ? AppGradients.backgroundDark : AppGradients.backgroundLight,
      ),
      child: Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Expanded(
            child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
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
                // Emoji + title
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        bill.emoji ?? '🧾',
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          bill.title,
                          style: GoogleFonts.notoSansThai(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!isDraft) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.emerald.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock_rounded,
                                  size: 11, color: AppColors.emerald),
                              const SizedBox(width: 3),
                              Text(
                                'ปิดแล้ว',
                                style: GoogleFonts.notoSansThai(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.emerald,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              // action buttons by status
              if (isDraft)
                GestureDetector(
                  onTap: () async {
                    final ok = await showConfirmDialog(
                      context,
                      title: 'ปิดบิลนี้?',
                      description:
                          'หลังจากปิดแล้ว จะไม่สามารถแก้ไขสมาชิกหรือรายการได้ แต่ยังสามารถทำเครื่องหมายว่าจ่ายแล้วได้',
                      confirmLabel: 'ปิดบิล',
                    );
                    if (ok == true) {
                      await billProvider.setPendingPayment(bill.id);
                      _tabController.animateTo(2); // switch to สรุป
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.amber,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_rounded,
                            size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          'ปิดบิล',
                          style: GoogleFonts.notoSansThai(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (isPendingPayment) ...[
                GestureDetector(
                  onTap: () async {
                    final ok = await showConfirmDialog(
                      context,
                      title: 'เปิดบิลใหม่?',
                      description: 'บิลจะกลับมาแก้ไขได้อีกครั้ง',
                      confirmLabel: 'เปิดใหม่',
                    );
                    if (ok == true) {
                      await billProvider.reopenBill(bill.id);
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.borderDark : AppColors.neutral100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_open_rounded,
                            size: 14,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight),
                        const SizedBox(width: 4),
                        Text(
                          'เปิดใหม่',
                          style: GoogleFonts.notoSansThai(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () async {
                    final ok = await showConfirmDialog(
                      context,
                      title: 'ยืนยันเสร็จสิ้น?',
                      description: 'บิลจะถูกปิดสมบูรณ์ ทุกคนชำระเงินครบแล้ว',
                      confirmLabel: 'เสร็จแล้ว',
                    );
                    if (ok == true) {
                      await billProvider.completeBill(bill.id);
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.emerald,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_rounded,
                            size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          'เสร็จแล้ว',
                          style: GoogleFonts.notoSansThai(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else
                GestureDetector(
                  onTap: () async {
                    final ok = await showConfirmDialog(
                      context,
                      title: 'เปิดบิลใหม่?',
                      description: 'บิลจะกลับมาแก้ไขได้อีกครั้ง',
                      confirmLabel: 'เปิดใหม่',
                    );
                    if (ok == true) {
                      await billProvider.reopenBill(bill.id);
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.borderDark : AppColors.neutral100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_open_rounded,
                            size: 14,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight),
                        const SizedBox(width: 4),
                        Text(
                          'เปิดใหม่',
                          style: GoogleFonts.notoSansThai(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // ⚙️ gear — only owner + draft
              if (isOwner && isDraft)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _showEditBillSheet(context, bill, billProvider),
                ),
              const SizedBox(width: 4),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: _PillTabBar(
                controller: _tabController,
                isDark: isDark,
                membersCount: members.length,
                itemsCount: items.length,
              ),
            ),
          ),
        ],
        body: Column(
          children: [
            // Status banner (pending_payment or completed)
            if (!isDraft)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? (isDark ? AppColors.emeraldDark.withValues(alpha: 0.25) : AppColors.greenFaint)
                      : (isDark ? AppColors.amber.withValues(alpha: 0.15) : AppColors.amberFaint),
                  border: Border(
                    bottom: BorderSide(
                        color: isCompleted
                            ? (isDark ? AppColors.emeraldDark : AppColors.emerald.withValues(alpha: 0.3))
                            : (isDark ? AppColors.amber.withValues(alpha: 0.4) : AppColors.amber.withValues(alpha: 0.3)),
                        width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isCompleted ? Icons.lock_rounded : Icons.hourglass_top_rounded,
                      size: 14,
                      color: isCompleted
                          ? (isDark ? AppColors.emerald : AppColors.emeraldText)
                          : AppColors.amber,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isCompleted
                          ? 'บิลนี้เสร็จแล้ว — ดูได้อย่างเดียว'
                          : 'บิลนี้รอจ่าย — ดูได้อย่างเดียว ไม่สามารถแก้ไขได้',
                      style: GoogleFonts.notoSansThai(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isCompleted
                            ? (isDark ? AppColors.emerald : AppColors.emeraldText)
                            : AppColors.amber,
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _MembersTab(
                      bill: bill,
                      billProvider: billProvider,
                      calc: calc,
                      readOnly: !isDraft),
                  _ItemsTab(
                      bill: bill,
                      billProvider: billProvider,
                      calc: calc,
                      readOnly: !isDraft),
                  SummaryTab(
                      bill: bill, billProvider: billProvider, calc: calc),
                  AnalyticsTab(
                      bill: bill, billProvider: billProvider, calc: calc),
                ],
              ),
            ),
          ],
        ),
      ),
          ),
          const BannerAdWidget(),
        ],
      ),
      ),
    );
  }


  Future<void> _showEditBillSheet(
      BuildContext context, Bill bill, BillProvider billProvider) async {
    final settings = bill.settings;
    final billsListProvider = context.read<BillsListProvider>();
    final result = await showCreateEntitySheet(
      context,
      type: 'bill',
      mode: 'edit',
      initialData: EntityFormResult(
        name: bill.title,
        emoji: bill.emoji,
        description: '',
        tags: List<String>.from(bill.tags),
        settings: settings,
      ),
      onDelete: () async {
        await billProvider.deleteBill(bill.id);
        // Sync bills list screen
        billsListProvider.removeBill(bill.id);
        if (context.mounted) context.pop();
      },
    );
    if (result != null && mounted) {
      await billProvider.updateBillMeta(
        billId: bill.id,
        title: result.name,
        emoji: result.emoji,
        tags: result.tags,
        settings: result.settings,
      );
      // Sync bills list screen with updated bill
      if (billProvider.bill != null) {
        billsListProvider.updateBill(billProvider.bill!);
      }
    }
  }

}

// ── Pill Tab Bar ──────────────────────────────────────────────
class _PillTabBar extends StatelessWidget {
  final TabController controller;
  final bool isDark;
  final int membersCount;
  final int itemsCount;

  const _PillTabBar({
    required this.controller,
    required this.isDark,
    required this.membersCount,
    required this.itemsCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.neutral100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          color: isDark ? AppColors.borderDark : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        labelColor: AppColors.primary,
        unselectedLabelColor: isDark
            ? AppColors.textTertiaryDark
            : AppColors.neutral600,
        labelStyle: GoogleFonts.notoSansThai(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.notoSansThai(
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
        tabs: [
          _CountTab(label: 'สมาชิก', count: membersCount),
          _CountTab(label: 'รายการ', count: itemsCount),
          const Tab(text: 'สรุป'),
          const Tab(text: 'วิเคราะห์'),
        ],
      ),
    );
  }
}

/// A Tab that shows a label + count badge.
/// The TabBar's labelColor/unselectedLabelColor handles text color automatically.
class _CountTab extends StatelessWidget {
  final String label;
  final int count;

  const _CountTab({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: isDark ? AppColors.borderDark : AppColors.neutral100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.notoSansThai(
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Items Tab ─────────────────────────────────────────────────
class _ItemsTab extends StatelessWidget {
  final Bill bill;
  final BillProvider billProvider;
  final BillCalculation calc;
  final bool readOnly;

  const _ItemsTab({
    required this.bill,
    required this.billProvider,
    required this.calc,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = billProvider.items;
    final members = billProvider.members;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Add item button
        if (!readOnly)
          GestureDetector(
            onTap: () => _showAddItemSheet(context, bill, billProvider),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_rounded,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'เพิ่มรายการ',
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

        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Column(
                children: [
                  const Text('🍽️', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 12),
                  Text(
                    'ยังไม่มีรายการ',
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
        else ...[
          const SizedBox(height: 12),
          ...items.map((item) => _ItemTile(
                item: item,
                members: members,
                bill: bill,
                billProvider: billProvider,
                readOnly: readOnly,
              )),
        ],

        // Bill summary
        if (items.isNotEmpty) ...[
          const SizedBox(height: 16),
          _BillSummaryCard(calc: calc, currency: bill.settings.currency),
        ],
      ],
    );
  }

  void _showAddItemSheet(
      BuildContext context, Bill bill, BillProvider billProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ItemFormSheet(
        bill: bill,
        billProvider: billProvider,
        members: billProvider.members,
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  final BillItem item;
  final List<BillMember> members;
  final Bill bill;
  final BillProvider billProvider;
  final bool readOnly;

  const _ItemTile({
    required this.item,
    required this.members,
    required this.bill,
    required this.billProvider,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final assignedMembers = members
        .where((m) => item.shares.containsKey(m.id) && item.shares[m.id]! > 0)
        .toList();
    final paidByMember = item.paidBy != null
        ? members.where((m) => m.id == item.paidBy).firstOrNull
        : null;

    return GestureDetector(
      onTap: readOnly ? null : () => _showEditItemSheet(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: GoogleFonts.notoSansThai(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                ),
                // Unequal split badge
                if (item.isUnequalSplit) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.amber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'หารไม่เท่า',
                      style: GoogleFonts.notoSansThai(
                        fontSize: 10,
                        color: AppColors.amber,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  formatNumber(item.price),
                  style: GoogleFonts.notoSansThai(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                if (!readOnly) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight,
                  ),
                ],
              ],
            ),
            if (assignedMembers.isNotEmpty || paidByMember != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  // Stacked avatars
                  _StackedAvatars(members: assignedMembers),
                  const SizedBox(width: 6),
                  // "X คน · ฿Y/คน"
                  Expanded(
                    child: Text(
                      '${assignedMembers.length} คน'
                      '${!item.isUnequalSplit && assignedMembers.isNotEmpty ? ' · ฿${formatNumber(item.price / assignedMembers.length)}/คน' : ''}',
                      style: GoogleFonts.notoSansThai(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiaryLight,
                      ),
                    ),
                  ),
                  // Paid by avatar
                  if (paidByMember != null) ...[
                    Text(
                      'จ่ายโดย',
                      style: GoogleFonts.notoSansThai(
                        fontSize: 10,
                        color: isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiaryLight,
                      ),
                    ),
                    const SizedBox(width: 4),
                    MemberAvatar(
                      name: paidByMember.name,
                      color: colorFromHex(paidByMember.color),
                      size: 20,
                      avatarUrl: paidByMember.profile?.avatarUrl,
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showEditItemSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ItemFormSheet(
        bill: bill,
        billProvider: billProvider,
        members: members,
        editItem: item,
      ),
    );
  }
}

class _BillSummaryCard extends StatelessWidget {
  final BillCalculation calc;
  final String currency;

  const _BillSummaryCard({required this.calc, required this.currency});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        children: [
          _SummaryRow(
              label: 'ยอดรวมก่อนภาษี',
              value: calc.subtotal,
              currency: currency),
          if (calc.serviceAmount > 0)
            _SummaryRow(
                label: 'Service Charge',
                value: calc.serviceAmount,
                currency: currency),
          if (calc.vatAmount > 0)
            _SummaryRow(
                label: 'VAT', value: calc.vatAmount, currency: currency),
          if (calc.tipAmount > 0)
            _SummaryRow(
                label: 'ทิป', value: calc.tipAmount, currency: currency),
          if (calc.discountAmount > 0)
            _SummaryRow(
                label: 'ส่วนลด',
                value: -calc.discountAmount,
                currency: currency,
                isDiscount: true),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ยอดรวมทั้งหมด',
                style: GoogleFonts.notoSansThai(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              Text(
                '${formatNumber(calc.total)} $currency',
                style: GoogleFonts.notoSansThai(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double value;
  final String currency;
  final bool isDiscount;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.currency,
    this.isDiscount = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.notoSansThai(
              fontSize: 13,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          Text(
            '${isDiscount ? '-' : ''}${formatNumber(value.abs())} $currency',
            style: GoogleFonts.notoSansThai(
              fontSize: 13,
              color: isDiscount
                  ? AppColors.emerald
                  : (isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Members Tab ───────────────────────────────────────────────
class _MembersTab extends StatelessWidget {
  final Bill bill;
  final BillProvider billProvider;
  final BillCalculation calc;
  final bool readOnly;

  const _MembersTab({
    required this.bill,
    required this.billProvider,
    required this.calc,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final members = billProvider.members;
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final friendsProvider = context.read<FriendsProvider>();
    final friendUserIds = friendsProvider.friends
        .map((f) => f.otherProfile(currentUserId ?? '')?.id)
        .whereType<String>()
        .toSet();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (!readOnly)
          GestureDetector(
            onTap: () => _showAddMemberSheet(context, bill, billProvider),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_add_outlined,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'เพิ่มสมาชิก',
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

        if (members.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Column(
                children: [
                  const Text('👥', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 12),
                  Text(
                    'ยังไม่มีสมาชิก',
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
        else ...[
          const SizedBox(height: 12),
          ...members.map((member) {
            final summary = calc.memberSummaries
                .firstWhere((s) => s.member.id == member.id,
                    orElse: () => MemberSummary(
                        member: member, total: 0, items: []));
            final isPaid =
                bill.paidMemberIds.contains(member.id);

            return _MemberTile(
              member: member,
              summary: summary,
              isPaid: isPaid,
              bill: bill,
              billProvider: billProvider,
              currency: bill.settings.currency,
              readOnly: readOnly,
              currentUserId: currentUserId,
              friendUserIds: friendUserIds,
            );
          }),
        ],
      ],
    );
  }

  void _showAddMemberSheet(
      BuildContext context, Bill bill, BillProvider billProvider) {
showModalBottomSheet(
context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _MemberFormSheet(
        bill: bill,
        billProvider: billProvider,
      ),
    );
  }

}

class _MemberTile extends StatelessWidget {
  final BillMember member;
  final MemberSummary summary;
  final bool isPaid;
  final Bill bill;
  final BillProvider billProvider;
  final String currency;
  final bool readOnly;
  final String? currentUserId;
  final Set<String> friendUserIds;

  const _MemberTile({
    required this.member,
    required this.summary,
    required this.isPaid,
    required this.bill,
    required this.billProvider,
    required this.currency,
    this.readOnly = false,
    this.currentUserId,
    this.friendUserIds = const {},
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = colorFromHex(member.color);

    return GestureDetector(
      onTap: readOnly || !member.isExternal
          ? null
          : () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                backgroundColor: Colors.transparent,
                builder: (ctx) => _MemberFormSheet(
                  bill: bill,
                  billProvider: billProvider,
                  editMember: member,
                ),
              ),
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
            MemberAvatar(
              name: member.name,
              color: color,
              size: 40,
              avatarUrl: member.profile?.avatarUrl,
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        member.name,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.notoSansThai(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                    ),
                    ..._buildMemberPill(),
                  ],
                ),
                Text(
                  '${summary.items.length} รายการ',
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatNumber(summary.total),
                style: GoogleFonts.notoSansThai(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              Text(
                currency,
                style: GoogleFonts.notoSansThai(
                  fontSize: 11,
                  color: isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textTertiaryLight,
                ),
              ),
            ],
          ),
            const SizedBox(width: 8),
            // Paid toggle
            GestureDetector(
              onTap: () async {
                await billProvider.toggleMemberPaid(
                    bill.id, member.id, bill.paidMemberIds);
              },
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isPaid
                      ? AppColors.emerald
                      : (isDark
                          ? AppColors.borderDark
                          : AppColors.neutral100),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPaid ? Icons.check_rounded : Icons.circle_outlined,
                  color: isPaid
                      ? Colors.white
                      : (isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight),
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMemberPill() {
    final String label;
    final Color color;

    if (member.isExternal) {
      label = 'ภายนอก';
      color = AppColors.neutral600;
    } else if (member.userId != null && member.userId == currentUserId) {
      label = 'ฉัน';
      color = AppColors.primary;
    } else if (member.userId != null && friendUserIds.contains(member.userId)) {
      label = 'เพื่อน';
      color = AppColors.emerald;
    } else {
      return [];
    }

    return [
      const SizedBox(width: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.notoSansThai(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ),
    ];
  }
}

// ── Item Form Sheet ───────────────────────────────────────────
class _ItemFormSheet extends StatefulWidget {
  final Bill bill;
  final BillProvider billProvider;
  final List<BillMember> members;
  final BillItem? editItem;

  const _ItemFormSheet({
    required this.bill,
    required this.billProvider,
    required this.members,
    this.editItem,
  });

  @override
  State<_ItemFormSheet> createState() => _ItemFormSheetState();
}

class _ItemFormSheetState extends State<_ItemFormSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _priceCtrl;
  late Map<String, bool> _selectedMembers;
  late Map<String, TextEditingController> _unequalCtrls;
  String? _paidBy;
  bool _isUnequalSplit = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final edit = widget.editItem;
    _nameCtrl = TextEditingController(text: edit?.name ?? '');
    _priceCtrl = TextEditingController(
        text: edit != null ? edit.price.toStringAsFixed(2) : '');
    _isUnequalSplit = edit?.isUnequalSplit ?? false;
    _selectedMembers = {
      for (final m in widget.members)
        m.id: edit != null
            ? (edit.isUnequalSplit
                ? edit.customShares.containsKey(m.id)
                : edit.memberIds.contains(m.id))
            : false,
    };
    _unequalCtrls = {
      for (final m in widget.members)
        m.id: TextEditingController(
          text: (edit?.isUnequalSplit == true &&
                  edit!.customShares.containsKey(m.id))
              ? edit.customShares[m.id]!.toStringAsFixed(2)
              : '',
        ),
    };
    _paidBy = edit?.paidBy;
    // Default paidBy to first member if none set
    if (_paidBy == null && widget.members.isNotEmpty) {
      _paidBy = widget.members.first.id;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    for (final c in _unequalCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> get _selectedIds =>
      _selectedMembers.entries.where((e) => e.value).map((e) => e.key).toList();

  double get _price => double.tryParse(_priceCtrl.text) ?? 0;

  double get _perPersonAmount {
    final count = _selectedIds.length;
    if (count == 0 || _price <= 0) return 0;
    return _price / count;
  }

  double get _unequalTotal => _unequalCtrls.entries
      .where((e) => _selectedMembers[e.key] == true)
      .fold(0.0, (sum, e) => sum + (double.tryParse(e.value.text) ?? 0));

  bool get _unequalValid =>
      !_isUnequalSplit ||
      (_price > 0 && (_unequalTotal - _price).abs() < 0.01);

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final price = _price;
    if (name.isEmpty || price <= 0) return;
    if (!_unequalValid) return;

    final selectedIds = _selectedIds;
    Map<String, double> customShares = {};
    if (_isUnequalSplit) {
      for (final id in selectedIds) {
        customShares[id] = double.tryParse(_unequalCtrls[id]!.text) ?? 0;
      }
    }

    setState(() => _loading = true);
    try {
      if (widget.editItem != null) {
        await widget.billProvider.editItem(
          widget.editItem!.id,
          name: name,
          price: price,
          memberIds: _isUnequalSplit ? [] : selectedIds,
          customShares: _isUnequalSplit ? customShares : {},
          paidBy: _paidBy,
          clearCustomShares: !_isUnequalSplit,
        );
      } else {
        await widget.billProvider.addItem(
          name: name,
          price: price,
          memberIds: _isUnequalSplit ? [] : selectedIds,
          customShares: _isUnequalSplit ? customShares : {},
          paidBy: _paidBy,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _delete() async {
    if (widget.editItem == null) return;
    final confirmed = await showConfirmDialog(
      context,
      title: 'ลบรายการนี้?',
      description: 'รายการ "${widget.editItem!.name}" จะถูกลบถาวร',
      confirmLabel: 'ลบ',
      danger: true,
    );
    if (!confirmed) return;
    setState(() => _loading = true);
    await widget.billProvider.deleteItem(widget.editItem!.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEdit = widget.editItem != null;
    final selectedIds = _selectedIds;
    final price = _price;

    return Container(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
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
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEdit ? 'แก้ไขรายการ' : 'เพิ่มรายการ',
                  style: GoogleFonts.notoSansThai(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                if (isEdit)
                  IconButton(
                    onPressed: _delete,
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: AppColors.red),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Name field
            TextField(
              controller: _nameCtrl,
              autofocus: !isEdit,
              decoration: const InputDecoration(hintText: 'ชื่อรายการ'),
            ),
            const SizedBox(height: 12),

            // Price field
            TextField(
              controller: _priceCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(hintText: 'ราคา'),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
              ],
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // ── Split mode toggle ──
            Row(
              children: [
                Expanded(
                  child: Text(
                    'วิธีหาร',
                    style: GoogleFonts.notoSansThai(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                ),
                // Equal split button
                GestureDetector(
                  onTap: () => setState(() => _isUnequalSplit = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: !_isUnequalSplit
                          ? AppColors.primary
                          : (isDark
                              ? AppColors.surfaceDark
                              : AppColors.neutral100),
                      borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(8)),
                    ),
                    child: Text(
                      'หารเท่า',
                      style: GoogleFonts.notoSansThai(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: !_isUnequalSplit
                            ? Colors.white
                            : (isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight),
                      ),
                    ),
                  ),
                ),
                // Unequal split button
                GestureDetector(
                  onTap: () => setState(() => _isUnequalSplit = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isUnequalSplit
                          ? AppColors.primary
                          : (isDark
                              ? AppColors.surfaceDark
                              : AppColors.neutral100),
                      borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(8)),
                    ),
                    child: Text(
                      'หารไม่เท่า',
                      style: GoogleFonts.notoSansThai(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _isUnequalSplit
                            ? Colors.white
                            : (isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Member selection ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'แบ่งให้ใคร',
                  style: GoogleFonts.notoSansThai(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                if (widget.members.isNotEmpty)
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() {
                          for (final m in widget.members) {
                            _selectedMembers[m.id] = true;
                          }
                        }),
                        child: Text(
                          'เลือกทั้งหมด',
                          style: GoogleFonts.notoSansThai(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => setState(() {
                          for (final m in widget.members) {
                            _selectedMembers[m.id] = false;
                          }
                        }),
                        child: Text(
                          'ล้าง',
                          style: GoogleFonts.notoSansThai(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiaryLight,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),

            if (widget.members.isEmpty)
              Text(
                'ยังไม่มีสมาชิก',
                style: GoogleFonts.notoSansThai(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textTertiaryLight,
                ),
              )
            else
              Column(
                children: widget.members.map((m) {
                  final selected = _selectedMembers[m.id] ?? false;
                  final color = colorFromHex(m.color);
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedMembers[m.id] = !selected),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? color.withOpacity(0.08)
                            : (isDark
                                ? AppColors.surfaceDark
                                : AppColors.neutral50),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected ? color : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          MemberAvatar(name: m.name, color: color, size: 28, avatarUrl: m.profile?.avatarUrl),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              m.name,
                              style: GoogleFonts.notoSansThai(
                                fontSize: 14,
                                color: selected
                                    ? color
                                    : (isDark
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textPrimaryLight),
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          // Equal split: show per-person amount
                          if (!_isUnequalSplit && selected && price > 0)
                            Text(
                              '฿${_perPersonAmount.toStringAsFixed(2)}',
                              style: GoogleFonts.notoSansThai(
                                fontSize: 13,
                                color: color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          // Unequal split: show amount input
                          if (_isUnequalSplit && selected) ...[
                            SizedBox(
                              width: 90,
                              child: TextField(
                                controller: _unequalCtrls[m.id],
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                textAlign: TextAlign.right,
                                style: GoogleFonts.notoSansThai(
                                    fontSize: 13, color: color),
                                decoration: InputDecoration(
                                  hintText: '0.00',
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 6),
                                  isDense: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: color),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                        color: color, width: 2),
                                  ),
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d+\.?\d{0,2}'))
                                ],
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                          const SizedBox(width: 8),
                          Icon(
                            selected
                                ? Icons.check_circle_rounded
                                : Icons.circle_outlined,
                            color: selected
                                ? color
                                : (isDark
                                    ? AppColors.textTertiaryDark
                                    : AppColors.textTertiaryLight),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

            // Unequal split validation hint
            if (_isUnequalSplit && price > 0 && selectedIds.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _unequalValid
                      ? AppColors.emerald.withOpacity(0.08)
                      : AppColors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ยอดที่กรอก',
                      style: GoogleFonts.notoSansThai(
                        fontSize: 12,
                        color: _unequalValid
                            ? AppColors.emerald
                            : AppColors.red,
                      ),
                    ),
                    Text(
                      '${_unequalTotal.toStringAsFixed(2)} / ${price.toStringAsFixed(2)}',
                      style: GoogleFonts.notoSansThai(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _unequalValid
                            ? AppColors.emerald
                            : AppColors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // ── Paid by ──
            if (widget.members.isNotEmpty) ...[
              Text(
                'ใครจ่ายก่อน?',
                style: GoogleFonts.notoSansThai(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _paidBy = null),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _paidBy == null
                            ? AppColors.primary.withOpacity(0.15)
                            : (isDark
                                ? AppColors.surfaceDark
                                : AppColors.neutral100),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _paidBy == null
                              ? AppColors.primary
                              : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        'ไม่ระบุ',
                        style: GoogleFonts.notoSansThai(
                          fontSize: 13,
                          color: _paidBy == null
                              ? AppColors.primary
                              : (isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight),
                        ),
                      ),
                    ),
                  ),
                  ...widget.members.map((m) {
                    final selected = _paidBy == m.id;
                    final color = colorFromHex(m.color);
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _paidBy = selected ? null : m.id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected
                              ? color.withOpacity(0.15)
                              : (isDark
                                  ? AppColors.surfaceDark
                                  : AppColors.neutral100),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected ? color : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            MemberAvatar(
                                name: m.name, color: color, size: 18, avatarUrl: m.profile?.avatarUrl),
                            const SizedBox(width: 6),
                            Text(
                              m.name,
                              style: GoogleFonts.notoSansThai(
                                fontSize: 13,
                                color: selected
                                    ? color
                                    : (isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight),
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 16),
            ],

            ElevatedButton(
              onPressed: (_loading || !_unequalValid) ? null : _save,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(
                      isEdit ? 'บันทึก' : 'เพิ่มรายการ',
                      style: GoogleFonts.notoSansThai(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Member Form Sheet ─────────────────────────────────────────
class _MemberFormSheet extends StatefulWidget {
  final Bill bill;
  final BillProvider billProvider;
  final BillMember? editMember;

  const _MemberFormSheet({
    required this.bill,
    required this.billProvider,
    this.editMember,
  });

  @override
  State<_MemberFormSheet> createState() => _MemberFormSheetState();
}

class _MemberFormSheetState extends State<_MemberFormSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  // "สร้างเอง" fields
  late TextEditingController _nameCtrl;
  late TextEditingController _promptpayCtrl;
  late Color _selectedColor;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Standalone → 2 tabs (friends, create); group bill / editing → 1 (unused but required)
    final tabCount = (widget.editMember == null && widget.bill.groupId == null) ? 2 : 1;
    _tabCtrl = TabController(length: tabCount, vsync: this);
    _nameCtrl = TextEditingController(text: widget.editMember?.name ?? '');
    _promptpayCtrl =
        TextEditingController(text: widget.editMember?.promptpay ?? '');
    _selectedColor = widget.editMember != null
        ? colorFromHex(widget.editMember!.color)
        : AppColors.memberColors[
            widget.billProvider.members.length %
                AppColors.memberColors.length];
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _nameCtrl.dispose();
    _promptpayCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveCustom() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _loading = true);
    try {
      if (widget.editMember != null) {
        await widget.billProvider.editMember(
          widget.editMember!.id,
          name: name,
          color: hexFromColor(_selectedColor),
          promptpay: _promptpayCtrl.text.trim().isEmpty
              ? null
              : _promptpayCtrl.text.trim(),
        );
      } else {
        await widget.billProvider.addMember(
          name: name,
          color: hexFromColor(_selectedColor),
          promptpay: _promptpayCtrl.text.trim().isEmpty
              ? null
              : _promptpayCtrl.text.trim(),
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _addFriend(Profile profile) async {
    final name = profile.displayName ?? profile.username ?? 'เพื่อน';
    final colorIdx =
        widget.billProvider.members.length % AppColors.memberColors.length;
    final color = hexFromColor(AppColors.memberColors[colorIdx]);
    setState(() => _loading = true);
    try {
      await widget.billProvider.addMemberFromGroupMember(
        userId: profile.id,
        name: name,
        color: color,
        promptpay: profile.promptpay,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _addFromGroupMember(GroupMember gm) async {
    final name = gm.name;
    final colorIdx =
        widget.billProvider.members.length % AppColors.memberColors.length;
    final color = hexFromColor(AppColors.memberColors[colorIdx]);
    setState(() => _loading = true);
    try {
      await widget.billProvider.addMemberFromGroupMember(
        userId: gm.userId,
        name: name,
        color: color,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEdit = widget.editMember != null;

    // If editing, show simple edit form (no tabs)
    if (isEdit) {
      return _buildEditForm(context, isDark);
    }

    final alreadyAddedUserIds = widget.billProvider.members
        .where((m) => m.userId != null)
        .map((m) => m.userId!)
        .toSet();
    final alreadyAddedExternalNames = widget.billProvider.members
        .where((m) => m.userId == null)
        .map((m) => m.name)
        .toSet();

    // ── Group bill: only show group members, no tabs ──
    final groupId = widget.bill.groupId;
    if (groupId != null) {
      final gp = context.read<GroupsProvider>();
      final groupMembers = gp.currentGroup?.members.where((m) => m.isAccepted).toList() ?? [];
      final availableGroupMembers = groupMembers.where((m) {
        if (m.userId != null) return !alreadyAddedUserIds.contains(m.userId);
        return !alreadyAddedExternalNames.contains(m.name);
      }).toList();

      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.65,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  'เพิ่มสมาชิก',
                  style: GoogleFonts.notoSansThai(
                    fontSize: 18, fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
              ),
              Expanded(child: _buildGroupMembersTab(context, isDark, availableGroupMembers)),
            ],
          ),
        ),
      );
    }

    // ── Standalone bill: 2 tabs (เพื่อน + สร้างเอง) ──
    final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final friendsProvider = context.read<FriendsProvider>();
    final availableFriends = friendsProvider.friends
        .where((f) {
          final p = f.otherProfile(currentUserId);
          return p != null && !alreadyAddedUserIds.contains(p.id);
        })
        .map((f) => f.otherProfile(currentUserId)!)
        .toList();

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Text(
                'เพิ่มสมาชิก',
                style: GoogleFonts.notoSansThai(
                  fontSize: 18, fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.neutral100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabCtrl,
                indicator: BoxDecoration(
                  color: isDark ? AppColors.borderDark : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 1))],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: AppColors.primary,
                unselectedLabelColor: isDark ? AppColors.textTertiaryDark : AppColors.neutral600,
                labelStyle: GoogleFonts.notoSansThai(fontSize: 13, fontWeight: FontWeight.w600),
                unselectedLabelStyle: GoogleFonts.notoSansThai(fontSize: 13),
                tabs: const [Tab(text: 'เพื่อน'), Tab(text: 'สร้างเอง')],
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _buildFriendsTab(context, isDark, availableFriends),
                  _buildCustomForm(context, isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Standalone custom form (no group) — wraps with keyboard-aware container
  Widget _buildFriendsTab(BuildContext context, bool isDark, List<Profile> available) {
    if (available.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(
            'ไม่มีเพื่อนที่สามารถเพิ่มได้\nลองเพิ่มเพื่อนในแอปก่อน',
            style: GoogleFonts.notoSansThai(
              fontSize: 14,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      itemCount: available.length,
      itemBuilder: (ctx, i) {
        final profile = available[i];
        final name = profile.displayName ?? profile.username ?? 'เพื่อน';
        final colorIdx = i % AppColors.memberColors.length;
        final color = AppColors.memberColors[colorIdx];

        return GestureDetector(
          onTap: _loading ? null : () => _addFriend(profile),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.neutral50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Row(
              children: [
                MemberAvatar(
                  name: name,
                  color: color,
                  size: 36,
                  avatarUrl: profile.avatarUrl,
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
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                      if (profile.username != null)
                        Text(
                          '@${profile.username}',
                          style: GoogleFonts.notoSansThai(
                            fontSize: 12,
                            color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                          ),
                        ),
                    ],
                  ),
                ),
                if (_loading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  )
                else
                  const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 22),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGroupMembersTab(
      BuildContext context, bool isDark, List<GroupMember> available) {
    if (available.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(
            'สมาชิกในกลุ่มทุกคนถูกเพิ่มแล้ว',
            style: GoogleFonts.notoSansThai(
              fontSize: 14,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      itemCount: available.length,
      itemBuilder: (ctx, i) {
        final gm = available[i];
        final name =
            gm.profile?.displayName ?? gm.profile?.username ?? 'สมาชิก';
        final username = gm.profile?.username;
        final avatarUrl = gm.profile?.avatarUrl;
        final colorIdx = i % AppColors.memberColors.length;
        final color = AppColors.memberColors[colorIdx];

        return GestureDetector(
          onTap: _loading ? null : () => _addFromGroupMember(gm),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceDark
                  : AppColors.neutral50,
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
                  color: color,
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
                if (_loading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary),
                  )
                else
                  const Icon(Icons.add_circle_outline_rounded,
                      color: AppColors.primary, size: 22),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomForm(BuildContext context, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _nameCtrl,
            autofocus: widget.editMember == null,
            decoration: const InputDecoration(hintText: 'ชื่อสมาชิก'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _promptpayCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
                hintText: 'เบอร์ PromptPay (ไม่บังคับ)'),
          ),
          const SizedBox(height: 16),
          Text(
            'สีประจำตัว',
            style: GoogleFonts.notoSansThai(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppColors.memberColors.map((color) {
              final isSelected = _selectedColor == color;
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = color),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(
                            color: isDark ? Colors.white : Colors.black,
                            width: 2)
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 18)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loading ? null : _saveCustom,
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Text(
                    'เพิ่มสมาชิก',
                    style: GoogleFonts.notoSansThai(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm(BuildContext context, bool isDark) {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
        ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.borderDark
                      : AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'แก้ไขสมาชิก',
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
              controller: _nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'ชื่อสมาชิก'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _promptpayCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                  hintText: 'เบอร์ PromptPay (ไม่บังคับ)'),
            ),
            const SizedBox(height: 16),
            Text(
              'สีประจำตัว',
              style: GoogleFonts.notoSansThai(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppColors.memberColors.map((color) {
                final isSelected = _selectedColor == color;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(
                              color: isDark ? Colors.white : Colors.black,
                              width: 2)
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check_rounded,
                            color: Colors.white, size: 18)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _saveCustom,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(
                      'บันทึก',
                      style: GoogleFonts.notoSansThai(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

// ── Stacked Avatars ───────────────────────────────────────────
class _StackedAvatars extends StatelessWidget {
  final List<BillMember> members;

  const _StackedAvatars({required this.members});

  @override
  Widget build(BuildContext context) {
    const maxShow = 3;
    final shown = members.take(maxShow).toList();
    final extra = members.length - shown.length;
    final totalWidth = shown.isEmpty
        ? 0.0
        : 24.0 + (shown.length - 1) * 16.0 + (extra > 0 ? 20.0 : 0.0);

    if (shown.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      width: totalWidth,
      height: 24,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ...shown.asMap().entries.map((e) => Positioned(
                left: e.key * 16.0,
                child: MemberAvatar(
                  name: e.value.name,
                  color: colorFromHex(e.value.color),
                  size: 24,
                  avatarUrl: e.value.profile?.avatarUrl,
                  showBorder: true,
                ),
              )),
          if (extra > 0)
            Positioned(
              left: shown.length * 16.0,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.neutral400,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    '+$extra',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
