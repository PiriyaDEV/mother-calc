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
import 'package:kidtang_flutter/widgets/shared/confirm_dialog.dart';
import 'package:kidtang_flutter/widgets/shared/skeleton_loader.dart';
import 'package:kidtang_flutter/widgets/bill/analytics_tab.dart';
import 'package:kidtang_flutter/widgets/shared/banner_ad_widget.dart';
import 'package:kidtang_flutter/widgets/bill/summary_tab.dart';
import 'package:kidtang_flutter/widgets/bill/index.dart';

class BillDetailScreen extends StatefulWidget {
  final String billId;
  const BillDetailScreen({super.key, required this.billId});

  @override
  State<BillDetailScreen> createState() => _BillDetailScreenState();
}

class _BillDetailScreenState extends State<BillDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;

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
              style: GoogleFonts.notoSansThai(fontSize: 16),
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
              child: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  SliverAppBar(
                    pinned: true,
                    expandedHeight: 0,
                    backgroundColor: Colors.transparent,
                    forceMaterialTransparency: true,
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
                        children: [
                          MembersTab(
                            bill: bill,
                            billsStore: billsStore,
                            calc: calc,
                            readOnly: !isDraft,
                            currentUserId: currentUserId,
                            friendUserIds: friendUserIds,
                          ),
                          ItemsTab(
                            bill: bill,
                            billsStore: billsStore,
                            calc: calc,
                            readOnly: !isDraft,
                          ),
                          SummaryTab(bill: bill, billsStore: billsStore, calc: calc),
                          AnalyticsTab(bill: bill, billsStore: billsStore, calc: calc),
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
    final l = context.watch<LocaleProvider>();
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Text(bill.emoji ?? '🧾', style: const TextStyle(fontSize: 18)),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  bill.title,
                  style: GoogleFonts.notoSansThai(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.neutral900Dark : AppColors.neutral900,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!isDraft) ...[
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.emerald.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadii.full),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_rounded, size: 11, color: AppColors.emerald),
                      const SizedBox(width: AppSpacing.xxs),
                      Text(
                        l.t('bill_closed_badge'),
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

  @override
  Widget build(BuildContext context) {
    final l = context.watch<LocaleProvider>();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isDraft)
          _ActionChip(
            label: l.t('bill_close_label'),
            icon: Icons.lock_rounded,
            color: AppColors.amber,
            textColor: Colors.white,
            onTap: () async {
              final ok = await showConfirmDialog(
                context,
                title: l.t('bill_close_confirm_title'),
                description: l.t('bill_close_confirm_body'),
                confirmLabel: l.t('bill_close_label'),
              );
              if (ok == true) {
                await billsStore.setPendingPayment(bill.id);
                tabController.animateTo(2);
              }
            },
          )
        else if (isPendingPayment) ...[
          _ActionChip(
            label: l.t('bill_reopen'),
            icon: Icons.lock_open_rounded,
            color: isDark ? AppColors.borderDark : AppColors.neutral100,
            textColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            iconColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            onTap: () async {
              final ok = await showConfirmDialog(
                context,
                title: l.t('bill_reopen_confirm_title'),
                description: l.t('bill_reopen_confirm_body'),
                confirmLabel: l.t('bill_reopen'),
              );
              if (ok == true) await billsStore.reopenBill(bill.id);
            },
          ),
          const SizedBox(width: 4),
          _ActionChip(
            label: l.t('bill_completed_label'),
            icon: Icons.check_rounded,
            color: AppColors.emerald,
            textColor: Colors.white,
            onTap: () async {
              final ok = await showConfirmDialog(
                context,
                title: l.t('bill_complete_confirm_title'),
                description: l.t('bill_complete_confirm_body'),
                confirmLabel: l.t('bill_completed_label'),
              );
              if (ok == true) await billsStore.completeBill(bill.id);
            },
          ),
        ] else
          _ActionChip(
            label: l.t('bill_reopen'),
            icon: Icons.lock_open_rounded,
            color: isDark ? AppColors.borderDark : AppColors.neutral100,
            textColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            iconColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            onTap: () async {
              final ok = await showConfirmDialog(
                context,
                title: l.t('bill_reopen_confirm_title'),
                description: l.t('bill_reopen_confirm_body'),
                confirmLabel: l.t('bill_reopen'),
              );
              if (ok == true) await billsStore.reopenBill(bill.id);
            },
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

class _ActionChip extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color textColor;
  final Color? iconColor;
  final VoidCallback onTap;

  const _ActionChip({
    required this.label,
    required this.icon,
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
                style: GoogleFonts.notoSansThai(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: widget.textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
            style: GoogleFonts.notoSansThai(
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
