import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kidtang_flutter/models/models.dart';
import 'package:kidtang_flutter/stores/bills_store.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';
import 'package:kidtang_flutter/utils/bill_utils.dart';
import 'package:kidtang_flutter/widgets/shared/member_avatar.dart';

class ItemFormSheet extends StatefulWidget {
  final Bill bill;
  final BillsStore billsStore;
  final List<BillMember> members;
  final BillItem? editItem;

  const ItemFormSheet({
    super.key,
    required this.bill,
    required this.billsStore,
    required this.members,
    this.editItem,
  });

  @override
  State<ItemFormSheet> createState() => _ItemFormSheetState();
}

class _ItemFormSheetState extends State<ItemFormSheet> {
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  bool _loading = false;
  bool _isUnequalSplit = false;
  String? _paidBy;

  // member id → selected (equal split) or weight (unequal split)
  late Map<String, bool> _selected;
  late Map<String, TextEditingController> _weightCtrls;

  // Debounce timer for price preview
  Timer? _debounce;
  double _previewPrice = 0;

  @override
  void initState() {
    super.initState();
    final edit = widget.editItem;
    if (edit != null) {
      _nameCtrl.text = edit.name;
      _priceCtrl.text = edit.price.toString();
      _previewPrice = edit.price;
      _isUnequalSplit = edit.isUnequalSplit;
      _paidBy = edit.paidBy;
      _selected = {
        for (final m in widget.members)
          m.id: edit.splitWeights.containsKey(m.id) &&
              edit.splitWeights[m.id]! > 0,
      };
      _weightCtrls = {
        for (final m in widget.members)
          m.id: TextEditingController(
            text: edit.splitWeights[m.id]?.toString() ?? '',
          ),
      };
    } else {
      _selected = {for (final m in widget.members) m.id: true};
      _weightCtrls = {
        for (final m in widget.members) m.id: TextEditingController(),
      };
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _debounce?.cancel();
    for (final c in _weightCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _onPriceChanged(String val) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _previewPrice = double.tryParse(val) ?? 0;
        });
      }
    });
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final price = double.tryParse(_priceCtrl.text.trim()) ?? 0;
    if (name.isEmpty || price <= 0) return;

    List<String> memberIds;
    Map<String, double> customShares;

    if (_isUnequalSplit) {
      memberIds = [];
      customShares = {};
      for (final m in widget.members) {
        if (_selected[m.id] == true) {
          final w = double.tryParse(_weightCtrls[m.id]!.text.trim()) ?? 0;
          if (w > 0) {
            memberIds.add(m.id);
            customShares[m.id] = w;
          }
        }
      }
    } else {
      memberIds = [
        for (final m in widget.members)
          if (_selected[m.id] == true) m.id,
      ];
      customShares = {};
    }

    setState(() => _loading = true);
    try {
      if (widget.editItem != null) {
        await widget.billsStore.editItem(
          widget.bill.id,
          widget.editItem!.id,
          name: name,
          price: price,
          memberIds: memberIds,
          customShares: customShares.isEmpty ? null : customShares,
          clearCustomShares: customShares.isEmpty,
          paidBy: _paidBy,
          clearPaidBy: _paidBy == null,
        );
      } else {
        await widget.billsStore.addItem(
          widget.bill.id,
          name: name,
          price: price,
          memberIds: memberIds,
          customShares: customShares,
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
    setState(() => _loading = true);
    try {
      await widget.billsStore.deleteItem(
          widget.bill.id, widget.editItem!.id);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEdit = widget.editItem != null;
    final selectedCount = _selected.values.where((v) => v).length;
    final perPerson =
        selectedCount > 0 && !_isUnequalSplit && _previewPrice > 0
            ? _previewPrice / selectedCount
            : 0.0;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ──
          _ItemFormHeader(
            isEdit: isEdit,
            isDark: isDark,
            onDelete: isEdit ? _delete : null,
            loading: _loading,
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: 32 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d*')),
                    ],
                    onChanged: _onPriceChanged,
                    decoration: const InputDecoration(hintText: 'ราคา'),
                  ),
                  const SizedBox(height: 16),
                  // Split mode toggle
                  _SplitModeToggle(
                    isUnequal: _isUnequalSplit,
                    isDark: isDark,
                    onChanged: (val) => setState(() => _isUnequalSplit = val),
                  ),
                  const SizedBox(height: 12),
                  // Member picker
                  _MemberPickerList(
                    members: widget.members,
                    selected: _selected,
                    weightCtrls: _weightCtrls,
                    isUnequalSplit: _isUnequalSplit,
                    isDark: isDark,
                    previewPrice: _previewPrice,
                    onToggle: (id, val) =>
                        setState(() => _selected[id] = val),
                    onWeightChanged: () => setState(() {}),
                  ),
                  // Unequal validation banner
                  if (_isUnequalSplit) ...[
                    const SizedBox(height: 8),
                    _UnequalValidationBanner(
                      members: widget.members,
                      selected: _selected,
                      weightCtrls: _weightCtrls,
                      price: _previewPrice,
                      isDark: isDark,
                    ),
                  ],
                  if (!_isUnequalSplit && perPerson > 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      '฿${formatNumber(perPerson)}/คน ($selectedCount คน)',
                      style: GoogleFonts.notoSansThai(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiaryLight,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 16),
                  // Paid by picker
                  _PaidByPicker(
                    members: widget.members,
                    paidBy: _paidBy,
                    isDark: isDark,
                    onChanged: (id) => setState(() => _paidBy = id),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _loading ? null : _save,
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
                                fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── File-private sub-widgets ──────────────────────────────────

class _ItemFormHeader extends StatelessWidget {
  final bool isEdit;
  final bool isDark;
  final VoidCallback? onDelete;
  final bool loading;

  const _ItemFormHeader({
    required this.isEdit,
    required this.isDark,
    this.onDelete,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
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
          if (isEdit && onDelete != null)
            IconButton(
              onPressed: loading ? null : onDelete,
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.red),
            ),
        ],
      ),
    );
  }
}

class _SplitModeToggle extends StatelessWidget {
  final bool isUnequal;
  final bool isDark;
  final ValueChanged<bool> onChanged;

  const _SplitModeToggle({
    required this.isUnequal,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'วิธีหาร',
          style: GoogleFonts.notoSansThai(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
        ),
        const Spacer(),
        _ToggleChip(
          label: 'เท่ากัน',
          selected: !isUnequal,
          onTap: () => onChanged(false),
          isDark: isDark,
        ),
        const SizedBox(width: 8),
        _ToggleChip(
          label: 'ไม่เท่ากัน',
          selected: isUnequal,
          onTap: () => onChanged(true),
          isDark: isDark,
        ),
      ],
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;

  const _ToggleChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : (isDark ? AppColors.borderDark : AppColors.neutral100),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.notoSansThai(
            fontSize: 12,
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
  }
}

class _MemberPickerList extends StatelessWidget {
  final List<BillMember> members;
  final Map<String, bool> selected;
  final Map<String, TextEditingController> weightCtrls;
  final bool isUnequalSplit;
  final bool isDark;
  final double previewPrice;
  final void Function(String id, bool val) onToggle;
  final VoidCallback onWeightChanged;

  const _MemberPickerList({
    required this.members,
    required this.selected,
    required this.weightCtrls,
    required this.isUnequalSplit,
    required this.isDark,
    required this.previewPrice,
    required this.onToggle,
    required this.onWeightChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'สมาชิกที่ร่วมจ่าย',
          style: GoogleFonts.notoSansThai(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 8),
        ...members.map((m) {
          final isSelected = selected[m.id] ?? false;
          final color = colorFromHex(m.color);
          return GestureDetector(
            onTap: () => onToggle(m.id, !isSelected),
            child: Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : (isDark ? AppColors.surfaceDark : AppColors.neutral50),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.4)
                      : (isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight),
                ),
              ),
              child: Row(
                children: [
                  MemberAvatar(
                      name: m.name,
                      color: color,
                      size: 32,
                      avatarUrl: m.profile?.avatarUrl),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      m.name,
                      style: GoogleFonts.notoSansThai(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                  ),
                  if (isUnequalSplit && isSelected) ...[
                    SizedBox(
                      width: 80,
                      child: TextField(
                        controller: weightCtrls[m.id],
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d*')),
                        ],
                        onChanged: (_) => onWeightChanged(),
                        decoration: InputDecoration(
                          hintText: 'น้ำหนัก',
                          hintStyle:
                              GoogleFonts.notoSansThai(fontSize: 11),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          isDense: true,
                        ),
                        style: GoogleFonts.notoSansThai(fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ] else ...[
                    Icon(
                      isSelected
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      color: isSelected
                          ? AppColors.primary
                          : (isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textTertiaryLight),
                      size: 20,
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _UnequalValidationBanner extends StatelessWidget {
  final List<BillMember> members;
  final Map<String, bool> selected;
  final Map<String, TextEditingController> weightCtrls;
  final double price;
  final bool isDark;

  const _UnequalValidationBanner({
    required this.members,
    required this.selected,
    required this.weightCtrls,
    required this.price,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    double totalWeight = 0;
    for (final m in members) {
      if (selected[m.id] == true) {
        totalWeight += double.tryParse(weightCtrls[m.id]!.text.trim()) ?? 0;
      }
    }
    final isValid = totalWeight > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isValid
            ? AppColors.emerald.withValues(alpha: 0.1)
            : AppColors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isValid
            ? 'น้ำหนักรวม: $totalWeight'
            : 'กรุณาใส่น้ำหนักให้ครบ',
        style: GoogleFonts.notoSansThai(
          fontSize: 12,
          color: isValid ? AppColors.emerald : AppColors.amber,
        ),
      ),
    );
  }
}

class _PaidByPicker extends StatelessWidget {
  final List<BillMember> members;
  final String? paidBy;
  final bool isDark;
  final ValueChanged<String?> onChanged;

  const _PaidByPicker({
    required this.members,
    required this.paidBy,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ใครจ่ายก่อน? (ไม่บังคับ)',
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
              onTap: () => onChanged(null),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: paidBy == null
                      ? AppColors.primary
                      : (isDark
                          ? AppColors.borderDark
                          : AppColors.neutral100),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'ไม่ระบุ',
                  style: GoogleFonts.notoSansThai(
                    fontSize: 12,
                    color: paidBy == null
                        ? Colors.white
                        : (isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight),
                  ),
                ),
              ),
            ),
            ...members.map((m) {
              final isSelected = paidBy == m.id;
              return GestureDetector(
                onTap: () => onChanged(m.id),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark
                            ? AppColors.borderDark
                            : AppColors.neutral100),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    m.name,
                    style: GoogleFonts.notoSansThai(
                      fontSize: 12,
                      color: isSelected
                          ? Colors.white
                          : (isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }
}
