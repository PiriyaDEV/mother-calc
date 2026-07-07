import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import 'friends_section_header.dart';
import 'rounded_avatar.dart';

class PendingRequestsCard extends StatelessWidget {
  final List<Friend> requests;
  final String? respondingId;
  final bool isDark;
  final void Function(Friend) onAccept;
  final void Function(Friend) onDecline;

  const PendingRequestsCard({
    super.key,
    required this.requests,
    required this.respondingId,
    required this.isDark,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FriendsSectionHeader(
          title: 'คำขอเป็นเพื่อน',
          count: requests.length,
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
              color: isDark
                  ? AppColors.borderDark
                  : const Color(0xFFDBEAFE),
            ),
          ),
          child: Column(
            children: requests.asMap().entries.map((e) {
              final idx = e.key;
              final req = e.value;
              final myId =
                  Supabase.instance.client.auth.currentUser?.id ?? '';
              final profile =
                  req.requesterProfile ?? req.otherProfile(myId);
              final name =
                  profile?.displayName ?? profile?.username ?? 'ผู้ใช้';
              final username = profile?.username;
              final isResponding = respondingId == req.id;
              final isLast = idx == requests.length - 1;

              return RepaintBoundary(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          RoundedAvatar(
                            name: name,
                            avatarUrl: profile?.avatarUrl,
                            size: 40,
                            radius: 16,
                          ),
                          const SizedBox(width: AppSpacing.md),
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
                          GestureDetector(
                            onTap: isResponding ? null : () => onAccept(req),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isResponding
                                    ? const Color(0xFF9CA3AF)
                                    : const Color(0xFF286BFE),
                                borderRadius:
                                    BorderRadius.circular(AppRadii.md),
                              ),
                              child: const Icon(Icons.check_rounded,
                                  color: Colors.white, size: 16),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          GestureDetector(
                            onTap:
                                isResponding ? null : () => onDecline(req),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF374151)
                                    : AppColors.borderLight,
                                borderRadius:
                                    BorderRadius.circular(AppRadii.md),
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                color: isDark
                                    ? AppColors.textTertiaryDark
                                    : const Color(0xFF6B7280),
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Divider(
                        height: 1,
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}
