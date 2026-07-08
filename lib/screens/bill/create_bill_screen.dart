import 'package:kidtang_flutter/providers/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kidtang_flutter/widgets/shared/emoji_text.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:kidtang_flutter/models/models.dart';
import 'package:kidtang_flutter/stores/bills_store.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';
import 'package:kidtang_flutter/widgets/shared/confirm_dialog.dart';
import 'package:kidtang_flutter/widgets/shared/form_label.dart';
import 'package:kidtang_flutter/widgets/shared/constants.dart';
import 'package:kidtang_flutter/widgets/shared/emoji_picker_grid.dart';
import 'package:kidtang_flutter/widgets/shared/toggle_card.dart';

// ── Screen ─────────────────────────────────────────────────────

/// Full-page create/edit bill screen.
/// Route params (via GoRouter extra):
///   - mode: 'create' | 'edit'
///   - billId: required when mode='edit'
///   - groupId: optional, pre-links bill to a group
class CreateBillScreen extends StatefulWidget {
  final String mode;
  final String? billId;
  final String? groupId;

  const CreateBillScreen({
    super.key,
    this.mode = 'create',
    this.billId,
    this.groupId,
  });

  @override
  State<CreateBillScreen> createState() => _CreateBillScreenState();
}

class _CreateBillScreenState extends State<CreateBillScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _tagCtrl;
  late TextEditingController _vatCtrl;
  late TextEditingController _serviceCtrl;

  String? _emoji;
  late List<String> _tags;

  bool _isVat = false;
  double _vat = 7;
  bool _isService = false;
  double _serviceCharge = 10;
  String _currency = 'THB';
  String _roundingMode = 'none';

  bool _loading = false;
  bool _showEmojiPicker = false;

  bool get _isEdit => widget.mode == 'edit';

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _descCtrl = TextEditingController();
    _tagCtrl = TextEditingController();
    _tags = [];
    _vatCtrl = TextEditingController(text: '7');
    _serviceCtrl = TextEditingController(text: '10');

    if (_isEdit && widget.billId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final bill = context.read<BillsStore>().getById(widget.billId!);
        if (bill != null) {
          setState(() {
            _nameCtrl.text = bill.title;
            _emoji = bill.emoji;
            _tags = List<String>.from(bill.tags);
            final s = bill.settings;
            _isVat = s.isVat;
            _vat = s.isVat ? s.vat : 7;
            _isService = s.isService;
            _serviceCharge = s.isService ? s.serviceCharge : 10;
            _currency = s.currency;
            _vatCtrl.text = _vat.toStringAsFixed(0);
            _serviceCtrl.text = _serviceCharge.toStringAsFixed(0);
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _tagCtrl.dispose();
    _vatCtrl.dispose();
    _serviceCtrl.dispose();
    super.dispose();
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_tags.contains(tag)) {
        _tags.remove(tag);
      } else {
        _tags.add(tag);
      }
    });
  }

  void _addCustomTag() {
    final t = _tagCtrl.text.trim().replaceAll('#', '');
    if (t.isEmpty || _tags.contains(t)) return;
    setState(() => _tags.add(t));
    _tagCtrl.clear();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _loading = true);

    final vatVal = double.tryParse(_vatCtrl.text) ?? _vat;
    final svcVal = double.tryParse(_serviceCtrl.text) ?? _serviceCharge;
    final settings = BillSettings(
      isVat: _isVat,
      vat: _isVat ? vatVal : 0,
      isService: _isService,
      serviceCharge: _isService ? svcVal : 0,
      currency: _currency,
    );

    final billsStore = context.read<BillsStore>();

    try {
      if (_isEdit && widget.billId != null) {
        await billsStore.updateBillMeta(
          widget.billId!,
          title: name,
          emoji: _emoji,
          tags: _tags,
          settings: settings,
        );
        if (mounted) context.pop();
      } else {
        final bill = await billsStore.createBill(
          title: name,
          emoji: _emoji,
          tags: _tags,
          groupId: widget.groupId,
          settings: settings,
        );
        if (bill != null && mounted) {
          // Replace this page with the bill detail
          context.pushReplacement('/bills/${bill.id}');
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteBill() async {
      final l = context.read<LocaleProvider>();
    if (widget.billId == null) return;
    final confirmed = await showConfirmDialog(
      context,
      title: l.t('create_bill_delete_title'),
      description: l.t('create_bill_delete_desc'),
      confirmLabel: l.t('create_bill_delete_confirm'),
      danger: true,
    );
    if (!confirmed || !mounted) return;
    setState(() => _loading = true);
    try {
      await context.read<BillsStore>().deleteBill(widget.billId!);
      if (mounted) {
        // Pop back to bills list
        while (context.canPop()) {
          context.pop();
        }
        context.go('/bills');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
      final l = context.watch<LocaleProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleText = _isEdit ? l.t('create_bill_title_edit') : l.t('create_bill_title_new');
    final submitLabel = _isEdit ? l.t('create_bill_submit_edit') : l.t('create_bill_submit_new');

    return Container(
      decoration: BoxDecoration(
        gradient: isDark ? AppGradients.backgroundDark : AppGradients.backgroundLight,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: isDark
              ? AppColors.bgDark.withValues(alpha: 0.95)
              : Colors.white.withValues(alpha: 0.95),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/bills');
              }
            },
          ),
          title: Text(
            titleText,
            style: GoogleFonts.sarabun(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
          actions: [
            if (_isEdit)
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.red),
                onPressed: _loading ? null : _deleteBill,
              ),
          ],
        ),
        body: GestureDetector(
          onTap: () {
            if (_showEmojiPicker) setState(() => _showEmojiPicker = false);
            FocusScope.of(context).unfocus();
          },
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 40,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Emoji + Name ──────────────────────────────
                FormSectionLabel(label: l.t('create_bill_name_label')),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _showEmojiPicker = !_showEmojiPicker),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.bgDark : AppColors.neutral100,
                          borderRadius: BorderRadius.circular(AppRadii.md),
                          border: Border.all(
                            color: _showEmojiPicker
                                ? AppColors.primary
                                : (isDark ? AppColors.borderDark : AppColors.borderLight),
                            width: _showEmojiPicker ? 2 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _emoji ?? '💸',
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _nameCtrl,
                        autofocus: !_isEdit,
                        decoration: InputDecoration(
                          hintText: l.t('create_bill_name_hint'),
                        ),
                        onSubmitted: (_) => _submit(),
                      ),
                    ),
                  ],
                ),

                if (_showEmojiPicker) ...[
                  const SizedBox(height: 8),
                  EmojiPickerGrid(
                    selected: _emoji,
                    isDark: isDark,
                    onSelect: (e) => setState(() {
                      _emoji = e;
                      _showEmojiPicker = false;
                    }),
                    onClear: () => setState(() {
                      _emoji = null;
                      _showEmojiPicker = false;
                    }),
                  ),
                ],

                const SizedBox(height: 16),

                // ── Description ───────────────────────────────
                FormSectionLabel(label: l.t('create_bill_desc_label')),
                const SizedBox(height: 8),
                TextField(
                  controller: _descCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: l.t('create_bill_desc_hint'),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Tags ──────────────────────────────────────
                FormSectionLabel(label: l.t('create_bill_tags_label')),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: kDefaultTags.map((tag) {
                    final selected = _tags.contains(tag);
                    return GestureDetector(
                      onTap: () => _toggleTag(tag),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary.withValues(alpha: 0.12)
                              : (isDark ? AppColors.surfaceDark : AppColors.neutral100),
                          borderRadius: BorderRadius.circular(AppRadii.xl),
                          border: Border.all(
                            color: selected
                                ? AppColors.primary.withValues(alpha: 0.4)
                                : Colors.transparent,
                          ),
                        ),
                        child: Text(
                          '#$tag',
                          style: GoogleFonts.sarabun(
                            fontSize: 12,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                            color: selected
                                ? AppColors.primary
                                : (isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _tagCtrl,
                        decoration: InputDecoration(
                          hintText: l.t('create_bill_tag_hint'),
                          prefixText: '#',
                        ),
                        onSubmitted: (_) => _addCustomTag(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _addCustomTag,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(AppRadii.md),
                        ),
                        child: const Icon(Icons.add_rounded, color: AppColors.surface, size: 20),
                      ),
                    ),
                  ],
                ),

                // ── Bill Settings ─────────────────────────────
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        l.t('create_bill_settings_label'),
                        style: GoogleFonts.sarabun(
                          fontSize: 12,
                          color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // VAT + Service
                Row(
                  children: [
                    Expanded(
                      child: ToggleCard(
                        label: 'VAT',
                        enabled: _isVat,
                        isDark: isDark,
                        onToggle: (v) => setState(() => _isVat = v),
                        child: _isVat
                            ? Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _vatCtrl,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                      style: GoogleFonts.sarabun(fontSize: 13),
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text('%', style: GoogleFonts.sarabun(fontSize: 13)),
                                ],
                              )
                            : Text(
                                l.t('create_bill_off'),
                                style: GoogleFonts.sarabun(
                                  fontSize: 12,
                                  color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ToggleCard(
                        label: 'Service',
                        enabled: _isService,
                        isDark: isDark,
                        onToggle: (v) => setState(() => _isService = v),
                        child: _isService
                            ? Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _serviceCtrl,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                      style: GoogleFonts.sarabun(fontSize: 13),
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text('%', style: GoogleFonts.sarabun(fontSize: 13)),
                                ],
                              )
                            : Text(
                                l.t('create_bill_off'),
                                style: GoogleFonts.sarabun(
                                  fontSize: 12,
                                  color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Currency
                FormSectionLabel(label: l.t('create_bill_currency_label')),
                const SizedBox(height: 8),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 3.2,
                  children: kBillFormCurrencies.map((c) {
                    final selected = _currency == c.code;
                    return GestureDetector(
                      onTap: () => setState(() => _currency = c.code),
                      child: Container(
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary
                              : (isDark ? AppColors.surfaceDark : AppColors.neutral100),
                          borderRadius: BorderRadius.circular(AppRadii.md),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            EmojiText(c.flag, fontSize: 14),
                            const SizedBox(width: 6),
                            Text(
                              '${c.symbol} ${c.label}',
                              style: GoogleFonts.sarabun(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? Colors.white
                                    : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                              ),
                            ),
                            if (selected) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 14),

                // Rounding
                FormSectionLabel(label: l.t('create_bill_rounding_label')),
                const SizedBox(height: 8),
                Row(
                  children: kRoundingOptions.map((r) {
                    final selected = _roundingMode == r['value'];
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _roundingMode = r['value']!),
                        child: Container(
                          margin: EdgeInsets.only(right: r['value'] != 'down' ? 6 : 0),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.primary
                                : (isDark ? AppColors.surfaceDark : AppColors.neutral100),
                            borderRadius: BorderRadius.circular(AppRadii.sm),
                          ),
                          child: Center(
                            child: Text(
                              r['label']!,
                              style: GoogleFonts.sarabun(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? Colors.white
                                    : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 32),

                // ── Submit ────────────────────────────────────
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _nameCtrl,
                  builder: (_, val, __) {
                    final canSubmit = val.text.trim().isNotEmpty && !_loading;
                    return ElevatedButton(
                      onPressed: canSubmit ? _submit : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              submitLabel,
                              style: GoogleFonts.sarabun(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.surface,
                              ),
                            ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

