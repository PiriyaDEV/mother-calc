import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:kidtang_flutter/models/models.dart';
import 'package:kidtang_flutter/stores/bills_store.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';
import 'package:kidtang_flutter/utils/bill_utils.dart';
import 'package:kidtang_flutter/widgets/bill/summary_tab.dart';
import 'empty_state.dart';

/// Stateful so it owns [_expandedBillId] locally — expanding/collapsing a
/// bill row only rebuilds this subtree, not the sibling Members/Bills/Analytics
/// tabs (Phase 1 perf fix #6 from REFACTOR_PLAN.md).
///
/// Also caches [_totalAmount] via [initState]/[didUpdateWidget] so the fold
/// doesn't re-run on every build (perf fix #4).
class GroupSummaryTab extends StatefulWidget {
  final List<Bill> bills;
  final bool isDark;

  const GroupSummaryTab({
    super.key,
    required this.bills,
    required this.isDark,
  });

  @override
  State<GroupSummaryTab> createState() => _GroupSummaryTabState();
}

class _GroupSummaryTabState extends State<GroupSummaryTab> {
  String? _expandedBillId;

  // Cached total — recomputed only when bills actually change.
  late double _totalAmount;

  @override
  void initState() {
    super.initState();
    _recompute();
  }

  @override
  void didUpdateWidget(GroupSummaryTab old) {
    super.didUpdateWidget(old);
    if (!billsEqual(old.bills, widget.bills)) {
      _recompute();
    }
  }

  void _recompute() {
    _totalAmount = widget.bills.fold<double>(0, (sum, b) => sum + b.total);
  }

  void _toggle(String billId) {
    setState(() {
      _expandedBillId = _expandedBillId == billId ? null : billId;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.bills.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GroupDetailEmptyState(
              icon: Icons.bar_chart_rounded,
              label: 'ยังไม่มีบิลในกลุ่ม',
              sub: 'สร้างบิลก่อนเพื่อดูสรุป',
              isDark: widget.isDark,
            ),
          ],
        ),
      );
    }

    // Layout: index 0 is the hero card, indices 1..N are the per-bill
    // collapsible rows — built lazily via ListView.builder so an unbounded
    // bills list doesn't build off-screen rows up front.
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: 1 + widget.bills.length,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4366f4), Color(0xFF6b8aff)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppRadii.xl),
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
                    '${formatNumber(_totalAmount)} บาท',
                    style: GoogleFonts.notoSansThai(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.bills.length} บิล',
                    style: GoogleFonts.notoSansThai(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final bill = widget.bills[index - 1];
        final billTotal = bill.total;
        final isExpanded = _expandedBillId == bill.id;

        return RepaintBoundary(
          child: Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            decoration: BoxDecoration(
              color: widget.isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(
                  color: widget.isDark
                      ? AppColors.borderDark
                      : AppColors.borderLight),
            ),
            child: Column(
              children: [
                // Row header
                GestureDetector(
                  onTap: () => _toggle(bill.id),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: widget.isDark
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
                                  color: widget.isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimaryLight,
                                ),
                              ),
                              Text(
                                '${bill.items.length} รายการ · ${bill.members.length} คน',
                                style: GoogleFonts.notoSansThai(
                                  fontSize: 12,
                                  color: widget.isDark
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
                            color: widget.isDark
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
                          color: widget.isDark
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
                    color: widget.isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                  ),
                  Builder(
                    builder: (ctx) {
                      final calc = calculateBill(bill);
                      return SizedBox(
                        height: 500,
                        child: SummaryTab(
                          bill: bill,
                          billsStore: ctx.read<BillsStore>(),
                          calc: calc,
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
