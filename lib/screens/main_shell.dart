import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/notifications_provider.dart';
import '../providers/friends_provider.dart';
import '../providers/groups_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class MainShell extends StatefulWidget {
  final StatefulNavigationShell child;
  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final auth = context.read<AuthProvider>();
    if (auth.profile != null) {
      context.read<NotificationsProvider>().loadNotifications();
      context.read<FriendsProvider>().loadFriends();
      context.read<GroupsProvider>().loadGroups();
    }
  }

  void _onTap(int index) {
    widget.child.goBranch(
      index,
      initialLocation: index == widget.child.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notifCount = context.watch<NotificationsProvider>().unreadCount;
    final friendCount = context.watch<FriendsProvider>().pendingCount;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppGradients.backgroundDark : AppGradients.backgroundLight,
        ),
        child: widget.child,
      ),
      extendBody: true,
      bottomNavigationBar: _FloatingNavBar(
        currentIndex: widget.child.currentIndex,
        isDark: isDark,
        notifCount: notifCount,
        friendCount: friendCount,
        onTap: _onTap,
      ),
    );
  }
}

// ── Floating Nav Bar ──────────────────────────────────────────
class _FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final bool isDark;
  final int notifCount;
  final int friendCount;
  final ValueChanged<int> onTap;

  const _FloatingNavBar({
    required this.currentIndex,
    required this.isDark,
    required this.notifCount,
    required this.friendCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      const _NavDef(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'หน้าหลัก'),
      const _NavDef(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long_rounded, label: 'บิล'),
      const _NavDef(icon: Icons.group_outlined, activeIcon: Icons.group_rounded, label: 'กลุ่ม'),
      _NavDef(icon: Icons.people_outline_rounded, activeIcon: Icons.people_rounded, label: 'เพื่อน', badge: friendCount),
      _NavDef(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'ฉัน', badge: notifCount),
    ];

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceDark.withValues(alpha: 0.94)
                    : Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.4)
                        : Colors.black.withValues(alpha: 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: items.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final item = entry.value;
                  final isActive = currentIndex == idx;
                  return _NavItem(
                    item: item,
                    isActive: isActive,
                    isDark: isDark,
                    onTap: () => onTap(idx),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavDef {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int badge;
  const _NavDef({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badge = 0,
  });
}

class _NavItem extends StatefulWidget {
  final _NavDef item;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;

  const _NavItem({
    required this.item,
    required this.isActive,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: _isPressed ? 0.88 : 1.0,
          duration: const Duration(milliseconds: 80),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon with pill background when active
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: widget.isActive
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadii.lg),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          widget.isActive ? widget.item.activeIcon : widget.item.icon,
                          key: ValueKey(widget.isActive),
                          size: 22,
                          color: widget.isActive
                              ? AppColors.primary
                              : (widget.isDark
                                  ? AppColors.textTertiaryDark
                                  : const Color(0xFF9CA3AF)),
                        ),
                      ),
                      if (widget.item.badge > 0)
                        Positioned(
                          top: -5,
                          right: -8,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: AppColors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              widget.item.badge > 99 ? '99+' : '${widget.item.badge}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: GoogleFonts.notoSansThai(
                    fontSize: 10,
                    fontWeight: widget.isActive ? FontWeight.w700 : FontWeight.normal,
                    color: widget.isActive
                        ? AppColors.primary
                        : (widget.isDark
                            ? AppColors.textTertiaryDark
                            : const Color(0xFF9CA3AF)),
                  ),
                  child: Text(widget.item.label),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
