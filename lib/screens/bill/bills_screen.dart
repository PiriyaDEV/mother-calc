import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:kidtang_flutter/models/models.dart';
import 'package:kidtang_flutter/stores/bills_store.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';
import 'package:kidtang_flutter/widgets/shared/banner_ad_widget.dart';
import 'package:kidtang_flutter/widgets/shared/empty_state.dart';
import 'package:kidtang_flutter/widgets/shared/skeleton_loader.dart';
import 'package:kidtang_flutter/providers/locale_provider.dart';
import 'package:kidtang_flutter/widgets/shared/shared_bill_card.dart';

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
    final allLoaded = draftView.loaded && pendingView.loaded && completedView.loaded;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.t('bills_title'),
                          style: GoogleFonts.anuphan(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.neutral900Dark
                                : AppColors.neutral900,
                            height: 1.1,
                          ),
                        ),
                        if (allBillsCount > 0) ...[
                          const SizedBox(height: 2),
                          Text(
                            '$allBillsCount ${l.t('nav_bills')}',
                            style: GoogleFonts.notoSansThai(
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
                  GestureDetector(
                    onTap: _createBill,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: AppGradients.primaryButtonLight,
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryBlue.withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Tabs ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Container(
                height: 44,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.neutral100,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: isDark ? AppColors.bgDark : Colors.white,
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
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
                  labelStyle: GoogleFonts.notoSansThai(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: GoogleFonts.notoSansThai(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                  tabs: [
                    Tab(text: '${l.t('bills_tab_draft')} ($draftCount)'),
                    Tab(text: '${l.t('bills_tab_pending')} ($pendingCount)'),
                    Tab(text: '${l.t('bills_tab_completed')} ($completedCount)'),
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

    if (bills.isEmpty) {
      return EmptyStateWidget(
        emoji: widget.emptyEmoji ?? '🧾',
        title: widget.emptyText,
        subtitle: widget.emptySubtext,
        ctaLabel: widget.emptyCtaLabel,
        onCta: widget.onEmptyCta,
      );
    }

    final standaloneBills = bills.where((b) => b.groupId == null).toList();
    final groupBills = bills.where((b) => b.groupId != null).toList();

    final Map<String, List<Bill>> byGroup = {};
    for (final b in groupBills) {
      byGroup.putIfAbsent(b.groupId!, () => []).add(b);
    }

    final List<_ListItem> items = [];

    if (standaloneBills.isNotEmpty) {
      items.add(_SectionHeader(label: l.t('bills_section_standalone'), count: standaloneBills.length));
      for (final b in standaloneBills) {
        items.add(_BillEntry(bill: b));
      }
    }

    if (byGroup.isNotEmpty) {
      for (final entry in byGroup.entries) {
        final groupBillList = entry.value;
        final groupName = groupBillList.first.groupName ?? l.t('bills_group_fallback');
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
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
        itemCount: items.length + (showFooter ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= items.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
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
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SharedBillCard(
              bill: bill,
              onTap: () => context.push('/bills/${bill.id}'),
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
  _SectionHeader({required this.label, required this.count, this.isGroup = false});
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
      padding: const EdgeInsets.only(bottom: 10, top: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: item.isGroup
                  ? AppColors.primaryBlue.withValues(alpha: 0.10)
                  : (isDark ? AppColors.surfaceDark : AppColors.neutral100),
              borderRadius: BorderRadius.circular(AppRadii.full),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item.isGroup ? Icons.group_rounded : Icons.receipt_outlined,
                  size: 13,
                  color: item.isGroup
                      ? AppColors.primaryBlue
                      : (isDark
                          ? AppColors.neutral400Dark
                          : AppColors.neutral400),
                ),
                const SizedBox(width: 5),
                Text(
                  item.label,
                  style: GoogleFonts.notoSansThai(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: item.isGroup
                        ? AppColors.primaryBlue
                        : (isDark
                            ? AppColors.neutral600Dark
                            : AppColors.neutral600),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: item.isGroup
                        ? AppColors.primaryBlue.withValues(alpha: 0.15)
                        : (isDark ? AppColors.borderDark : AppColors.neutral100),
                    borderRadius: BorderRadius.circular(AppRadii.full),
                  ),
                  child: Text(
                    '${item.count}',
                    style: GoogleFonts.notoSansThai(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: item.isGroup
                          ? AppColors.primaryBlue
                          : (isDark
                              ? AppColors.neutral400Dark
                              : AppColors.neutral600),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
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
