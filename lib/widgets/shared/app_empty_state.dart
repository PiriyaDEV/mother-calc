import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';

/// Unified empty state widget used across all screens.
///
/// Flik principle: empty states are first-class UI — they communicate
/// clearly, use a large muted icon, a headline, a body, and an optional CTA.
/// This replaces the 3+ ad-hoc empty state implementations in the codebase.
///
/// Usage:
/// ```dart
/// AppEmptyState(
///   icon: Icons.receipt_long_outlined,
///   title: 'ยังไม่มีบิล',
///   body: 'สร้างบิลแรกของคุณเพื่อเริ่มต้น',
///   ctaLabel: 'สร้างบิล',
///   onCta: () => context.push('/bills/create'),
/// )
/// ```
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.ctaLabel,
    this.onCta,
    this.iconSize = 64.0,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.xxl,
      vertical: AppSpacing.xxxl,
    ),
  });

  final IconData icon;
  final String title;
  final String? body;
  final String? ctaLabel;
  final VoidCallback? onCta;
  final double iconSize;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconBg = isDark ? AppColors.accentIceDark : AppColors.accentIce;
    final iconColor = isDark ? AppColors.primaryBlueDark : AppColors.primaryBlue;
    final titleColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final bodyColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon container — large, tonal background
          Container(
            width: iconSize + 24,
            height: iconSize + 24,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: iconSize * 0.6, color: iconColor),
          ),
          const SizedBox(height: AppSpacing.xl),

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

          // Body
          if (body != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              body!,
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansThai(
                fontSize: 14,
                color: bodyColor,
                height: 1.5,
              ),
            ),
          ],

          // CTA button
          if (ctaLabel != null && onCta != null) ...[
            const SizedBox(height: AppSpacing.xl),
            _EmptyStateCta(label: ctaLabel!, onTap: onCta!, isDark: isDark),
          ],
        ],
      ),
    );
  }
}

class _EmptyStateCta extends StatefulWidget {
  const _EmptyStateCta({
    required this.label,
    required this.onTap,
    required this.isDark,
  });

  final String label;
  final VoidCallback onTap;
  final bool isDark;

  @override
  State<_EmptyStateCta> createState() => _EmptyStateCtaState();
}

class _EmptyStateCtaState extends State<_EmptyStateCta> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
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
            gradient: widget.isDark
                ? AppGradients.primaryButtonDark
                : AppGradients.primaryButtonLight,
            borderRadius: BorderRadius.circular(AppRadii.full),
            boxShadow: widget.isDark
                ? null
                : [
                    BoxShadow(
                      color: AppColors.primaryBlue.withValues(alpha: 0.28),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Text(
            widget.label,
            style: GoogleFonts.notoSansThai(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
