import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../providers/bill_provider.dart';
import '../theme/app_theme.dart';
import '../utils/bill_utils.dart';
import '../widgets/member_avatar.dart';
import 'confirm_dialog.dart';
import 'form_label.dart';

Future<void> showItemFormSheet(
  BuildContext context, {
  required BillProvider billProvider,
  required List<BillMember> members,
  BillItem? editItem,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ItemFormSheet(
      billProvider: billProvider,
      members: members,
      editItem: editItem,
    ),
  );
}

class _ItemFormSheet extends StatefulWidget {
  final BillProvider billProvider;
  final List<BillMember> members;
  final BillItem? editItem;

  const _ItemFormSheet({
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

  String? get _validationError {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return 'กรุณาใส่ชื่อรายการ';
    if (_price <= 0) return 'กรุณาใส่ราคา';
    if (_selectedIds.isEmpty) return 'เลือกสมาชิกอย่างน้อย 1 คน';
    if (_isUnequalSplit && !_unequalValid) {
      return 'ยอดรวมต้องเท่ากับ ฿${_price.toStringAsFixed(2)} (ตอนนี้ ฿${_unequalTotal.toStringAsFixed(2)})';
    }
    return null;
  }

  Future<void> _save() async {
    final err = _validationError;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(err, style: GoogleFonts.notoSansThai()),
        backgroundColor: AppColors.red,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

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
          name: _nameCtrl.text.trim(),
          price: _price,
          memberIds: _isUnequalSplit ? [] : selectedIds,
          customShares: _isUnequalSplit ? customShares : {},
          paidBy: _paidBy,
          clearCustomShares: !_isUnequalSplit,
        );
      } else {
        await widget.billProvider.addItem(
          name: _nameCtrl.text.trim(),
          price: _price,
          memberIds: _isUnequalSplit ? [] : selectedIds,
          customShares: _isUnequalSplit ? customShares : {},
          paidBy: _paidBy,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _delete() async {
    if (widget.editItem == null) return;
    final confirmed = await showConfirmDialog(
      context,
      title: 'ลบรายการนี้?',
      description: 'รายการ "${widget.editItem!.name}" จะถูกลบถาวร',
      confirmLabel: 'ลบ',
      danger: true,
    );
    if (!confirmed) return;
    setState(() => _loading = true);
    await widget.billProvider.deleteItem(widget.editItem!.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEdit = widget.editItem != null;
    final price = _price;

    return Container(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color:
                      isDark ? AppColors.borderDark : AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    isEdit ? 'แก้ไขรายการ' : 'เพิ่มรายการ',
                    style: GoogleFonts.notoSansThai(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                ),
                if (isEdit)
                  IconButton(
                    onPressed: _loading ? null : _delete,
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: AppColors.red),
                  ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close_rounded,
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Name field ──
            FormSectionLabel(label: 'ชื่อรายการ'),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              autofocus: !isEdit,
              decoration: const InputDecoration(hintText: 'เช่น ข้าวผัด, เบียร์...'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),

            // ── Price field ──
            FormSectionLabel(label: 'ราคารวม (บาท)'),
            const SizedBox(height: 8),
            TextField(
              controller: _priceCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(hintText: '0.00'),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
              ],
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // ── Paid by selector ──
            if (widget.members.isNotEmpty) ...[
              FormSectionLabel(label: 'ใครจ่ายไปก่อน *'),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: widget.members.map((m) {
                    final selected = _paidBy == m.id;
                    final color = colorFromHex(m.color);
                    return GestureDetector(
                      onTap: () => setState(() => _paidBy = m.id),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : (isDark
                                  ? const Color(0xFF1F2937)
                                  : const Color(0xFFF3F4F6)),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            selected
                                ? Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.check_rounded,
                                        color: Colors.white, size: 13),
                                  )
                                : MemberAvatar(
                                    name: m.name, color: color, size: 20),
                            const SizedBox(width: 6),
                            Text(
                              m.name,
                              style: GoogleFonts.notoSansThai(
                                fontSize: 13,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: selected
                                    ? AppColors.primary
                                    : (isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Split mode toggle ──
            Row(
              children: [
                Expanded(
                  child: FormSectionLabel(label: 'วิธีหาร'),
                ),
                _SplitToggle(
                  isUnequal: _isUnequalSplit,
                  isDark: isDark,
                  onEqual: () => setState(() => _isUnequalSplit = false),
                  onUnequal: () => setState(() => _isUnequalSplit = true),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Member selection ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FormSectionLabel(label: 'เลือกสมาชิก'),
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
                'ยังไม่มีสมาชิก — เพิ่มสมาชิกก่อนเพิ่มรายการ',
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
                            ? color.withValues(alpha: 0.08)
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
                          // Equal mode: per-person amount
                          if (!_isUnequalSplit && selected && price > 0)
                            Text(
                              '฿${formatNumber(_perPersonAmount)}',
                              style: GoogleFonts.notoSansThai(
                                fontSize: 13,
                                color: color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          // Unequal mode: amount input
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
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 6),
                                  isDense: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: color),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide:
                                        BorderSide(color: color, width: 2),
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

            // Unequal running total
            if (_isUnequalSplit && price > 0 && _selectedIds.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _unequalValid
                      ? AppColors.emerald.withValues(alpha: 0.08)
                      : AppColors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'รวม',
                      style: GoogleFonts.notoSansThai(
                        fontSize: 12,
                        color: _unequalValid
                            ? AppColors.emerald
                            : AppColors.red,
                      ),
                    ),
                    Text(
                      '฿${_unequalTotal.toStringAsFixed(2)} / ฿${price.toStringAsFixed(2)}',
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

            const SizedBox(height: 20),

            // Save button
            ElevatedButton(
              onPressed: _loading ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor:
                    AppColors.primary.withValues(alpha: 0.4),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      isEdit ? 'บันทึก' : 'เพิ่มรายการ',
                      style: GoogleFonts.notoSansThai(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Split Toggle ───────────────────────────────────────────────
class _SplitToggle extends StatelessWidget {
  final bool isUnequal;
  final bool isDark;
  final VoidCallback onEqual;
  final VoidCallback onUnequal;

  const _SplitToggle({
    required this.isUnequal,
    required this.isDark,
    required this.onEqual,
    required this.onUnequal,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onEqual,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: !isUnequal
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
                color: !isUnequal
                    ? Colors.white
                    : (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight),
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: onUnequal,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isUnequal
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
                color: isUnequal
                    ? Colors.white
                    : (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

