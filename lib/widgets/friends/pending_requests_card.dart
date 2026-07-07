import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kidtang_flutter/providers/locale_provider.dart';
import 'package:kidtang_flutter/models/models.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
    final l = context.watch<LocaleProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FriendsSectionHeader(
          title: l.t('friends_request_label'),
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
              return _RequestTile(
                key: ValueKey(e.value.id),
                request: e.value,
                isLast: e.key == requests.length - 1,
                isResponding: respondingId == e.value.id,
                isDark: isDark,
                onAccept: onAccept,
                onDecline: onDecline,
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

// ── Private extracted tile ────────────────────────────────────────────────────
// Extracted from the inline map() so each row is an independent widget with
// its own RepaintBoundary — only the tapped row rebuilds on isResponding change.
class _RequestTile extends StatelessWidget {
  final Friend request;
  final bool isLast;
  final bool isResponding;
  final bool isDark;
  final void Function(Friend) onAccept;
  final void Function(Friend) onDecline;

  const _RequestTile({
    super.key,
    required this.request,
    required this.isLast,
    required this.isResponding,
    required this.isDark,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final myId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final profile = request.requesterProfile ?? request.otherProfile(myId);
    final name = profile?.displayName ?? profile?.username ?? context.read<LocaleProvider>().t('common_user');
    final username = profile?.username;

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
                  onTap: isResponding ? null : () => onAccept(request),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isResponding
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF286BFE),
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: Colors.white, size: 16),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                GestureDetector(
                  onTap: isResponding ? null : () => onDecline(request),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF374151)
                          : AppColors.borderLight,
                      borderRadius: BorderRadius.circular(AppRadii.md),
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
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
        ],
      ),
    );
  }
}
