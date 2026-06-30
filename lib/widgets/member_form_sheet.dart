import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../providers/bill_provider.dart';
import '../theme/app_theme.dart';
import '../utils/bill_utils.dart';
import '../widgets/member_avatar.dart';

// 10 member colors matching Next.js kMemberColors
const kMemberColors = [
  '#ef4444', // red
  '#f97316', // orange
  '#eab308', // yellow
  '#22c55e', // green
  '#14b8a6', // teal
  '#3b82f6', // blue
  '#8b5cf6', // violet
  '#ec4899', // pink
  '#6b7280', // gray
  '#1a1d2e', // dark
];

Future<void> showMemberFormSheet(
  BuildContext context, {
  required BillProvider billProvider,
  BillMember? editMember,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _MemberFormSheet(
      billProvider: billProvider,
      editMember: editMember,
    ),
  );
}

class _MemberFormSheet extends StatefulWidget {
  final BillProvider billProvider;
  final BillMember? editMember;

  const _MemberFormSheet({
    required this.billProvider,
    this.editMember,
  });

  @override
  State<_MemberFormSheet> createState() => _MemberFormSheetState();
}

class _MemberFormSheetState extends State<_MemberFormSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _promptpayCtrl;
  late String _selectedColorHex;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.editMember?.name ?? '');
    _promptpayCtrl =
        TextEditingController(text: widget.editMember?.promptpay ?? '');

    if (widget.editMember != null) {
      _selectedColorHex = widget.editMember!.color;
    } else {
      // Default = first color not yet used
      final usedColors =
          widget.billProvider.members.map((m) => m.color).toSet();
      _selectedColorHex = kMemberColors.firstWhere(
        (c) => !usedColors.contains(c),
        orElse: () => kMemberColors[
            widget.billProvider.members.length % kMemberColors.length],
      );
    }
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
          color: _selectedColorHex,
          promptpay: _promptpayCtrl.text.trim().isEmpty
              ? null
              : _promptpayCtrl.text.trim(),
        );
      } else {
        await widget.billProvider.addMember(
          name: name,
          color: _selectedColorHex,
          promptpay: _promptpayCtrl.text.trim().isEmpty
              ? null
              : _promptpayCtrl.text.trim(),
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEdit = widget.editMember != null;

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
                    isEdit ? 'แก้ไขสมาชิก' : 'เพิ่มสมาชิก',
                    style: GoogleFonts.notoSansThai(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
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

            // Name field
            _Label(label: 'ชื่อสมาชิก *', isDark: isDark),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              autofocus: !isEdit,
              decoration: const InputDecoration(hintText: 'ชื่อสมาชิก'),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 16),

            // Color picker
            _Label(label: 'สีประจำตัว', isDark: isDark),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: kMemberColors.map((hex) {
                final isSelected = _selectedColorHex == hex;
                final color = colorFromHex(hex);
                return GestureDetector(
                  onTap: () => setState(() => _selectedColorHex = hex),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(
                              color: isDark ? Colors.white : Colors.black87,
                              width: 2.5,
                            )
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
            const SizedBox(height: 16),

            // PromptPay field
            _Label(label: 'พร้อมเพย์ (ไม่บังคับ)', isDark: isDark),
            const SizedBox(height: 8),
            TextField(
              controller: _promptpayCtrl,
              keyboardType: TextInputType.phone,
              decoration:
                  const InputDecoration(hintText: 'เบอร์โทร / เลขบัตร'),
            ),
            const SizedBox(height: 24),

            // Preview avatar
            Row(
              children: [
                MemberAvatar(
                  name: _nameCtrl.text.isEmpty ? '?' : _nameCtrl.text,
                  color: colorFromHex(_selectedColorHex),
                  size: 40,
                ),
                const SizedBox(width: 12),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _nameCtrl,
                  builder: (_, val, __) => Text(
                    val.text.isEmpty ? 'ชื่อสมาชิก' : val.text,
                    style: GoogleFonts.notoSansThai(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Save button
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _nameCtrl,
              builder: (_, val, __) {
                final canSave = val.text.trim().isNotEmpty && !_loading;
                return ElevatedButton(
                  onPressed: canSave ? _save : null,
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
                          isEdit ? 'บันทึก' : 'เพิ่มสมาชิก',
                          style: GoogleFonts.notoSansThai(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String label;
  final bool isDark;
  const _Label({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.notoSansThai(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: isDark
            ? AppColors.textSecondaryDark
            : AppColors.textSecondaryLight,
      ),
    );
  }
}
