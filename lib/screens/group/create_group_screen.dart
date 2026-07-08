import 'package:kidtang_flutter/providers/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:kidtang_flutter/stores/groups_store.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';
import 'package:kidtang_flutter/widgets/shared/confirm_dialog.dart';
import 'package:kidtang_flutter/widgets/shared/form_label.dart';
import 'package:kidtang_flutter/widgets/shared/constants.dart';
import 'package:kidtang_flutter/widgets/shared/emoji_picker_grid.dart';

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
            _tags = List<String>.from(group.tags);
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
      final l = context.read<LocaleProvider>();
    if (widget.groupId == null) return;
    final confirmed = await showConfirmDialog(
      context,
      title: l.t('create_group_delete_title'),
      description: l.t('create_group_delete_desc'),
      confirmLabel: l.t('create_group_delete_confirm'),
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
      final l = context.watch<LocaleProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleText = _isEdit ? l.t('create_group_title_edit') : l.t('create_group_title_new');
    final submitLabel = _isEdit ? l.t('create_group_submit_edit') : l.t('create_group_submit_new');

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
                context.go('/groups');
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
                FormSectionLabel(label: l.t('create_group_name_label')),
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
                        decoration: InputDecoration(hintText: l.t('create_group_name_hint')),
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
                FormSectionLabel(label: l.t('create_group_desc_label')),
                const SizedBox(height: 8),
                TextField(
                  controller: _descCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(hintText: l.t('create_group_desc_hint')),
                ),

                const SizedBox(height: 16),

                // ── Tags ──────────────────────────────────────
                FormSectionLabel(label: l.t('create_group_tags_label')),
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
                          hintText: l.t('create_group_tag_hint'),
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

