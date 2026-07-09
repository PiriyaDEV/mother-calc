import 'package:provider/provider.dart';
import 'package:kidtang_flutter/providers/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kidtang_flutter/models/models.dart';
import 'package:kidtang_flutter/stores/bills_store.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';
import 'analytics_tab/biggest_spender_card.dart';
import 'analytics_tab/fairness_card.dart';
import 'analytics_tab/items_per_member_grid.dart';
import 'analytics_tab/member_spending_list.dart';
import 'analytics_tab/member_total.dart';
import 'analytics_tab/pie_chart_card.dart';
import 'analytics_tab/stats_row.dart';
import 'analytics_tab/top_items_card.dart';

export 'analytics_tab/biggest_spender_card.dart';
export 'analytics_tab/fairness_card.dart';
export 'analytics_tab/items_per_member_grid.dart';
export 'analytics_tab/member_spending_list.dart';
export 'analytics_tab/member_total.dart';
export 'analytics_tab/pie_chart_card.dart';
export 'analytics_tab/section_card.dart';
export 'analytics_tab/stats_row.dart';
export 'analytics_tab/top_items_card.dart';

class AnalyticsTab extends StatelessWidget {
  final Bill bill;
  final BillsStore billsStore;
  final BillCalculation calc;

  const AnalyticsTab({
    super.key,
    required this.bill,
    required this.billsStore,
    required this.calc,
  });

  @override
  Widget build(BuildContext context) {
      final l = context.watch<LocaleProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final members = bill.members;
    final items = bill.items;

    if (items.isEmpty || members.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: const Center(
                child: Text('📊', style: TextStyle(fontSize: 36)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l.t('analytics_add_first'),
              style: GoogleFonts.sarabun(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l.t('analytics_no_data'),
              style: GoogleFonts.sarabun(
                fontSize: 13,
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight,
              ),
            ),
          ],
        ),
      );
    }

    final avgPerPerson =
        members.isNotEmpty ? calc.total / members.length : 0.0;

    final memberTotals = calc.memberSummaries
        .map((s) => MemberTotal(
              member: s.member,
              total: s.total,
              itemCount: s.items.length,
            ))
        .toList()
      ..sort((a, b) => b.total.compareTo(a.total));

    final biggestPayer = memberTotals.isNotEmpty ? memberTotals.first : null;
    final smallestPayer = memberTotals.isNotEmpty ? memberTotals.last : null;

    final topItems =
        (List<BillItem>.from(items)..sort((a, b) => b.price.compareTo(a.price)))
            .take(5)
            .toList();
    final maxItemPrice = topItems.isNotEmpty ? topItems.first.price : 1.0;

    // Wrap each heavy analytics card in RepaintBoundary so that
    // animating one card does not repaint the others.
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Stats Row ──────────────────────────────────────────
        RepaintBoundary(
          child: StatsRow(
            itemCount: items.length,
            memberCount: members.length,
            avgPerPerson: avgPerPerson,
          ),
        ),
        const SizedBox(height: 16),

        // ── Pie Chart - Member Spending ────────────────────────
        RepaintBoundary(
          child: PieChartCard(
            memberTotals: memberTotals,
            total: calc.total,
            isDark: isDark,
          ),
        ),
        const SizedBox(height: 12),

        // ── Biggest Spender ────────────────────────────────────
        if (biggestPayer != null) ...[
          RepaintBoundary(
            child: BiggestSpenderCard(payer: biggestPayer, total: calc.total),
          ),
          const SizedBox(height: 12),
        ],

        // ── Member Spending Bars ───────────────────────────────
        RepaintBoundary(
          child: MemberSpendingList(
            memberTotals: memberTotals,
            billTotal: calc.total,
            isDark: isDark,
          ),
        ),
        const SizedBox(height: 12),

        // ── Top Items Bar Chart ────────────────────────────────
        RepaintBoundary(
          child: TopItemsCard(
            topItems: topItems,
            maxItemPrice: maxItemPrice,
            isDark: isDark,
          ),
        ),
        const SizedBox(height: 12),

        // ── Fairness Section ───────────────────────────────────
        if (memberTotals.length >= 2 &&
            biggestPayer != null &&
            smallestPayer != null) ...[
          RepaintBoundary(
            child: FairnessCard(
              biggestPayer: biggestPayer,
              smallestPayer: smallestPayer,
              avgPerPerson: avgPerPerson,
              isDark: isDark,
            ),
          ),
          const SizedBox(height: 12),
        ],

        // ── Items Per Member ───────────────────────────────────
        RepaintBoundary(
          child: ItemsPerMemberGrid(
            memberTotals: memberTotals,
            isDark: isDark,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
