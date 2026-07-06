import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../stores/bills_store.dart';
import '../theme/app_theme.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/empty_state.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/shared_bill_card.dart';

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
      context.read<BillsStore>().loadAll();
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
    final activeBills = context.select<BillsStore, List<Bill>>((s) => s.activeBills);
    final pendingPaymentBills = context.select<BillsStore, List<Bill>>((s) => s.pendingPaymentBills);
    final completedBills = context.select<BillsStore, List<Bill>>((s) => s.completedBills);
    final allBillsCount = context.select<BillsStore, int>((s) => s.all.length);
    final loading = context.select<BillsStore, bool>((s) => s.loading);
    final hasLoaded = context.select<BillsStore, bool>((s) => s.hasLoaded);

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
                          'บิลของฉัน',
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
                            '$allBillsCount บิลทั้งหมด',
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
                    Tab(text: 'ดราฟ (${activeBills.length})'),
                    Tab(text: 'รอจ่าย (${pendingPaymentBills.length})'),
                    Tab(text: 'เสร็จแล้ว (${completedBills.length})'),
                  ],
                ),
              ),
            ),

            // ── Ad Banner ────────────────────────────────────────
            const BannerAdWidget(),

            // ── Content ──────────────────────────────────────────
            Expanded(
              child: loading && !hasLoaded
                  ? const BillsListSkeleton()
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _BillList(
                          bills: activeBills,
                          emptyEmoji: '🧾',
                          emptyText: 'ยังไม่มีบิล',
                          emptySubtext: 'กดปุ่ม + เพื่อสร้างบิลแรกของคุณ',
                          emptyCtaLabel: 'สร้างบิล',
                          onEmptyCta: _createBill,
                          onRefresh: () => context.read<BillsStore>().loadAll(force: true),
                        ),
                        _BillList(
                          bills: pendingPaymentBills,
                          emptyEmoji: '⏳',
                          emptyText: 'ยังไม่มีบิลที่รอจ่าย',
                          emptySubtext: 'บิลที่ปิดแล้วและรอชำระเงินจะปรากฏที่นี่',
                          onRefresh: () => context.read<BillsStore>().loadAll(force: true),
                        ),
                        _BillList(
                          bills: completedBills,
                          emptyEmoji: '✅',
                          emptyText: 'ยังไม่มีบิลที่เสร็จ',
                          emptySubtext: 'บิลที่ชำระครบแล้วจะปรากฏที่นี่',
                          onRefresh: () => context.read<BillsStore>().loadAll(force: true),
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
class _BillList extends StatelessWidget {
  final List<Bill> bills;
  final String emptyText;
  final String emptySubtext;
  final String? emptyEmoji;
  final String? emptyCtaLabel;
  final VoidCallback? onEmptyCta;
  final Future<void> Function() onRefresh;

  const _BillList({
    required this.bills,
    required this.emptyText,
    required this.emptySubtext,
    this.emptyEmoji,
    this.emptyCtaLabel,
    this.onEmptyCta,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (bills.isEmpty) {
      return EmptyStateWidget(
        emoji: emptyEmoji ?? '🧾',
        title: emptyText,
        subtitle: emptySubtext,
        ctaLabel: emptyCtaLabel,
        onCta: onEmptyCta,
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
      items.add(_SectionHeader(label: 'บิลเดี่ยว', count: standaloneBills.length));
      for (final b in standaloneBills) {
        items.add(_BillEntry(bill: b));
      }
    }

    if (byGroup.isNotEmpty) {
      for (final entry in byGroup.entries) {
        final groupBillList = entry.value;
        final groupName = groupBillList.first.groupName ?? 'กลุ่ม';
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

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
        itemCount: items.length,
        itemBuilder: (context, index) {
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
