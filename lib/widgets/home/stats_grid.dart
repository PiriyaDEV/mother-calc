import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../stores/bills_store.dart';
import '../../theme/app_theme.dart';
import '../../utils/bill_utils.dart';

double _billTotal(Bill b) => b.items.fold(0.0, (s, i) => s + i.price);

class StatsGrid extends StatelessWidget {
  final bool isDark;
  const StatsGrid({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Selector<BillsStore, List<Bill>>(
      selector: (_, s) => s.all,
      builder: (context, allBills, _) {
        if (allBills.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }
        final grandTotal =
            allBills.fold<double>(0, (s, b) => s + _billTotal(b));
        final totalItems =
            allBills.fold<int>(0, (s, b) => s + b.items.length);
        final biggestBill =
            allBills.reduce((a, b) => _billTotal(a) >= _billTotal(b) ? a : b);

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.55,
            ),
            delegate: SliverChildListDelegate([
              StatCard(
                icon: Icons.trending_up_rounded,
                label: 'เฉลี่ยต่อบิล',
                value: '฿${formatNumber(grandTotal / allBills.length)}',
                accentColor: AppColors.primaryBlue,
                bgColor:
                    isDark ? AppColors.accentIceDark : AppColors.accentIce,
              ),
              StatCard(
                icon: Icons.receipt_long_rounded,
                label: 'บิลทั้งหมด',
                value: '${allBills.length} บิล',
                accentColor: const Color(0xFF7B5CF6),
                bgColor: isDark
                    ? const Color(0xFF1E1A3A)
                    : const Color(0xFFEDE9FE),
              ),
              StatCard(
                icon: Icons.format_list_bulleted_rounded,
                label: 'รายการทั้งหมด',
                value: '$totalItems รายการ',
                accentColor: AppColors.amber,
                bgColor: isDark
                    ? AppColors.amber.withValues(alpha: 0.12)
                    : AppColors.amberFaint,
              ),
              StatCard(
                icon: Icons.star_rounded,
                label: 'บิลใหญ่สุด',
                value: '฿${formatNumber(_billTotal(biggestBill))}',
                accentColor: AppColors.emerald,
                bgColor: isDark
                    ? AppColors.emerald.withValues(alpha: 0.12)
                    : AppColors.greenFaint,
              ),
            ]),
          ),
        );
      },
    );
  }
}

class StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;
  final Color bgColor;

  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.md),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF2D5BFF).withValues(alpha: 0.07),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Icon(icon, size: 20, color: accentColor),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.anuphan(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.notoSansThai(
                  fontSize: 11,
                  color: isDark
                      ? AppColors.neutral400Dark
                      : AppColors.neutral400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
