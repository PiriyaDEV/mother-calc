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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationsProvider>().loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<NotificationsProvider>();

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text('การแจ้งเตือน',
            style: GoogleFonts.notoSansThai(fontWeight: FontWeight.w600)),
        elevation: 0,
        actions: [
          if (provider.unreadCount > 0)
            TextButton(
              onPressed: () => provider.markAllAsRead(),
              child: Text(
                'อ่านทั้งหมด',
                style: GoogleFonts.notoSansThai(
                  fontSize: 13,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
      body: provider.loading
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppColors.primary, strokeWidth: 2))
          : RefreshIndicator(
              onRefresh: () => provider.loadNotifications(),
              color: AppColors.primary,
              child: provider.notifications.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('🔔',
                                    style: TextStyle(fontSize: 48)),
                                const SizedBox(height: 12),
                                Text(
                                  'ยังไม่มีการแจ้งเตือน',
                                  style: GoogleFonts.notoSansThai(
                                    fontSize: 15,
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
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: provider.notifications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final notification = provider.notifications[index];
                        return _NotificationTile(
                          notification: notification,
                          onTap: () {
                            if (!notification.read) {
                              provider.markAsRead(notification.id);
                            }
                          },
                          onAccept: notification.type == 'group_invite'
                              ? () async {
                                  final err = await provider
                                      .acceptGroupInvite(notification);
                                  if (err != null && context.mounted) {
                                    _showSnack(context, err, isError: true);
                                  } else if (context.mounted) {
                                    _showSnack(context, 'เข้าร่วมกลุ่มแล้ว!');
                                  }
                                }
                              : null,
                          onDecline: notification.type == 'group_invite'
                              ? () async {
                                  final err = await provider
                                      .declineGroupInvite(notification);
                                  if (err != null && context.mounted) {
                                    _showSnack(context, err, isError: true);
                                  }
                                }
                              : null,
                        );
                      },
                    ),
            ),
    );
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

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
    this.onAccept,
    this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUnread = !notification.read;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUnread
              ? (isDark
                  ? AppColors.primary.withOpacity(0.08)
                  : AppColors.primary.withOpacity(0.04))
              : (isDark ? AppColors.surfaceDark : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUnread
                ? AppColors.primary.withOpacity(0.2)
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _iconBgColor(notification.type),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _iconEmoji(notification.type),
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (notification.title != null)
                        Text(
                          notification.title!,
                          style: GoogleFonts.notoSansThai(
                            fontSize: 14,
                            fontWeight: isUnread
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                      if (notification.body != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          notification.body!,
                          style: GoogleFonts.notoSansThai(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(notification.createdAt),
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
                if (isUnread)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),

            // Group invite actions
            if (notification.type == 'group_invite' &&
                !notification.read &&
                onAccept != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onDecline,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.red,
                        side: const BorderSide(color: AppColors.red),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: Text('ปฏิเสธ',
                          style: GoogleFonts.notoSansThai(
                              fontSize: 13, fontWeight: FontWeight.w500)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onAccept,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.emerald,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: Text('ยอมรับ',
                          style: GoogleFonts.notoSansThai(
                              fontSize: 13, fontWeight: FontWeight.w500)),
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

  String _iconEmoji(String type) {
    switch (type) {
      case 'group_invite':
        return '👥';
      case 'friend_request':
        return '🤝';
      case 'bill_shared':
        return '🧾';
      default:
        return '🔔';
    }
  }

  Color _iconBgColor(String type) {
    switch (type) {
      case 'group_invite':
        return AppColors.primary.withOpacity(0.12);
      case 'friend_request':
        return AppColors.emerald.withOpacity(0.12);
      case 'bill_shared':
        return AppColors.amber.withOpacity(0.12);
      default:
        return AppColors.primary.withOpacity(0.08);
    }
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'เมื่อกี้';
    if (diff.inMinutes < 60) return '${diff.inMinutes} นาทีที่แล้ว';
    if (diff.inHours < 24) return '${diff.inHours} ชั่วโมงที่แล้ว';
    if (diff.inDays < 7) return '${diff.inDays} วันที่แล้ว';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
