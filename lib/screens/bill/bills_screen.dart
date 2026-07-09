import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kidtang_flutter/models/models.dart';
import 'package:kidtang_flutter/stores/bills_store.dart';
import 'package:kidtang_flutter/stores/friends_store.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';
import 'package:kidtang_flutter/widgets/shared/banner_ad_widget.dart';
import 'package:kidtang_flutter/widgets/shared/skeleton_loader.dart';
import 'package:kidtang_flutter/providers/locale_provider.dart';
import 'package:kidtang_flutter/widgets/shared/shared_bill_card.dart';
import 'package:kidtang_flutter/widgets/shared/app_empty_state.dart';

class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final store = context.read<BillsStore>();
      store.loadStats();
      for (final status in kBillStatuses) {
        store.loadInitialPage(status);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _createBill() {
    context.push('/bills/create');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l = context.watch<LocaleProvider>();
    final store = context.watch<BillsStore>();
    final draftView = store.viewFor('draft');
    final pendingView = store.viewFor('pending_payment');
    final completedView = store.viewFor('completed');
    final stats = store.stats;
    final allBillsCount = stats?.totalCount ?? 0;
    final draftCount = stats?.draftCount ?? draftView.items.length;
    final pendingCount = stats?.pendingPaymentCount ?? pendingView.items.length;
    final completedCount = stats?.completedCount ?? completedView.items.length;
    final allLoaded =
        draftView.loaded && pendingView.loaded && completedView.loaded;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.t('bills_title'),
                          style: GoogleFonts.sarabun(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.neutral900Dark
                                : AppColors.neutral900,
                            height: 1.1,
                          ),
                        ),
                        if (allBillsCount > 0) ...[
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            '$allBillsCount ${l.t('nav_bills')}',
                            style: GoogleFonts.sarabun(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.neutral400Dark
                                  : AppColors.neutral400,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Semantics(
                    label: l.t('bills_create'),
                    button: true,
                    child: _CreateButton(onTap: _createBill),
                  ),
                ],
              ),
            ),

            // ── Tabs ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                0,
              ),
              child: Container(
                height: 44,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color:
                      isDark ? AppColors.surfaceDark : AppColors.neutral100,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: isDark ? AppColors.bgDark : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                    boxShadow: const [AppShadows.subtle],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  overlayColor: WidgetStateProperty.all(Colors.transparent),
                  labelColor: isDark
                      ? AppColors.neutral900Dark
                      : AppColors.neutral900,
                  unselectedLabelColor: isDark
                      ? AppColors.neutral400Dark
                      : AppColors.neutral400,
                  labelStyle: GoogleFonts.sarabun(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: GoogleFonts.sarabun(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                  tabs: [
                    Tab(text: '${l.t('bills_tab_draft')} ($draftCount)'),
                    Tab(text: '${l.t('bills_tab_pending')} ($pendingCount)'),
                    Tab(
                        text:
                            '${l.t('bills_tab_completed')} ($completedCount)'),
                  ],
                ),
              ),
            ),

            // ── Ad Banner ────────────────────────────────────────
            const BannerAdWidget(),

            // ── Content ──────────────────────────────────────────
            Expanded(
              child: !allLoaded
                  ? const BillsListSkeleton()
                  : TabBarView(
                      controller: _tabController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _BillList(
                          status: 'draft',
                          view: draftView,
                          emptyEmoji: '🧾',
                          emptyText: l.t('bills_empty_draft'),
                          emptySubtext: l.t('bills_empty_draft_sub'),
                          emptyCtaLabel: l.t('bills_create'),
                          onEmptyCta: _createBill,
                        ),
                        _BillList(
                          status: 'pending_payment',
                          view: pendingView,
                          emptyEmoji: '⏳',
                          emptyText: l.t('bills_empty_pending'),
                          emptySubtext: l.t('bills_empty_pending_sub'),
                        ),
                        _BillList(
                          status: 'completed',
                          view: completedView,
                          emptyEmoji: '✅',
                          emptyText: l.t('bills_empty_completed'),
                          emptySubtext: l.t('bills_empty_completed_sub'),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Animated create button ─────────────────────────────────────────────────────

class _CreateButton extends StatefulWidget {
  const _CreateButton({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_CreateButton> createState() => _CreateButtonState();
}

class _CreateButtonState extends State<_CreateButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: isDark
                ? AppGradients.primaryButtonDark
                : AppGradients.primaryButtonLight,
            borderRadius: BorderRadius.circular(AppRadii.md),
            boxShadow: isDark ? null : const [AppShadows.card],
          ),
          child: const Icon(
            Icons.add_rounded,
            color: AppColors.surface,
            size: 24,
          ),
        ),
      ),
    );
  }
}

// ── Bill List ──────────────────────────────────────────────────
class _BillList extends StatefulWidget {
  final String status;
  final BillsListView view;
  final String emptyText;
  final String emptySubtext;
  final String? emptyEmoji;
  final String? emptyCtaLabel;
  final VoidCallback? onEmptyCta;

  const _BillList({
    required this.status,
    required this.view,
    required this.emptyText,
    required this.emptySubtext,
    this.emptyEmoji,
    this.emptyCtaLabel,
    this.onEmptyCta,
  });

  @override
  State<_BillList> createState() => _BillListState();
}

class _BillListState extends State<_BillList> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels > position.maxScrollExtent - 400) {
      context.read<BillsStore>().loadMore(widget.status);
    }
  }

  Future<void> _onRefresh() async {
    final store = context.read<BillsStore>();
    await Future.wait([
      store.refreshPage(widget.status),
      store.loadStats(force: true),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l = context.watch<LocaleProvider>();
    final bills = widget.view.items;
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final friendUserIds = context
        .read<FriendsStore>()
        .friends
        .map((f) =>
            f.requesterId == currentUserId ? f.addresseeId : f.requesterId)
        .toSet();

    if (bills.isEmpty) {
      return Center(
        child: AppEmptyState(
          icon: Icons.receipt_long_outlined,
          title: widget.emptyText,
          body: widget.emptySubtext,
          ctaLabel: widget.emptyCtaLabel,
          onCta: widget.onEmptyCta,
        ),
      );
    }

    final myBills = bills
        .where((b) => b.groupId == null && b.ownerId == currentUserId)
        .toList();
    final sharedBills = bills
        .where((b) => b.groupId == null && b.ownerId != currentUserId)
        .toList();
    final groupBills = bills.where((b) => b.groupId != null).toList();

    final Map<String, List<Bill>> byGroup = {};
    for (final b in groupBills) {
      byGroup.putIfAbsent(b.groupId!, () => []).add(b);
    }

    final List<_ListItem> items = [];

    if (myBills.isNotEmpty) {
      items.add(_SectionHeader(
          label: l.t('bills_section_standalone'),
          count: myBills.length));
      for (final b in myBills) {
        items.add(_BillEntry(bill: b));
      }
    }

    if (sharedBills.isNotEmpty) {
      items.add(_SectionHeader(
          label: l.t('bills_section_shared'),
          count: sharedBills.length,
          isShared: true));
      for (final b in sharedBills) {
        items.add(_BillEntry(bill: b));
      }
    }

    if (byGroup.isNotEmpty) {
      for (final entry in byGroup.entries) {
        final groupBillList = entry.value;
        final groupName =
            groupBillList.first.groupName ?? l.t('bills_group_fallback');
        final groupEmoji = groupBillList.first.groupEmoji ?? '👥';
        items.add(_SectionHeader(
          label: '$groupEmoji $groupName',
          count: groupBillList.length,
          isGroup: true,
        ));
        for (final b in groupBillList) {
          items.add(_BillEntry(bill: b));
        }
      }
    }

    final showFooter = widget.view.loadingMore || widget.view.hasMore;

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppColors.primary,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          110,
        ),
        itemCount: items.length + (showFooter ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= items.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Center(
                child: widget.view.loadingMore
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const SizedBox.shrink(),
              ),
            );
          }
          final item = items[index];
          if (item is _SectionHeader) {
            return _SectionHeaderWidget(item: item, isDark: isDark);
          }
          final bill = (item as _BillEntry).bill;
          // RepaintBoundary isolates each card so scrolling only repaints
          // the cards that are actually changing, not the entire list.
          return RepaintBoundary(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
              child: SharedBillCard(
                bill: bill,
                onTap: () => context.push('/bills/${bill.id}'),
                currentUserId: currentUserId,
                friendUserIds: friendUserIds,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── List item types ────────────────────────────────────────────
abstract class _ListItem {}

class _SectionHeader extends _ListItem {
  final String label;
  final int count;
  final bool isGroup;
  final bool isShared;
  _SectionHeader({
    required this.label,
    required this.count,
    this.isGroup = false,
    this.isShared = false,
  });
}

class _BillEntry extends _ListItem {
  final Bill bill;
  _BillEntry({required this.bill});
}

class _SectionHeaderWidget extends StatelessWidget {
  final _SectionHeader item;
  final bool isDark;
  const _SectionHeaderWidget({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: AppSpacing.sm + 2,
        top: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: item.isGroup
                  ? AppColors.primaryBlue.withValues(alpha: 0.10)
                  : item.isShared
                      ? AppColors.emerald.withValues(alpha: 0.10)
                      : (isDark ? AppColors.surfaceDark : AppColors.neutral100),
              borderRadius: BorderRadius.circular(AppRadii.full),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item.isGroup
                      ? Icons.group_rounded
                      : item.isShared
                          ? Icons.people_outline_rounded
                          : Icons.receipt_outlined,
                  size: 13,
                  color: item.isGroup
                      ? AppColors.primaryBlue
                      : item.isShared
                          ? AppColors.emerald
                          : (isDark
                              ? AppColors.neutral400Dark
                              : AppColors.neutral400),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  item.label,
                  style: GoogleFonts.sarabun(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: item.isGroup
                        ? AppColors.primaryBlue
                        : item.isShared
                            ? AppColors.emerald
                            : (isDark
                                ? AppColors.neutral600Dark
                                : AppColors.neutral600),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: item.isGroup
                        ? AppColors.primaryBlue.withValues(alpha: 0.15)
                        : item.isShared
                            ? AppColors.emerald.withValues(alpha: 0.15)
                            : (isDark
                                ? AppColors.borderDark
                                : AppColors.neutral100),
                    borderRadius: BorderRadius.circular(AppRadii.full),
                  ),
                  child: Text(
                    '${item.count}',
                    style: GoogleFonts.sarabun(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: item.isGroup
                          ? AppColors.primaryBlue
                          : item.isShared
                              ? AppColors.emerald
                              : (isDark
                                  ? AppColors.neutral400Dark
                                  : AppColors.neutral600),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm + 2),
          Expanded(
            child: Divider(
              color: isDark ? AppColors.borderDark : AppColors.neutral100,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
