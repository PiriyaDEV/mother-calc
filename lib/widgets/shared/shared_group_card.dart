import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:kidtang_flutter/models/models.dart';
import 'package:kidtang_flutter/providers/locale_provider.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';
import 'package:kidtang_flutter/widgets/shared/member_avatar.dart';

class SharedGroupCard extends StatelessWidget {
  final Group group;
  final VoidCallback onTap;

  const SharedGroupCard({
    super.key,
    required this.group,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.watch<LocaleProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final acceptedMembers = group.members.where((m) => m.isAccepted).toList();
    final pendingCount = group.members.where((m) => m.isPending).length;

    return Material(
      color: isDark ? AppColors.surfaceDark : AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.neutral100,
            ),
            boxShadow: isDark ? null : const [AppShadows.card],
          ),
          child: Row(
            children: [
              // ── Emoji icon ──────────────────────────────────────
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primaryBlue.withValues(alpha: 0.15),
                  ),
                ),
                child: Center(
                  child: Text(
                    group.emoji ?? '👥',
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // ── Name + member count ─────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: GoogleFonts.sarabun(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.neutral900Dark
                            : AppColors.neutral900,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          l.t('unit_people').replaceFirst('{count}', '${acceptedMembers.length}'),
                          style: GoogleFonts.sarabun(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.neutral400Dark
                                : AppColors.neutral400,
                          ),
                        ),
                        if (pendingCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.amberLight,
                              borderRadius:
                                  BorderRadius.circular(AppRadii.full),
                            ),
                            child: Text(
                              l.t('group_pending_badge').replaceFirst(
                                  '{count}', '$pendingCount'),
                              style: GoogleFonts.sarabun(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.amberText,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // ── Member avatar stack ─────────────────────────────
              if (acceptedMembers.isNotEmpty)
                MemberAvatarStack(
                  members: acceptedMembers
                      .asMap()
                      .entries
                      .map((e) => (
                            name: e.value.profile?.displayName ??
                                e.value.profile?.username ??
                                '?',
                            color: AppColors.memberColors[
                                e.key % AppColors.memberColors.length],
                            avatarUrl: e.value.profile?.avatarUrl,
                          ))
                      .toList(),
                  size: 26,
                  maxVisible: 4,
                ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: isDark
                    ? AppColors.neutral400Dark
                    : AppColors.neutral400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
