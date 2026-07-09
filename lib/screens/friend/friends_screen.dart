import 'package:kidtang_flutter/providers/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kidtang_flutter/models/models.dart';
import 'package:kidtang_flutter/stores/friends_store.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';
import 'package:kidtang_flutter/widgets/shared/banner_ad_widget.dart';
import 'package:kidtang_flutter/widgets/shared/confirm_dialog.dart';
import 'package:kidtang_flutter/widgets/shared/skeleton_loader.dart';
import 'package:kidtang_flutter/widgets/friends/index.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  bool _showAdd = false;
  String? _respondingId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FriendsStore>().loadFriends();
    });
  }

  Future<void> _handleAccept(Friend friend) async {
    setState(() => _respondingId = friend.id);
    final provider = context.read<FriendsStore>();
    final err = await provider.acceptFriendRequest(friend.id);
    if (!mounted) return;
    setState(() => _respondingId = null);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(err, style: GoogleFonts.sarabun()),
        backgroundColor: AppColors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.sm)),
      ));
    }
  }

  Future<void> _handleDecline(Friend friend) async {
    setState(() => _respondingId = friend.id);
    final provider = context.read<FriendsStore>();
    final err = await provider.declineFriendRequest(friend.id);
    if (!mounted) return;
    setState(() => _respondingId = null);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(err, style: GoogleFonts.sarabun()),
        backgroundColor: AppColors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.sm)),
      ));
    }
  }

  Future<void> _handleRemove(Friend friend) async {
    final l = context.read<LocaleProvider>();
    final myId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final profile = friend.otherProfile(myId);
    final name =
        profile?.displayName ?? profile?.username ?? l.t('friends_tab_label');

    final confirmed = await showConfirmDialog(
      context,
      title: l.t('friends_remove_title'),
      description: l.t('friends_remove_desc').replaceAll('{name}', name),
      confirmLabel: l.t('friends_remove_confirm'),
      danger: true,
    );

    if (confirmed && mounted) {
      await context.read<FriendsStore>().removeFriend(friend.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.watch<LocaleProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // context.select — rebuilds only when friends list or pending requests change.
    final friends = context.select<FriendsStore, List>((s) => s.friends);
    final requests =
        context.select<FriendsStore, List>((s) => s.pendingReceived);
    final provider = context.read<FriendsStore>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.t('friends_tab_label'),
                          style: GoogleFonts.sarabun(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.neutral900Dark
                                : AppColors.neutral900,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          requests.isNotEmpty
                              ? '${friends.length} เพื่อน · ${requests.length} คำขอใหม่'
                              : '${friends.length} เพื่อน',
                          style: GoogleFonts.sarabun(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.neutral400Dark
                                : AppColors.neutral400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Add friend button — animated press feedback
                  _AddFriendButton(
                    label: l.t('friends_add_btn'),
                    active: _showAdd,
                    onTap: () => setState(() => _showAdd = !_showAdd),
                  ),
                ],
              ),
            ),

            // ── Add Friend Panel ─────────────────────────────────
            // Owns its own TextField state — keystrokes only rebuild the panel.
            if (_showAdd)
              AddFriendPanel(
                isDark: isDark,
                store: provider,
                onClose: () => setState(() => _showAdd = false),
              ),

            // ── Ad Banner ────────────────────────────────────────
            const BannerAdWidget(),

            // ── Body ─────────────────────────────────────────────
            Expanded(
              child: provider.loading
                  ? const FriendsListSkeleton()
                  : RefreshIndicator(
                      onRefresh: () => provider.loadFriends(),
                      color: AppColors.primary,
                      // Use ListView.builder so only visible rows are built.
                      // Layout:
                      //   index 0            → pending-requests section (if any)
                      //   index 1            → friends section header
                      //   index 2            → empty state OR first friend row
                      //   index 3..N+1       → remaining friend rows
                      child: ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        itemCount: requests.isNotEmpty
                            ? 2 + (friends.isEmpty ? 1 : friends.length)
                            : 1 + (friends.isEmpty ? 1 : friends.length),
                        itemBuilder: (ctx, index) {
                          // ── Pending Requests block ──
                          if (requests.isNotEmpty) {
                            if (index == 0) {
                              return PendingRequestsCard(
                                requests: List<Friend>.from(requests),
                                respondingId: _respondingId,
                                isDark: isDark,
                                onAccept: _handleAccept,
                                onDecline: _handleDecline,
                              );
                            }
                            // shift remaining indices by 1
                            index -= 1;
                          }

                          // ── Friends section header ──
                          if (index == 0) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FriendsSectionHeader(
                                  title: l.t('friends_title'),
                                  count: friends.length,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                              ],
                            );
                          }

                          // ── Empty state ──
                          if (friends.isEmpty) {
                            return EmptyFriendsState(
                              isDark: isDark,
                              onAdd: () => setState(() => _showAdd = true),
                            );
                          }

                          // ── Friend rows (index 1..N) ──
                          final f = friends[index - 1] as Friend;
                          // RepaintBoundary isolates each row so that
                          // scrolling or updating one row doesn't repaint
                          // the entire list.
                          return RepaintBoundary(
                            child: FriendRow(
                              friend: f,
                              isDark: isDark,
                              onRemove: () => _handleRemove(f),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Animated add-friend button ─────────────────────────────────────────────────

class _AddFriendButton extends StatefulWidget {
  const _AddFriendButton({
    required this.label,
    required this.active,
    required this.onTap,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_AddFriendButton> createState() => _AddFriendButtonState();
}

class _AddFriendButtonState extends State<_AddFriendButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? AppMotion.pressScaleButton : 1.0,
        duration: AppMotion.press,
        curve: AppMotion.standard,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.standard,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            gradient: widget.active
                ? null
                : (isDark
                    ? AppGradients.primaryButtonDark
                    : AppGradients.primaryButtonLight),
            color: widget.active
                ? (isDark ? AppColors.surfaceDark : AppColors.neutral100)
                : null,
            borderRadius: BorderRadius.circular(AppRadii.md),
            boxShadow: widget.active || isDark
                ? null
                : [
                    BoxShadow(
                      color: AppColors.primaryBlue.withValues(alpha: 0.30),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.active
                    ? Icons.close_rounded
                    : Icons.person_add_outlined,
                color: widget.active
                    ? (isDark
                        ? AppColors.neutral400Dark
                        : AppColors.neutral600)
                    : Colors.white,
                size: 16,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                widget.label,
                style: GoogleFonts.sarabun(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: widget.active
                      ? (isDark
                          ? AppColors.neutral400Dark
                          : AppColors.neutral600)
                      : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
