import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/groups_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/create_entity_sheet.dart';
import '../widgets/member_avatar.dart';

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

  Future<void> _showCreateGroupSheet() async {
    final result = await showCreateEntitySheet(
      context,
      type: 'group',
      mode: 'create',
    );
    if (result != null && mounted) {
      final provider = context.read<GroupsProvider>();
      final group = await provider.createGroup(
        name: result.name,
        emoji: result.emoji,
      );
      if (group != null && mounted) {
        context.push('/groups/${group.id}');
      }
    }
  }

  Future<void> _showEditGroupSheet(Group group) async {
    final result = await showCreateEntitySheet(
      context,
      type: 'group',
      mode: 'edit',
      initialData: EntityFormResult(
        name: group.name,
        emoji: group.emoji,
        description: group.description ?? '',
        tags: group.tags,
      ),
      onDelete: () async {
        final provider = context.read<GroupsProvider>();
        await provider.deleteGroup(group.id);
      },
    );
    if (result != null && mounted) {
      final provider = context.read<GroupsProvider>();
      final err = await provider.updateGroup(
        groupId: group.id,
        name: result.name,
        emoji: result.emoji,
      );
      if (err != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(err, style: GoogleFonts.notoSansThai()),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Future<void> _confirmDelete(Group group) async {
    final confirm = await showConfirmDialog(
      context,
      title: 'ลบกลุ่ม',
      description: 'ต้องการลบกลุ่ม "${group.name}" หรือไม่?',
      confirmLabel: 'ลบ',
      danger: true,
    );
    if (confirm && mounted) {
      await context.read<GroupsProvider>().deleteGroup(group.id);
    }
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
                  GestureDetector(
                    onTap: _showCreateGroupSheet,
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
                                          onPressed: _showCreateGroupSheet,
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
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                              itemCount: provider.groups.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final group = provider.groups[index];
                                return _GroupTile(
                                  group: group,
                                  onTap: () =>
                                      context.push('/groups/${group.id}'),
                                  onEdit: () => _showEditGroupSheet(group),
                                  onDelete: () => _confirmDelete(group),
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
    final acceptedMembers = group.members.where((m) => m.isAccepted).toList();
    final pendingCount = group.members.where((m) => m.isPending).length;
    final visibleTags = group.tags.take(2).toList();
    final extraTags = group.tags.length > 2 ? group.tags.length - 2 : 0;
    final avatarMembers = acceptedMembers.take(4).toList();
    final extraAvatars = acceptedMembers.length > 4 ? acceptedMembers.length - 4 : 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
          boxShadow: isDark
              ? null
              : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Group emoji icon
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.15),
                        AppColors.primaryLight.withValues(alpha: 0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                  ),
                  child: Center(
                    child: Text(group.emoji ?? '👥', style: const TextStyle(fontSize: 24)),
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
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.people_outline_rounded, size: 13,
                              color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight),
                          const SizedBox(width: 4),
                          Text(
                            '${acceptedMembers.length} สมาชิก',
                            style: GoogleFonts.notoSansThai(
                              fontSize: 12,
                              color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                            ),
                          ),
                          if (pendingCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'รอ $pendingCount',
                                style: GoogleFonts.notoSansThai(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFD97706),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Action buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: onEdit,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.settings_outlined, size: 16,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: onDelete,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.red.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.red),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Member avatars row
            if (acceptedMembers.isNotEmpty) ...[
              const SizedBox(height: 14),
              Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.borderLight),
              const SizedBox(height: 12),
              Row(
                children: [
                  // Overlapping avatars
                  SizedBox(
                    height: 28,
                    width: avatarMembers.length * 22.0 + (extraAvatars > 0 ? 30 : 0),
                    child: Stack(
                      children: [
                        ...avatarMembers.asMap().entries.map((e) {
                          final member = e.value;
                          final name = member.profile?.displayName ?? member.profile?.username ?? '?';
                          return Positioned(
                            left: e.key * 20.0,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark ? AppColors.surfaceDark : Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: MemberAvatar(
                                name: name,
                                color: AppColors.memberColors[e.key % AppColors.memberColors.length],
                                size: 26,
                                avatarUrl: member.profile?.avatarUrl,
                              ),
                            ),
                          );
                        }),
                        if (extraAvatars > 0)
                          Positioned(
                            left: avatarMembers.length * 20.0,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark ? AppColors.surfaceDark : Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '+$extraAvatars',
                                  style: GoogleFonts.notoSansThai(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Tags
                  ...visibleTags.map((tag) => Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('#$tag',
                              style: GoogleFonts.notoSansThai(
                                  fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500)),
                        ),
                      )),
                  if (extraTags > 0)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Text(
                        '+$extraTags',
                        style: GoogleFonts.notoSansThai(
                            fontSize: 11,
                            color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight),
                      ),
                    ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded, size: 20,
                      color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
