import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../providers/bill_provider.dart';
import '../theme/app_theme.dart';
import '../utils/bill_utils.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/member_avatar.dart';
import '../widgets/analytics_tab.dart';
import '../widgets/summary_tab.dart';

class BillDetailScreen extends StatefulWidget {
  final String billId;
  const BillDetailScreen({super.key, required this.billId});

  @override
  State<BillDetailScreen> createState() => _BillDetailScreenState();
}

class _BillDetailScreenState extends State<BillDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _currentTab = _tabController.index);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BillProvider>().loadBill(widget.billId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final billProvider = context.watch<BillProvider>();
    final bill = billProvider.bill;

    if (billProvider.loading) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
        ),
      );
    }

    if (bill == null) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Text(
            'ไม่พบบิล',
            style: GoogleFonts.notoSansThai(fontSize: 16),
          ),
        ),
      );
    }

    final calc = calculateBill(bill.copyWith(
      members: billProvider.members,
      items: billProvider.items,
    ));

    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isOwner = bill.ownerId == currentUserId;
    final isCompleted = bill.isCompleted;
    final members = billProvider.members;
    final items = billProvider.items;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            pinned: true,
            expandedHeight: 0,
            backgroundColor: isDark
                ? AppColors.bgDark.withValues(alpha: 0.95)
                : Colors.white.withValues(alpha: 0.95),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded),
              onPressed: () => context.pop(),
            ),
            title: Row(
              children: [
                // Emoji + title
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        bill.emoji ?? '🧾',
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          bill.title,
                          style: GoogleFonts.notoSansThai(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isCompleted) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.emerald.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock_rounded,
                                  size: 11, color: AppColors.emerald),
                              const SizedBox(width: 3),
                              Text(
                                'ปิดแล้ว',
                                style: GoogleFonts.notoSansThai(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.emerald,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              // ปิดบิล / เปิดใหม่ button
              if (!isCompleted)
                GestureDetector(
                  onTap: () async {
                    final ok = await showConfirmDialog(
                      context,
                      title: 'ปิดบิลนี้?',
                      description:
                          'หลังจากปิดแล้ว จะไม่สามารถแก้ไขสมาชิกหรือรายการได้ แต่ยังสามารถทำเครื่องหมายว่าจ่ายแล้วได้',
                      confirmLabel: 'ปิดบิล',
                    );
                    if (ok == true) {
                      await billProvider.completeBill(bill.id);
                      _tabController.animateTo(2); // switch to สรุป
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.emerald,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_rounded,
                            size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          'ปิดบิล',
                          style: GoogleFonts.notoSansThai(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                GestureDetector(
                  onTap: () async {
                    final ok = await showConfirmDialog(
                      context,
                      title: 'เปิดบิลใหม่?',
                      description: 'บิลจะกลับมาแก้ไขได้อีกครั้ง',
                      confirmLabel: 'เปิดใหม่',
                    );
                    if (ok == true) {
                      await billProvider.reopenBill(bill.id);
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF374151)
                          : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_open_rounded,
                            size: 14,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight),
                        const SizedBox(width: 4),
                        Text(
                          'เปิดใหม่',
                          style: GoogleFonts.notoSansThai(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // ⚙️ gear — only owner + draft
              if (isOwner && !isCompleted)
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => _showSettingsSheet(context, bill, billProvider),
                ),
              const SizedBox(width: 4),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: _PillTabBar(
                controller: _tabController,
                currentIndex: _currentTab,
                isDark: isDark,
                membersCount: members.length,
                itemsCount: items.length,
              ),
            ),
          ),
        ],
        body: Column(
          children: [
            // Completed banner
            if (isCompleted)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  border: Border(
                    bottom: BorderSide(
                        color: const Color(0xFFA7F3D0), width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_rounded,
                        size: 14, color: Color(0xFF065F46)),
                    const SizedBox(width: 8),
                    Text(
                      'บิลนี้ปิดแล้ว — ดูได้อย่างเดียว ไม่สามารถแก้ไขได้',
                      style: GoogleFonts.notoSansThai(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF065F46),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _MembersTab(
                      bill: bill,
                      billProvider: billProvider,
                      calc: calc,
                      readOnly: isCompleted),
                  _ItemsTab(
                      bill: bill,
                      billProvider: billProvider,
                      calc: calc,
                      readOnly: isCompleted),
                  SummaryTab(
                      bill: bill, billProvider: billProvider, calc: calc),
                  AnalyticsTab(
                      bill: bill, billProvider: billProvider, calc: calc),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  void _showSettingsSheet(
      BuildContext context, Bill bill, BillProvider billProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = bill.settings;
    bool isService = settings.isService;
    bool isVat = settings.isVat;
    double serviceCharge = settings.serviceCharge > 0 ? settings.serviceCharge : 10;
    double vat = settings.vat > 0 ? settings.vat : 7;
    double tip = settings.tip;
    double discount = settings.discount;
    String currency = settings.currency;

    const currencies = ['THB', 'USD', 'EUR', 'JPY', 'SGD', 'GBP', 'CNY', 'KRW'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'ตั้งค่าบิล',
                  style: GoogleFonts.notoSansThai(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 20),

                // ── Service Charge toggle ──
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isService
                          ? AppColors.primary.withOpacity(0.4)
                          : (isDark ? AppColors.borderDark : AppColors.borderLight),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Service Charge',
                                  style: GoogleFonts.notoSansThai(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textPrimaryLight,
                                  ),
                                ),
                                Text(
                                  'ค่าบริการ ${serviceCharge.toStringAsFixed(0)}%',
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
                          Switch(
                            value: isService,
                            onChanged: (v) => setModalState(() => isService = v),
                            activeColor: AppColors.primary,
                          ),
                        ],
                      ),
                      if (isService) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Slider(
                                value: serviceCharge.clamp(0, 20),
                                min: 0,
                                max: 20,
                                divisions: 20,
                                activeColor: AppColors.primary,
                                onChanged: (v) =>
                                    setModalState(() => serviceCharge = v),
                              ),
                            ),
                            SizedBox(
                              width: 60,
                              child: TextField(
                                controller: TextEditingController(
                                    text: serviceCharge.toStringAsFixed(0)),
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.notoSansThai(fontSize: 13),
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 6),
                                  isDense: true,
                                  suffixText: '%',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onChanged: (v) => setModalState(
                                    () => serviceCharge = double.tryParse(v) ?? serviceCharge),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // ── VAT toggle ──
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isVat
                          ? AppColors.primary.withOpacity(0.4)
                          : (isDark ? AppColors.borderDark : AppColors.borderLight),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'VAT',
                                  style: GoogleFonts.notoSansThai(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textPrimaryLight,
                                  ),
                                ),
                                Text(
                                  'ภาษีมูลค่าเพิ่ม ${vat.toStringAsFixed(0)}%',
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
                          Switch(
                            value: isVat,
                            onChanged: (v) => setModalState(() => isVat = v),
                            activeColor: AppColors.primary,
                          ),
                        ],
                      ),
                      if (isVat) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Slider(
                                value: vat.clamp(0, 20),
                                min: 0,
                                max: 20,
                                divisions: 20,
                                activeColor: AppColors.primary,
                                onChanged: (v) =>
                                    setModalState(() => vat = v),
                              ),
                            ),
                            SizedBox(
                              width: 60,
                              child: TextField(
                                controller: TextEditingController(
                                    text: vat.toStringAsFixed(0)),
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.notoSansThai(fontSize: 13),
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 6),
                                  isDense: true,
                                  suffixText: '%',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onChanged: (v) => setModalState(
                                    () => vat = double.tryParse(v) ?? vat),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // ── Tip ──
                _SettingsRow(
                  label: 'ทิป (บาท)',
                  value: tip,
                  onChanged: (v) => setModalState(() => tip = v),
                ),
                const SizedBox(height: 10),

                // ── Discount ──
                _SettingsRow(
                  label: 'ส่วนลด (บาท)',
                  value: discount,
                  onChanged: (v) => setModalState(() => discount = v),
                ),
                const SizedBox(height: 16),

                // ── Currency grid ──
                Text(
                  'สกุลเงิน',
                  style: GoogleFonts.notoSansThai(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: currencies.map((c) {
                    final selected = currency == c;
                    return GestureDetector(
                      onTap: () => setModalState(() => currency = c),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary
                              : (isDark
                                  ? const Color(0xFF1F2937)
                                  : const Color(0xFFF3F4F6)),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : Colors.transparent,
                          ),
                        ),
                        child: Text(
                          c,
                          style: GoogleFonts.notoSansThai(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? Colors.white
                                : (isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await billProvider.updateBillMeta(
                      billId: bill.id,
                      settings: BillSettings(
                        serviceCharge: isService ? serviceCharge : 0,
                        vat: isVat ? vat : 0,
                        tip: tip,
                        discount: discount,
                        currency: currency,
                        isService: isService,
                        isVat: isVat,
                      ),
                    );
                  },
                  child: Text('บันทึก',
                      style: GoogleFonts.notoSansThai(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}

// ── Pill Tab Bar ──────────────────────────────────────────────
class _PillTabBar extends StatelessWidget {
  final TabController controller;
  final int currentIndex;
  final bool isDark;
  final int membersCount;
  final int itemsCount;

  const _PillTabBar({
    required this.controller,
    required this.currentIndex,
    required this.isDark,
    required this.membersCount,
    required this.itemsCount,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _TabDef(id: 0, label: 'สมาชิก', count: membersCount),
      _TabDef(id: 1, label: 'รายการ', count: itemsCount),
      _TabDef(id: 2, label: 'สรุป', count: null),
      _TabDef(id: 3, label: 'วิเคราะห์', count: null),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: tabs.map((tab) {
          final isActive = currentIndex == tab.id;
          return Expanded(
            child: GestureDetector(
              onTap: () => controller.animateTo(tab.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isActive
                      ? (isDark ? const Color(0xFF374151) : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          )
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tab.label,
                      style: GoogleFonts.notoSansThai(
                        fontSize: 12,
                        fontWeight: isActive
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: isActive
                            ? AppColors.primary
                            : (isDark
                                ? AppColors.textTertiaryDark
                                : const Color(0xFF6B7280)),
                      ),
                    ),
                    if (tab.count != null) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : (isDark
                                  ? const Color(0xFF374151)
                                  : const Color(0xFFE5E7EB)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${tab.count}',
                          style: GoogleFonts.notoSansThai(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isActive
                                ? AppColors.primary
                                : (isDark
                                    ? AppColors.textTertiaryDark
                                    : const Color(0xFF6B7280)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TabDef {
  final int id;
  final String label;
  final int? count;
  const _TabDef({required this.id, required this.label, this.count});
}

// ── Items Tab ─────────────────────────────────────────────────
class _ItemsTab extends StatelessWidget {
  final Bill bill;
  final BillProvider billProvider;
  final BillCalculation calc;
  final bool readOnly;

  const _ItemsTab({
    required this.bill,
    required this.billProvider,
    required this.calc,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = billProvider.items;
    final members = billProvider.members;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Add item button
        if (!readOnly)
          GestureDetector(
            onTap: () => _showAddItemSheet(context, bill, billProvider),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_rounded,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'เพิ่มรายการ',
                    style: GoogleFonts.notoSansThai(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),

        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Column(
                children: [
                  const Text('🍽️', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 12),
                  Text(
                    'ยังไม่มีรายการ',
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
          )
        else ...[
          const SizedBox(height: 12),
          ...items.map((item) => _ItemTile(
                item: item,
                members: members,
                bill: bill,
                billProvider: billProvider,
                readOnly: readOnly,
              )),
        ],

        // Bill summary
        if (items.isNotEmpty) ...[
          const SizedBox(height: 16),
          _BillSummaryCard(calc: calc, currency: bill.settings.currency),
        ],
      ],
    );
  }

  void _showAddItemSheet(
      BuildContext context, Bill bill, BillProvider billProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ItemFormSheet(
        bill: bill,
        billProvider: billProvider,
        members: billProvider.members,
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  final BillItem item;
  final List<BillMember> members;
  final Bill bill;
  final BillProvider billProvider;
  final bool readOnly;

  const _ItemTile({
    required this.item,
    required this.members,
    required this.bill,
    required this.billProvider,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final assignedMembers = members
        .where((m) => item.shares.containsKey(m.id) && item.shares[m.id]! > 0)
        .toList();
    final paidByMember = item.paidBy != null
        ? members.where((m) => m.id == item.paidBy).firstOrNull
        : null;

    return GestureDetector(
      onTap: readOnly ? null : () => _showEditItemSheet(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: GoogleFonts.notoSansThai(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                ),
                // Unequal split badge
                if (item.isUnequalSplit) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.amber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'หารไม่เท่า',
                      style: GoogleFonts.notoSansThai(
                        fontSize: 10,
                        color: AppColors.amber,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  formatNumber(item.price),
                  style: GoogleFonts.notoSansThai(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                if (!readOnly) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight,
                  ),
                ],
              ],
            ),
            if (assignedMembers.isNotEmpty || paidByMember != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  // Stacked avatars
                  _StackedAvatars(members: assignedMembers),
                  const SizedBox(width: 6),
                  // "X คน · ฿Y/คน"
                  Expanded(
                    child: Text(
                      '${assignedMembers.length} คน'
                      '${!item.isUnequalSplit && assignedMembers.isNotEmpty ? ' · ฿${formatNumber(item.price / assignedMembers.length)}/คน' : ''}',
                      style: GoogleFonts.notoSansThai(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiaryLight,
                      ),
                    ),
                  ),
                  // Paid by avatar
                  if (paidByMember != null) ...[
                    Text(
                      'จ่ายโดย',
                      style: GoogleFonts.notoSansThai(
                        fontSize: 10,
                        color: isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiaryLight,
                      ),
                    ),
                    const SizedBox(width: 4),
                    MemberAvatar(
                      name: paidByMember.name,
                      color: colorFromHex(paidByMember.color),
                      size: 20,
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showEditItemSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ItemFormSheet(
        bill: bill,
        billProvider: billProvider,
        members: members,
        editItem: item,
      ),
    );
  }
}

class _BillSummaryCard extends StatelessWidget {
  final BillCalculation calc;
  final String currency;

  const _BillSummaryCard({required this.calc, required this.currency});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        children: [
          _SummaryRow(
              label: 'ยอดรวมก่อนภาษี',
              value: calc.subtotal,
              currency: currency),
          if (calc.serviceAmount > 0)
            _SummaryRow(
                label: 'Service Charge',
                value: calc.serviceAmount,
                currency: currency),
          if (calc.vatAmount > 0)
            _SummaryRow(
                label: 'VAT', value: calc.vatAmount, currency: currency),
          if (calc.tipAmount > 0)
            _SummaryRow(
                label: 'ทิป', value: calc.tipAmount, currency: currency),
          if (calc.discountAmount > 0)
            _SummaryRow(
                label: 'ส่วนลด',
                value: -calc.discountAmount,
                currency: currency,
                isDiscount: true),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ยอดรวมทั้งหมด',
                style: GoogleFonts.notoSansThai(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              Text(
                '${formatNumber(calc.total)} $currency',
                style: GoogleFonts.notoSansThai(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double value;
  final String currency;
  final bool isDiscount;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.currency,
    this.isDiscount = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.notoSansThai(
              fontSize: 13,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          Text(
            '${isDiscount ? '-' : ''}${formatNumber(value.abs())} $currency',
            style: GoogleFonts.notoSansThai(
              fontSize: 13,
              color: isDiscount
                  ? AppColors.emerald
                  : (isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Members Tab ───────────────────────────────────────────────
class _MembersTab extends StatelessWidget {
  final Bill bill;
  final BillProvider billProvider;
  final BillCalculation calc;
  final bool readOnly;

  const _MembersTab({
    required this.bill,
    required this.billProvider,
    required this.calc,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final members = billProvider.members;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (!readOnly)
          GestureDetector(
            onTap: () => _showAddMemberSheet(context, bill, billProvider),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_add_outlined,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'เพิ่มสมาชิก',
                    style: GoogleFonts.notoSansThai(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),

        if (members.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Column(
                children: [
                  const Text('👥', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 12),
                  Text(
                    'ยังไม่มีสมาชิก',
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
          )
        else ...[
          const SizedBox(height: 12),
          ...members.map((member) {
            final summary = calc.memberSummaries
                .firstWhere((s) => s.member.id == member.id,
                    orElse: () => MemberSummary(
                        member: member, total: 0, items: []));
            final isPaid =
                bill.paidMemberIds.contains(member.id);

            return _MemberTile(
              member: member,
              summary: summary,
              isPaid: isPaid,
              bill: bill,
              billProvider: billProvider,
              currency: bill.settings.currency,
              readOnly: readOnly,
            );
          }),
        ],
      ],
    );
  }

  void _showAddMemberSheet(
      BuildContext context, Bill bill, BillProvider billProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _MemberFormSheet(
        bill: bill,
        billProvider: billProvider,
      ),
    );
  }

}

class _MemberTile extends StatelessWidget {
  final BillMember member;
  final MemberSummary summary;
  final bool isPaid;
  final Bill bill;
  final BillProvider billProvider;
  final String currency;
  final bool readOnly;

  const _MemberTile({
    required this.member,
    required this.summary,
    required this.isPaid,
    required this.bill,
    required this.billProvider,
    required this.currency,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = colorFromHex(member.color);

    return GestureDetector(
      onTap: readOnly
          ? null
          : () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (ctx) => _MemberFormSheet(
                  bill: bill,
                  billProvider: billProvider,
                  editMember: member,
                ),
              ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        child: Row(
          children: [
            MemberAvatar(name: member.name, color: color, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: GoogleFonts.notoSansThai(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                Text(
                  '${summary.items.length} รายการ',
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatNumber(summary.total),
                style: GoogleFonts.notoSansThai(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              Text(
                currency,
                style: GoogleFonts.notoSansThai(
                  fontSize: 11,
                  color: isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textTertiaryLight,
                ),
              ),
            ],
          ),
            const SizedBox(width: 8),
            // Paid toggle
            GestureDetector(
              onTap: () async {
                await billProvider.toggleMemberPaid(
                    bill.id, member.id, bill.paidMemberIds);
              },
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isPaid
                      ? AppColors.emerald
                      : (isDark
                          ? const Color(0xFF374151)
                          : const Color(0xFFF3F4F6)),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPaid ? Icons.check_rounded : Icons.circle_outlined,
                  color: isPaid
                      ? Colors.white
                      : (isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight),
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Item Form Sheet ───────────────────────────────────────────
class _ItemFormSheet extends StatefulWidget {
  final Bill bill;
  final BillProvider billProvider;
  final List<BillMember> members;
  final BillItem? editItem;

  const _ItemFormSheet({
    required this.bill,
    required this.billProvider,
    required this.members,
    this.editItem,
  });

  @override
  State<_ItemFormSheet> createState() => _ItemFormSheetState();
}

class _ItemFormSheetState extends State<_ItemFormSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _priceCtrl;
  late Map<String, bool> _selectedMembers;
  late Map<String, TextEditingController> _unequalCtrls;
  String? _paidBy;
  bool _isUnequalSplit = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final edit = widget.editItem;
    _nameCtrl = TextEditingController(text: edit?.name ?? '');
    _priceCtrl = TextEditingController(
        text: edit != null ? edit.price.toStringAsFixed(2) : '');
    _isUnequalSplit = edit?.isUnequalSplit ?? false;
    _selectedMembers = {
      for (final m in widget.members)
        m.id: edit != null
            ? (edit.isUnequalSplit
                ? edit.customShares.containsKey(m.id)
                : edit.memberIds.contains(m.id))
            : false,
    };
    _unequalCtrls = {
      for (final m in widget.members)
        m.id: TextEditingController(
          text: (edit?.isUnequalSplit == true &&
                  edit!.customShares.containsKey(m.id))
              ? edit.customShares[m.id]!.toStringAsFixed(2)
              : '',
        ),
    };
    _paidBy = edit?.paidBy;
    // Default paidBy to first member if none set
    if (_paidBy == null && widget.members.isNotEmpty) {
      _paidBy = widget.members.first.id;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    for (final c in _unequalCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> get _selectedIds =>
      _selectedMembers.entries.where((e) => e.value).map((e) => e.key).toList();

  double get _price => double.tryParse(_priceCtrl.text) ?? 0;

  double get _perPersonAmount {
    final count = _selectedIds.length;
    if (count == 0 || _price <= 0) return 0;
    return _price / count;
  }

  double get _unequalTotal => _unequalCtrls.entries
      .where((e) => _selectedMembers[e.key] == true)
      .fold(0.0, (sum, e) => sum + (double.tryParse(e.value.text) ?? 0));

  bool get _unequalValid =>
      !_isUnequalSplit ||
      (_price > 0 && (_unequalTotal - _price).abs() < 0.01);

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final price = _price;
    if (name.isEmpty || price <= 0) return;
    if (!_unequalValid) return;

    final selectedIds = _selectedIds;
    Map<String, double> customShares = {};
    if (_isUnequalSplit) {
      for (final id in selectedIds) {
        customShares[id] = double.tryParse(_unequalCtrls[id]!.text) ?? 0;
      }
    }

    setState(() => _loading = true);
    try {
      if (widget.editItem != null) {
        await widget.billProvider.editItem(
          widget.editItem!.id,
          name: name,
          price: price,
          memberIds: _isUnequalSplit ? [] : selectedIds,
          customShares: _isUnequalSplit ? customShares : {},
          paidBy: _paidBy,
          clearCustomShares: !_isUnequalSplit,
        );
      } else {
        await widget.billProvider.addItem(
          name: name,
          price: price,
          memberIds: _isUnequalSplit ? [] : selectedIds,
          customShares: _isUnequalSplit ? customShares : {},
          paidBy: _paidBy,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _delete() async {
    if (widget.editItem == null) return;
    await widget.billProvider.deleteItem(widget.editItem!.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEdit = widget.editItem != null;
    final selectedIds = _selectedIds;
    final price = _price;

    return Container(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEdit ? 'แก้ไขรายการ' : 'เพิ่มรายการ',
                  style: GoogleFonts.notoSansThai(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                if (isEdit)
                  IconButton(
                    onPressed: _delete,
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: AppColors.red),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Name field
            TextField(
              controller: _nameCtrl,
              autofocus: !isEdit,
              decoration: const InputDecoration(hintText: 'ชื่อรายการ'),
            ),
            const SizedBox(height: 12),

            // Price field
            TextField(
              controller: _priceCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(hintText: 'ราคา'),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
              ],
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // ── Split mode toggle ──
            Row(
              children: [
                Expanded(
                  child: Text(
                    'วิธีหาร',
                    style: GoogleFonts.notoSansThai(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                ),
                // Equal split button
                GestureDetector(
                  onTap: () => setState(() => _isUnequalSplit = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: !_isUnequalSplit
                          ? AppColors.primary
                          : (isDark
                              ? const Color(0xFF1F2937)
                              : const Color(0xFFF3F4F6)),
                      borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(8)),
                    ),
                    child: Text(
                      'หารเท่า',
                      style: GoogleFonts.notoSansThai(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: !_isUnequalSplit
                            ? Colors.white
                            : (isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight),
                      ),
                    ),
                  ),
                ),
                // Unequal split button
                GestureDetector(
                  onTap: () => setState(() => _isUnequalSplit = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isUnequalSplit
                          ? AppColors.primary
                          : (isDark
                              ? const Color(0xFF1F2937)
                              : const Color(0xFFF3F4F6)),
                      borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(8)),
                    ),
                    child: Text(
                      'หารไม่เท่า',
                      style: GoogleFonts.notoSansThai(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _isUnequalSplit
                            ? Colors.white
                            : (isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Member selection ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'แบ่งให้ใคร',
                  style: GoogleFonts.notoSansThai(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                if (widget.members.isNotEmpty)
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() {
                          for (final m in widget.members) {
                            _selectedMembers[m.id] = true;
                          }
                        }),
                        child: Text(
                          'เลือกทั้งหมด',
                          style: GoogleFonts.notoSansThai(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => setState(() {
                          for (final m in widget.members) {
                            _selectedMembers[m.id] = false;
                          }
                        }),
                        child: Text(
                          'ล้าง',
                          style: GoogleFonts.notoSansThai(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiaryLight,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),

            if (widget.members.isEmpty)
              Text(
                'ยังไม่มีสมาชิก',
                style: GoogleFonts.notoSansThai(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textTertiaryLight,
                ),
              )
            else
              Column(
                children: widget.members.map((m) {
                  final selected = _selectedMembers[m.id] ?? false;
                  final color = colorFromHex(m.color);
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedMembers[m.id] = !selected),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? color.withOpacity(0.08)
                            : (isDark
                                ? const Color(0xFF1F2937)
                                : const Color(0xFFF9FAFB)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected ? color : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          MemberAvatar(name: m.name, color: color, size: 28),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              m.name,
                              style: GoogleFonts.notoSansThai(
                                fontSize: 14,
                                color: selected
                                    ? color
                                    : (isDark
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textPrimaryLight),
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          // Equal split: show per-person amount
                          if (!_isUnequalSplit && selected && price > 0)
                            Text(
                              '฿${_perPersonAmount.toStringAsFixed(2)}',
                              style: GoogleFonts.notoSansThai(
                                fontSize: 13,
                                color: color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          // Unequal split: show amount input
                          if (_isUnequalSplit && selected) ...[
                            SizedBox(
                              width: 90,
                              child: TextField(
                                controller: _unequalCtrls[m.id],
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                textAlign: TextAlign.right,
                                style: GoogleFonts.notoSansThai(
                                    fontSize: 13, color: color),
                                decoration: InputDecoration(
                                  hintText: '0.00',
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 6),
                                  isDense: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: color),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                        color: color, width: 2),
                                  ),
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d+\.?\d{0,2}'))
                                ],
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                          const SizedBox(width: 8),
                          Icon(
                            selected
                                ? Icons.check_circle_rounded
                                : Icons.circle_outlined,
                            color: selected
                                ? color
                                : (isDark
                                    ? AppColors.textTertiaryDark
                                    : AppColors.textTertiaryLight),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

            // Unequal split validation hint
            if (_isUnequalSplit && price > 0 && selectedIds.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _unequalValid
                      ? AppColors.emerald.withOpacity(0.08)
                      : AppColors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ยอดที่กรอก',
                      style: GoogleFonts.notoSansThai(
                        fontSize: 12,
                        color: _unequalValid
                            ? AppColors.emerald
                            : AppColors.red,
                      ),
                    ),
                    Text(
                      '${_unequalTotal.toStringAsFixed(2)} / ${price.toStringAsFixed(2)}',
                      style: GoogleFonts.notoSansThai(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _unequalValid
                            ? AppColors.emerald
                            : AppColors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // ── Paid by ──
            if (widget.members.isNotEmpty) ...[
              Text(
                'ใครจ่ายก่อน?',
                style: GoogleFonts.notoSansThai(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _paidBy = null),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _paidBy == null
                            ? AppColors.primary.withOpacity(0.15)
                            : (isDark
                                ? const Color(0xFF1F2937)
                                : const Color(0xFFF3F4F6)),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _paidBy == null
                              ? AppColors.primary
                              : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        'ไม่ระบุ',
                        style: GoogleFonts.notoSansThai(
                          fontSize: 13,
                          color: _paidBy == null
                              ? AppColors.primary
                              : (isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight),
                        ),
                      ),
                    ),
                  ),
                  ...widget.members.map((m) {
                    final selected = _paidBy == m.id;
                    final color = colorFromHex(m.color);
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _paidBy = selected ? null : m.id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected
                              ? color.withOpacity(0.15)
                              : (isDark
                                  ? const Color(0xFF1F2937)
                                  : const Color(0xFFF3F4F6)),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected ? color : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            MemberAvatar(
                                name: m.name, color: color, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              m.name,
                              style: GoogleFonts.notoSansThai(
                                fontSize: 13,
                                color: selected
                                    ? color
                                    : (isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight),
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 16),
            ],

            ElevatedButton(
              onPressed: (_loading || !_unequalValid) ? null : _save,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(
                      isEdit ? 'บันทึก' : 'เพิ่มรายการ',
                      style: GoogleFonts.notoSansThai(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Member Form Sheet ─────────────────────────────────────────
class _MemberFormSheet extends StatefulWidget {
  final Bill bill;
  final BillProvider billProvider;
  final BillMember? editMember;

  const _MemberFormSheet({
    required this.bill,
    required this.billProvider,
    this.editMember,
  });

  @override
  State<_MemberFormSheet> createState() => _MemberFormSheetState();
}

class _MemberFormSheetState extends State<_MemberFormSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _promptpayCtrl;
  late Color _selectedColor;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl =
        TextEditingController(text: widget.editMember?.name ?? '');
    _promptpayCtrl = TextEditingController(
        text: widget.editMember?.promptpay ?? '');
    _selectedColor = widget.editMember != null
        ? colorFromHex(widget.editMember!.color)
        : AppColors.memberColors[
            widget.billProvider.members.length %
                AppColors.memberColors.length];
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _promptpayCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    setState(() => _loading = true);
    try {
      if (widget.editMember != null) {
        await widget.billProvider.editMember(
          widget.editMember!.id,
          name: name,
          color: hexFromColor(_selectedColor),
          promptpay: _promptpayCtrl.text.trim().isEmpty
              ? null
              : _promptpayCtrl.text.trim(),
        );
      } else {
        await widget.billProvider.addMember(
          name: name,
          color: hexFromColor(_selectedColor),
          promptpay: _promptpayCtrl.text.trim().isEmpty
              ? null
              : _promptpayCtrl.text.trim(),
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEdit = widget.editMember != null;

    return Container(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.borderDark
                      : AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isEdit ? 'แก้ไขสมาชิก' : 'เพิ่มสมาชิก',
              style: GoogleFonts.notoSansThai(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'ชื่อสมาชิก'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _promptpayCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                  hintText: 'เบอร์ PromptPay (ไม่บังคับ)'),
            ),
            const SizedBox(height: 16),
            Text(
              'สีประจำตัว',
              style: GoogleFonts.notoSansThai(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppColors.memberColors.map((color) {
                final isSelected = _selectedColor == color;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(
                              color: isDark ? Colors.white : Colors.black,
                              width: 2)
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check_rounded,
                            color: Colors.white, size: 18)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _save,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(
                      isEdit ? 'บันทึก' : 'เพิ่มสมาชิก',
                      style: GoogleFonts.notoSansThai(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  const _SettingsRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final ctrl = TextEditingController(
        text: value == 0 ? '' : value.toString());
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.notoSansThai(fontSize: 14),
          ),
        ),
        SizedBox(
          width: 100,
          child: TextField(
            controller: ctrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.right,
            decoration: const InputDecoration(
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onChanged: (v) => onChanged(double.tryParse(v) ?? 0),
          ),
        ),
      ],
    );
  }
}

// ── Stacked Avatars ───────────────────────────────────────────
class _StackedAvatars extends StatelessWidget {
  final List<BillMember> members;

  const _StackedAvatars({required this.members});

  @override
  Widget build(BuildContext context) {
    const maxShow = 3;
    final shown = members.take(maxShow).toList();
    final extra = members.length - shown.length;
    final totalWidth = shown.isEmpty
        ? 0.0
        : 24.0 + (shown.length - 1) * 16.0 + (extra > 0 ? 20.0 : 0.0);

    if (shown.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      width: totalWidth,
      height: 24,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ...shown.asMap().entries.map((e) => Positioned(
                left: e.key * 16.0,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: colorFromHex(e.value.color),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      e.value.name.isNotEmpty
                          ? e.value.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              )),
          if (extra > 0)
            Positioned(
              left: shown.length * 16.0,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFF9CA3AF),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    '+$extra',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
