import 'package:provider/provider.dart';
import 'package:kidtang_flutter/providers/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kidtang_flutter/models/models.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';
import 'package:kidtang_flutter/utils/bill_utils.dart';
import 'package:kidtang_flutter/widgets/shared/member_avatar.dart';

class MemberSelector extends StatelessWidget {
  final List<BillMember> members;
  final String? selectedId;
  final List<String> paidIds;
  final String? currentUserId;
  final ValueChanged<String> onSelect;

  const MemberSelector({
    super.key,
    required this.members,
    required this.selectedId,
    required this.paidIds,
    required this.currentUserId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
      final l = context.watch<LocaleProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.t('summary_view_of'),
          style: GoogleFonts.sarabun(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: members.map((m) {
              final isSelected = selectedId == m.id;
              final isPaid = paidIds.contains(m.id);
              final isMe = m.userId == currentUserId;
              final color = colorFromHex(m.color);

              Color bgColor;
              Color textColor;
              Color? borderColor;

              if (isSelected) {
                bgColor = AppColors.blue500;
                textColor = Colors.white;
                borderColor = null;
              } else if (isPaid) {
                bgColor = AppColors.emerald50;
                textColor = AppColors.emerald700;
                borderColor = AppColors.emerald200;
              } else {
                bgColor = isDark
                    ? AppColors.surfaceDark
                    : AppColors.bgSubtle;
                textColor = isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight;
                borderColor = null;
              }

              return GestureDetector(
                onTap: () => onSelect(m.id),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(AppRadii.xl),
                    border: borderColor != null
                        ? Border.all(color: borderColor)
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MemberAvatar(
                        name: m.name,
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.9)
                            : color,
                        size: 22,
                        avatarUrl: m.profile?.avatarUrl,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        m.name,
                        style: GoogleFonts.sarabun(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.25)
                                : AppColors.blue400.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppRadii.sm),
                          ),
                          child: Text(
                            l.t('member_selector_you'),
                            style: GoogleFonts.sarabun(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.blue400,
                            ),
                          ),
                        ),
                      ],
                      if (isPaid && !isSelected) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.check_rounded,
                            size: 14, color: AppColors.emerald600),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
