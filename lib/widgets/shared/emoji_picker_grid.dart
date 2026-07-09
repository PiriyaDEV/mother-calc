import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';
import 'constants.dart';
import 'emoji_text.dart';

/// Emoji picker grid shared by CreateBillScreen and CreateGroupScreen.
/// Includes a [+] button that lets the user type any custom emoji.
class EmojiPickerGrid extends StatefulWidget {
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
  State<EmojiPickerGrid> createState() => _EmojiPickerGridState();
}

class _EmojiPickerGridState extends State<EmojiPickerGrid> {
  bool _showCustomInput = false;
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _confirmCustom() {
    final raw = _controller.text.trim();
    if (raw.isEmpty) {
      setState(() => _showCustomInput = false);
      return;
    }
    // Take only the first emoji/character cluster
    final characters = raw.characters;
    final emoji = characters.isNotEmpty ? characters.first : raw;
    widget.onSelect(emoji);
    _controller.clear();
    setState(() => _showCustomInput = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final bgColor = isDark ? AppColors.bgDark : AppColors.neutral50;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          constraints: const BoxConstraints(maxHeight: 192),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: borderColor),
          ),
          // GridView.builder renders only visible cells instead of building
          // all ~100+ emoji children at once with Wrap.
          // +2 items: index 0 = clear button, last = custom (+) button.
          child: GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 1,
            ),
            itemCount: kEmojiPresets.length + 2,
            itemBuilder: (context, index) {
              // ── Clear button (index 0) ──────────────────────────────
              if (index == 0) {
                return GestureDetector(
                  onTap: widget.onClear,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.neutral100,
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                    child: const Center(
                      child: Text('✕',
                          style: TextStyle(fontSize: 14, color: Colors.grey)),
                    ),
                  ),
                );
              }
              // ── Custom emoji (+) button (last index) ────────────────
              if (index == kEmojiPresets.length + 1) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _showCustomInput = true;
                      _controller.clear();
                    });
                    Future.microtask(() => _focusNode.requestFocus());
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: _showCustomInput
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : (isDark
                              ? AppColors.borderDark
                              : AppColors.neutral100),
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                      border: _showCustomInput
                          ? Border.all(
                              color: AppColors.primary.withValues(alpha: 0.5),
                              width: 1.5)
                          : null,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.add_rounded,
                        size: 18,
                        color: _showCustomInput
                            ? AppColors.primary
                            : (isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight),
                      ),
                    ),
                  ),
                );
              }
              // ── Preset emoji (index 1 … length) ────────────────────
              final e = kEmojiPresets[index - 1];
              final isSelected = widget.selected == e;
              return GestureDetector(
                onTap: () => widget.onSelect(e),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                    border: isSelected
                        ? Border.all(color: AppColors.primary, width: 2)
                        : null,
                  ),
                  child: Center(
                    child: EmojiText(e, fontSize: 18),
                  ),
                ),
              );
            },
          ),
        ),

        // ── Inline custom emoji input ─────────────────────────────────
        if (_showCustomInput)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    style: GoogleFonts.notoSansThai(fontSize: 20),
                    textAlign: TextAlign.center,
                    maxLength: 8, // enough for multi-codepoint emoji
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: 'พิมพ์ emoji...',
                      hintStyle: GoogleFonts.notoSansThai(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiaryLight,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      filled: true,
                      fillColor: isDark
                          ? AppColors.surfaceDark
                          : AppColors.surfaceWhite,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 1.5),
                      ),
                    ),
                    onSubmitted: (_) => _confirmCustom(),
                  ),
                ),
                const SizedBox(width: 8),
                // Confirm button
                GestureDetector(
                  onTap: _confirmCustom,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                    child: const Center(
                      child: Icon(Icons.check_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Cancel button
                GestureDetector(
                  onTap: () {
                    _controller.clear();
                    setState(() => _showCustomInput = false);
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.neutral100,
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                    child: Center(
                      child: Icon(Icons.close_rounded,
                          size: 18,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
