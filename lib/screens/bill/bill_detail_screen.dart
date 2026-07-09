import 'package:kidtang_flutter/providers/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kidtang_flutter/models/models.dart';
import 'package:kidtang_flutter/stores/bills_store.dart';
import 'package:kidtang_flutter/stores/friends_store.dart';
import 'package:kidtang_flutter/stores/groups_store.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';
import 'package:kidtang_flutter/utils/bill_utils.dart';
import 'package:kidtang_flutter/widgets/shared/skeleton_loader.dart';
import 'package:kidtang_flutter/widgets/bill/analytics_tab.dart';
import 'package:kidtang_flutter/widgets/shared/banner_ad_widget.dart';
import 'package:kidtang_flutter/widgets/bill/summary_tab.dart';
import 'package:kidtang_flutter/widgets/bill/index.dart';
import 'package:kidtang_flutter/widgets/shared/emoji_text.dart';

class BillDetailScreen extends StatefulWidget {
  final String billId;
  const BillDetailScreen({super.key, required this.billId});

  @override
  State<BillDetailScreen> createState() => _BillDetailScreenState();
}

class _BillDetailScreenState extends State<BillDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;
  bool _refreshing = false;

  Future<void> _onRefresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    try {
      final bp = context.read<BillsStore>();
      await bp.ensureLoaded(widget.billId);
      // Force re-fetch by removing from cache and reloading
      final bill = bp.getById(widget.billId);
      if (bill != null) {
        final groupId = bill.groupId;
        if (groupId != null && mounted) {
          await context.read<GroupsStore>().loadGroupDetail(groupId);
        }
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  // Cache the last bill + its calculation to avoid recomputing on every rebuild.
  Bill? _lastBill;
  BillCalculation? _cachedCalc;

  BillCalculation _getCalc(Bill bill) {
    if (!identical(_lastBill, bill) && (_lastBill == null || _lastBill!.items != bill.items || _lastBill!.members != bill.members || _lastBill!.settings != bill.settings)) {
      _lastBill = bill;
      _cachedCalc = calculateBill(bill);
    }
    return _cachedCalc!;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final bp = context.read<BillsStore>();
      try {
        final bill = await bp.ensureLoaded(widget.billId);
        // Auto-add current user as first member if bill is new (no members yet)
        if (bill != null && bill.members.isEmpty && bill.isDraft) {
          await bp.autoAddCurrentUser(widget.billId);
        }
        // Load group detail if this bill belongs to a group
        if (!mounted) return;
        final groupId = bp.getById(widget.billId)?.groupId;
        if (groupId != null) {
          final gp = context.read<GroupsStore>();
          if (gp.getById(groupId) == null) {
            await gp.loadGroupDetail(groupId);
          }
        }
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.watch<LocaleProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bill = context.select<BillsStore, Bill?>((s) => s.getById(widget.billId));
    final billsStore = context.read<BillsStore>();

    if (_loading) {
      return Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppGradients.backgroundDark : AppGradients.backgroundLight,
        ),
        child: const Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(child: BillDetailSkeleton()),
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
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/bills');
                }
              },
            ),
          ),
          body: Center(
            child: Text(
              l.t('bill_not_found'),
              style: GoogleFonts.sarabun(fontSize: 16),
            ),
          ),
        ),
      );
    }

    final calc = _getCalc(bill);
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isOwner = bill.ownerId == currentUserId;
    final isCompleted = bill.isCompleted;
    final isPendingPayment = bill.isPendingPayment;
    final isDraft = bill.isDraft;
    final members = bill.members;
    final items = bill.items;

    // Build friend user-id set for member pills (O(1) lookup)
    final friendUserIds = context.read<FriendsStore>().friends.map((f) => f.requesterId == currentUserId ? f.addresseeId : f.requesterId).toSet();

    return Container(
      decoration: BoxDecoration(
        gradient: isDark ? AppGradients.backgroundDark : AppGradients.backgroundLight,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                color: AppColors.primary,
                notificationPredicate: (notification) => notification.depth == 2,
                child: NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) => [
                    SliverAppBar(
                      pinned: true,
                      expandedHeight: 0,
                      backgroundColor: Colors.transparent,
                      flexibleSpace: Container(
                        decoration: BoxDecoration(
                          gradient: isDark ? AppGradients.backgroundDark : AppGradients.backgroundLight,
                        ),
                      ),
                      leading: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_rounded),
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/bills');
                          }
                        },
                      ),
                      title: _BillAppBarTitle(
                        bill: bill,
                        isDark: isDark,
                        isDraft: isDraft,
                      ),
                      actions: [
                        _BillStatusActions(
                          bill: bill,
                          billsStore: billsStore,
                          isDark: isDark,
                          isDraft: isDraft,
                          isPendingPayment: isPendingPayment,
                          isOwner: isOwner,
                          tabController: _tabController,
                          onEditBill: () => context.push('/bills/${bill.id}/edit'),
                        ),
                      ],
                      bottom: PreferredSize(
                        preferredSize: const Size.fromHeight(56),
                        child: PillTabBar(
                          controller: _tabController,
                          tabs: [
                            CountTab(label: l.t('bill_tab_members'), count: members.length),
                            CountTab(label: l.t('bill_tab_items'), count: items.length),
                            CountTab(label: l.t('bill_tab_summary'), count: 0),
                            CountTab(label: l.t('bill_tab_analytics'), count: 0),
                          ],
                        ),
                      ),
                    ),
                  ],
                  body: Column(
                    children: [
                      // Status banner
                      if (!isDraft) _StatusBanner(isCompleted: isCompleted, isDark: isDark),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            // Each tab is wrapped in _LazyTabBody so it is only
                            // built the first time the user navigates to it.
                            // This prevents AnalyticsTab (PieChart + sorts) and
                            // SummaryTab from being constructed on screen open.
                            _LazyTabBody(
                              tabController: _tabController,
                              tabIndex: 0,
                              child: MembersTab(
                                bill: bill,
                                billsStore: billsStore,
                                calc: calc,
                                readOnly: !isDraft,
                                currentUserId: currentUserId,
                                friendUserIds: friendUserIds,
                              ),
                            ),
                            _LazyTabBody(
                              tabController: _tabController,
                              tabIndex: 1,
                              child: ItemsTab(
                                bill: bill,
                                billsStore: billsStore,
                                calc: calc,
                                readOnly: !isDraft,
                              ),
                            ),
                            _LazyTabBody(
                              tabController: _tabController,
                              tabIndex: 2,
                              child: SummaryTab(bill: bill, billsStore: billsStore, calc: calc),
                            ),
                            _LazyTabBody(
                              tabController: _tabController,
                              tabIndex: 3,
                              child: AnalyticsTab(bill: bill, billsStore: billsStore, calc: calc),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const BannerAdWidget(),
          ],
        ),
      ),
    );
  }
}

// ── File-private sub-widgets ──────────────────────────────────

class _BillAppBarTitle extends StatelessWidget {
  final Bill bill;
  final bool isDark;
  final bool isDraft;

  const _BillAppBarTitle({
    required this.bill,
    required this.isDark,
    required this.isDraft,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              EmojiText(bill.emoji ?? '🧾', fontSize: 18),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  bill.title,
                  style: GoogleFonts.sarabun(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.neutral900Dark : AppColors.neutral900,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BillStatusActions extends StatelessWidget {
  final Bill bill;
  final BillsStore billsStore;
  final bool isDark;
  final bool isDraft;
  final bool isPendingPayment;
  final bool isOwner;
  final TabController tabController;
  final VoidCallback onEditBill;

  const _BillStatusActions({
    required this.bill,
    required this.billsStore,
    required this.isDark,
    required this.isDraft,
    required this.isPendingPayment,
    required this.isOwner,
    required this.tabController,
    required this.onEditBill,
  });

  void _showStatusPicker(BuildContext context, LocaleProvider l) {
    showDialog(
      context: context,
      builder: (_) => _BillStatusPickerDialog(
        bill: bill,
        billsStore: billsStore,
        isDark: isDark,
        tabController: tabController,
      ),
    );
  }

  // Returns the chip appearance for the current bill status.
  _StatusChipStyle _chipStyle(LocaleProvider l) {
    if (bill.isCompleted) {
      return _StatusChipStyle(
        label: l.t('bill_status_completed'),
        icon: Icons.check_circle_rounded,
        color: AppColors.emerald,
        bgColor: AppColors.emerald.withValues(alpha: 0.15),
      );
    } else if (bill.isPendingPayment) {
      return _StatusChipStyle(
        label: l.t('bill_status_pending'),
        icon: Icons.hourglass_top_rounded,
        color: AppColors.amber,
        bgColor: AppColors.amber.withValues(alpha: 0.15),
      );
    } else {
      return _StatusChipStyle(
        label: l.t('bill_status_draft'),
        icon: Icons.edit_note_rounded,
        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        bgColor: isDark ? AppColors.borderDark : AppColors.neutral100,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.watch<LocaleProvider>();
    final style = _chipStyle(l);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionChip(
          label: style.label,
          icon: style.icon,
          trailingIcon: Icons.expand_more_rounded,
          color: style.bgColor,
          textColor: style.color,
          iconColor: style.color,
          onTap: () => _showStatusPicker(context, l),
        ),
        if (isOwner) ...[
          IconButton(
            icon: const Icon(Icons.group_add_outlined),
            tooltip: l.t('bill_move_to_group_title'),
            onPressed: () {
              MoveToGroupSheet.show(context, bill: bill);
            },
          ),
        ],
        if (isOwner && isDraft)
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: onEditBill,
          ),
        const SizedBox(width: 4),
      ],
    );
  }
}

// ── Status Picker Dialog ──────────────────────────────────────

class _BillStatusPickerDialog extends StatelessWidget {
  final Bill bill;
  final BillsStore billsStore;
  final bool isDark;
  final TabController tabController;

  const _BillStatusPickerDialog({
    required this.bill,
    required this.billsStore,
    required this.isDark,
    required this.tabController,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.watch<LocaleProvider>();
    final currentStatus = bill.status;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppRadii.xl),
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.t('bill_adjust_status'),
              style: GoogleFonts.sarabun(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.neutral900Dark : AppColors.neutral900,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l.t('bill_adjust_status_subtitle'),
              style: GoogleFonts.sarabun(
                fontSize: 13,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _StatusOption(
              label: l.t('bill_status_draft'),
              description: l.t('bill_status_draft_desc'),
              icon: Icons.edit_note_rounded,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              bgColor: isDark ? AppColors.borderDark : AppColors.neutral100,
              isSelected: currentStatus == 'draft',
              isDark: isDark,
              onTap: () async {
                Navigator.of(context).pop();
                if (currentStatus == 'draft') return;
                await billsStore.reopenBill(bill.id);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            _StatusOption(
              label: l.t('bill_status_pending'),
              description: l.t('bill_status_pending_desc'),
              icon: Icons.hourglass_top_rounded,
              color: AppColors.amber,
              bgColor: AppColors.amber.withValues(alpha: 0.12),
              isSelected: currentStatus == 'pending_payment',
              isDark: isDark,
              onTap: () async {
                Navigator.of(context).pop();
                if (currentStatus == 'pending_payment') return;
                await billsStore.setPendingPayment(bill.id);
                tabController.animateTo(2);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            _StatusOption(
              label: l.t('bill_status_completed'),
              description: l.t('bill_status_completed_desc'),
              icon: Icons.check_circle_rounded,
              color: AppColors.emerald,
              bgColor: AppColors.emerald.withValues(alpha: 0.12),
              isSelected: currentStatus == 'completed',
              isDark: isDark,
              onTap: () async {
                Navigator.of(context).pop();
                if (currentStatus == 'completed') return;
                await billsStore.completeBill(bill.id);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  l.t('cancel'),
                  style: GoogleFonts.sarabun(
                    fontSize: 14,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusOption extends StatelessWidget {
  final String label;
  final String description;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _StatusOption({
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.press,
        curve: AppMotion.standard,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        decoration: BoxDecoration(
          color: isSelected ? bgColor : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
            color: isSelected ? color.withValues(alpha: 0.5) : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.sarabun(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? color : (isDark ? AppColors.neutral900Dark : AppColors.neutral900),
                    ),
                  ),
                  Text(
                    description,
                    style: GoogleFonts.sarabun(
                      fontSize: 12,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_rounded, size: 18, color: color),
          ],
        ),
      ),
    );
  }
}

// Simple value object for status chip appearance.
class _StatusChipStyle {
  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;
  const _StatusChipStyle({
    required this.label,
    required this.icon,
    required this.color,
    required this.bgColor,
  });
}

class _ActionChip extends StatefulWidget {
  final String label;
  final IconData icon;
  final IconData? trailingIcon;
  final Color color;
  final Color textColor;
  final Color? iconColor;
  final VoidCallback onTap;

  const _ActionChip({
    required this.label,
    required this.icon,
    this.trailingIcon,
    required this.color,
    required this.textColor,
    this.iconColor,
    required this.onTap,
  });

  @override
  State<_ActionChip> createState() => _ActionChipState();
}

class _ActionChipState extends State<_ActionChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? AppMotion.pressScaleButton : 1.0,
        duration: AppMotion.press,
        curve: AppMotion.standard,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm + 4,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(AppRadii.full),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 14, color: widget.iconColor ?? widget.textColor),
              const SizedBox(width: AppSpacing.xxs + 2),
              Text(
                widget.label,
                style: GoogleFonts.sarabun(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: widget.textColor,
                ),
              ),
              if (widget.trailingIcon != null) ...[
                const SizedBox(width: AppSpacing.xxs),
                Icon(widget.trailingIcon, size: 14, color: widget.iconColor ?? widget.textColor),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Lazy tab body ─────────────────────────────────────────────
// Defers building the child until the tab is first selected.
// Once built, the child is kept alive so it is not rebuilt on
// every tab switch (AutomaticKeepAliveClientMixin equivalent
// without requiring the child to implement it).
class _LazyTabBody extends StatefulWidget {
  final TabController tabController;
  final int tabIndex;
  final Widget child;

  const _LazyTabBody({
    required this.tabController,
    required this.tabIndex,
    required this.child,
  });

  @override
  State<_LazyTabBody> createState() => _LazyTabBodyState();
}

class _LazyTabBodyState extends State<_LazyTabBody>
    with AutomaticKeepAliveClientMixin {
  bool _built = false;

  @override
  bool get wantKeepAlive => _built;

  @override
  void initState() {
    super.initState();
    // Build immediately if this is the initially selected tab.
    if (widget.tabController.index == widget.tabIndex) {
      _built = true;
    } else {
      widget.tabController.addListener(_onTabChanged);
    }
  }

  void _onTabChanged() {
    if (!_built && widget.tabController.index == widget.tabIndex) {
      setState(() => _built = true);
      widget.tabController.removeListener(_onTabChanged);
    }
  }

  @override
  void dispose() {
    widget.tabController.removeListener(_onTabChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // required by AutomaticKeepAliveClientMixin
    if (!_built) return const SizedBox.shrink();
    return widget.child;
  }
}

class _StatusBanner extends StatelessWidget {
  final bool isCompleted;
  final bool isDark;

  const _StatusBanner({required this.isCompleted, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = isCompleted ? (isDark ? AppColors.emerald : AppColors.emeraldText) : AppColors.amber;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: isCompleted ? (isDark ? AppColors.emeraldDark.withValues(alpha: 0.25) : AppColors.greenFaint) : (isDark ? AppColors.amber.withValues(alpha: 0.15) : AppColors.amberFaint),
        border: Border(
          bottom: BorderSide(
            color:
                isCompleted ? (isDark ? AppColors.emeraldDark : AppColors.emerald.withValues(alpha: 0.3)) : (isDark ? AppColors.amber.withValues(alpha: 0.4) : AppColors.amber.withValues(alpha: 0.3)),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isCompleted ? Icons.lock_rounded : Icons.hourglass_top_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            isCompleted ? context.watch<LocaleProvider>().t('bill_status_banner_completed') : context.watch<LocaleProvider>().t('bill_status_banner_pending'),
            style: GoogleFonts.sarabun(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
