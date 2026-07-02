import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../stores/friends_store.dart';
import '../theme/app_theme.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/confirm_dialog.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  bool _showAdd = false;
  final _addCtrl = TextEditingController();
  bool _addLoading = false;
  String _addError = '';
  String _addSuccess = '';
  String? _respondingId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FriendsStore>().loadFriends();
    });
  }

  @override
  void dispose() {
    _addCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSendRequest() async {
    final username = _addCtrl.text.trim().replaceAll('@', '');
    if (username.isEmpty) return;
    setState(() {
      _addLoading = true;
      _addError = '';
      _addSuccess = '';
    });
    final provider = context.read<FriendsStore>();
    final profile = await provider.searchByUsername(username);
    if (!mounted) return;
    if (profile == null) {
      setState(() {
        _addLoading = false;
        _addError = 'ไม่พบผู้ใช้ @$username';
      });
      return;
    }
    final err = await provider.sendFriendRequest(profile.id);
    if (!mounted) return;
    setState(() {
      _addLoading = false;
      if (err != null) {
        _addError = err;
      } else {
        _addSuccess = 'ส่งคำขอเป็นเพื่อนไปยัง @$username แล้ว!';
        _addCtrl.clear();
      }
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
    final provider = context.watch<FriendsStore>();
    final friends = provider.friends;
    final requests = provider.pendingReceived;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
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
                      _addError = '';
                      _addSuccess = '';
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

            // ── Add Friend Panel (inline) ─────────────────
            if (_showAdd)
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(AppRadii.lg),
                    border: Border.all(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.neutral100,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'เพิ่มเพื่อนใหม่',
                              style: GoogleFonts.notoSansThai(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _showAdd = false),
                            child: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: isDark
                                  ? AppColors.textTertiaryDark
                                  : AppColors.neutral400,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: Stack(
                              alignment: Alignment.centerLeft,
                              children: [
                                TextField(
                                  controller: _addCtrl,
                                  autofocus: true,
                                  style: GoogleFonts.notoSansThai(
                                      fontSize: 14),
                                  decoration: InputDecoration(
                                    hintText: '@username',
                                    hintStyle: GoogleFonts.notoSansThai(
                                      fontSize: 14,
                                      color: AppColors.neutral400,
                                    ),
                                    contentPadding:
                                        const EdgeInsets.fromLTRB(
                                            36, 10, 12, 10),
                                    filled: true,
                                    fillColor: isDark
                                        ? AppColors.surfaceDark
                                        : AppColors.neutral50,
                                    border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(AppRadii.md),
                                      borderSide: BorderSide(
                                        color: isDark
                                            ? AppColors.borderDark
                                            : AppColors.borderLight,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(AppRadii.md),
                                      borderSide: BorderSide(
                                        color: isDark
                                            ? AppColors.borderDark
                                            : AppColors.borderLight,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(AppRadii.md),
                                      borderSide: const BorderSide(
                                          color: Color(0xFF286BFE)),
                                    ),
                                  ),
                                  onChanged: (v) {
                                    // strip @ prefix automatically
                                    if (v.startsWith('@')) {
                                      _addCtrl.value = TextEditingValue(
                                        text: v.substring(1),
                                        selection: TextSelection.collapsed(
                                            offset: v.length - 1),
                                      );
                                    }
                                  },
                                  onSubmitted: (_) => _handleSendRequest(),
                                ),
                                const Padding(
                                  padding: EdgeInsets.only(left: 10),
                                  child: Icon(Icons.search_rounded,
                                      size: 16,
                                      color: Color(0xFF9CA3AF)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          GestureDetector(
                            onTap: _addLoading ||
                                    _addCtrl.text.trim().isEmpty
                                ? null
                                : _handleSendRequest,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg, vertical: 10),
                              decoration: BoxDecoration(
                                color: _addCtrl.text.trim().isEmpty
                                    ? AppColors.neutral400
                                    : AppColors.primaryBlue,
                                borderRadius: BorderRadius.circular(AppRadii.md),
                              ),
                              child: _addLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white),
                                    )
                                  : Text(
                                      'ส่ง',
                                      style: GoogleFonts.notoSansThai(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                      if (_addError.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(AppRadii.md),
                          ),
                          child: Text(
                            _addError,
                            style: GoogleFonts.notoSansThai(
                              fontSize: 12,
                              color: const Color(0xFFEF4444),
                            ),
                          ),
                        ),
                      ],
                      if (_addSuccess.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(AppRadii.md),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_rounded,
                                  size: 14,
                                  color: Color(0xFF16A34A)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _addSuccess,
                                  style: GoogleFonts.notoSansThai(
                                    fontSize: 12,
                                    color: const Color(0xFF16A34A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

            // ── Ad Banner ────────────────────────────────────────
            const BannerAdWidget(),

            // ── Body ─────────────────────────────────────────
            Expanded(
              child: provider.loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary, strokeWidth: 2))
                  : RefreshIndicator(
                      onRefresh: () => provider.loadFriends(),
                      color: AppColors.primary,
                      child: ListView(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        children: [
                          // ── Pending Requests ──
                          if (requests.isNotEmpty) ...[
                            _SectionHeader(
                              title: 'คำขอเป็นเพื่อน',
                              count: requests.length,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Container(
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.surfaceDark
                                    : Colors.white,
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
                                  final myId = Supabase.instance.client.auth
                                          .currentUser?.id ??
                                      '';
                                  final profile = req.requesterProfile ??
                                      req.otherProfile(myId);
                                  final name = profile?.displayName ??
                                      profile?.username ??
                                      'ผู้ใช้';
                                  final username = profile?.username;
                                  final isResponding =
                                      _respondingId == req.id;
                                  final isLast =
                                      idx == requests.length - 1;

                                  return Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: Row(
                                          children: [
                                            // Avatar (rounded rect 16)
                                            _RoundedAvatar(
                                              name: name,
                                              avatarUrl: profile?.avatarUrl,
                                              size: 40,
                                              radius: 16,
                                            ),
                                            const SizedBox(width: AppSpacing.md),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment
                                                        .start,
                                                children: [
                                                  Text(
                                                    name,
                                                    style: GoogleFonts
                                                        .notoSansThai(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: isDark
                                                          ? AppColors
                                                              .textPrimaryDark
                                                          : AppColors
                                                              .textPrimaryLight,
                                                    ),
                                                  ),
                                                  if (username != null)
                                                    Text(
                                                      '@$username',
                                                      style: GoogleFonts
                                                          .notoSansThai(
                                                        fontSize: 12,
                                                        color: isDark
                                                            ? AppColors
                                                                .textTertiaryDark
                                                            : AppColors
                                                                .textTertiaryLight,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            // ✓ Accept
                                            GestureDetector(
                                              onTap: isResponding
                                                  ? null
                                                  : () =>
                                                      _handleAccept(req),
                                              child: Container(
                                                width: 32,
                                                height: 32,
                                                decoration: BoxDecoration(
                                                  color: isResponding
                                                      ? const Color(
                                                          0xFF9CA3AF)
                                                      : const Color(
                                                          0xFF286BFE),
                                                  borderRadius:
                                                      BorderRadius
                                                          .circular(AppRadii.md),
                                                ),
                                                child: const Icon(
                                                    Icons.check_rounded,
                                                    color: Colors.white,
                                                    size: 16),
                                              ),
                                            ),
                                            const SizedBox(width: AppSpacing.sm),
                                            // ✗ Decline
                                            GestureDetector(
                                              onTap: isResponding
                                                  ? null
                                                  : () =>
                                                      _handleDecline(req),
                                              child: Container(
                                                width: 32,
                                                height: 32,
                                                decoration: BoxDecoration(
                                                  color: isDark
                                                      ? const Color(
                                                          0xFF374151)
                                                      : AppColors.borderLight,
                                                  borderRadius:
                                                      BorderRadius
                                                          .circular(AppRadii.md),
                                                ),
                                                child: Icon(
                                                    Icons.close_rounded,
                                                    color: isDark
                                                        ? AppColors
                                                            .textTertiaryDark
                                                        : const Color(
                                                            0xFF6B7280),
                                                    size: 16),
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
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                          ],

                          // ── Friends List ──
                          _SectionHeader(
                            title: 'เพื่อนทั้งหมด',
                            count: friends.length,
                          ),
                          const SizedBox(height: AppSpacing.sm),

                          if (friends.isEmpty)
                            _EmptyFriendsState(
                              isDark: isDark,
                              onAdd: () => setState(() => _showAdd = true),
                            )
                          else
                            ...friends.map((f) => _FriendRow(
                                  friend: f,
                                  isDark: isDark,
                                  onRemove: () => _handleRemove(f),
                                )),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
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
          padding:
              const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count',
            style: GoogleFonts.notoSansThai(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Empty Friends State ────────────────────────────────────────
class _EmptyFriendsState extends StatelessWidget {
  final bool isDark;
  final VoidCallback onAdd;
  const _EmptyFriendsState({required this.isDark, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(AppRadii.lg),
            ),
            child: const Icon(Icons.people_outline_rounded,
                size: 28, color: Color(0xFF286BFE)),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'ยังไม่มีเพื่อน',
            style: GoogleFonts.notoSansThai(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'เพิ่มเพื่อนด้วย @username เพื่อเพิ่มเข้ากลุ่มได้',
            style: GoogleFonts.notoSansThai(
              fontSize: 12,
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Text(
                'เพิ่มเพื่อนคนแรก',
                style: GoogleFonts.notoSansThai(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Rounded Avatar (borderRadius variant) ─────────────────────
class _RoundedAvatar extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final double size;
  final double radius;

  const _RoundedAvatar({
    required this.name,
    required this.size,
    required this.radius,
    this.avatarUrl,
  });

  String get _initial {
    final t = name.trim();
    return t.isNotEmpty ? t[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      if (avatarUrl!.startsWith('data:')) {
        // base64 data URI — CachedNetworkImage can't handle these.
        try {
          final bytes = base64Decode(avatarUrl!.split(',').last);
          return ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Image.memory(
              bytes,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildInitials(),
            ),
          );
        } catch (_) {
          return _buildInitials();
        }
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: CachedNetworkImage(
          imageUrl: avatarUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (ctx, url) => _buildInitials(),
          errorWidget: (ctx, url, err) => _buildInitials(),
        ),
      );
    }
    return _buildInitials();
  }

  Widget _buildInitials() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primaryBlue,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Center(
        child: Text(
          _initial,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.38,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// ── Friend Row ─────────────────────────────────────────────────
class _FriendRow extends StatelessWidget {
  final Friend friend;
  final bool isDark;
  final VoidCallback onRemove;

  const _FriendRow({
    required this.friend,
    required this.isDark,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final myId =
        Supabase.instance.client.auth.currentUser?.id ?? '';
    final profile = friend.otherProfile(myId);
    final name = profile?.displayName ?? profile?.username ?? 'ผู้ใช้';
    final username = profile?.username;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          _RoundedAvatar(
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
          // "เพื่อน ✓" badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person_outline_rounded,
                    size: 12, color: Color(0xFF16A34A)),
                const SizedBox(width: 4),
                Text(
                  'เพื่อน',
                  style: GoogleFonts.notoSansThai(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF16A34A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // 🗑️ Remove button
          GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.borderDark
                    : AppColors.borderLight,
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                size: 14,
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.neutral600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
