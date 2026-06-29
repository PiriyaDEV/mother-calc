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
      // Load groups
      final groupsData = await _supabase
          .from('group_members')
          .select('group:groups(*)')
          .eq('user_id', user.id);
      final groups = (groupsData as List)
          .map((e) => Group.fromJson(e['group'] as Map<String, dynamic>))
          .toList();

      // Load personal bills
      final billsData = await _supabase
          .from('bills')
          .select('*, bill_members(*), bill_items(*)')
          .eq('owner_id', user.id)
          .isFilter('group_id', null)
          .order('updated_at', ascending: false);
      final personalBills =
          (billsData as List).map((e) => Bill.fromJson(e)).toList();

      // Load group bills
      final Map<String, List<Bill>> groupBills = {};
      for (final g in groups) {
        final gBillsData = await _supabase
            .from('bills')
            .select('*, bill_members(*), bill_items(*)')
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
    // Fallback
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
      backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF4F6FB),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _loadData();
            await _loadRates();
          },
          color: AppColors.primary,
          child: CustomScrollView(
            slivers: [
              // ── Hero card ──────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF286BFE), Color(0xFF6B8AFF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF286BFE).withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'สวัสดี, $firstName 👋',
                                    style: GoogleFonts.notoSansThai(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withValues(alpha: 0.85),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'ยอดรวมทั้งหมดของคุณ',
                                    style: GoogleFonts.notoSansThai(
                                      fontSize: 12,
                                      color: Colors.white.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet_outlined,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_dataLoading)
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        else ...[
                          Text(
                            '${_formatBaht(_grandTotal)} บาท',
                            style: GoogleFonts.notoSansThai(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                '${_groups.length} กลุ่ม',
                                style: GoogleFonts.notoSansThai(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 6),
                                child: Text(
                                  '·',
                                  style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.4)),
                                ),
                              ),
                              Text(
                                '${_personalBills.length} บิลส่วนตัว',
                                style: GoogleFonts.notoSansThai(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 6),
                                child: Text(
                                  '·',
                                  style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.4)),
                                ),
                              ),
                              Text(
                                '$_totalItems รายการ',
                                style: GoogleFonts.notoSansThai(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              // ── Quick actions ──────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _QuickActionCard(
                          icon: Icons.people_outline_rounded,
                          label: 'กลุ่ม',
                          sublabel: '${_groups.length} กลุ่ม',
                          iconColor: const Color(0xFFA855F7),
                          iconBg: const Color(0xFFF5F3FF),
                          iconBgDark: const Color(0xFF2D1B69),
                          onTap: () => context.go('/groups'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _QuickActionCard(
                          icon: Icons.receipt_long_outlined,
                          label: 'บิล',
                          sublabel: '${_personalBills.length} บิล',
                          iconColor: Colors.white,
                          iconBg: const Color(0xFF286BFE),
                          iconBgDark: const Color(0xFF286BFE),
                          isPrimary: true,
                          onTap: () => context.go('/bills'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _QuickActionCard(
                          icon: Icons.person_add_outlined,
                          label: 'เพื่อน',
                          sublabel: 'จัดการ',
                          iconColor: const Color(0xFF22C55E),
                          iconBg: const Color(0xFFF0FDF4),
                          iconBgDark: const Color(0xFF14532D),
                          onTap: () => context.go('/friends'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Currency exchange rates ─────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'อัตราแลกเปลี่ยน',
                                  style: GoogleFonts.notoSansThai(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textPrimaryLight,
                                  ),
                                ),
                                if (_ratesUpdated.isNotEmpty)
                                  Text(
                                    'อัปเดต $_ratesUpdated',
                                    style: GoogleFonts.notoSansThai(
                                      fontSize: 10,
                                      color: isDark
                                          ? AppColors.textTertiaryDark
                                          : AppColors.textTertiaryLight,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: _ratesLoading ? null : _loadRates,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.surfaceDark
                                    : const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: _ratesLoading
                                  ? const Padding(
                                      padding: EdgeInsets.all(6),
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.primary),
                                    )
                                  : Icon(
                                      Icons.refresh_rounded,
                                      size: 14,
                                      color: isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondaryLight,
                                    ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 110,
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
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isDark
                                          ? AppColors.borderDark
                                          : AppColors.borderLight,
                                    ),
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
                                  return Container(
                                    width: 136,
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppColors.surfaceDark
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isDark
                                            ? AppColors.borderDark
                                            : AppColors.borderLight,
                                      ),
                                    ),
                                    child: Stack(
                                      children: [
                                        Positioned(
                                          right: -4,
                                          bottom: -8,
                                          child: Text(
                                            cfg.flag,
                                            style: const TextStyle(
                                                fontSize: 52),
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '฿$rateStr',
                                              style: GoogleFonts.notoSansThai(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: isDark
                                                    ? AppColors.textPrimaryDark
                                                    : AppColors.textPrimaryLight,
                                              ),
                                            ),
                                            Text(
                                              '1 ${r.code}',
                                              style: GoogleFonts.notoSansThai(
                                                fontSize: 10,
                                                color: isDark
                                                    ? AppColors.textTertiaryDark
                                                    : AppColors.textTertiaryLight,
                                              ),
                                            ),
                                            Text(
                                              cfg.name,
                                              style: GoogleFonts.notoSansThai(
                                                fontSize: 10,
                                                color: isDark
                                                    ? AppColors.textSecondaryDark
                                                    : AppColors.textSecondaryLight,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Stats / loading ────────────────────────────
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
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                      child: Text(
                        'สถิติของคุณ',
                        style: GoogleFonts.notoSansThai(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 2.4,
                      ),
                      delegate: SliverChildListDelegate([
                        _FactCard(
                          icon: Icons.trending_up_rounded,
                          label: 'เฉลี่ยต่อบิล',
                          value:
                              '${_formatBaht(_allBills.isEmpty ? 0 : _grandTotal / _allBills.length)} ฿',
                          iconColor: const Color(0xFF286BFE),
                          iconBg: const Color(0xFFEFF6FF),
                          iconBgDark: const Color(0xFF1E3A5F),
                        ),
                        _FactCard(
                          icon: Icons.receipt_long_outlined,
                          label: 'บิลทั้งหมด',
                          value: '${_allBills.length} บิล',
                          iconColor: const Color(0xFFA855F7),
                          iconBg: const Color(0xFFF5F3FF),
                          iconBgDark: const Color(0xFF2D1B69),
                        ),
                        _FactCard(
                          icon: Icons.local_fire_department_outlined,
                          label: 'รายการทั้งหมด',
                          value: '$_totalItems รายการ',
                          iconColor: const Color(0xFFF97316),
                          iconBg: const Color(0xFFFFF7ED),
                          iconBgDark: const Color(0xFF431407),
                        ),
                        _FactCard(
                          icon: Icons.star_outline_rounded,
                          label: 'บิลใหญ่สุด',
                          value: _biggestBill != null
                              ? '${_formatBaht(_billTotal(_biggestBill!))} ฿'
                              : '—',
                          iconColor: const Color(0xFFF59E0B),
                          iconBg: const Color(0xFFFFFBEB),
                          iconBgDark: const Color(0xFF451A03),
                        ),
                      ]),
                    ),
                  ),
                ],

                // Recent bills
                if (_recentBills.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'บิลล่าสุด',
                            style: GoogleFonts.notoSansThai(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.go('/bills'),
                            child: Text(
                              'ดูทั้งหมด',
                              style: GoogleFonts.notoSansThai(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final bill = _recentBills[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _RecentBillRow(
                              bill: bill,
                              total: _billTotal(bill),
                              formatBaht: _formatBaht,
                              onTap: () =>
                                  context.push('/bills/${bill.id}'),
                            ),
                          );
                        },
                        childCount: _recentBills.length,
                      ),
                    ),
                  ),
                ],

                // Biggest bill highlight
                if (_biggestBill != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.star_outline_rounded,
                                    size: 14,
                                    color: Color(0xFFF59E0B)),
                                const SizedBox(width: 6),
                                Text(
                                  'บิลที่ใหญ่ที่สุด',
                                  style: GoogleFonts.notoSansThai(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFFBEB),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      _biggestBill!.emoji ?? '🧾',
                                      style:
                                          const TextStyle(fontSize: 20),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _biggestBill!.title,
                                        style: GoogleFonts.notoSansThai(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? AppColors.textPrimaryDark
                                              : AppColors.textPrimaryLight,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '${_biggestBill!.items.length} รายการ',
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
                                Text(
                                  '${_formatBaht(_billTotal(_biggestBill!))} ฿',
                                  style: GoogleFonts.notoSansThai(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFF59E0B),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Empty state
                if (_allBills.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.receipt_long_outlined,
                              size: 28,
                              color: Color(0xFF286BFE),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'ยังไม่มีบิล',
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
                            'สร้างบิลแรกหรือเข้าร่วมกลุ่มเพื่อเริ่มต้น',
                            style: GoogleFonts.notoSansThai(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.textTertiaryDark
                                  : AppColors.textTertiaryLight,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: () => context.go('/bills'),
                                child: Text(
                                  'สร้างบิล',
                                  style: GoogleFonts.notoSansThai(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                              const SizedBox(width: 10),
                              OutlinedButton(
                                onPressed: () => context.go('/groups'),
                                child: Text(
                                  'สร้างกลุ่ม',
                                  style: GoogleFonts.notoSansThai(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],

              // Extra bottom padding for floating nav bar
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
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

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color iconColor;
  final Color iconBg;
  final Color iconBgDark;
  final bool isPrimary;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.iconColor,
    required this.iconBg,
    required this.iconBgDark,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: isPrimary
              ? const Color(0xFF286BFE)
              : (isDark ? AppColors.surfaceDark : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: isPrimary
              ? null
              : Border.all(
                  color:
                      isDark ? AppColors.borderDark : AppColors.borderLight),
                  boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: const Color(0xFF286BFE).withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isPrimary
                    ? Colors.white.withValues(alpha: 0.2)
                    : (isDark ? iconBgDark : iconBg),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon,
                  size: 20,
                  color: isPrimary ? Colors.white : iconColor),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.notoSansThai(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isPrimary
                    ? Colors.white
                    : (isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sublabel,
              style: GoogleFonts.notoSansThai(
                fontSize: 10,
                color: isPrimary
                    ? Colors.white.withValues(alpha: 0.7)
                    : (isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FactCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final Color iconBg;
  final Color iconBgDark;

  const _FactCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    required this.iconBg,
    required this.iconBgDark,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDark ? iconBgDark : iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: GoogleFonts.notoSansThai(
                    fontSize: 10,
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.notoSansThai(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentBillRow extends StatelessWidget {
  final Bill bill;
  final double total;
  final String Function(double) formatBaht;
  final VoidCallback onTap;

  const _RecentBillRow({
    required this.bill,
    required this.total,
    required this.formatBaht,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = bill.status == 'settled'
        ? const Color(0xFF22C55E)
        : bill.status == 'active'
            ? const Color(0xFF286BFE)
            : const Color(0xFF9CA3AF);
    final statusLabel = bill.status == 'settled'
        ? 'ชำระแล้ว'
        : bill.status == 'active'
            ? 'กำลังใช้งาน'
            : 'ร่าง';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  bill.emoji ?? '🧾',
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bill.title,
                    style: GoogleFonts.notoSansThai(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          statusLabel,
                          style: GoogleFonts.notoSansThai(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${bill.items.length} รายการ · ${_formatDate(bill.updatedAt)}',
                        style: GoogleFonts.notoSansThai(
                          fontSize: 10,
                          color: isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textTertiaryLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              '${formatBaht(total)} ฿',
              style: GoogleFonts.notoSansThai(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF286BFE),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    const months = [
      '', 'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
      'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
    ];
    return '${dt.day} ${months[dt.month]}';
  }
}
