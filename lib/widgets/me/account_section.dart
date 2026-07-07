import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../section_header.dart';
import 'profile_field_row.dart';

class AccountSection extends StatelessWidget {
  final bool isDark;
  final Profile? profile;

  // Name field
  final bool editingName;
  final TextEditingController nameCtrl;
  final bool saving;
  final VoidCallback onEditName;
  final VoidCallback onSaveName;
  final VoidCallback onCancelName;

  // Username field
  final bool editingUsername;
  final TextEditingController usernameCtrl;
  final VoidCallback onEditUsername;
  final VoidCallback onSaveUsername;
  final VoidCallback onCancelUsername;

  // Promptpay field
  final bool editingPromptpay;
  final TextEditingController promptpayCtrl;
  final VoidCallback onEditPromptpay;
  final VoidCallback onSavePromptpay;
  final VoidCallback onCancelPromptpay;

  const AccountSection({
    super.key,
    required this.isDark,
    required this.profile,
    required this.editingName,
    required this.nameCtrl,
    required this.saving,
    required this.onEditName,
    required this.onSaveName,
    required this.onCancelName,
    required this.editingUsername,
    required this.usernameCtrl,
    required this.onEditUsername,
    required this.onSaveUsername,
    required this.onCancelUsername,
    required this.editingPromptpay,
    required this.promptpayCtrl,
    required this.onEditPromptpay,
    required this.onSavePromptpay,
    required this.onCancelPromptpay,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeaderWidget(label: 'บัญชี'),
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
              ProfileFieldRow(
                isDark: isDark,
                label: 'ชื่อที่แสดง',
                value: profile?.displayName ?? '',
                isEditing: editingName,
                controller: nameCtrl,
                saving: saving,
                onEdit: onEditName,
                onSave: onSaveName,
                onCancel: onCancelName,
              ),
              Divider(
                  height: 1,
                  color: isDark
                      ? AppColors.borderDark
                      : AppColors.borderLight),
              ProfileFieldRow(
                isDark: isDark,
                label: 'Username',
                value: '@${profile?.username ?? ''}',
                isEditing: editingUsername,
                controller: usernameCtrl,
                saving: saving,
                prefix: '@',
                inputFormatters: [LowercaseFormatter()],
                onEdit: onEditUsername,
                onSave: onSaveUsername,
                onCancel: onCancelUsername,
              ),
              Divider(
                  height: 1,
                  color: isDark
                      ? AppColors.borderDark
                      : AppColors.borderLight),
              ProfileFieldRow(
                isDark: isDark,
                label: 'พร้อมเพย์ (ใช้เป็น default ในบิล)',
                value: profile?.promptpay != null &&
                        profile!.promptpay!.isNotEmpty
                    ? '📱 ${profile!.promptpay}'
                    : 'ยังไม่ได้ตั้งค่า',
                valueColor: profile?.promptpay == null ||
                        profile!.promptpay!.isEmpty
                    ? AppColors.textTertiaryLight
                    : null,
                isEditing: editingPromptpay,
                controller: promptpayCtrl,
                saving: saving,
                hintText: 'เบอร์โทร หรือ เลขบัตรประชาชน',
                onEdit: onEditPromptpay,
                onSave: onSavePromptpay,
                onCancel: onCancelPromptpay,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
