import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class ProfileFieldRow extends StatelessWidget {
  final bool isDark;
  final String label;
  final String value;
  final Color? valueColor;
  final bool isEditing;
  final TextEditingController controller;
  final bool saving;
  final String? prefix;
  final String? hintText;
  final List<TextInputFormatter>? inputFormatters;
  final VoidCallback onEdit;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const ProfileFieldRow({
    super.key,
    required this.isDark,
    required this.label,
    required this.value,
    required this.isEditing,
    required this.controller,
    required this.saving,
    required this.onEdit,
    required this.onSave,
    required this.onCancel,
    this.valueColor,
    this.prefix,
    this.hintText,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.notoSansThai(
                    fontSize: 12,
                    color: ThemeColors.textTertiary(isDark),
                  ),
                ),
              ),
              if (!isEditing)
                GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    child: Icon(
                      Icons.edit_outlined,
                      size: 15,
                      color: ThemeColors.textTertiary(isDark),
                    ),
                  ),
                )
              else ...[
                GestureDetector(
                  onTap: saving ? null : onSave,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: saving
                          ? AppColors.textTertiaryLight
                          : AppColors.primary,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    child: saving
                        ? const Center(
                            child: SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            ),
                          )
                        : const Icon(Icons.check_rounded,
                            color: Colors.white, size: 16),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onCancel,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: ThemeColors.textTertiary(isDark),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          if (!isEditing)
            Text(
              value,
              style: GoogleFonts.notoSansThai(
                fontSize: 14,
                color: valueColor ?? ThemeColors.textPrimary(isDark),
              ),
            )
          else
            Row(
              children: [
                if (prefix != null)
                  Text(
                    prefix!,
                    style: GoogleFonts.notoSansThai(
                      fontSize: 14,
                      color: ThemeColors.textTertiary(isDark),
                    ),
                  ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    autofocus: true,
                    inputFormatters: inputFormatters,
                    style: GoogleFonts.notoSansThai(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: hintText,
                      hintStyle: GoogleFonts.notoSansThai(
                        fontSize: 14,
                        color: AppColors.textTertiaryLight,
                      ),
                      isDense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 6),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: ThemeColors.border(isDark),
                        ),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                    ),
                    onSubmitted: (_) => onSave(),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Converts typed text to lowercase on the fly.
class LowercaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toLowerCase());
  }
}
