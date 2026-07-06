import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../member_avatar.dart';
import 'empty_state.dart';
import 'manage_members_sheet.dart';

class GroupMembersTab extends StatelessWidget {
  final Group group;
  final List<GroupMember> acceptedMembers;
  final List<GroupMember> pendingMembers;
  final bool isDark;

  const GroupMembersTab({
    super.key,
    required this.group,
    required this.acceptedMembers,
    required this.pendingMembers,
    required this.isDark,
  });

  void _showManageMembersSheet(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ManageMembersSheet(
          group: group,
          acceptedMembers: acceptedMembers,
          isDark: isDark,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: 1 + (pendingMembers.isNotEmpty ? 1 : 0) + acceptedMembers.length,
      itemBuilder: (context, index) {
        // Index 0: manage button
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showManageMembersSheet(context),
                icon: const Icon(Icons.people_outline, size: 18),
                label: Text(
                  'จัดการสมาชิก',
                  style: GoogleFonts.notoSansThai(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          );
        }

        // Index 1 (if pending): pending invites banner
        if (pendingMembers.isNotEmpty && index == 1) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.amberFaint,
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(color: AppColors.amberLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'รอตอบรับ ${pendingMembers.length} คน',
                    style: GoogleFonts.notoSansThai(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.amberText,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...pendingMembers.map((m) {
                    final name = m.profile?.displayName ??
                        m.profile?.username ??
                        'ผู้ใช้';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              color: AppColors.amberLight,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                name.isNotEmpty
                                    ? name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.amberText,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            name,
                            style: GoogleFonts.notoSansThai(
                              fontSize: 13,
                              color: AppColors.amberText,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        }

        // Accepted members (or empty state)
        final memberOffset = pendingMembers.isNotEmpty ? 2 : 1;
        final memberIndex = index - memberOffset;

        if (acceptedMembers.isEmpty && memberIndex == 0) {
          return GroupDetailEmptyState(
            icon: Icons.people_outline,
            label: 'ยังไม่มีสมาชิก',
            isDark: isDark,
          );
        }

        if (memberIndex >= acceptedMembers.length) return const SizedBox.shrink();

        final m = acceptedMembers[memberIndex];
        final name = m.name;
        final username = m.profile?.username;
        final avatarUrl = m.profile?.avatarUrl;
        final isOwner = m.role == 'owner';

        return RepaintBoundary(
          child: Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(
                  color: isDark
                      ? AppColors.borderDark
                      : AppColors.borderLight),
            ),
            child: Row(
              children: [
                MemberAvatar(
                  name: name,
                  color: m.isExternal
                      ? AppColors.neutral400
                      : AppColors.primary,
                  size: 36,
                  avatarUrl: avatarUrl,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.notoSansThai(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                      if (username != null)
                        Text(
                          '@$username',
                          style: GoogleFonts.notoSansThai(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiaryLight,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: m.isExternal
                        ? AppColors.neutral100
                        : isOwner
                            ? AppColors.accentIce
                            : AppColors.neutral100,
                    borderRadius: BorderRadius.circular(AppRadii.xl),
                  ),
                  child: Text(
                    m.isExternal
                        ? 'ภายนอก'
                        : isOwner
                            ? 'เจ้าของ'
                            : 'สมาชิก',
                    style: GoogleFonts.notoSansThai(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: m.isExternal
                          ? AppColors.neutral600
                          : isOwner
                              ? AppColors.primaryBlue
                              : AppColors.neutral600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
