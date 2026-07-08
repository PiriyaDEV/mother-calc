import 'package:provider/provider.dart';
import 'package:kidtang_flutter/providers/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';
import 'package:kidtang_flutter/utils/bill_utils.dart';
import 'package:kidtang_flutter/widgets/shared/member_avatar.dart';
import 'member_total.dart';
import 'section_card.dart';

class ItemsPerMemberGrid extends StatelessWidget {
  final List<MemberTotal> memberTotals;
  final bool isDark;

  const ItemsPerMemberGrid({
    super.key,
    required this.memberTotals,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
      final l = context.watch<LocaleProvider>();
    return SectionCard(
      isDark: isDark,
      title: l.t('analytics_items_per_member'),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 3.2,
        ),
        itemCount: memberTotals.length,
        itemBuilder: (ctx, i) {
          final mt = memberTotals[i];
          final color = colorFromHex(mt.member.color);
          return RepaintBoundary(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadii.sm),
                border: Border.all(
                  color:
                      isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: Row(
                children: [
                  MemberAvatar(
                    name: mt.member.name,
                    color: color,
                    size: 26,
                    avatarUrl: mt.member.profile?.avatarUrl,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          mt.member.name,
                          style: GoogleFonts.sarabun(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${mt.itemCount} รายการ',
                          style: GoogleFonts.sarabun(
                            fontSize: 10,
                            color: isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.neutral400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
