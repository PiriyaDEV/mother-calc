import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kidtang_flutter/models/models.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';
import 'package:kidtang_flutter/utils/bill_utils.dart';

class BillBreakdownCard extends StatelessWidget {
  final BillCalculation calc;
  final Bill bill;
  final bool isDark;

  const BillBreakdownCard({
    super.key,
    required this.calc,
    required this.bill,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final settings = bill.settings;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'รายละเอียดบิล',
            style: GoogleFonts.notoSansThai(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 12),
          _BreakdownRow(
            label: 'ยอดรวมสินค้า',
            value: calc.subtotal,
            currency: settings.currency,
            isDark: isDark,
          ),
          if (settings.isService && calc.serviceAmount > 0)
            _BreakdownRow(
              label:
                  'Service Charge (${settings.serviceCharge.toStringAsFixed(0)}%)',
              value: calc.serviceAmount,
              currency: settings.currency,
              isDark: isDark,
            ),
          if (settings.isVat && calc.vatAmount > 0)
            _BreakdownRow(
              label: 'VAT (${settings.vat.toStringAsFixed(0)}%)',
              value: calc.vatAmount,
              currency: settings.currency,
              isDark: isDark,
            ),
          if (calc.tipAmount > 0)
            _BreakdownRow(
              label: 'ทิป',
              value: calc.tipAmount,
              currency: settings.currency,
              isDark: isDark,
            ),
          if (calc.discountAmount > 0)
            _BreakdownRow(
              label: 'ส่วนลด',
              value: -calc.discountAmount,
              currency: settings.currency,
              isDark: isDark,
              isDiscount: true,
            ),
          Divider(
              height: 16,
              color: isDark ? AppColors.borderDark : AppColors.borderLight),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'รวมทั้งสิ้น',
                style: GoogleFonts.notoSansThai(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              Text(
                '฿${formatNumber(calc.total)}',
                style: GoogleFonts.notoSansThai(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.blue400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final String label;
  final double value;
  final String currency;
  final bool isDark;
  final bool isDiscount;

  const _BreakdownRow({
    required this.label,
    required this.value,
    required this.currency,
    required this.isDark,
    this.isDiscount = false,
  });

  @override
  Widget build(BuildContext context) {
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
            '฿${formatNumber(value.abs())}',
            style: GoogleFonts.notoSansThai(
              fontSize: 13,
              color: isDiscount
                  ? AppColors.emerald600
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
