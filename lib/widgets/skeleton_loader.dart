import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ── Shimmer animation wrapper ──────────────────────────────────────────────
class SkeletonLoader extends StatefulWidget {
  final Widget child;
  const SkeletonLoader({super.key, required this.child});

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _animation, child: widget.child);
  }
}

// ── Base skeleton box ──────────────────────────────────────────────────────
class SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF26314F) : const Color(0xFFE9EEF6),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

// ── Bill card skeleton ─────────────────────────────────────────────────────
class BillCardSkeleton extends StatelessWidget {
  const BillCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SkeletonBox(width: 40, height: 40, borderRadius: AppRadii.md),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: double.infinity, height: 14, borderRadius: 6),
                    SizedBox(height: 6),
                    SkeletonBox(width: 120, height: 11, borderRadius: 6),
                  ],
                ),
              ),
              SizedBox(width: 12),
              SkeletonBox(width: 60, height: 20, borderRadius: AppRadii.full),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              SkeletonBox(width: 80, height: 11, borderRadius: 6),
              Spacer(),
              SkeletonBox(width: 50, height: 11, borderRadius: 6),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Group card skeleton ────────────────────────────────────────────────────
class GroupCardSkeleton extends StatelessWidget {
  const GroupCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: const Row(
        children: [
          SkeletonBox(width: 48, height: 48, borderRadius: AppRadii.md),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: double.infinity, height: 14, borderRadius: 6),
                SizedBox(height: 6),
                SkeletonBox(width: 100, height: 11, borderRadius: 6),
              ],
            ),
          ),
          SizedBox(width: 12),
          SkeletonBox(width: 24, height: 24, borderRadius: AppRadii.sm),
        ],
      ),
    );
  }
}

// ── Friend row skeleton ────────────────────────────────────────────────────
class FriendRowSkeleton extends StatelessWidget {
  const FriendRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
      child: const Row(
        children: [
          SkeletonBox(width: 40, height: 40, borderRadius: 16),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 120, height: 14, borderRadius: 6),
                SizedBox(height: 6),
                SkeletonBox(width: 80, height: 11, borderRadius: 6),
              ],
            ),
          ),
          SkeletonBox(width: 50, height: 22, borderRadius: AppRadii.sm),
        ],
      ),
    );
  }
}

// ── Home screen skeleton (bills + groups sections) ─────────────────────────
class HomeScreenSkeleton extends StatelessWidget {
  const HomeScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SkeletonLoader(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 16),
            // Section header
            SkeletonBox(width: 120, height: 16, borderRadius: 6),
            SizedBox(height: 12),
            // Bill cards
            BillCardSkeleton(),
            BillCardSkeleton(),
            BillCardSkeleton(),
            SizedBox(height: 20),
            SkeletonBox(width: 100, height: 16, borderRadius: 6),
            SizedBox(height: 12),
            GroupCardSkeleton(),
            GroupCardSkeleton(),
          ],
        ),
      ),
    );
  }
}

// ── Bills list skeleton ────────────────────────────────────────────────────
class BillsListSkeleton extends StatelessWidget {
  const BillsListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(
            5,
            (_) => const BillCardSkeleton(),
          ),
        ),
      ),
    );
  }
}

// ── Groups list skeleton ───────────────────────────────────────────────────
class GroupsListSkeleton extends StatelessWidget {
  const GroupsListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(
            4,
            (_) => const GroupCardSkeleton(),
          ),
        ),
      ),
    );
  }
}

// ── Friends list skeleton ──────────────────────────────────────────────────
class FriendsListSkeleton extends StatelessWidget {
  const FriendsListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonBox(width: 100, height: 14, borderRadius: 6),
            const SizedBox(height: 12),
            ...List.generate(5, (_) => const FriendRowSkeleton()),
          ],
        ),
      ),
    );
  }
}
