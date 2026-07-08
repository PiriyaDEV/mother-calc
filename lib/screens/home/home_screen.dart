import 'package:kidtang_flutter/providers/locale_provider.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kidtang_flutter/models/models.dart';
import 'package:kidtang_flutter/providers/auth_provider.dart';
import 'package:kidtang_flutter/stores/bills_store.dart';
import 'package:kidtang_flutter/stores/groups_store.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';
import 'package:kidtang_flutter/widgets/shared/banner_ad_widget.dart';
import 'package:kidtang_flutter/widgets/shared/constants.dart';
import 'package:kidtang_flutter/widgets/shared/skeleton_loader.dart';
import 'package:kidtang_flutter/widgets/shared/app_section_header.dart';
import 'package:kidtang_flutter/widgets/home/index.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _supabase = Supabase.instance.client;

  List<_RateData> _rates = [];
  bool _ratesLoading = true;
  bool _ratesIsFallback = false;
  String _ratesTime = '';

  static const _currencies = kExchangeRateCurrencies;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadRates();
  }

  Future<void> _loadData({bool force = false}) async {
    await Future.wait([
      context.read<BillsStore>().loadStats(force: force),
      context.read<BillsStore>().loadRecent(force: force),
      context.read<BillsStore>().loadInitialPage('pending_payment'),
      context.read<GroupsStore>().loadGroupsCount(force: force),
    ]);
  }

  Future<void> _loadRates() async {
    setState(() => _ratesLoading = true);
    try {
      final res = await http
          .get(Uri.parse('https://open.er-api.com/v6/latest/THB'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final thbRates = data['rates'] as Map<String, dynamic>;
        final parsed = _currencies.map((c) {
          final r = (thbRates[c.code] as num?)?.toDouble() ?? 0;
          return _RateData(code: c.code, rate: r > 0 ? 1 / r : 0);
        }).toList();
        if (mounted) {
          setState(() {
            _rates = parsed;
            _ratesLoading = false;
            _ratesIsFallback = false;
            final now = TimeOfDay.now();
            _ratesTime =
                '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
          });
        }
        return;
      }
    } catch (_) {}
    const fallback = {
      'USD': 33.5, 'EUR': 36.2, 'JPY': 0.22, 'CNY': 4.6, 'GBP': 42.5,
      'KRW': 0.025, 'SGD': 24.8, 'AUD': 21.5, 'HKD': 4.3, 'MYR': 7.2,
    };
    if (mounted) {
      setState(() {
        _rates = _currencies
            .map((c) => _RateData(code: c.code, rate: fallback[c.code] ?? 0))
            .toList();
        _ratesLoading = false;
        _ratesIsFallback = true;
        _ratesTime = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.watch<LocaleProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final profile = context.select<AuthProvider, Profile?>((a) => a.profile);
    final dataLoading = context.select<BillsStore, bool>(
        (s) => s.statsLoading && s.stats == null);
    final hasBills = context
        .select<BillsStore, bool>((s) => (s.stats?.totalCount ?? 0) > 0);

    final user = _supabase.auth.currentUser;
    final displayName = profile?.displayName ??
        profile?.username ??
        user?.email?.split('@').first ??
        'คุณ';
    final firstName = displayName.split(' ').first;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppGradients.backgroundDark
              : AppGradients.backgroundLight,
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await _loadData(force: true);
                    await _loadRates();
                  },
                  color: AppColors.primary,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      // ── Top bar: greeting + wallet icon ─────────
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            AppSpacing.lg,
                            AppSpacing.lg,
                            0,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  l.t('home_greeting').replaceAll('{name}', firstName),
                                  style: GoogleFonts.anuphan(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? AppColors.neutral900Dark
                                        : AppColors.neutral900,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                              _WalletIconButton(isDark: isDark),
                            ],
                          ),
                        ),
                      ),

                      // ── Hero balance card ────────────────────────
                      const SliverToBoxAdapter(child: HeroBalanceCard()),

                      // ── Quick actions ────────────────────────────
                      SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Section header using shared component
                            AppSectionHeader(
                              title: l.t('home_main_menu'),
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.lg,
                                AppSpacing.xxl,
                                AppSpacing.lg,
                                AppSpacing.md,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: QuickActionTile(
                                      icon: Icons.receipt_long_rounded,
                                      label: l.t('home_nav_bills'),
                                      sublabel: l.t('home_nav_bills_sub'),
                                      color: AppColors.primaryBlue,
                                      bgColor: isDark
                                          ? AppColors.accentIceDark
                                          : AppColors.accentIce,
                                      onTap: () => context.go('/bills'),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: QuickActionTile(
                                      icon: Icons.group_rounded,
                                      label: l.t('home_nav_groups'),
                                      sublabel: l.t('home_nav_groups_sub'),
                                      color: const Color(0xFF7B5CF6),
                                      bgColor: isDark
                                          ? const Color(0xFF1E1A3A)
                                          : const Color(0xFFEDE9FE),
                                      onTap: () => context.go('/groups'),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: QuickActionTile(
                                      icon: Icons.people_rounded,
                                      label: l.t('home_nav_friends'),
                                      sublabel: l.t('home_nav_friends_sub'),
                                      color: AppColors.accentAqua,
                                      bgColor: isDark
                                          ? const Color(0xFF0D2A28)
                                          : const Color(0xFFE0FAF7),
                                      onTap: () => context.go('/friends'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Currency exchange rates ───────────────────
                      SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Section header with inline refresh button
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.lg,
                                AppSpacing.xxl,
                                AppSpacing.lg,
                                AppSpacing.md,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      l.t('home_exchange_rate') +
                                          (_ratesIsFallback
                                              ? ' · ${l.t('home_rates_fallback')}'
                                              : (_ratesTime.isNotEmpty
                                                  ? ' · $_ratesTime'
                                                  : '')),
                                      style: GoogleFonts.anuphan(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? AppColors.neutral900Dark
                                            : AppColors.neutral900,
                                      ),
                                    ),
                                  ),
                                  _RefreshButton(
                                    isDark: isDark,
                                    loading: _ratesLoading,
                                    onTap: _ratesLoading ? null : _loadRates,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 116,
                              child: _ratesLoading
                                  ? SkeletonLoader(
                                      child: ListView.separated(
                                        scrollDirection: Axis.horizontal,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.lg,
                                        ),
                                        itemCount: 5,
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(width: AppSpacing.sm + 2),
                                        itemBuilder: (_, __) =>
                                            const CurrencyCardSkeleton(),
                                      ),
                                    )
                                  : ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.lg,
                                      ),
                                      itemCount: _rates.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(width: AppSpacing.sm + 2),
                                      itemBuilder: (_, i) {
                                        final r = _rates[i];
                                        final cfg = _currencies.firstWhere(
                                            (c) => c.code == r.code);
                                        final isJpyKrw = r.code == 'JPY' ||
                                            r.code == 'KRW';
                                        final rateStr = isJpyKrw
                                            ? r.rate.toStringAsFixed(4)
                                            : r.rate.toStringAsFixed(2);
                                        return CurrencyCard(
                                          code: r.code,
                                          name: cfg.label,
                                          flag: cfg.flag,
                                          rateStr: rateStr,
                                          isDark: isDark,
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),

                      // ── My debts summary ─────────────────────────
                      SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppSectionHeader(
                              title: l.t('home_my_debts_title'),
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.lg,
                                AppSpacing.xxl,
                                AppSpacing.lg,
                                AppSpacing.md,
                              ),
                            ),
                            const MyDebtsCard(),
                          ],
                        ),
                      ),

                      // ── Stats / loading ──────────────────────────
                      if (dataLoading)
                        const SliverToBoxAdapter(
                          child: HomeScreenSkeleton(),
                        )
                      else ...[
                        if (hasBills) ...[
                          // Stats section header
                          SliverToBoxAdapter(
                            child: AppSectionHeader(
                              title: l.t('home_stats_title'),
                            ),
                          ),
                          StatsGrid(isDark: isDark),

                          // Recent bills section header
                          SliverToBoxAdapter(
                            child: AppSectionHeader(
                              title: l.t('home_recent_bills'),
                              onSeeAll: () => context.go('/bills'),
                              seeAllLabel: l.t('home_see_all'),
                            ),
                          ),
                          const RecentBillsList(),
                        ],

                        // Empty state
                        if (!hasBills) HomeEmptyState(isDark: isDark),
                      ],

                      // Extra bottom padding for floating nav bar
                      const SliverToBoxAdapter(child: SizedBox(height: 110)),
                    ],
                  ),
                ),
              ),
              const BannerAdWidget(),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Wallet icon button ────────────────────────────────────────────────────────

class _WalletIconButton extends StatelessWidget {
  const _WalletIconButton({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceDark
            : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppRadii.md),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: AppColors.primaryBlue.withValues(alpha: 0.10),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Icon(
        Icons.account_balance_wallet_outlined,
        size: 20,
        color: isDark ? AppColors.neutral600Dark : AppColors.neutral600,
      ),
    );
  }
}

// ── Refresh button for exchange rates ─────────────────────────────────────────

class _RefreshButton extends StatefulWidget {
  const _RefreshButton({
    required this.isDark,
    required this.loading,
    this.onTap,
  });

  final bool isDark;
  final bool loading;
  final VoidCallback? onTap;

  @override
  State<_RefreshButton> createState() => _RefreshButtonState();
}

class _RefreshButtonState extends State<_RefreshButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: widget.onTap != null
          ? (_) => setState(() => _pressed = true)
          : null,
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? AppMotion.pressScaleButton : 1.0,
        duration: AppMotion.press,
        curve: AppMotion.standard,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: widget.isDark
                ? AppColors.surfaceDark
                : Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(AppRadii.xs),
            boxShadow: widget.isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: widget.loading
              ? const Padding(
                  padding: EdgeInsets.all(7),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              : Icon(
                  Icons.refresh_rounded,
                  size: 16,
                  color: widget.isDark
                      ? AppColors.neutral600Dark
                      : AppColors.neutral600,
                ),
        ),
      ),
    );
  }
}

// ── Local data model (rate) ───────────────────────────────────────────────────

class _RateData {
  final String code;
  final double rate;
  const _RateData({required this.code, required this.rate});
}
