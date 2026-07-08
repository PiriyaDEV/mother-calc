import 'package:flutter/material.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';

/// Shared bottom sheet helper.
///
/// Flik principle: all bottom sheets share the same visual language —
/// consistent drag handle, top radius, background color, and padding.
/// This eliminates the inconsistent `showModalBottomSheet` calls scattered
/// across the codebase.
///
/// Usage:
/// ```dart
/// AppBottomSheet.show(
///   context,
///   child: MySheetContent(),
/// );
///
/// // Scrollable / tall content:
/// AppBottomSheet.showScrollable(
///   context,
///   builder: (context, scrollController) => MyScrollableContent(
///     controller: scrollController,
///   ),
/// );
/// ```
class AppBottomSheet {
  AppBottomSheet._();

  /// Show a fixed-height bottom sheet with a drag handle.
  static Future<T?> show<T>(
    BuildContext context, {
    required Widget child,
    bool isDismissible = true,
    bool enableDrag = true,
    double? height,
    EdgeInsetsGeometry contentPadding = const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      0,
      AppSpacing.lg,
      AppSpacing.lg,
    ),
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AppBottomSheetContainer(
        isDark: isDark,
        height: height,
        contentPadding: contentPadding,
        child: child,
      ),
    );
  }

  /// Show a draggable scrollable bottom sheet — ideal for long lists.
  static Future<T?> showScrollable<T>(
    BuildContext context, {
    required Widget Function(BuildContext context, ScrollController scrollController) builder,
    bool isDismissible = true,
    double initialChildSize = 0.6,
    double minChildSize = 0.3,
    double maxChildSize = 0.92,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: initialChildSize,
        minChildSize: minChildSize,
        maxChildSize: maxChildSize,
        expand: false,
        builder: (ctx2, scrollController) => _AppBottomSheetContainer(
          isDark: isDark,
          child: builder(ctx2, scrollController),
        ),
      ),
    );
  }
}

/// The visual container for all bottom sheets.
class _AppBottomSheetContainer extends StatelessWidget {
  const _AppBottomSheetContainer({
    required this.isDark,
    required this.child,
    this.height,
    this.contentPadding = const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      0,
      AppSpacing.lg,
      AppSpacing.lg,
    ),
  });

  final bool isDark;
  final Widget child;
  final double? height;
  final EdgeInsetsGeometry contentPadding;

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.surfaceDark : Colors.white;
    final handleColor = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : Colors.black.withValues(alpha: 0.12);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadii.sheet),
        ),
      ),
      child: Column(
        mainAxisSize: height == null ? MainAxisSize.min : MainAxisSize.max,
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: handleColor,
                borderRadius: BorderRadius.circular(AppRadii.full),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Content
          if (height != null)
            Expanded(
              child: Padding(
                padding: contentPadding,
                child: child,
              ),
            )
          else
            Padding(
              padding: contentPadding,
              child: child,
            ),

          // Safe area bottom padding
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
