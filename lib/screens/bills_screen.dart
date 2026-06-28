import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../utils/bill_utils.dart';

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
          .select('*, bill_members(*), bill_items(*)')
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

    final result = await showModalBottomSheet<Map<String, String?>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _CreateBillSheet(),
    );

    if (result != null) {
      final title = result['title'];
      if (title == null || title.isEmpty) return;
      final tagsStr = result['tags'] ?? '';
      final tags = tagsStr.isEmpty
          ? <String>[]
          : tagsStr.split(',').where((t) => t.isNotEmpty).toList();
      try {
        final data = await _supabase.from('bills').insert({
          'title': title,
          'emoji': result['emoji'],
          'owner_id': user.id,
          'status': 'draft',
          'settings': const BillSettings().toJson(),
          'tags': tags,
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
    final result = await showModalBottomSheet<Map<String, String?>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CreateBillSheet(
        initialTitle: bill.title,
        initialEmoji: bill.emoji,
        initialTags: bill.tags,
      ),
    );

    if (result != null) {
      final title = result['title'];
      if (title == null || title.isEmpty) return;
      final tagsStr = result['tags'] ?? '';
      final tags = tagsStr.isEmpty
          ? <String>[]
          : tagsStr.split(',').where((t) => t.isNotEmpty).toList();
      try {
        await _supabase.from('bills').update({
          'title': title,
          'emoji': result['emoji'],
          'tags': tags,
        }).eq('id', bill.id);
        _loadBills();
      } catch (e) {
        debugPrint('Error editing bill: $e');
      }
    }
  }

  Future<void> _deleteBill(Bill bill) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('ลบบิล',
            style: GoogleFonts.notoSansThai(fontWeight: FontWeight.bold)),
        content: Text('ต้องการลบบิล "${bill.title}" หรือไม่?',
            style: GoogleFonts.notoSansThai()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('ยกเลิก',
                style: GoogleFonts.notoSansThai(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('ลบ',
                style: GoogleFonts.notoSansThai(
                    color: AppColors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _supabase.from('bills').delete().eq('id', bill.id);
        _loadBills();
      } catch (e) {
        debugPrint('Error deleting bill: $e');
      }
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
                        color: Colors.black.withOpacity(0.06),
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
                          emptyText: 'ไม่มีบิลที่กำลังดำเนินการ',
                          emptySubtext: 'กดปุ่ม + เพื่อสร้างบิลใหม่',
                          onRefresh: _loadBills,
                          onEdit: _editBill,
                          onDelete: _deleteBill,
                        ),
                        _BillList(
                          bills: completedBills,
                          emptyText: 'ยังไม่มีบิลที่เสร็จแล้ว',
                          emptySubtext: 'บิลที่ชำระเสร็จแล้วจะแสดงที่นี่',
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
  final Future<void> Function() onRefresh;
  final Future<void> Function(Bill) onEdit;
  final Future<void> Function(Bill) onDelete;

  const _BillList({
    required this.bills,
    required this.emptyText,
    required this.emptySubtext,
    required this.onRefresh,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (bills.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🧾', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              emptyText,
              style: GoogleFonts.notoSansThai(
                fontSize: 15,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              emptySubtext,
              style: GoogleFonts.notoSansThai(
                fontSize: 13,
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: bills.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final bill = bills[index];
          return _BillListCard(
            bill: bill,
            onTap: () => context.push('/bills/${bill.id}'),
            onEdit: () => onEdit(bill),
            onDelete: () => onDelete(bill),
          );
        },
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

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Emoji icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
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
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            '${formatNumber(total)} ${bill.settings.currency}',
                            style: GoogleFonts.notoSansThai(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '· $memberCount คน',
                            style: GoogleFonts.notoSansThai(
                              fontSize: 12,
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
                // Status pill
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: bill.isCompleted
                        ? AppColors.emerald.withOpacity(0.1)
                        : AppColors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    bill.isCompleted ? 'ปิดแล้ว' : 'กำลังดำเนิน',
                    style: GoogleFonts.notoSansThai(
                      fontSize: 11,
                      color: bill.isCompleted
                          ? AppColors.emerald
                          : AppColors.amber,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                PopupMenuButton<String>(
                  onSelected: (val) {
                    if (val == 'edit') onEdit();
                    if (val == 'delete') onDelete();
                  },
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit_outlined,
                              size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text('แก้ไข',
                              style: GoogleFonts.notoSansThai(
                                  color: AppColors.primary)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete_outline_rounded,
                              size: 18, color: AppColors.red),
                          const SizedBox(width: 8),
                          Text('ลบ',
                              style: GoogleFonts.notoSansThai(
                                  color: AppColors.red)),
                        ],
                      ),
                    ),
                  ],
                  child: Icon(
                    Icons.more_vert_rounded,
                    size: 20,
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight,
                  ),
                ),
              ],
            ),

            // Tags
            if (bill.tags.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: bill.tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '#$tag',
                      style: GoogleFonts.notoSansThai(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Create / Edit Bill Sheet ───────────────────────────────────
class _CreateBillSheet extends StatefulWidget {
  final String? initialTitle;
  final String? initialEmoji;
  final List<String>? initialTags;

  const _CreateBillSheet({
    this.initialTitle,
    this.initialEmoji,
    this.initialTags,
  });

  @override
  State<_CreateBillSheet> createState() => _CreateBillSheetState();
}

class _CreateBillSheetState extends State<_CreateBillSheet> {
  late TextEditingController _titleCtrl;
  late TextEditingController _tagCtrl;
  String? _emoji;
  late List<String> _tags;

  final List<String> _emojis = [
    '🧾', '🍕', '🍜', '🍣', '☕', '🍺', '🛒', '🎉',
    '✈️', '🏨', '🎮', '🎵', '💊', '⛽', '🎁', '🏋️',
    '🍔', '🥗', '🍰', '🎂', '🏖️', '🎓', '💼', '🌏',
  ];

  final List<String> _suggestedTags = [
    'อาหาร', 'เที่ยว', 'ช้อปปิ้ง', 'ปาร์ตี้', 'ที่พัก',
    'ขนส่ง', 'บันเทิง', 'สุขภาพ', 'การศึกษา', 'อื่นๆ',
  ];

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.initialTitle ?? '');
    _tagCtrl = TextEditingController();
    _emoji = widget.initialEmoji;
    _tags = List<String>.from(widget.initialTags ?? []);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  void _addTag(String tag) {
    final t = tag.trim().replaceAll('#', '');
    if (t.isEmpty || _tags.contains(t)) return;
    setState(() => _tags.add(t));
    _tagCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEdit = widget.initialTitle != null;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
              isEdit ? 'แก้ไขบิล' : 'สร้างบิลใหม่',
              style: GoogleFonts.notoSansThai(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 16),

            // Emoji picker
            Text(
              'ไอคอนบิล',
              style: GoogleFonts.notoSansThai(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _emojis.map((e) {
                final selected = _emoji == e;
                return GestureDetector(
                  onTap: () => setState(() => _emoji = e),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary.withOpacity(0.15)
                          : (isDark
                              ? AppColors.bgDark
                              : const Color(0xFFF9FAFB)),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : (isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight),
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(e, style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Title field
            Text(
              'ชื่อบิล',
              style: GoogleFonts.notoSansThai(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _titleCtrl,
              autofocus: !isEdit,
              decoration: const InputDecoration(
                  hintText: 'ชื่อบิล เช่น ข้าวเที่ยง, ปาร์ตี้...'),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),

            // Tags
            Text(
              'แท็ก (ไม่บังคับ)',
              style: GoogleFonts.notoSansThai(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 8),
            // Selected tags
            if (_tags.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _tags.map((tag) {
                  return GestureDetector(
                    onTap: () => setState(() => _tags.remove(tag)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.primary.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '#$tag',
                            style: GoogleFonts.notoSansThai(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.close_rounded,
                              size: 14, color: AppColors.primary),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
            ],
            // Suggested tags
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _suggestedTags
                  .where((t) => !_tags.contains(t))
                  .map((tag) {
                return GestureDetector(
                  onTap: () => _addTag(tag),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1F2937)
                          : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '#$tag',
                      style: GoogleFonts.notoSansThai(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            // Custom tag input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagCtrl,
                    decoration: const InputDecoration(
                      hintText: 'เพิ่มแท็กเอง...',
                      prefixText: '#',
                    ),
                    onSubmitted: _addTag,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _addTag(_tagCtrl.text),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.add_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _submit,
              child: Text(
                isEdit ? 'บันทึก' : 'สร้างบิล',
                style: GoogleFonts.notoSansThai(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    Navigator.pop(context, {
      'title': title,
      'emoji': _emoji,
      'tags': _tags.join(','),
    });
  }
}
