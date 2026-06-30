import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../utils/bill_utils.dart';
import '../widgets/bill_status_pill.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/create_entity_sheet.dart';
import '../widgets/empty_state.dart';

class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  List<Bill> _bills = [];
  bool _loading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBills();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBills() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    try {
      final data = await _supabase
          .from('bills')
          .select('*, bill_members(*), bill_items(*), groups!bills_group_id_fkey(id, name, emoji)')
          .eq('owner_id', user.id)
          .order('updated_at', ascending: false);
      if (mounted) {
        setState(() {
          _bills = (data as List).map((e) => Bill.fromJson(e)).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createBill() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final result = await showCreateEntitySheet(
      context,
      type: 'bill',
      mode: 'create',
    );

    if (result != null && mounted) {
      try {
        final settings = result.settings ?? const BillSettings();
        final data = await _supabase.from('bills').insert({
          'title': result.name,
          'emoji': result.emoji,
          'owner_id': user.id,
          'status': 'draft',
          'settings': settings.toJson(),
          'tags': result.tags,
          'paid_member_ids': [],
        }).select('*, bill_members(*), bill_items(*)').single();

        final bill = Bill.fromJson(data);
        if (mounted) {
          context.push('/bills/${bill.id}');
          _loadBills();
        }
      } catch (e) {
        debugPrint('Error creating bill: $e');
      }
    }
  }

  Future<void> _editBill(Bill bill) async {
    final result = await showCreateEntitySheet(
      context,
      type: 'bill',
      mode: 'edit',
      initialData: EntityFormResult(
        name: bill.title,
        emoji: bill.emoji,
        description: '',
        tags: bill.tags,
        settings: bill.settings,
      ),
      onDelete: () => _deleteBillById(bill.id),
    );

    if (result != null && mounted) {
      try {
        final settings = result.settings ?? bill.settings;
        await _supabase.from('bills').update({
          'title': result.name,
          'emoji': result.emoji,
          'tags': result.tags,
          'settings': settings.toJson(),
        }).eq('id', bill.id);
        _loadBills();
      } catch (e) {
        debugPrint('Error editing bill: $e');
      }
    }
  }

  Future<void> _deleteBill(Bill bill) async {
    final confirm = await showConfirmDialog(
      context,
      title: 'ลบบิล',
      description: 'ต้องการลบบิล "${bill.title}" หรือไม่?',
      confirmLabel: 'ลบ',
      danger: true,
    );
    if (confirm) {
      await _deleteBillById(bill.id);
    }
  }

  Future<void> _deleteBillById(String id) async {
    try {
      await _supabase.from('bills').delete().eq('id', id);
      if (mounted) _loadBills();
    } catch (e) {
      debugPrint('Error deleting bill: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeBills = _bills.where((b) => !b.isCompleted).toList();
    final completedBills = _bills.where((b) => b.isCompleted).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'บิลของฉัน',
                    style: GoogleFonts.notoSansThai(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  GestureDetector(
                    onTap: _createBill,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Tabs
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1F2937)
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                  unselectedLabelColor: isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textTertiaryLight,
                  labelStyle: GoogleFonts.notoSansThai(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: GoogleFonts.notoSansThai(
                    fontSize: 13,
                  ),
                  tabs: [
                    Tab(text: 'กำลังดำเนินการ (${activeBills.length})'),
                    Tab(text: 'เสร็จแล้ว (${completedBills.length})'),
                  ],
                ),
              ),
            ),

            // Content
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2,
                      ),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _BillList(
                          bills: activeBills,
                          emptyEmoji: '🧾',
                          emptyText: 'ยังไม่มีบิล',
                          emptySubtext: 'กดปุ่ม + เพื่อสร้างบิลแรกของคุณ',
                          emptyCtaLabel: 'สร้างบิล',
                          onEmptyCta: _createBill,
                          onRefresh: _loadBills,
                          onEdit: _editBill,
                          onDelete: _deleteBill,
                        ),
                        _BillList(
                          bills: completedBills,
                          emptyEmoji: '✅',
                          emptyText: 'ยังไม่มีบิลที่เสร็จ',
                          emptySubtext: 'บิลที่ชำระครบแล้วจะปรากฏที่นี่',
                          onRefresh: _loadBills,
                          onEdit: _editBill,
                          onDelete: _deleteBill,
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

// ── Bill List ──────────────────────────────────────────────────
class _BillList extends StatelessWidget {
  final List<Bill> bills;
  final String emptyText;
  final String emptySubtext;
  final String? emptyEmoji;
  final String? emptyCtaLabel;
  final VoidCallback? onEmptyCta;
  final Future<void> Function() onRefresh;
  final Future<void> Function(Bill) onEdit;
  final Future<void> Function(Bill) onDelete;

  const _BillList({
    required this.bills,
    required this.emptyText,
    required this.emptySubtext,
    this.emptyEmoji,
    this.emptyCtaLabel,
    this.onEmptyCta,
    required this.onRefresh,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (bills.isEmpty) {
      return EmptyStateWidget(
        emoji: emptyEmoji ?? '🧾',
        title: emptyText,
        subtitle: emptySubtext,
        ctaLabel: emptyCtaLabel,
        onCta: onEmptyCta,
      );
    }

    // Separate standalone vs group bills
    final standaloneBills = bills.where((b) => b.groupId == null).toList();
    final groupBills = bills.where((b) => b.groupId != null).toList();

    // Group the group bills by groupId
    final Map<String, List<Bill>> byGroup = {};
    for (final b in groupBills) {
      byGroup.putIfAbsent(b.groupId!, () => []).add(b);
    }

    // Build flat list of items: section headers + bill cards
    final List<_ListItem> items = [];

    if (standaloneBills.isNotEmpty) {
      items.add(_SectionHeader(label: 'บิลเดี่ยว', count: standaloneBills.length));
      for (final b in standaloneBills) {
        items.add(_BillEntry(bill: b));
      }
    }

    if (byGroup.isNotEmpty) {
      for (final entry in byGroup.entries) {
        final groupBillList = entry.value;
        final groupName = groupBillList.first.groupName ?? 'กลุ่ม';
        final groupEmoji = groupBillList.first.groupEmoji ?? '👥';
        items.add(_SectionHeader(
          label: '$groupEmoji $groupName',
          count: groupBillList.length,
          isGroup: true,
        ));
        for (final b in groupBillList) {
          items.add(_BillEntry(bill: b));
        }
      }
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          if (item is _SectionHeader) {
            return _SectionHeaderWidget(item: item, isDark: isDark);
          }
          final bill = (item as _BillEntry).bill;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _BillListCard(
              bill: bill,
              onTap: () => context.push('/bills/${bill.id}'),
              onEdit: () => onEdit(bill),
              onDelete: () => onDelete(bill),
            ),
          );
        },
      ),
    );
  }
}

// ── List item types ────────────────────────────────────────────
abstract class _ListItem {}

class _SectionHeader extends _ListItem {
  final String label;
  final int count;
  final bool isGroup;
  _SectionHeader({required this.label, required this.count, this.isGroup = false});
}

class _BillEntry extends _ListItem {
  final Bill bill;
  _BillEntry({required this.bill});
}

class _SectionHeaderWidget extends StatelessWidget {
  final _SectionHeader item;
  final bool isDark;
  const _SectionHeaderWidget({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: item.isGroup
                  ? const Color(0xFFF0F4FF)
                  : (isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6)),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: item.isGroup
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : (isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item.isGroup)
                  Icon(Icons.group_rounded,
                      size: 13, color: AppColors.primary),
                if (!item.isGroup)
                  Icon(Icons.receipt_outlined,
                      size: 13,
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight),
                const SizedBox(width: 5),
                Text(
                  item.label,
                  style: GoogleFonts.notoSansThai(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: item.isGroup
                        ? AppColors.primary
                        : (isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: item.isGroup
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : (isDark
                            ? const Color(0xFF374151)
                            : const Color(0xFFE5E7EB)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${item.count}',
                    style: GoogleFonts.notoSansThai(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: item.isGroup
                          ? AppColors.primary
                          : (isDark
                              ? AppColors.textTertiaryDark
                              : const Color(0xFF6B7280)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Divider(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bill List Card ─────────────────────────────────────────────
class _BillListCard extends StatelessWidget {
  final Bill bill;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BillListCard({
    required this.bill,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = bill.items.fold(0.0, (s, i) => s + i.price);
    final memberCount = bill.members.length;
    final stripeColor = bill.isCompleted ? AppColors.emerald : AppColors.primary;
    final visibleTags = bill.tags.take(2).toList();
    final extraTags = bill.tags.length > 2 ? bill.tags.length - 2 : 0;
    final textTertiary = isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isDark ? null : AppColors.shadowCard,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left color stripe
                Container(width: 5, color: stripeColor),
                // Card content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 14, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Emoji icon
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: stripeColor.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(bill.emoji ?? '🧾', style: const TextStyle(fontSize: 20)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Title + meta
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    bill.title,
                                    style: GoogleFonts.notoSansThai(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  // Group badge (if group bill)
                                  if (bill.groupName != null) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.3) : AppColors.primaryFaint,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${bill.groupEmoji ?? '👥'} ${bill.groupName}',
                                        style: GoogleFonts.notoSansThai(
                                          fontSize: 11,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                  ],
                                  Row(
                                    children: [
                                      BillStatusPill(status: bill.status),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${bill.items.length} รายการ · $memberCount คน',
                                        style: GoogleFonts.notoSansThai(fontSize: 11, color: textTertiary),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Amount + action buttons
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  formatNumber(total),
                                  style: GoogleFonts.notoSansThai(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: stripeColor,
                                  ),
                                ),
                                Text(
                                  bill.settings.currency,
                                  style: GoogleFonts.notoSansThai(
                                    fontSize: 11,
                                    color: textTertiary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    GestureDetector(
                                      onTap: onEdit,
                                      child: Container(
                                        width: 28, height: 28,
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(Icons.settings_outlined, size: 15,
                                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    GestureDetector(
                                      onTap: onDelete,
                                      child: Container(
                                        width: 28, height: 28,
                                        decoration: BoxDecoration(
                                          color: AppColors.red.withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.delete_outline_rounded, size: 15, color: AppColors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        // Tags row
                        if (bill.tags.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              ...visibleTags.map((tag) => Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text('#$tag',
                                          style: GoogleFonts.notoSansThai(
                                              fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500)),
                                    ),
                                  )),
                              if (extraTags > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text('+$extraTags',
                                      style: GoogleFonts.notoSansThai(fontSize: 11, color: textTertiary)),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
