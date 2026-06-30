import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'member_avatar.dart';
import 'tag_chip.dart';

class SharedGroupCard extends StatelessWidget {
  final Group group;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const SharedGroupCard({
    super.key,
    required this.group,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final acceptedMembers = group.members.where((m) => m.isAccepted).toList();
    final pendingCount = group.members.where((m) => m.isPending).length;
    final visibleTags = group.tags.take(2).toList();
    final extraTags = group.tags.length > 2 ? group.tags.length - 2 : 0;
    final avatarMembers = acceptedMembers.take(4).toList();
    final extraAvatars = acceptedMembers.length > 4 ? acceptedMembers.length - 4 : 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
          boxShadow: isDark
              ? null
              : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Group emoji icon
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.15),
                        AppColors.primaryLight.withValues(alpha: 0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                  ),
                  child: Center(
                    child: Text(group.emoji ?? '👥', style: const TextStyle(fontSize: 24)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: GoogleFonts.notoSansThai(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.people_outline_rounded, size: 13,
                              color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight),
                          const SizedBox(width: 4),
                          Text(
                            '${acceptedMembers.length} สมาชิก',
                            style: GoogleFonts.notoSansThai(
                              fontSize: 12,
                              color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                            ),
                          ),
                          if (pendingCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'รอ $pendingCount',
                                style: GoogleFonts.notoSansThai(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFD97706),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Action buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: onEdit,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.settings_outlined, size: 16,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: onDelete,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.red.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.red),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Member avatars + tags row
            if (acceptedMembers.isNotEmpty) ...[
              const SizedBox(height: 14),
              Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.borderLight),
              const SizedBox(height: 12),
              Row(
                children: [
                  // Overlapping avatars
                  SizedBox(
                    height: 28,
                    width: avatarMembers.length * 22.0 + (extraAvatars > 0 ? 30 : 0),
                    child: Stack(
                      children: [
                        ...avatarMembers.asMap().entries.map((e) {
                          final member = e.value;
                          final name = member.profile?.displayName ?? member.profile?.username ?? '?';
                          return Positioned(
                            left: e.key * 20.0,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark ? AppColors.surfaceDark : Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: MemberAvatar(
                                name: name,
                                color: AppColors.memberColors[e.key % AppColors.memberColors.length],
                                size: 26,
                                avatarUrl: member.profile?.avatarUrl,
                              ),
                            ),
                          );
                        }),
                        if (extraAvatars > 0)
                          Positioned(
                            left: avatarMembers.length * 20.0,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark ? AppColors.surfaceDark : Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '+$extraAvatars',
                                  style: GoogleFonts.notoSansThai(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Tags
                  ...visibleTags.map((tag) => Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: TagChip(tag: tag, fontSize: 11, borderRadius: 8),
                      )),
                  if (extraTags > 0)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Text(
                        '+$extraTags',
                        style: GoogleFonts.notoSansThai(
                            fontSize: 11,
                            color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight),
                      ),
                    ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded, size: 20,
                      color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
