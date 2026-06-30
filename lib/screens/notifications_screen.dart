import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/notifications_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';

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
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.bgDark.withValues(alpha: 0.8)
                    : Colors.white.withValues(alpha: 0.8),
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
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
                            : AppColors.borderLight,
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
                  const SizedBox(width: AppSpacing.md),
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
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(AppRadii.xl),
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
                              size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            'อ่านทั้งหมด',
                            style: GoogleFonts.notoSansThai(
                              fontSize: 12,
                              color: AppColors.primary,
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
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              itemCount: provider.notifications.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: AppSpacing.sm),
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
    return const EmptyStateWidget(
      emoji: '🔔',
      title: 'ไม่มีการแจ้งเตือน',
      subtitle: 'คำเชิญกลุ่มและการอัพเดตจะปรากฏที่นี่',
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
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
            color: isUnread
                ? (isDark ? AppColors.primary.withValues(alpha: 0.4) : const Color(0xFFDBEAFE))
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
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
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppRadii.md),
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
                const SizedBox(width: AppSpacing.md),
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
                                color: AppColors.primary,
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
                              : AppColors.textTertiaryLight,
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
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),

            // Action buttons
            if (showActions) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  // ปฏิเสธ — border-only
                  Expanded(
                    child: GestureDetector(
                      onTap: isResponding ? null : onDecline,
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isDark ? AppColors.borderDark : const Color(0xFFD1D5DB),
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            isResponding ? 'กำลังดำเนินการ...' : 'ปฏิเสธ',
                            style: GoogleFonts.notoSansThai(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.textSecondaryDark : const Color(0xFF4B5563),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  // รับคำเชิญ — green filled
                  Expanded(
                    child: GestureDetector(
                      onTap: isResponding ? null : onAccept,
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: isResponding ? const Color(0xFF9CA3AF) : AppColors.emerald,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            isResponding ? 'กำลังดำเนินการ...' : 'รับคำเชิญ',
                            style: GoogleFonts.notoSansThai(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
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
