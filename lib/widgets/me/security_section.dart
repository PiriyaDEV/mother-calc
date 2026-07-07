import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../section_header.dart';
import 'password_field.dart';

class SecuritySection extends StatelessWidget {
  final bool isDark;
  final bool editingPassword;
  final bool saving;
  final TextEditingController newPassCtrl;
  final TextEditingController confirmPassCtrl;
  final VoidCallback onToggleEdit;
  final VoidCallback onSave;

  const SecuritySection({
    super.key,
    required this.isDark,
    required this.editingPassword,
    required this.saving,
    required this.newPassCtrl,
    required this.confirmPassCtrl,
    required this.onToggleEdit,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeaderWidget(label: 'ความปลอดภัย'),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'เปลี่ยนรหัสผ่าน',
                        style: GoogleFonts.notoSansThai(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: onToggleEdit,
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
                          editingPassword
                              ? Icons.close_rounded
                              : Icons.edit_outlined,
                          size: 15,
                          color: isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (editingPassword) ...[
                Divider(
                    height: 1,
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      PasswordField(
                        controller: newPassCtrl,
                        hint: 'รหัสผ่านใหม่',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 10),
                      PasswordField(
                        controller: confirmPassCtrl,
                        hint: 'ยืนยันรหัสผ่านใหม่',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 14),
                      GestureDetector(
                        onTap: saving ? null : onSave,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md),
                          decoration: BoxDecoration(
                            color: saving
                                ? AppColors.textTertiaryLight
                                : AppColors.primary,
                            borderRadius:
                                BorderRadius.circular(AppRadii.md),
                          ),
                          child: Center(
                            child: Text(
                              saving ? 'กำลังบันทึก...' : 'บันทึก',
                              style: GoogleFonts.notoSansThai(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
