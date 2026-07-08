import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';

/// Unified error state widget used across all screens.
///
/// Flik principle: error states mirror empty states structurally —
/// same layout, same visual weight — but use a warning icon and
/// always include a retry action.
///
/// Usage:
/// ```dart
/// AppErrorState(
///   message: 'โหลดข้อมูลไม่สำเร็จ',
///   onRetry: () => _loadData(force: true),
/// )
/// ```
class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    this.message = 'เกิดข้อผิดพลาด กรุณาลองใหม่',
    this.retryLabel = 'ลองใหม่',
    this.onRetry,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.xxl,
      vertical: AppSpacing.xxxl,
    ),
  });

  final String message;
  final String retryLabel;
  final VoidCallback? onRetry;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconBg = isDark
        ? const Color(0xFF2A1A1A)
        : AppColors.redFaint;
    final iconColor = isDark ? AppColors.redDark : AppColors.red;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final bodyColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Error icon
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: 40,
              color: iconColor,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Title
          Text(
            'เกิดข้อผิดพลาด',
            textAlign: TextAlign.center,
            style: GoogleFonts.anuphan(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textColor,
              height: 1.3,
            ),
          ),

          // Message
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSansThai(
              fontSize: 14,
              color: bodyColor,
              height: 1.5,
            ),
          ),

          // Retry button
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.xl),
            _RetryButton(label: retryLabel, onTap: onRetry!, isDark: isDark),
          ],
        ],
      ),
    );
  }
}

class _RetryButton extends StatefulWidget {
  const _RetryButton({
    required this.label,
    required this.onTap,
    required this.isDark,
  });

  final String label;
  final VoidCallback onTap;
  final bool isDark;

  @override
  State<_RetryButton> createState() => _RetryButtonState();
}

class _RetryButtonState extends State<_RetryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final borderColor =
        widget.isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor =
        widget.isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? AppMotion.pressScaleButton : 1.0,
        duration: AppMotion.press,
        curve: AppMotion.standard,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadii.full),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.refresh_rounded,
                size: 16,
                color: textColor,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                widget.label,
                style: GoogleFonts.notoSansThai(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
