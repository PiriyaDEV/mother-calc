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
  String _ratesUpdated = '';

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
            final now = TimeOfDay.now();
            _ratesUpdated =
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
        _ratesUpdated = 'ข้อมูลสำรอง';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                          padding:
                              const EdgeInsets.fromLTRB(20, 20, 20, 0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'สวัสดี, $firstName 👋 !',
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
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.surfaceDark
                                      : Colors.white.withValues(alpha: 0.9),
                                  borderRadius:
                                      BorderRadius.circular(AppRadii.md),
                                  boxShadow: isDark
                                      ? null
                                      : [
                                          BoxShadow(
                                            color: const Color(0xFF2D5BFF)
                                                .withValues(alpha: 0.10),
                                            blurRadius: 16,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                ),
                                child: Icon(
                                  Icons.account_balance_wallet_outlined,
                                  size: 20,
                                  color: isDark
                                      ? AppColors.neutral600Dark
                                      : AppColors.neutral600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ── Hero balance card ────────────────────────
                      const SliverToBoxAdapter(child: HeroBalanceCard()),

                      // ── Quick actions ────────────────────────────
                      SliverToBoxAdapter(
                        child: Padding(
                          padding:
                              const EdgeInsets.fromLTRB(20, 24, 20, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'เมนูหลัก',
                                style: GoogleFonts.anuphan(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.neutral900Dark
                                      : AppColors.neutral900,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: QuickActionTile(
                                      icon: Icons.receipt_long_rounded,
                                      label: 'บิล',
                                      sublabel: 'จัดการบิล',
                                      color: AppColors.primaryBlue,
                                      bgColor: isDark
                                          ? AppColors.accentIceDark
                                          : AppColors.accentIce,
                                      onTap: () => context.go('/bills'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: QuickActionTile(
                                      icon: Icons.group_rounded,
                                      label: 'กลุ่ม',
                                      sublabel: 'จัดการกลุ่ม',
                                      color: const Color(0xFF7B5CF6),
                                      bgColor: isDark
                                          ? const Color(0xFF1E1A3A)
                                          : const Color(0xFFEDE9FE),
                                      onTap: () => context.go('/groups'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: QuickActionTile(
                                      icon: Icons.people_rounded,
                                      label: 'เพื่อน',
                                      sublabel: 'จัดการ',
                                      color: AppColors.accentAqua,
                                      bgColor: isDark
                                          ? const Color(0xFF0D2A28)
                                          : const Color(0xFFE0FAF7),
                                      onTap: () => context.go('/friends'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ── Currency exchange rates ───────────────────
                      SliverToBoxAdapter(
                        child: Padding(
                          padding:
                              const EdgeInsets.fromLTRB(20, 28, 20, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'อัตราแลกเปลี่ยน${_ratesUpdated.isNotEmpty ? ' · $_ratesUpdated' : ''}',
                                      style: GoogleFonts.anuphan(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? AppColors.neutral900Dark
                                            : AppColors.neutral900,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: _ratesLoading ? null : _loadRates,
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? AppColors.surfaceDark
                                            : Colors.white
                                                .withValues(alpha: 0.9),
                                        borderRadius:
                                            BorderRadius.circular(AppRadii.sm),
                                        boxShadow: isDark
                                            ? null
                                            : [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.06),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                      ),
                                      child: _ratesLoading
                                          ? const Padding(
                                              padding: EdgeInsets.all(7),
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: AppColors.primary),
                                            )
                                          : Icon(
                                              Icons.refresh_rounded,
                                              size: 16,
                                              color: isDark
                                                  ? AppColors.neutral600Dark
                                                  : AppColors.neutral600,
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                height: 116,
                                child: _ratesLoading
                                    ? SkeletonLoader(
                                        child: ListView.separated(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: 5,
                                          separatorBuilder: (_, __) =>
                                              const SizedBox(width: 10),
                                          itemBuilder: (_, __) =>
                                              const CurrencyCardSkeleton(),
                                        ),
                                      )
                                    : ListView.separated(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: _rates.length,
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(width: 10),
                                        itemBuilder: (_, i) {
                                          final r = _rates[i];
                                          final cfg = _currencies
                                              .firstWhere(
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
                      ),

                      // ── Stats / loading ──────────────────────────
                      if (dataLoading)
                        const SliverToBoxAdapter(
                          child: HomeScreenSkeleton(),
                        )
                      else ...[
                        if (hasBills) ...[
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  20, 28, 20, 14),
                              child: Text(
                                'สถิติของคุณ',
                                style: GoogleFonts.anuphan(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.neutral900Dark
                                      : AppColors.neutral900,
                                ),
                              ),
                            ),
                          ),
                          StatsGrid(isDark: isDark),

                          // Recent bills
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  20, 28, 20, 14),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'บิลล่าสุด',
                                      style: GoogleFonts.anuphan(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? AppColors.neutral900Dark
                                            : AppColors.neutral900,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => context.go('/bills'),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? AppColors.accentIceDark
                                            : AppColors.accentIce,
                                        borderRadius: BorderRadius.circular(
                                            AppRadii.full),
                                      ),
                                      child: Text(
                                        'ดูทั้งหมด',
                                        style: GoogleFonts.notoSansThai(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? AppColors.primaryBlueDark
                                              : AppColors.primaryBlue,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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

// ── Local data model (rate) ───────────────────────────────────────────────────

class _RateData {
  final String code;
  final double rate;
  const _RateData({required this.code, required this.rate});
}
