import 'package:kidtang_flutter/providers/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kidtang_flutter/models/models.dart';
import 'package:kidtang_flutter/stores/bills_store.dart';
import 'package:kidtang_flutter/stores/groups_store.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';
import 'package:kidtang_flutter/utils/bill_utils.dart';
import 'package:kidtang_flutter/widgets/shared/member_avatar.dart';
import 'package:provider/provider.dart';

class MemberFormSheet extends StatefulWidget {
  final Bill bill;
  final BillsStore billsStore;
  final BillMember? editMember;

  const MemberFormSheet({
    super.key,
    required this.bill,
    required this.billsStore,
    this.editMember,
  });

  @override
  State<MemberFormSheet> createState() => _MemberFormSheetState();
}

class _MemberFormSheetState extends State<MemberFormSheet> {
  final _nameCtrl = TextEditingController();
  final _promptpayCtrl = TextEditingController();
  String _color = '#4366F4';
  bool _loading = false;

  static const _colorOptions = [
    '#4366F4', '#10B981', '#F59E0B', '#EF4444',
    '#8B5CF6', '#EC4899', '#06B6D4', '#84CC16',
  ];

  @override
  void initState() {
    super.initState();
    final edit = widget.editMember;
    if (edit != null) {
      _nameCtrl.text = edit.name;
      _promptpayCtrl.text = edit.promptpay ?? '';
      _color = edit.color;
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
    final promptpay = _promptpayCtrl.text.trim().isEmpty
        ? null
        : _promptpayCtrl.text.trim();

    setState(() => _loading = true);
    try {
      if (widget.editMember != null) {
        await widget.billsStore.editMember(
          widget.bill.id,
          widget.editMember!.id,
          name: name,
          color: _color,
          promptpay: promptpay,
        );
      } else {
        await widget.billsStore.addMember(
          widget.bill.id,
          name: name,
          color: _color,
          promptpay: promptpay,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _delete() async {
    if (widget.editMember == null) return;
    setState(() => _loading = true);
    try {
      await widget.billsStore.deleteMember(
          widget.bill.id, widget.editMember!.id);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
      final l = context.watch<LocaleProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEdit = widget.editMember != null;

    // Group members available to quick-add (not already in bill)
    final groupId = widget.bill.groupId;
    final groupMembers = groupId != null
        ? context.read<GroupsStore>().getById(groupId)?.members ?? []
        : <dynamic>[];
    final billMemberUserIds =
        widget.bill.members.map((m) => m.userId).whereType<String>().toSet();
    final availableGroupMembers = groupMembers
        .where((gm) => !billMemberUserIds.contains(gm.userId))
        .toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.xl),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    isEdit ? l.t('member_form_edit_title') : l.t('member_form_add_title'),
                    style: GoogleFonts.sarabun(
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
              ],
            ),
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
                  // Quick-add from group (only when adding, not editing)
                  if (!isEdit && availableGroupMembers.isNotEmpty) ...[
                    Text(
                      l.t('member_form_add_from_group'),
                      style: GoogleFonts.sarabun(
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
                      children: availableGroupMembers.map((gm) {
                        return GestureDetector(
                          onTap: () async {
                            setState(() => _loading = true);
                            final nav = Navigator.of(context);
                            try {
                              await widget.billsStore
                                  .addMemberFromGroupMember(
                                widget.bill.id,
                                userId: gm.userId as String?,
                                name: gm.displayName as String? ?? gm.name as String,
                                color: _color,
                              );
                              if (!mounted) return;
                              nav.pop();
                            } catch (_) {
                              if (mounted) setState(() => _loading = false);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.borderDark
                                  : AppColors.neutral100,
                              borderRadius: BorderRadius.circular(AppRadii.xl),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                MemberAvatar(
                                  name: gm.displayName as String? ?? gm.name as String,
                                  color: colorFromHex(_color),
                                  size: 22,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  gm.displayName as String? ?? gm.name as String,
                                  style: GoogleFonts.sarabun(
                                    fontSize: 12,
                                    color: isDark
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textPrimaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Divider(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight),
                    const SizedBox(height: 16),
                    Text(
                      l.t('member_form_or_new'),
                      style: GoogleFonts.sarabun(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  // Name field
                  TextField(
                    controller: _nameCtrl,
                    autofocus: !isEdit && availableGroupMembers.isEmpty,
                    decoration: InputDecoration(hintText: l.t('member_form_name_hint')),
                  ),
                  const SizedBox(height: 12),
                  // PromptPay field
                  TextField(
                    controller: _promptpayCtrl,
                    keyboardType: TextInputType.phone,
                    decoration:
                        InputDecoration(hintText: l.t('member_form_promptpay_hint')),
                  ),
                  const SizedBox(height: 16),
                  // Color picker
                  Text(
                    l.t('member_form_color_label'),
                    style: GoogleFonts.sarabun(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    children: _colorOptions.map((c) {
                      final isSelected = _color == c;
                      return GestureDetector(
                        onTap: () => setState(() => _color = c),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: colorFromHex(c),
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                    width: 2.5)
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check_rounded,
                                  color: AppColors.surface, size: 16)
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
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            isEdit ? l.t('member_form_save') : l.t('member_form_add_btn'),
                            style: GoogleFonts.sarabun(
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
