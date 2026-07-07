import 'package:flutter/material.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';
import 'bill_form_constants.dart';

/// Emoji picker grid shared by CreateBillScreen and CreateGroupScreen.
class EmojiPickerGrid extends StatelessWidget {
  final String? selected;
  final bool isDark;
  final void Function(String) onSelect;
  final VoidCallback onClear;

  const EmojiPickerGrid({
    super.key,
    required this.selected,
    required this.isDark,
    required this.onSelect,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 192),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgDark : AppColors.neutral50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            GestureDetector(
              onTap: onClear,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.borderDark : AppColors.neutral100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text('✕',
                      style: TextStyle(fontSize: 14, color: Colors.grey)),
                ),
              ),
            ),
            ...kEmojiPresets.map((e) {
              final isSelected = selected == e;
              return GestureDetector(
                onTap: () => onSelect(e),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected
                        ? Border.all(color: AppColors.primary, width: 2)
                        : null,
                  ),
                  child: Center(
                    child: Text(e, style: const TextStyle(fontSize: 18)),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
