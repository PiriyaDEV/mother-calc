import 'package:provider/provider.dart';
import 'package:kidtang_flutter/providers/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:kidtang_flutter/models/models.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';
import 'package:kidtang_flutter/widgets/shared/section_header.dart';
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
      final l = context.watch<LocaleProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeaderWidget(label: l.t('me_account')),
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
                label: l.t('profile_display_name'),
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
                label: l.t('me_promptpay_label'),
                value: profile?.promptpay != null &&
                        profile!.promptpay!.isNotEmpty
                    ? '📱 ${profile!.promptpay}'
                    : l.t('me_not_set'),
                valueColor: profile?.promptpay == null ||
                        profile!.promptpay!.isEmpty
                    ? AppColors.textTertiaryLight
                    : null,
                isEditing: editingPromptpay,
                controller: promptpayCtrl,
                saving: saving,
                hintText: l.t('me_promptpay_hint_short'),
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
