import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';

/// Polished dialog component following Flik's dialog design language.
///
/// Flik principle: dialogs have a clear visual hierarchy —
/// optional icon at top, bold title, body text, then action buttons.
/// Destructive actions use full-width stacked buttons (not inline TextButtons).
///
/// This upgrades the existing `showConfirmDialog` with better visual polish
/// while keeping the same API surface for backward compatibility.
///
/// Usage:
/// ```dart
/// final confirmed = await AppDialog.showConfirm(
///   context,
///   title: 'ลบบิล',
///   body: 'คุณต้องการลบบิลนี้ใช่ไหม?',
///   confirmLabel: 'ลบ',
///   danger: true,
/// );
/// ```
class AppDialog {
  AppDialog._();

  /// Show a confirm/cancel dialog.
  /// Returns `true` if confirmed, `false` if cancelled.
  static Future<bool> showConfirm(
    BuildContext context, {
    required String title,
    required String body,
    required String confirmLabel,
    String? cancelLabel,
    bool danger = false,
    IconData? icon,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) => _AppConfirmDialog(
        title: title,
        body: body,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel ?? 'ยกเลิก',
        danger: danger,
        icon: icon,
      ),
    );
    return result ?? false;
  }
}

class _AppConfirmDialog extends StatelessWidget {
  const _AppConfirmDialog({
    required this.title,
    required this.body,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.danger,
    this.icon,
  });

  final String title;
  final String body;
  final String confirmLabel;
  final String cancelLabel;
  final bool danger;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.surfaceDark : Colors.white;
    final titleColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final bodyColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderColor =
        isDark ? AppColors.borderDark : AppColors.borderLight;

    final confirmColor = danger
        ? (isDark ? AppColors.redDark : AppColors.red)
        : (isDark ? AppColors.primaryBlueDark : AppColors.primaryBlue);
    final confirmBg = danger
        ? (isDark ? const Color(0xFF2A1A1A) : AppColors.redFaint)
        : (isDark ? AppColors.accentIceDark : AppColors.accentIce);

    // Icon colors
    Color? iconColor;
    Color? iconBg;
    if (icon != null) {
      iconColor = danger
          ? (isDark ? AppColors.redDark : AppColors.red)
          : (isDark ? AppColors.primaryBlueDark : AppColors.primaryBlue);
      iconBg = danger
          ? (isDark ? const Color(0xFF2A1A1A) : AppColors.redFaint)
          : (isDark ? AppColors.accentIceDark : AppColors.accentIce);
    }

    return Dialog(
      backgroundColor: bg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.dialog),
        side: BorderSide(color: borderColor, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Optional icon
            if (icon != null) ...[
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: iconColor),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.anuphan(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: titleColor,
                height: 1.3,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Body
            Text(
              body,
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansThai(
                fontSize: 14,
                color: bodyColor,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Action buttons — stacked for destructive, side-by-side otherwise
            if (danger)
              _StackedActions(
                confirmLabel: confirmLabel,
                cancelLabel: cancelLabel,
                confirmColor: confirmColor,
                confirmBg: confirmBg,
                isDark: isDark,
              )
            else
              _InlineActions(
                confirmLabel: confirmLabel,
                cancelLabel: cancelLabel,
                confirmColor: confirmColor,
                isDark: isDark,
              ),
          ],
        ),
      ),
    );
  }
}

/// Stacked buttons for destructive actions (confirm on top, cancel below).
class _StackedActions extends StatelessWidget {
  const _StackedActions({
    required this.confirmLabel,
    required this.cancelLabel,
    required this.confirmColor,
    required this.confirmBg,
    required this.isDark,
  });

  final String confirmLabel;
  final String cancelLabel;
  final Color confirmColor;
  final Color confirmBg;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final cancelColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Column(
      children: [
        // Confirm (destructive)
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              backgroundColor: confirmBg,
              foregroundColor: confirmColor,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
            ),
            child: Text(
              confirmLabel,
              style: GoogleFonts.notoSansThai(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: confirmColor,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Cancel
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: cancelColor,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
            ),
            child: Text(
              cancelLabel,
              style: GoogleFonts.notoSansThai(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: cancelColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Side-by-side buttons for non-destructive confirmations.
class _InlineActions extends StatelessWidget {
  const _InlineActions({
    required this.confirmLabel,
    required this.cancelLabel,
    required this.confirmColor,
    required this.isDark,
  });

  final String confirmLabel;
  final String cancelLabel;
  final Color confirmColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final cancelColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: cancelColor,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
            ),
            child: Text(
              cancelLabel,
              style: GoogleFonts.notoSansThai(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: cancelColor,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              backgroundColor: isDark
                  ? AppColors.accentIceDark
                  : AppColors.accentIce,
              foregroundColor: confirmColor,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
            ),
            child: Text(
              confirmLabel,
              style: GoogleFonts.notoSansThai(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: confirmColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
