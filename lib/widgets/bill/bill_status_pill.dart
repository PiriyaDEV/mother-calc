import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';

/// BillStatusPill — status pill widget
/// status = 'completed'       → สีเขียว "เสร็จแล้ว"
/// status = 'pending_payment' → สีส้ม   "รอจ่าย"
/// status = 'draft'           → สีเทา   "ดราฟ"
class BillStatusPill extends StatelessWidget {
  final String status;

  const BillStatusPill({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    final Color dotColor;
    final Color textColor;
    final String label;

    if (status == 'completed') {
      bgColor = AppColors.emeraldLight;
      dotColor = AppColors.emerald;
      textColor = AppColors.emeraldText;
      label = 'เสร็จแล้ว';
    } else if (status == 'pending_payment') {
      bgColor = AppColors.amberFaint;
      dotColor = AppColors.amber;
      textColor = AppColors.amberText;
      label = 'รอจ่าย';
    } else {
      bgColor = AppColors.borderLight;
      dotColor = AppColors.textTertiaryLight;
      textColor = AppColors.textSecondaryLight;
      label = 'ดราฟ';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadii.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: GoogleFonts.notoSansThai(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
