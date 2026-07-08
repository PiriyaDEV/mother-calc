import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';

class ToastBanner extends StatelessWidget {
  final String message;
  final bool isError;
  final bool isDark;
  final VoidCallback? onDismiss;

  const ToastBanner({
    super.key,
    required this.message,
    required this.isError,
    required this.isDark,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isError
        ? (isDark
            ? AppColors.red.withValues(alpha: 0.15)
            : AppColors.redFaint)
        : (isDark
            ? AppColors.emeraldDark.withValues(alpha: 0.15)
            : AppColors.greenFaint);
    final border = isError
        ? AppColors.red.withValues(alpha: 0.3)
        : AppColors.emerald.withValues(alpha: 0.3);
    final textColor = isError
        ? AppColors.red
        : (isDark ? AppColors.emerald : AppColors.emeraldText);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Row(
        children: [
          Icon(
            isError
                ? Icons.error_outline_rounded
                : Icons.check_circle_outline_rounded,
            size: 16,
            color: textColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: GoogleFonts.sarabun(
                    fontSize: 13, color: textColor)),
          ),
          if (onDismiss != null)
            GestureDetector(
              onTap: onDismiss,
              child: Icon(Icons.close_rounded, size: 14, color: textColor),
            ),
        ],
      ),
    );
  }
}
