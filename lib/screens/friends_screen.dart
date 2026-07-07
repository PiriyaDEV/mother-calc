import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../stores/friends_store.dart';
import '../theme/app_theme.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/friends/index.dart';

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
        content: Text(err, style: GoogleFonts.notoSansThai()),
        backgroundColor: AppColors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        content: Text(err, style: GoogleFonts.notoSansThai()),
        backgroundColor: AppColors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  Future<void> _handleRemove(Friend friend) async {
    final myId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final profile = friend.otherProfile(myId);
    final name = profile?.displayName ?? profile?.username ?? 'เพื่อน';

    final confirmed = await showConfirmDialog(
      context,
      title: 'ลบเพื่อน?',
      description: 'ต้องการลบ $name ออกจากรายชื่อเพื่อนหรือไม่?',
      confirmLabel: 'ลบ',
      danger: true,
    );

    if (confirmed && mounted) {
      await context.read<FriendsStore>().removeFriend(friend.id);
    }
  }

  @override
  Widget build(BuildContext context) {
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
            // ── Header ──────────────────────────────────────
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
                          'เพื่อน',
                          style: GoogleFonts.notoSansThai(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                        Text(
                          requests.isNotEmpty
                              ? '${friends.length} เพื่อน · ${requests.length} คำขอใหม่'
                              : '${friends.length} เพื่อน',
                          style: GoogleFonts.notoSansThai(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.neutral400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() {
                      _showAdd = !_showAdd;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue,
                        borderRadius: BorderRadius.circular(AppRadii.md),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.person_add_outlined,
                              color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'เพิ่มเพื่อน',
                            style: GoogleFonts.notoSansThai(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Add Friend Panel ─────────────────────────────
            // Owns its own TextField state — keystrokes only rebuild the panel.
            if (_showAdd)
              AddFriendPanel(
                isDark: isDark,
                store: provider,
                onClose: () => setState(() => _showAdd = false),
              ),

            // ── Ad Banner ────────────────────────────────────
            const BannerAdWidget(),

            // ── Body ─────────────────────────────────────────
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
                                  title: 'เพื่อนทั้งหมด',
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
                          return FriendRow(
                            friend: f,
                            isDark: isDark,
                            onRemove: () => _handleRemove(f),
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
