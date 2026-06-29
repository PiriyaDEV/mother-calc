import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// showConfirmDialog — reusable confirm dialog
/// danger=true  → confirm button สีแดง
/// danger=false → confirm button สีน้ำเงิน
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String description,
  required String confirmLabel,
  String cancelLabel = 'ยกเลิก',
  bool danger = false,
}) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        title,
        style: GoogleFonts.notoSansThai(
          fontWeight: FontWeight.bold,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        ),
      ),
      content: Text(
        description,
        style: GoogleFonts.notoSansThai(
          color: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(
            cancelLabel,
            style: GoogleFonts.notoSansThai(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(
            confirmLabel,
            style: GoogleFonts.notoSansThai(
              fontWeight: FontWeight.w600,
              color: danger ? AppColors.red : AppColors.primary,
            ),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}
