import 'package:flutter/material.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';

// ── Shimmer InheritedWidget — shares a single AnimationController ──────────
// All SkeletonBox widgets on screen read from this ancestor and animate in sync.
class _ShimmerScope extends InheritedWidget {
  final Animation<double> animation;
  const _ShimmerScope({required this.animation, required super.child});

  static _ShimmerScope? of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<_ShimmerScope>();

  @override
  bool updateShouldNotify(_ShimmerScope old) => animation != old.animation;
}

// ── Shimmer animation wrapper ──────────────────────────────────────────────
// Wrap an entire skeleton screen in ONE SkeletonLoader.
// All SkeletonBox children inside will shimmer in sync.
class SkeletonLoader extends StatefulWidget {
  final Widget child;
  const SkeletonLoader({super.key, required this.child});

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -2.0, end: 2.0).animate(
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
    return _ShimmerScope(animation: _animation, child: widget.child);
  }
}

// ── Base skeleton box — reads shimmer from ancestor ────────────────────────
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scope = _ShimmerScope.of(context);

    final baseColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final highlightColor = isDark ? AppColors.textTertiaryDark : AppColors.bgSubtle;

    if (scope == null) {
      // Fallback: no shimmer scope, just a static box
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      );
    }

    return AnimatedBuilder(
      animation: scope.animation,
      builder: (context, _) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [baseColor, highlightColor, baseColor],
              stops: const [0.0, 0.5, 1.0],
              transform: _SlidingGradientTransform(scope.animation.value),
            ),
          ),
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;
  const _SlidingGradientTransform(this.slidePercent);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0, 0);
  }
}

// ── SkeletonCircle ─────────────────────────────────────────────────────────
class SkeletonCircle extends StatelessWidget {
  final double size;
  const SkeletonCircle({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(width: size, height: size, borderRadius: size / 2);
  }
}

// ── SkeletonText — convenience for a text-line placeholder ────────────────
class SkeletonText extends StatelessWidget {
  final double? width;
  final double height;

  const SkeletonText({super.key, this.width, this.height = 13});

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(width: width, height: height, borderRadius: 6);
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
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
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
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
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
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
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

// ── Currency card skeleton ─────────────────────────────────────────────────
class CurrencyCardSkeleton extends StatelessWidget {
  const CurrencyCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 130,
      height: 116,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              SkeletonBox(width: 28, height: 20, borderRadius: 4),
              SizedBox(width: 8),
              SkeletonBox(width: 36, height: 13, borderRadius: 6),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(width: 80, height: 18, borderRadius: 6),
              SizedBox(height: 6),
              SkeletonBox(width: 60, height: 11, borderRadius: 6),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Stat card skeleton (2×2 grid) ─────────────────────────────────────────
class StatCardSkeleton extends StatelessWidget {
  const StatCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SkeletonBox(width: 36, height: 36, borderRadius: AppRadii.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(width: 80, height: 16, borderRadius: 6),
              SizedBox(height: 4),
              SkeletonBox(width: 60, height: 11, borderRadius: 6),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Quick action tile skeleton ─────────────────────────────────────────────
class QuickActionTileSkeleton extends StatelessWidget {
  const QuickActionTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(width: 36, height: 36, borderRadius: AppRadii.sm),
          SizedBox(height: 10),
          SkeletonBox(width: 40, height: 13, borderRadius: 6),
          SizedBox(height: 4),
          SkeletonBox(width: 56, height: 10, borderRadius: 6),
        ],
      ),
    );
  }
}

// ── Full Home Screen Skeleton ──────────────────────────────────────────────
// Covers the entire scroll view: greeting → hero card → quick actions →
// currency → stats → recent bills. Prevents any text from rendering before
// data + fonts are ready.
class HomeScreenSkeleton extends StatelessWidget {
  const HomeScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SkeletonLoader(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Greeting bar ──────────────────────────────────
              Row(
                children: [
                  const Expanded(
                    child: SkeletonBox(width: double.infinity, height: 26, borderRadius: 8),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    child: const SkeletonBox(width: 44, height: 44, borderRadius: AppRadii.md),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Hero balance card ─────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppRadii.card),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Label
                    Container(
                      width: 100,
                      height: 13,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Amount
                    Container(
                      width: 180,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Pills row
                    Row(
                      children: [
                        _HeroPillSkeleton(),
                        const SizedBox(width: 8),
                        _HeroPillSkeleton(),
                        const SizedBox(width: 8),
                        _HeroPillSkeleton(),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Quick actions section ─────────────────────────
              const SkeletonBox(width: 80, height: 16, borderRadius: 6),
              const SizedBox(height: 14),
              const Row(
                children: [
                  Expanded(child: QuickActionTileSkeleton()),
                  SizedBox(width: 12),
                  Expanded(child: QuickActionTileSkeleton()),
                  SizedBox(width: 12),
                  Expanded(child: QuickActionTileSkeleton()),
                ],
              ),
              const SizedBox(height: 28),

              // ── Currency section ──────────────────────────────
              Row(
                children: [
                  const Expanded(
                    child: SkeletonBox(width: 140, height: 16, borderRadius: 6),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 116,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 5,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, __) => const CurrencyCardSkeleton(),
                ),
              ),
              const SizedBox(height: 28),

              // ── Stats section ─────────────────────────────────
              const SkeletonBox(width: 100, height: 16, borderRadius: 6),
              const SizedBox(height: 14),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.55,
                children: const [
                  StatCardSkeleton(),
                  StatCardSkeleton(),
                  StatCardSkeleton(),
                  StatCardSkeleton(),
                ],
              ),
              const SizedBox(height: 28),

              // ── Recent bills section ──────────────────────────
              Row(
                children: [
                  const Expanded(
                    child: SkeletonBox(width: 80, height: 16, borderRadius: 6),
                  ),
                  Container(
                    width: 72,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.accentIceDark : AppColors.accentIce,
                      borderRadius: BorderRadius.circular(AppRadii.full),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const BillCardSkeleton(),
              const BillCardSkeleton(),
              const BillCardSkeleton(),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroPillSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(AppRadii.full),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
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

// ── Notification card skeleton ─────────────────────────────────────────────
class NotificationCardSkeleton extends StatelessWidget {
  const NotificationCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(width: 40, height: 40, borderRadius: AppRadii.md),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: double.infinity, height: 13, borderRadius: 6),
                    SizedBox(height: 6),
                    SkeletonBox(width: 160, height: 13, borderRadius: 6),
                    SizedBox(height: 6),
                    SkeletonBox(width: 80, height: 11, borderRadius: 6),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Action buttons placeholder
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Notifications list skeleton ────────────────────────────────────────────
class NotificationsListSkeleton extends StatelessWidget {
  const NotificationsListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: List.generate(4, (_) => const NotificationCardSkeleton()),
        ),
      ),
    );
  }
}

// ── Bill detail skeleton ───────────────────────────────────────────────────
// Mirrors the BillDetailScreen layout: app bar area + tab bar + member rows.
class BillDetailSkeleton extends StatelessWidget {
  const BillDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Fake app bar ──────────────────────────────────────
          Container(
            color: Colors.transparent,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: const Row(
              children: [
                SkeletonBox(width: 32, height: 32, borderRadius: AppRadii.sm),
                SizedBox(width: 12),
                Expanded(
                  child: SkeletonBox(width: double.infinity, height: 16, borderRadius: 6),
                ),
                SizedBox(width: 12),
                SkeletonBox(width: 70, height: 30, borderRadius: AppRadii.full),
              ],
            ),
          ),
          // ── Fake tab bar ──────────────────────────────────────
          Container(
            color: Colors.transparent,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: List.generate(
                4,
                (i) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i < 3 ? 8 : 0),
                    child: const SkeletonBox(width: double.infinity, height: 32, borderRadius: 8),
                  ),
                ),
              ),
            ),
          ),
          // ── Content: member rows ──────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section header
                  const Row(
                    children: [
                      SkeletonBox(width: 80, height: 14, borderRadius: 6),
                      Spacer(),
                      SkeletonBox(width: 80, height: 32, borderRadius: AppRadii.full),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Member rows
                  ...List.generate(4, (_) => const _MemberRowSkeleton()),
                  const SizedBox(height: 24),
                  // Items section header
                  const Row(
                    children: [
                      SkeletonBox(width: 80, height: 14, borderRadius: 6),
                      Spacer(),
                      SkeletonBox(width: 80, height: 32, borderRadius: AppRadii.full),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(3, (_) => const _ItemRowSkeleton()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberRowSkeleton extends StatelessWidget {
  const _MemberRowSkeleton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: const Row(
        children: [
          SkeletonCircle(size: 40),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 100, height: 14, borderRadius: 6),
                SizedBox(height: 5),
                SkeletonBox(width: 70, height: 11, borderRadius: 6),
              ],
            ),
          ),
          SkeletonBox(width: 60, height: 20, borderRadius: AppRadii.full),
        ],
      ),
    );
  }
}

class _ItemRowSkeleton extends StatelessWidget {
  const _ItemRowSkeleton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: const Row(
        children: [
          SkeletonBox(width: 36, height: 36, borderRadius: AppRadii.sm),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 140, height: 14, borderRadius: 6),
                SizedBox(height: 5),
                SkeletonBox(width: 80, height: 11, borderRadius: 6),
              ],
            ),
          ),
          SkeletonBox(width: 60, height: 14, borderRadius: 6),
        ],
      ),
    );
  }
}

// ── Group detail skeleton ──────────────────────────────────────────────────
class GroupDetailSkeleton extends StatelessWidget {
  const GroupDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SkeletonLoader(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Fake app bar ──────────────────────────────────────
          Container(
            color: Colors.transparent,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: const Row(
              children: [
                SkeletonBox(width: 32, height: 32, borderRadius: AppRadii.sm),
                SizedBox(width: 12),
                SkeletonBox(width: 28, height: 28, borderRadius: AppRadii.sm),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(width: double.infinity, height: 15, borderRadius: 6),
                      SizedBox(height: 4),
                      SkeletonBox(width: 100, height: 11, borderRadius: 6),
                    ],
                  ),
                ),
                SizedBox(width: 12),
                SkeletonBox(width: 32, height: 32, borderRadius: AppRadii.sm),
              ],
            ),
          ),
          // ── Fake tab bar ──────────────────────────────────────
          Container(
            color: Colors.transparent,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: List.generate(
                4,
                (i) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i < 3 ? 8 : 0),
                    child: const SkeletonBox(width: double.infinity, height: 32, borderRadius: 8),
                  ),
                ),
              ),
            ),
          ),
          // ── Content ───────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Member avatar row
                  Row(
                    children: List.generate(
                      5,
                      (i) => Padding(
                        padding: EdgeInsets.only(right: i < 4 ? 8 : 0),
                        child: const SkeletonCircle(size: 44),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Bill cards
                  ...List.generate(3, (_) => _GroupBillRowSkeleton(isDark: isDark)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupBillRowSkeleton extends StatelessWidget {
  final bool isDark;
  const _GroupBillRowSkeleton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: const Row(
        children: [
          SkeletonBox(width: 40, height: 40, borderRadius: AppRadii.md),
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
          SkeletonBox(width: 60, height: 20, borderRadius: AppRadii.full),
        ],
      ),
    );
  }
}

// ── Me screen skeleton ─────────────────────────────────────────────────────
class MeScreenSkeleton extends StatelessWidget {
  const MeScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SkeletonLoader(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Profile header ────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              color: isDark ? AppColors.surfaceDark : AppColors.surface,
              child: const Column(
                children: [
                  SkeletonCircle(size: 80),
                  SizedBox(height: 14),
                  SkeletonBox(width: 140, height: 20, borderRadius: 8),
                  SizedBox(height: 8),
                  SkeletonBox(width: 100, height: 14, borderRadius: 6),
                  SizedBox(height: 8),
                  SkeletonBox(width: 120, height: 28, borderRadius: AppRadii.full),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // ── Account section ───────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonBox(width: 80, height: 13, borderRadius: 6),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadii.lg),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      ),
                    ),
                    child: Column(
                      children: List.generate(3, (i) {
                        return Column(
                          children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              child: Row(
                                children: [
                                  SkeletonBox(width: 36, height: 36, borderRadius: AppRadii.sm),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        SkeletonBox(width: 80, height: 13, borderRadius: 6),
                                        SizedBox(height: 5),
                                        SkeletonBox(width: 120, height: 11, borderRadius: 6),
                                      ],
                                    ),
                                  ),
                                  SkeletonBox(width: 20, height: 20, borderRadius: 4),
                                ],
                              ),
                            ),
                            if (i < 2)
                              Divider(
                                height: 1,
                                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                              ),
                          ],
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Settings section
                  const SkeletonBox(width: 60, height: 13, borderRadius: 6),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadii.lg),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      ),
                    ),
                    child: Column(
                      children: List.generate(3, (i) {
                        return Column(
                          children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              child: Row(
                                children: [
                                  SkeletonBox(width: 36, height: 36, borderRadius: AppRadii.sm),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: SkeletonBox(width: double.infinity, height: 13, borderRadius: 6),
                                  ),
                                  SizedBox(width: 12),
                                  SkeletonBox(width: 20, height: 20, borderRadius: 4),
                                ],
                              ),
                            ),
                            if (i < 2)
                              Divider(
                                height: 1,
                                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                              ),
                          ],
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
