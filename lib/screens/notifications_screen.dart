import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/notifications_provider.dart';
import '../theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String? _respondingId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationsProvider>().loadNotifications();
    });
  }

  Future<void> _handleRespond(
      AppNotification notif, String action) async {
    setState(() => _respondingId = notif.id);
    final provider = context.read<NotificationsProvider>();

    await provider.markAsRead(notif.id);

    if (action == 'accepted') {
      final err = await provider.acceptGroupInvite(notif);
      if (!mounted) return;
      setState(() => _respondingId = null);
      if (err != null) {
        _showSnack(err, isError: true);
      } else {
        final groupId = notif.data['group_id'] as String?;
        if (groupId != null) {
          context.push('/groups/$groupId');
        }
      }
    } else {
      final err = await provider.declineGroupInvite(notif);
      if (!mounted) return;
      setState(() => _respondingId = null);
      if (err != null) {
        _showSnack(err, isError: true);
      }
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.notoSansThai()),
      backgroundColor: isError ? AppColors.red : AppColors.emerald,
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<NotificationsProvider>();
    final unread = provider.unreadCount;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF4F6FB),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.bgDark.withValues(alpha: 0.8)
                    : Colors.white.withValues(alpha: 0.8),
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? AppColors.borderDark
                        : const Color(0xFFF3F4F6),
                  ),
                ),
              ),
              child: Row(
                children: [
                  // ← back
                  GestureDetector(
                    onTap: () => context.go('/'),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.surfaceDark
                            : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_rounded,
                        size: 14,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'การแจ้งเตือน',
                    style: GoogleFonts.notoSansThai(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  if (unread > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4366F4),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$unread',
                        style: GoogleFonts.notoSansThai(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (unread > 0)
                    GestureDetector(
                      onTap: () => provider.markAllAsRead(),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.done_all_rounded,
                              size: 14, color: Color(0xFF4366F4)),
                          const SizedBox(width: 4),
                          Text(
                            'อ่านทั้งหมด',
                            style: GoogleFonts.notoSansThai(
                              fontSize: 12,
                              color: const Color(0xFF4366F4),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // ── Body ─────────────────────────────────────────
            Expanded(
              child: provider.loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary, strokeWidth: 2))
                  : RefreshIndicator(
                      onRefresh: () => provider.loadNotifications(),
                      color: AppColors.primary,
                      child: provider.notifications.isEmpty
                          ? _buildEmpty(isDark)
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: provider.notifications.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final notif =
                                    provider.notifications[index];
                                return _NotificationCard(
                                  notification: notif,
                                  isDark: isDark,
                                  isResponding:
                                      _respondingId == notif.id,
                                  onTap: () {
                                    if (!notif.read) {
                                      provider.markAsRead(notif.id);
                                    }
                                  },
                                  onAccept: () =>
                                      _handleRespond(notif, 'accepted'),
                                  onDecline: () =>
                                      _handleRespond(notif, 'declined'),
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

  Widget _buildEmpty(bool isDark) {
    return ListView(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfaceDark
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.notifications_none_rounded,
                    size: 24,
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : const Color(0xFF9CA3AF),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'ไม่มีการแจ้งเตือน',
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
        ),
      ],
    );
  }
}

// ── Notification Card ──────────────────────────────────────────
class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final bool isDark;
  final bool isResponding;
  final VoidCallback onTap;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _NotificationCard({
    required this.notification,
    required this.isDark,
    required this.isResponding,
    required this.onTap,
    required this.onAccept,
    required this.onDecline,
  });

  String get _avatarInitial {
    final data = notification.data;
    final name = (data['invited_by_display_name'] as String?)?.trim() ??
        (data['invited_by_username'] as String?)?.trim() ??
        '';
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    const thMonths = [
      '',
      'ม.ค.',
      'ก.พ.',
      'มี.ค.',
      'เม.ย.',
      'พ.ค.',
      'มิ.ย.',
      'ก.ค.',
      'ส.ค.',
      'ก.ย.',
      'ต.ค.',
      'พ.ย.',
      'ธ.ค.',
    ];
    final buddhistYear = dt.year + 543;
    final month = thMonths[dt.month];
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} $month $buddhistYear $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.read;
    final data = notification.data;
    final inviterName =
        (data['invited_by_display_name'] as String?)?.trim() ??
            '@${(data['invited_by_username'] as String?) ?? ''}';
    final groupName = (data['group_name'] as String?) ?? '';
    final showActions =
        isUnread && notification.type == 'group_invite';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUnread
              ? (isDark
                  ? const Color(0xFF1E3A5F)
                  : const Color(0xFFEFF6FF))
              : (isDark ? AppColors.surfaceDark : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnread
                ? const Color(0xFFDBEAFE)
                : (isDark ? AppColors.borderDark : const Color(0xFFF3F4F6)),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar with initial
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4366F4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      _avatarInitial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Rich text: ชื่อ bold + " เชิญคุณเข้าร่วมกลุ่ม " + group bold blue
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.notoSansThai(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                          children: [
                            TextSpan(
                              text: inviterName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),
                            const TextSpan(
                                text: ' เชิญคุณเข้าร่วมกลุ่ม '),
                            TextSpan(
                              text: groupName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4366F4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(notification.createdAt),
                        style: GoogleFonts.notoSansThai(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.textTertiaryDark
                              : const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),
                // Unread dot
                if (isUnread)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF4366F4),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),

            // Action buttons
            if (showActions) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  // ปฏิเสธ
                  Expanded(
                    child: GestureDetector(
                      onTap: isResponding ? null : onDecline,
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF374151)
                              : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            isResponding
                                ? 'กำลังดำเนินการ...'
                                : 'ปฏิเสธ',
                            style: GoogleFonts.notoSansThai(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : const Color(0xFF4B5563),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // ยอมรับ
                  Expanded(
                    child: GestureDetector(
                      onTap: isResponding ? null : onAccept,
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: isResponding
                              ? const Color(0xFF9CA3AF)
                              : const Color(0xFF4366F4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            isResponding
                                ? 'กำลังดำเนินการ...'
                                : 'ยอมรับ',
                            style: GoogleFonts.notoSansThai(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
