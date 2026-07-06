import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../stores/groups_store.dart';
import '../theme/app_theme.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/form_label.dart';

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

/// Full-page create/edit group screen.
class CreateGroupScreen extends StatefulWidget {
  final String mode;
  final String? groupId;

  const CreateGroupScreen({
    super.key,
    this.mode = 'create',
    this.groupId,
  });

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _tagCtrl;

  String? _emoji;
  late List<String> _tags;

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

    if (_isEdit && widget.groupId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final group = context.read<GroupsStore>().getById(widget.groupId!);
        if (group != null) {
          setState(() {
            _nameCtrl.text = group.name;
            _emoji = group.emoji;
            _tags = List<String>.from(group.tags ?? []);
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

    final groupsStore = context.read<GroupsStore>();

    try {
      if (_isEdit && widget.groupId != null) {
        await groupsStore.updateGroup(
          groupId: widget.groupId!,
          name: name,
          emoji: _emoji,
          tags: _tags,
        );
        if (mounted) context.pop();
      } else {
        final group = await groupsStore.createGroup(
          name: name,
          emoji: _emoji,
          tags: _tags,
        );
        if (group != null && mounted) {
          context.pushReplacement('/groups/${group.id}');
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteGroup() async {
    if (widget.groupId == null) return;
    final confirmed = await showConfirmDialog(
      context,
      title: 'ลบกลุ่มนี้?',
      description: 'กลุ่มและข้อมูลทั้งหมดจะถูกลบถาวร ไม่สามารถกู้คืนได้',
      confirmLabel: 'ลบ',
      danger: true,
    );
    if (!confirmed || !mounted) return;
    setState(() => _loading = true);
    try {
      final err = await context.read<GroupsStore>().deleteGroup(widget.groupId!);
      if (!mounted) return;
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err)),
        );
      } else {
        while (context.canPop()) {
          context.pop();
        }
        context.go('/groups');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleText = _isEdit ? 'แก้ไขกลุ่ม' : 'สร้างกลุ่มใหม่';
    final submitLabel = _isEdit ? 'บันทึกกลุ่ม' : 'สร้างกลุ่ม';

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
            onPressed: () => context.pop(),
          ),
          title: Text(
            titleText,
            style: GoogleFonts.notoSansThai(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
          actions: [
            if (_isEdit)
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.red),
                onPressed: _loading ? null : _deleteGroup,
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
                const FormSectionLabel(label: 'ชื่อกลุ่ม *'),
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
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _showEmojiPicker
                                ? AppColors.primary
                                : (isDark ? AppColors.borderDark : AppColors.borderLight),
                            width: _showEmojiPicker ? 2 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _emoji ?? '👥',
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
                        decoration: const InputDecoration(hintText: 'ชื่อกลุ่ม'),
                        onSubmitted: (_) => _submit(),
                      ),
                    ),
                  ],
                ),

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
                const FormSectionLabel(label: 'คำอธิบาย (ไม่บังคับ)'),
                const SizedBox(height: 8),
                TextField(
                  controller: _descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(hintText: 'คำอธิบายเพิ่มเติม...'),
                ),

                const SizedBox(height: 16),

                // ── Tags ──────────────────────────────────────
                const FormSectionLabel(label: 'แท็ก'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _kDefaultTags.map((tag) {
                    final selected = _tags.contains(tag);
                    return GestureDetector(
                      onTap: () => _toggleTag(tag),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary.withValues(alpha: 0.12)
                              : (isDark ? AppColors.surfaceDark : AppColors.neutral100),
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
                        child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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
              ],
            ),
          ),
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
        color: isDark ? AppColors.bgDark : AppColors.neutral50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            GestureDetector(
              onTap: onClear,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.borderDark : AppColors.neutral100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text('✕', style: TextStyle(fontSize: 14, color: Colors.grey)),
                ),
              ),
            ),
            ..._kEmojiPresets.map((e) {
              final isSelected = selected == e;
              return GestureDetector(
                onTap: () => onSelect(e),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected ? Border.all(color: AppColors.primary, width: 2) : null,
                  ),
                  child: Center(child: Text(e, style: const TextStyle(fontSize: 18))),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
