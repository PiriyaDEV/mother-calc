import 'package:flutter/material.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';

/// AppPopup — Clubhouse-style centered modal dialog.
///
/// Replaces the old bottom-sheet pattern with a clean centered popup:
/// white surface, 20px radius, title bar with × close button.
///
/// Usage:
/// ```dart
/// AppPopup.show(
///   context,
///   title: 'Add Item',
///   child: MyContent(),
/// );
///
/// // Scrollable / tall content:
/// AppPopup.showScrollable(
///   context,
///   title: 'Members',
///   builder: (context, scrollController) => MyScrollableContent(
///     controller: scrollController,
///   ),
/// );
/// ```
///
/// Backward-compat alias: AppBottomSheet = AppPopup
class AppPopup {
  AppPopup._();

  /// Show a centered popup dialog.
  static Future<T?> show<T>(
    BuildContext context, {
    required Widget child,
    String? title,
    bool isDismissible = true,
    EdgeInsetsGeometry contentPadding = const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      0,
      AppSpacing.lg,
      AppSpacing.lg,
    ),
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showDialog<T>(
      context: context,
      barrierDismissible: isDismissible,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => _AppPopupContainer(
        isDark: isDark,
        title: title,
        contentPadding: contentPadding,
        child: child,
      ),
    );
  }

  /// Show a scrollable centered popup dialog — ideal for long lists.
  static Future<T?> showScrollable<T>(
    BuildContext context, {
    required Widget Function(BuildContext context, ScrollController scrollController) builder,
    String? title,
    bool isDismissible = true,
    double maxHeightFraction = 0.85,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showDialog<T>(
      context: context,
      barrierDismissible: isDismissible,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) {
        final scrollController = ScrollController();
        return _AppPopupContainer(
          isDark: isDark,
          title: title,
          maxHeightFraction: maxHeightFraction,
          contentPadding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: builder(ctx, scrollController),
        );
      },
    );
  }
}

/// Backward-compat alias — existing callers of AppBottomSheet still work.
typedef AppBottomSheet = AppPopup;

/// The visual container for all popups.
class _AppPopupContainer extends StatelessWidget {
  const _AppPopupContainer({
    required this.isDark,
    required this.child,
    this.title,
    this.maxHeightFraction = 0.85,
    this.contentPadding = const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      0,
      AppSpacing.lg,
      AppSpacing.lg,
    ),
  });

  final bool isDark;
  final Widget child;
  final String? title;
  final double maxHeightFraction;
  final EdgeInsetsGeometry contentPadding;

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.surfaceDark : AppColors.surfaceWhite;
    final maxHeight = MediaQuery.of(context).size.height * maxHeightFraction;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadii.dialog),
          boxShadow: isDark ? AppColors.shadowCardDark : AppColors.shadowFloat,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header bar ──
            _PopupHeader(isDark: isDark, title: title),

            // ── Content ──
            Flexible(
              child: Padding(
                padding: contentPadding,
                child: child,
              ),
            ),

            // Safe area bottom padding
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}

class _PopupHeader extends StatelessWidget {
  const _PopupHeader({required this.isDark, this.title});

  final bool isDark;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final textColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final iconColor = isDark
        ? AppColors.textTertiaryDark
        : AppColors.textTertiaryLight;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.sm, AppSpacing.sm),
      child: Row(
        children: [
          if (title != null)
            Expanded(
              child: Text(
                title!,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            )
          else
            const Spacer(),
          // Close button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.borderDark
                    : AppColors.bgLight,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close_rounded, size: 18, color: iconColor),
            ),
          ),
        ],
      ),
    );
  }
}
