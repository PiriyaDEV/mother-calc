import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/bill_utils.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/shared_bill_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _supabase = Supabase.instance.client;

  List<Group> _groups = [];
  List<Bill> _personalBills = [];
  Map<String, List<Bill>> _groupBills = {};
  bool _dataLoading = true;

  List<_RateData> _rates = [];
  bool _ratesLoading = true;
  String _ratesUpdated = '';

  static const _currencies = [
    _CurrencyConfig('USD', 'ดอลลาร์สหรัฐ', '🇺🇸'),
    _CurrencyConfig('EUR', 'ยูโร', '🇪🇺'),
    _CurrencyConfig('JPY', 'เยนญี่ปุ่น', '🇯🇵'),
    _CurrencyConfig('CNY', 'หยวนจีน', '🇨🇳'),
    _CurrencyConfig('GBP', 'ปอนด์อังกฤษ', '🇬🇧'),
    _CurrencyConfig('KRW', 'วอนเกาหลี', '🇰🇷'),
    _CurrencyConfig('SGD', 'ดอลลาร์สิงคโปร์', '🇸🇬'),
    _CurrencyConfig('AUD', 'ดอลลาร์ออสเตรเลีย', '🇦🇺'),
    _CurrencyConfig('HKD', 'ดอลลาร์ฮ่องกง', '🇭🇰'),
    _CurrencyConfig('MYR', 'ริงกิตมาเลเซีย', '🇲🇾'),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadRates();
  }

  Future<void> _loadData() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    setState(() => _dataLoading = true);
    try {
      final groupsData = await _supabase
          .from('group_members')
          .select('group:groups(*)')
          .eq('user_id', user.id);
      final groups = (groupsData as List)
          .map((e) => Group.fromJson(e['group'] as Map<String, dynamic>))
          .toList();

      final billsData = await _supabase
          .from('bills')
          .select('*, bill_members(*, profiles(id, username, display_name, avatar_url)), bill_items(*)')
          .eq('owner_id', user.id)
          .isFilter('group_id', null)
          .order('updated_at', ascending: false);
      final personalBills =
          (billsData as List).map((e) => Bill.fromJson(e)).toList();

      final Map<String, List<Bill>> groupBills = {};
      for (final g in groups) {
        final gBillsData = await _supabase
            .from('bills')
            .select('*, bill_members(*, profiles(id, username, display_name, avatar_url)), bill_items(*)')
            .eq('group_id', g.id)
            .order('updated_at', ascending: false);
        groupBills[g.id] =
            (gBillsData as List).map((e) => Bill.fromJson(e)).toList();
      }

      if (mounted) {
        setState(() {
          _groups = groups;
          _personalBills = personalBills;
          _groupBills = groupBills;
          _dataLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading home data: $e');
      if (mounted) setState(() => _dataLoading = false);
    }
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

  List<Bill> get _allBills => [
        ..._personalBills,
        ..._groupBills.values.expand((b) => b),
      ];

  double get _grandTotal =>
      _allBills.fold(0, (s, b) => s + _billTotal(b));

  int get _totalItems =>
      _allBills.fold(0, (s, b) => s + b.items.length);

  double _billTotal(Bill b) =>
      b.items.fold(0.0, (s, i) => s + i.price);

  List<Bill> get _recentBills {
    final sorted = [..._allBills]
      ..sort((a, b) {
        final aTime = a.updatedAt ?? DateTime(0);
        final bTime = b.updatedAt ?? DateTime(0);
        return bTime.compareTo(aTime);
      });
    return sorted.take(3).toList();
  }

  Bill? get _biggestBill {
    if (_allBills.isEmpty) return null;
    return [..._allBills]
        .reduce((a, b) => _billTotal(a) >= _billTotal(b) ? a : b);
  }

  String _formatBaht(double n) => formatNumber(n);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = context.watch<AuthProvider>().profile;
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
          gradient: isDark ? AppGradients.backgroundDark : AppGradients.backgroundLight,
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: RefreshIndicator(
            onRefresh: () async {
              await _loadData();
              await _loadRates();
            },
            color: AppColors.primary,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ── Top bar: greeting + avatar ──────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'สวัสดี, $firstName 👋',
                                style: GoogleFonts.anuphan(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? AppColors.neutral600Dark
                                      : AppColors.neutral600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'ยินดีต้อนรับกลับมา',
                                style: GoogleFonts.anuphan(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.neutral900Dark
                                      : AppColors.neutral900,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Notification / wallet icon button
                        Container(
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
                                      color: const Color(0xFF2D5BFF).withValues(alpha: 0.10),
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

                // ── Hero balance card ────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2D5BFF), Color(0xFF1A3FCC), Color(0xFF0B1E3D)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          stops: [0.0, 0.55, 1.0],
                        ),
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2D5BFF).withValues(alpha: 0.40),
                            blurRadius: 32,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Decorative circles
                          Positioned(
                            right: -24,
                            top: -32,
                            child: Container(
                              width: 130,
                              height: 130,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.06),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 30,
                            bottom: -50,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.04),
                              ),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ยอดรวมทั้งหมด',
                                style: GoogleFonts.notoSansThai(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.65),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (_dataLoading)
                                const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              else
                                Text(
                                  '฿${_formatBaht(_grandTotal)}',
                                  style: GoogleFonts.anuphan(
                                    fontSize: 38,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: -1,
                                    height: 1.1,
                                  ),
                                ),
                              const SizedBox(height: 20),
                              // Stats pills row
                              if (!_dataLoading)
                                Row(
                                  children: [
                                    _HeroPill(
                                      label: '${_groups.length} กลุ่ม',
                                      icon: Icons.people_rounded,
                                    ),
                                    const SizedBox(width: 8),
                                    _HeroPill(
                                      label: '${_allBills.length} บิล',
                                      icon: Icons.receipt_rounded,
                                    ),
                                    const SizedBox(width: 8),
                                    _HeroPill(
                                      label: '$_totalItems รายการ',
                                      icon: Icons.list_rounded,
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Quick actions ────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
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
                              child: _QuickActionTile(
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
                              child: _QuickActionTile(
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
                              child: _QuickActionTile(
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

                // ── Currency exchange rates ───────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
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
                                      : Colors.white.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(AppRadii.sm),
                                  boxShadow: isDark
                                      ? null
                                      : [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.06),
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
                              ? ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: 5,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 10),
                                  itemBuilder: (_, __) => Container(
                                    width: 130,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppColors.surfaceDark
                                          : Colors.white,
                                      borderRadius:
                                          BorderRadius.circular(AppRadii.md),
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _rates.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 10),
                                  itemBuilder: (_, i) {
                                    final r = _rates[i];
                                    final cfg = _currencies.firstWhere(
                                        (c) => c.code == r.code);
                                    final isJpyKrw =
                                        r.code == 'JPY' || r.code == 'KRW';
                                    final rateStr = isJpyKrw
                                        ? r.rate.toStringAsFixed(4)
                                        : r.rate.toStringAsFixed(2);
                                    return _CurrencyCard(
                                      code: r.code,
                                      name: cfg.name,
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

                // ── Stats / loading ──────────────────────────────
                if (_dataLoading)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  )
                else ...[
                  // Stats cards
                  if (_allBills.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
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
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.55,
                        ),
                        delegate: SliverChildListDelegate([
                          _StatCard(
                            icon: Icons.trending_up_rounded,
                            label: 'เฉลี่ยต่อบิล',
                            value: '฿${_formatBaht(_allBills.isEmpty ? 0 : _grandTotal / _allBills.length)}',
                            accentColor: AppColors.primaryBlue,
                            bgColor: isDark
                                ? AppColors.accentIceDark
                                : AppColors.accentIce,
                          ),
                          _StatCard(
                            icon: Icons.receipt_long_rounded,
                            label: 'บิลทั้งหมด',
                            value: '${_allBills.length} บิล',
                            accentColor: const Color(0xFF7B5CF6),
                            bgColor: isDark
                                ? const Color(0xFF1E1A3A)
                                : const Color(0xFFEDE9FE),
                          ),
                          _StatCard(
                            icon: Icons.format_list_bulleted_rounded,
                            label: 'รายการทั้งหมด',
                            value: '$_totalItems รายการ',
                            accentColor: AppColors.amber,
                            bgColor: isDark
                                ? AppColors.amber.withValues(alpha: 0.12)
                                : AppColors.amberFaint,
                          ),
                          _StatCard(
                            icon: Icons.star_rounded,
                            label: 'บิลใหญ่สุด',
                            value: _biggestBill != null
                                ? '฿${_formatBaht(_billTotal(_biggestBill!))}'
                                : '—',
                            accentColor: AppColors.emerald,
                            bgColor: isDark
                                ? AppColors.emerald.withValues(alpha: 0.12)
                                : AppColors.greenFaint,
                          ),
                        ]),
                      ),
                    ),
                  ],

                  // Recent bills
                  if (_recentBills.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
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
                                  borderRadius:
                                      BorderRadius.circular(AppRadii.full),
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
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final bill = _recentBills[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: SharedBillCard(
                                bill: bill,
                                onTap: () => context.push('/bills/${bill.id}'),
                              ),
                            );
                          },
                          childCount: _recentBills.length,
                        ),
                      ),
                    ),
                  ],

                  // Empty state
                  if (_allBills.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.surfaceDark
                                : Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(AppRadii.lg),
                            boxShadow: isDark
                                ? null
                                : [
                                    BoxShadow(
                                      color: const Color(0xFF2D5BFF)
                                          .withValues(alpha: 0.08),
                                      blurRadius: 24,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.accentIceDark
                                      : AppColors.accentIce,
                                  borderRadius:
                                      BorderRadius.circular(AppRadii.lg),
                                ),
                                child: const Icon(
                                  Icons.receipt_long_outlined,
                                  size: 32,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'ยังไม่มีบิล',
                                style: GoogleFonts.anuphan(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.neutral900Dark
                                      : AppColors.neutral900,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'สร้างบิลแรกหรือเข้าร่วมกลุ่มเพื่อเริ่มต้น',
                                style: GoogleFonts.notoSansThai(
                                  fontSize: 13,
                                  color: isDark
                                      ? AppColors.neutral600Dark
                                      : AppColors.neutral600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => context.go('/bills'),
                                      child: Container(
                                        height: 48,
                                        decoration: BoxDecoration(
                                          gradient: AppGradients.primaryButtonLight,
                                          borderRadius: BorderRadius.circular(
                                              AppRadii.full),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.primaryBlue
                                                  .withValues(alpha: 0.30),
                                              blurRadius: 16,
                                              offset: const Offset(0, 6),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Text(
                                            'สร้างบิล',
                                            style: GoogleFonts.notoSansThai(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => context.go('/groups'),
                                      child: Container(
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? AppColors.surfaceDark
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(
                                              AppRadii.full),
                                          border: Border.all(
                                            color: isDark
                                                ? AppColors.borderDark
                                                : AppColors.neutral100,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            'สร้างกลุ่ม',
                                            style: GoogleFonts.notoSansThai(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: isDark
                                                  ? AppColors.neutral900Dark
                                                  : AppColors.neutral900,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
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

// ── Helper widgets ─────────────────────────────────────────────────────────────

class _CurrencyConfig {
  final String code;
  final String name;
  final String flag;
  const _CurrencyConfig(this.code, this.name, this.flag);
}

class _RateData {
  final String code;
  final double rate;
  const _RateData({required this.code, required this.rate});
}

class _HeroPill extends StatelessWidget {
  final String label;
  final IconData icon;

  const _HeroPill({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadii.full),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.9)),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.notoSansThai(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(AppRadii.md),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: const Color(0xFF2D5BFF).withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: GoogleFonts.notoSansThai(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.neutral900Dark : AppColors.neutral900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sublabel,
              style: GoogleFonts.notoSansThai(
                fontSize: 10,
                color: isDark ? AppColors.neutral400Dark : AppColors.neutral400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrencyCard extends StatelessWidget {
  final String code;
  final String name;
  final String flag;
  final String rateStr;
  final bool isDark;

  const _CurrencyCard({
    required this.code,
    required this.name,
    required this.flag,
    required this.rateStr,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.neutral100,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -6,
            bottom: -10,
            child: Opacity(
              opacity: 0.18,
              child: Text(flag, style: const TextStyle(fontSize: 52)),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Text(
                  code,
                  style: GoogleFonts.notoSansThai(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '฿$rateStr',
                style: GoogleFonts.anuphan(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.neutral900Dark : AppColors.neutral900,
                ),
              ),
              Text(
                name,
                style: GoogleFonts.notoSansThai(
                  fontSize: 10,
                  color: isDark ? AppColors.neutral400Dark : AppColors.neutral400,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;
  final Color bgColor;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.md),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF2D5BFF).withValues(alpha: 0.07),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Icon(icon, size: 20, color: accentColor),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.anuphan(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.notoSansThai(
                  fontSize: 11,
                  color: isDark ? AppColors.neutral400Dark : AppColors.neutral400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
