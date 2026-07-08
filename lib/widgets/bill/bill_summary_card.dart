import 'package:provider/provider.dart';
import 'package:kidtang_flutter/providers/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kidtang_flutter/models/models.dart';
import 'package:kidtang_flutter/utils/bill_utils.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';

class BillSummaryCard extends StatelessWidget {
  final BillCalculation calc;
  final String currency;

  const BillSummaryCard({super.key, required this.calc, required this.currency});

  @override
  Widget build(BuildContext context) {
      final l = context.watch<LocaleProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        children: [
          _SummaryRow(
              label: l.t('summary_subtotal'),
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
                label: l.t('summary_tip'), value: calc.tipAmount, currency: currency),
          if (calc.discountAmount > 0)
            _SummaryRow(
                label: l.t('summary_discount'),
                value: -calc.discountAmount,
                currency: currency,
                isDiscount: true),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l.t('summary_grand_total'),
                style: GoogleFonts.sarabun(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              Text(
                '${formatNumber(calc.total)} $currency',
                style: GoogleFonts.sarabun(
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
            style: GoogleFonts.sarabun(
              fontSize: 13,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          Text(
            '${isDiscount ? '-' : ''}${formatNumber(value.abs())} $currency',
            style: GoogleFonts.sarabun(
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
