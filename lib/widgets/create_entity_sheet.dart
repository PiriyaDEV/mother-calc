import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

// ── Constants (ตรงกับ Next.js EMOJI_PRESETS, DEFAULT_TAGS, currencies, rounding) ──

const _kEmojiPresets = [
  '🍜', '🍕', '🍺', '🎉', '✈️', '🏖️', '🎂', '🛒',
  '🏠', '💊', '🎮', '🎵', '🚗', '⚽', '📚', '💼',
  '🌮', '🍣', '🥗', '🍔', '🍦', '☕', '🍷', '🎁',
  '🏋️', '🎬', '🛫', '🏕️', '🎯', '💰',
];

const _kDefaultTags = [
  'อาหาร', 'เที่ยว', 'ปาร์ตี้', 'ช้อปปิ้ง', 'ที่พัก',
  'เดินทาง', 'บันเทิง', 'สุขภาพ', 'การศึกษา', 'อื่นๆ',
];

const _kCurrencies = [
  {'code': 'THB', 'flag': '🇹🇭', 'symbol': '฿',  'label': 'บาท'},
  {'code': 'USD', 'flag': '🇺🇸', 'symbol': '\$', 'label': 'USD'},
  {'code': 'EUR', 'flag': '🇪🇺', 'symbol': '€',  'label': 'EUR'},
  {'code': 'JPY', 'flag': '🇯🇵', 'symbol': '¥',  'label': 'JPY'},
  {'code': 'SGD', 'flag': '🇸🇬', 'symbol': 'S\$','label': 'SGD'},
  {'code': 'GBP', 'flag': '🇬🇧', 'symbol': '£',  'label': 'GBP'},
  {'code': 'CNY', 'flag': '🇨🇳', 'symbol': '¥',  'label': 'CNY'},
  {'code': 'KRW', 'flag': '🇰🇷', 'symbol': '₩',  'label': 'KRW'},
];

const _kRoundingOptions = [
  {'value': 'none',    'label': 'ไม่ปัด'},
  {'value': 'nearest', 'label': 'ใกล้สุด'},
  {'value': 'up',      'label': 'ขึ้น'},
  {'value': 'down',    'label': 'ลง'},
];

// ── Result data class ──────────────────────────────────────────

class EntityFormResult {
  final String name;
  final String? emoji;
  final String description;
  final List<String> tags;
  final BillSettings? settings; // null for group type

  const EntityFormResult({
    required this.name,
    this.emoji,
    this.description = '',
    this.tags = const [],
    this.settings,
  });
}

// ── Public helper ──────────────────────────────────────────────

/// Show the create/edit sheet.
/// [type] = 'bill' | 'group'
/// [mode] = 'create' | 'edit'
/// [initialData] — pre-fill when mode='edit'
/// [onDelete] — called when user confirms delete (edit mode only)
Future<EntityFormResult?> showCreateEntitySheet(
  BuildContext context, {
  required String type,
  String mode = 'create',
  EntityFormResult? initialData,
  Future<void> Function()? onDelete,
}) {
  return showModalBottomSheet<EntityFormResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CreateEntitySheet(
      type: type,
      mode: mode,
      initialData: initialData,
      onDelete: onDelete,
    ),
  );
}

// ── Sheet widget ───────────────────────────────────────────────

class _CreateEntitySheet extends StatefulWidget {
  final String type;
  final String mode;
  final EntityFormResult? initialData;
  final Future<void> Function()? onDelete;

  const _CreateEntitySheet({
    required this.type,
    required this.mode,
    this.initialData,
    this.onDelete,
  });

  @override
  State<_CreateEntitySheet> createState() => _CreateEntitySheetState();
}

class _CreateEntitySheetState extends State<_CreateEntitySheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _tagCtrl;
  late TextEditingController _vatCtrl;
  late TextEditingController _serviceCtrl;

  String? _emoji;
  late List<String> _tags;

  // Bill settings
  bool _isVat = false;
  double _vat = 7;
  bool _isService = false;
  double _serviceCharge = 10;
  String _currency = 'THB';
  String _roundingMode = 'none';

  bool _loading = false;
  bool _showEmojiPicker = false;

  bool get _isBill => widget.type == 'bill';
  bool get _isEdit => widget.mode == 'edit';

  @override
  void initState() {
    super.initState();
    final d = widget.initialData;
    _nameCtrl = TextEditingController(text: d?.name ?? '');
    _descCtrl = TextEditingController(text: d?.description ?? '');
    _tagCtrl = TextEditingController();
    _emoji = d?.emoji;
    _tags = List<String>.from(d?.tags ?? []);

    if (d?.settings != null) {
      final s = d!.settings!;
      _isVat = s.isVat;
      _vat = s.isVat ? s.vat : 7;
      _isService = s.isService;
      _serviceCharge = s.isService ? s.serviceCharge : 10;
      _currency = s.currency;
    }
    _vatCtrl = TextEditingController(text: _vat.toStringAsFixed(0));
    _serviceCtrl =
        TextEditingController(text: _serviceCharge.toStringAsFixed(0));
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

  void _submit() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    BillSettings? settings;
    if (_isBill) {
      final vatVal = double.tryParse(_vatCtrl.text) ?? _vat;
      final svcVal = double.tryParse(_serviceCtrl.text) ?? _serviceCharge;
      settings = BillSettings(
        isVat: _isVat,
        vat: _isVat ? vatVal : 0,
        isService: _isService,
        serviceCharge: _isService ? svcVal : 0,
        currency: _currency,
      );
    }

    Navigator.pop(
      context,
      EntityFormResult(
        name: name,
        emoji: _emoji,
        description: _descCtrl.text.trim(),
        tags: List<String>.from(_tags),
        settings: settings,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isBill = _isBill;
    final isEdit = _isEdit;

    final titleText = isBill
        ? (isEdit ? 'แก้ไขบิล' : 'สร้างบิลใหม่')
        : (isEdit ? 'แก้ไขกลุ่ม' : 'สร้างกลุ่มใหม่');

    final submitLabel = isBill
        ? (isEdit ? 'บันทึกบิล' : 'สร้างบิล')
        : (isEdit ? 'บันทึกกลุ่ม' : 'สร้างกลุ่ม');

    final namePlaceholder = isBill ? 'เช่น ข้าวเย็น, ปาร์ตี้...' : 'ชื่อกลุ่ม';

    return GestureDetector(
      onTap: () {
        if (_showEmojiPicker) setState(() => _showEmojiPicker = false);
      },
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header row
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      titleText,
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
            ),
            // Scrollable body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Emoji + Name row ──────────────────────────
                    _SectionLabel(
                      label: isBill ? 'ชื่อบิล *' : 'ชื่อกลุ่ม *',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Emoji button
                        GestureDetector(
                          onTap: () => setState(
                              () => _showEmojiPicker = !_showEmojiPicker),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.bgDark
                                  : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _showEmojiPicker
                                    ? AppColors.primary
                                    : (isDark
                                        ? AppColors.borderDark
                                        : AppColors.borderLight),
                                width: _showEmojiPicker ? 2 : 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                _emoji ?? (isBill ? '💰' : '👥'),
                                style: const TextStyle(fontSize: 22),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _nameCtrl,
                            autofocus: !isEdit,
                            decoration: InputDecoration(
                              hintText: namePlaceholder,
                            ),
                            onSubmitted: (_) => _submit(),
                          ),
                        ),
                      ],
                    ),

                    // Emoji picker popup
                    if (_showEmojiPicker) ...[
                      const SizedBox(height: 8),
                      _EmojiPickerGrid(
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
                    _SectionLabel(
                        label: 'คำอธิบาย (ไม่บังคับ)', isDark: isDark),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _descCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'คำอธิบายเพิ่มเติม...',
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Tags ──────────────────────────────────────
                    _SectionLabel(label: 'แท็ก', isDark: isDark),
                    const SizedBox(height: 8),
                    // Preset chips
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _kDefaultTags.map((tag) {
                        final selected = _tags.contains(tag);
                        return GestureDetector(
                          onTap: () => _toggleTag(tag),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primary.withValues(alpha: 0.12)
                                  : (isDark
                                      ? const Color(0xFF1F2937)
                                      : const Color(0xFFF3F4F6)),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: selected
                                    ? AppColors.primary.withValues(alpha: 0.4)
                                    : Colors.transparent,
                              ),
                            ),
                            child: Text(
                              '#$tag',
                              style: GoogleFonts.notoSansThai(
                                fontSize: 12,
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
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.add_rounded,
                                color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),

                    // ── Bill Settings (bill only) ──────────────────
                    if (isBill) ...[
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: isDark
                                  ? AppColors.borderDark
                                  : AppColors.borderLight,
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              'ตั้งค่าบิล',
                              style: GoogleFonts.notoSansThai(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.textTertiaryDark
                                    : AppColors.textTertiaryLight,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: isDark
                                  ? AppColors.borderDark
                                  : AppColors.borderLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // VAT + Service 2-column grid
                      Row(
                        children: [
                          Expanded(
                            child: _ToggleCard(
                              label: 'VAT',
                              enabled: _isVat,
                              isDark: isDark,
                              onToggle: (v) =>
                                  setState(() => _isVat = v),
                              child: _isVat
                                  ? Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _vatCtrl,
                                            keyboardType:
                                                TextInputType.number,
                                            inputFormatters: [
                                              FilteringTextInputFormatter
                                                  .digitsOnly
                                            ],
                                            style: GoogleFonts.notoSansThai(
                                                fontSize: 13),
                                            decoration:
                                                const InputDecoration(
                                              isDense: true,
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 6),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text('%',
                                            style:
                                                GoogleFonts.notoSansThai(
                                                    fontSize: 13)),
                                      ],
                                    )
                                  : Text(
                                      'ปิดอยู่',
                                      style: GoogleFonts.notoSansThai(
                                        fontSize: 12,
                                        color: isDark
                                            ? AppColors.textTertiaryDark
                                            : AppColors.textTertiaryLight,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _ToggleCard(
                              label: 'Service',
                              enabled: _isService,
                              isDark: isDark,
                              onToggle: (v) =>
                                  setState(() => _isService = v),
                              child: _isService
                                  ? Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _serviceCtrl,
                                            keyboardType:
                                                TextInputType.number,
                                            inputFormatters: [
                                              FilteringTextInputFormatter
                                                  .digitsOnly
                                            ],
                                            style: GoogleFonts.notoSansThai(
                                                fontSize: 13),
                                            decoration:
                                                const InputDecoration(
                                              isDense: true,
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 6),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text('%',
                                            style:
                                                GoogleFonts.notoSansThai(
                                                    fontSize: 13)),
                                      ],
                                    )
                                  : Text(
                                      'ปิดอยู่',
                                      style: GoogleFonts.notoSansThai(
                                        fontSize: 12,
                                        color: isDark
                                            ? AppColors.textTertiaryDark
                                            : AppColors.textTertiaryLight,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Currency grid (2-column, 8 items)
                      _SectionLabel(label: 'สกุลเงิน', isDark: isDark),
                      const SizedBox(height: 8),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 3.2,
                        children: _kCurrencies.map((c) {
                          final selected = _currency == c['code'];
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _currency = c['code']!),
                            child: Container(
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.primary
                                    : (isDark
                                        ? const Color(0xFF1F2937)
                                        : const Color(0xFFF3F4F6)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Text(c['flag']!,
                                      style:
                                          const TextStyle(fontSize: 14)),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${c['symbol']} ${c['label']}',
                                    style: GoogleFonts.notoSansThai(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: selected
                                          ? Colors.white
                                          : (isDark
                                              ? AppColors.textSecondaryDark
                                              : AppColors
                                                  .textSecondaryLight),
                                    ),
                                  ),
                                  if (selected) ...[
                                    const SizedBox(width: 4),
                                    const Icon(Icons.check_rounded,
                                        size: 14, color: Colors.white),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 14),

                      // Rounding grid (4-column)
                      _SectionLabel(label: 'การปัดเศษ', isDark: isDark),
                      const SizedBox(height: 8),
                      Row(
                        children: _kRoundingOptions.map((r) {
                          final selected = _roundingMode == r['value'];
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setState(
                                  () => _roundingMode = r['value']!),
                              child: Container(
                                margin: EdgeInsets.only(
                                  right: r['value'] != 'down' ? 6 : 0,
                                ),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? AppColors.primary
                                      : (isDark
                                          ? const Color(0xFF1F2937)
                                          : const Color(0xFFF3F4F6)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    r['label']!,
                                    style: GoogleFonts.notoSansThai(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: selected
                                          ? Colors.white
                                          : (isDark
                                              ? AppColors.textSecondaryDark
                                              : AppColors
                                                  .textSecondaryLight),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // ── Submit button ─────────────────────────────
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _nameCtrl,
                      builder: (_, val, __) {
                        final canSubmit =
                            val.text.trim().isNotEmpty && !_loading;
                        return ElevatedButton(
                          onPressed: canSubmit ? _submit : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            disabledBackgroundColor:
                                AppColors.primary.withValues(alpha: 0.4),
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white),
                                )
                              : Text(
                                  submitLabel,
                                  style: GoogleFonts.notoSansThai(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        );
                      },
                    ),

                    // ── Delete button (edit mode only) ────────────
                    if (isEdit && widget.onDelete != null) ...[
                      const SizedBox(height: 10),
                      OutlinedButton(
                        onPressed: _loading
                            ? null
                            : () async {
                                setState(() => _loading = true);
                                final nav = Navigator.of(context);
                                await widget.onDelete!();
                                if (mounted) {
                                  setState(() => _loading = false);
                                  nav.pop();
                                }
                              },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.red),
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          isBill ? 'ลบบิลนี้' : 'ลบกลุ่มนี้',
                          style: GoogleFonts.notoSansThai(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.red,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Emoji Picker Grid ──────────────────────────────────────────

class _EmojiPickerGrid extends StatelessWidget {
  final String? selected;
  final bool isDark;
  final void Function(String) onSelect;
  final VoidCallback onClear;

  const _EmojiPickerGrid({
    required this.selected,
    required this.isDark,
    required this.onSelect,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 192),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgDark : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            // Clear button
            GestureDetector(
              onTap: onClear,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF374151)
                      : const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text('✕',
                      style: TextStyle(fontSize: 14, color: Colors.grey)),
                ),
              ),
            ),
            // Emoji items
            ..._kEmojiPresets.map((e) {
              final isSelected = selected == e;
              return GestureDetector(
                onTap: () => onSelect(e),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected
                        ? Border.all(
                            color: AppColors.primary, width: 2)
                        : null,
                  ),
                  child: Center(
                    child: Text(e,
                        style: const TextStyle(fontSize: 18)),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── Toggle Card (VAT / Service) ────────────────────────────────

class _ToggleCard extends StatelessWidget {
  final String label;
  final bool enabled;
  final bool isDark;
  final ValueChanged<bool> onToggle;
  final Widget child;

  const _ToggleCard({
    required this.label,
    required this.enabled,
    required this.isDark,
    required this.onToggle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: enabled
              ? AppColors.primary.withValues(alpha: 0.4)
              : (isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.notoSansThai(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: enabled,
                  onChanged: onToggle,
                  activeColor: AppColors.primary,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}

// ── Section Label ──────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isDark;

  const _SectionLabel({required this.label, required this.isDark});

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
