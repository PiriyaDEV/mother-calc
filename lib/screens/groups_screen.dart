import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/groups_provider.dart';
import '../theme/app_theme.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GroupsProvider>().loadGroups();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<GroupsProvider>();

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Text(
                    'กลุ่ม',
                    style: GoogleFonts.notoSansThai(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => _showCreateGroupSheet(context),
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.group_add_outlined,
                          color: AppColors.primary, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: provider.loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary, strokeWidth: 2))
                  : RefreshIndicator(
                      onRefresh: () => provider.loadGroups(),
                      color: AppColors.primary,
                      child: provider.groups.isEmpty
                          ? ListView(
                              children: [
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.5,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Text('👥',
                                            style: TextStyle(fontSize: 48)),
                                        const SizedBox(height: 12),
                                        Text(
                                          'ยังไม่มีกลุ่ม',
                                          style: GoogleFonts.notoSansThai(
                                            fontSize: 15,
                                            color: isDark
                                                ? AppColors.textSecondaryDark
                                                : AppColors.textSecondaryLight,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        TextButton.icon(
                                          onPressed: () =>
                                              _showCreateGroupSheet(context),
                                          icon: const Icon(
                                              Icons.add_circle_outline,
                                              color: AppColors.primary),
                                          label: Text(
                                            'สร้างกลุ่มใหม่',
                                            style: GoogleFonts.notoSansThai(
                                                color: AppColors.primary),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: provider.groups.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final group = provider.groups[index];
                                return _GroupTile(
                                  group: group,
                                  onTap: () =>
                                      context.push('/groups/${group.id}'),
                                  onEdit: () =>
                                      _showEditGroupSheet(context, group),
                                  onDelete: () =>
                                      _confirmDelete(context, group, provider),
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateGroupSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _GroupFormSheet(
        onSave: (name, emoji) async {
          final provider = context.read<GroupsProvider>();
          final group =
              await provider.createGroup(name: name, emoji: emoji);
          if (group != null && ctx.mounted) {
            Navigator.pop(ctx);
            context.push('/groups/${group.id}');
          }
        },
      ),
    );
  }

  void _showEditGroupSheet(BuildContext context, Group group) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _GroupFormSheet(
        initialName: group.name,
        initialEmoji: group.emoji,
        onSave: (name, emoji) async {
          final provider = context.read<GroupsProvider>();
          final err = await provider.updateGroup(
              groupId: group.id, name: name, emoji: emoji);
          if (ctx.mounted) Navigator.pop(ctx);
          if (err != null && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(err, style: GoogleFonts.notoSansThai()),
              backgroundColor: AppColors.red,
              behavior: SnackBarBehavior.floating,
            ));
          }
        },
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, Group group, GroupsProvider provider) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('ลบกลุ่ม',
            style: GoogleFonts.notoSansThai(fontWeight: FontWeight.bold)),
        content: Text('ต้องการลบกลุ่ม "${group.name}" หรือไม่?',
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
      await provider.deleteGroup(group.id);
    }
  }
}

// ── Group Tile ─────────────────────────────────────────────────
class _GroupTile extends StatelessWidget {
  final Group group;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _GroupTile({
    required this.group,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final acceptedMembers =
        group.members.where((m) => m.role != 'pending').toList();

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
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  group.emoji ?? '👥',
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.name,
                    style: GoogleFonts.notoSansThai(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${acceptedMembers.length} สมาชิก',
                    style: GoogleFonts.notoSansThai(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                    ),
                  ),
                ],
              ),
            ),
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
      ),
    );
  }
}

// ── Group Form Sheet ───────────────────────────────────────────
class _GroupFormSheet extends StatefulWidget {
  final String? initialName;
  final String? initialEmoji;
  final Future<void> Function(String name, String? emoji) onSave;

  const _GroupFormSheet({
    this.initialName,
    this.initialEmoji,
    required this.onSave,
  });

  @override
  State<_GroupFormSheet> createState() => _GroupFormSheetState();
}

class _GroupFormSheetState extends State<_GroupFormSheet> {
  late TextEditingController _nameCtrl;
  String? _emoji;
  bool _loading = false;

  final List<String> _emojis = [
    '👥', '🏠', '🍕', '✈️', '🎉', '💼', '🏖️', '🎮',
    '🍜', '🎵', '⚽', '🏋️', '🎓', '💰', '🛒', '🌏',
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName ?? '');
    _emoji = widget.initialEmoji;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEdit = widget.initialName != null;

    return Container(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
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
              isEdit ? 'แก้ไขกลุ่ม' : 'สร้างกลุ่มใหม่',
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
              'ไอคอนกลุ่ม',
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

            // Name field
            Text(
              'ชื่อกลุ่ม',
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
              controller: _nameCtrl,
              autofocus: !isEdit,
              decoration: const InputDecoration(hintText: 'ชื่อกลุ่ม'),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _loading
                  ? null
                  : () async {
                      final name = _nameCtrl.text.trim();
                      if (name.isEmpty) return;
                      setState(() => _loading = true);
                      await widget.onSave(name, _emoji);
                      if (mounted) setState(() => _loading = false);
                    },
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(
                      isEdit ? 'บันทึก' : 'สร้างกลุ่ม',
                      style: GoogleFonts.notoSansThai(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
