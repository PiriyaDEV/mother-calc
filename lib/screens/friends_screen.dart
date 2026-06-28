import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../providers/friends_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/member_avatar.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FriendsProvider>().loadFriends();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<FriendsProvider>();

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
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
                  const Spacer(),
                  IconButton(
                    onPressed: () => _showAddFriendSheet(context),
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.person_add_outlined,
                          color: AppColors.primary, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: provider.loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary, strokeWidth: 2))
                  : RefreshIndicator(
                      onRefresh: () => provider.loadFriends(),
                      color: AppColors.primary,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          // Pending received requests
                          if (provider.pendingReceived.isNotEmpty) ...[
                            _SectionHeader(
                              title: 'คำขอเป็นเพื่อน',
                              count: provider.pendingReceived.length,
                            ),
                            const SizedBox(height: 8),
                            ...provider.pendingReceived.map((f) =>
                                _PendingRequestTile(
                                  friend: f,
                                  onAccept: () async {
                                    final err = await provider
                                        .acceptFriendRequest(f.id);
                                    if (err != null && context.mounted) {
                                      _showSnack(context, err, isError: true);
                                    }
                                  },
                                  onDecline: () async {
                                    final err = await provider
                                        .declineFriendRequest(f.id);
                                    if (err != null && context.mounted) {
                                      _showSnack(context, err, isError: true);
                                    }
                                  },
                                )),
                            const SizedBox(height: 20),
                          ],

                          // Friends list
                          _SectionHeader(
                            title: 'เพื่อนทั้งหมด',
                            count: provider.friends.length,
                          ),
                          const SizedBox(height: 8),
                          if (provider.friends.isEmpty)
                            _EmptyState(
                              emoji: '👥',
                              message: 'ยังไม่มีเพื่อน\nกดปุ่ม + เพื่อเพิ่มเพื่อน',
                            )
                          else
                            ...provider.friends.map((f) => _FriendTile(
                                  friend: f,
                                  onRemove: () =>
                                      _confirmRemove(context, f, provider),
                                )),

                          // Pending sent
                          if (provider.pendingSent.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            _SectionHeader(
                              title: 'คำขอที่ส่งออก',
                              count: provider.pendingSent.length,
                            ),
                            const SizedBox(height: 8),
                            ...provider.pendingSent.map((f) =>
                                _SentRequestTile(
                                  friend: f,
                                  onCancel: () async {
                                    final err = await provider
                                        .declineFriendRequest(f.id);
                                    if (err != null && context.mounted) {
                                      _showSnack(context, err, isError: true);
                                    }
                                  },
                                )),
                          ],
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddFriendSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddFriendSheet(
        onSend: (username) async {
          final provider = context.read<FriendsProvider>();
          final profile = await provider.searchByUsername(username);
          if (profile == null) {
            return 'ไม่พบผู้ใช้ @$username';
          }
          return await provider.sendFriendRequest(profile.id);
        },
      ),
    );
  }

  Future<void> _confirmRemove(
      BuildContext context, Friend friend, FriendsProvider provider) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final _myId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final displayProfile = friend.otherProfile(_myId);
    final name = displayProfile?.displayName ??
        displayProfile?.username ??
        'เพื่อน';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('ลบเพื่อน',
            style: GoogleFonts.notoSansThai(fontWeight: FontWeight.bold)),
        content: Text('ต้องการลบ $name ออกจากรายชื่อเพื่อนหรือไม่?',
            style: GoogleFonts.notoSansThai()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('ยกเลิก',
                style: GoogleFonts.notoSansThai(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('ลบ',
                style: GoogleFonts.notoSansThai(
                    color: AppColors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final err = await provider.removeFriend(friend.id);
      if (err != null && context.mounted) {
        _showSnack(context, err, isError: true);
      }
    }
  }

  void _showSnack(BuildContext context, String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.notoSansThai()),
      backgroundColor: isError ? AppColors.red : AppColors.emerald,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }
}

// ── Section Header ─────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.notoSansThai(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.textTertiaryDark
                : AppColors.textTertiaryLight,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: GoogleFonts.notoSansThai(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Empty State ────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String emoji;
  final String message;
  const _EmptyState({required this.emoji, required this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansThai(
                fontSize: 14,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Friend Tile ────────────────────────────────────────────────
class _FriendTile extends StatelessWidget {
  final Friend friend;
  final VoidCallback onRemove;
  const _FriendTile({required this.friend, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final _myId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final profile = friend.otherProfile(_myId);
    final name =
        profile?.displayName ?? profile?.username ?? 'ผู้ใช้';
    final username = profile?.username;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Row(
        children: [
          MemberAvatar(
            name: name,
            color: AppColors.primary,
            size: 44,
            avatarUrl: profile?.avatarUrl,
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
          IconButton(
            onPressed: onRemove,
            icon: Icon(
              Icons.person_remove_outlined,
              size: 20,
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pending Request Tile ───────────────────────────────────────
class _PendingRequestTile extends StatelessWidget {
  final Friend friend;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  const _PendingRequestTile(
      {required this.friend,
      required this.onAccept,
      required this.onDecline});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final _myId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final profile = friend.requesterProfile ?? friend.otherProfile(_myId);
    final name =
        profile?.displayName ?? profile?.username ?? 'ผู้ใช้';
    final username = profile?.username;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Row(
        children: [
          MemberAvatar(
            name: name,
            color: AppColors.amber,
            size: 44,
            avatarUrl: profile?.avatarUrl,
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
          Row(
            children: [
              GestureDetector(
                onTap: onDecline,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded,
                      color: AppColors.red, size: 18),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onAccept,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: AppColors.emerald,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Sent Request Tile ──────────────────────────────────────────
class _SentRequestTile extends StatelessWidget {
  final Friend friend;
  final VoidCallback onCancel;
  const _SentRequestTile({required this.friend, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final _myId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final profile = friend.otherProfile(_myId);
    final name =
        profile?.displayName ?? profile?.username ?? 'ผู้ใช้';
    final username = profile?.username;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Row(
        children: [
          MemberAvatar(
            name: name,
            color: AppColors.primary,
            size: 44,
            avatarUrl: profile?.avatarUrl,
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
                Text(
                  'รอการตอบรับ',
                  style: GoogleFonts.notoSansThai(
                    fontSize: 11,
                    color: AppColors.amber,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onCancel,
            child: Text(
              'ยกเลิก',
              style: GoogleFonts.notoSansThai(
                fontSize: 12,
                color: AppColors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Add Friend Sheet ───────────────────────────────────────────
class _AddFriendSheet extends StatefulWidget {
  final Future<String?> Function(String username) onSend;
  const _AddFriendSheet({required this.onSend});

  @override
  State<_AddFriendSheet> createState() => _AddFriendSheetState();
}

class _AddFriendSheetState extends State<_AddFriendSheet> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final username = _ctrl.text.trim().replaceAll('@', '');
    if (username.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });
    final err = await widget.onSend(username);
    if (mounted) {
      setState(() {
        _loading = false;
        if (err != null) {
          _error = err;
        } else {
          _success = 'ส่งคำขอเป็นเพื่อนแล้ว!';
          _ctrl.clear();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'เพิ่มเพื่อน',
              style: GoogleFonts.notoSansThai(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'ค้นหาด้วย username',
              style: GoogleFonts.notoSansThai(
                fontSize: 13,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ctrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '@username',
                prefixIcon: const Icon(Icons.alternate_email_rounded,
                    color: AppColors.primary, size: 20),
              ),
              onSubmitted: (_) => _send(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!,
                  style: GoogleFonts.notoSansThai(
                      fontSize: 13, color: AppColors.red)),
            ],
            if (_success != null) ...[
              const SizedBox(height: 10),
              Text(_success!,
                  style: GoogleFonts.notoSansThai(
                      fontSize: 13, color: AppColors.emerald)),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : _send,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text('ส่งคำขอ',
                      style: GoogleFonts.notoSansThai(
                          fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
