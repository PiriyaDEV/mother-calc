import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/groups_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/create_entity_sheet.dart';
import '../widgets/empty_state.dart';
import '../widgets/shared_group_card.dart';

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
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
              child: Row(
                children: [
                  Text(
                    'กลุ่ม',
                    style: GoogleFonts.notoSansThai(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  if (provider.groups.isNotEmpty) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryFaint,
                        borderRadius: BorderRadius.circular(AppRadii.xl),
                      ),
                      child: Text(
                        '${provider.groups.length}',
                        style: GoogleFonts.notoSansThai(
                          fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                      ),
                    ),
                  ],
                  const Spacer(),
                  GestureDetector(
                    onTap: _showCreateGroupSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(AppRadii.md),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add_rounded, color: Colors.white, size: 16),
                          const SizedBox(width: 5),
                          Text('สร้างกลุ่ม',
                              style: GoogleFonts.notoSansThai(
                                  fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                        ],
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
                          ? EmptyStateWidget(
                              emoji: '👥',
                              title: 'ยังไม่มีกลุ่ม',
                              subtitle: 'สร้างกลุ่มและเชิญเพื่อนมาหารค่าใช้จ่ายด้วยกัน',
                              ctaLabel: 'สร้างกลุ่มแรก',
                              onCta: _showCreateGroupSheet,
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 100),
                              itemCount: provider.groups.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: AppSpacing.sm),
                              itemBuilder: (context, index) {
                                final group = provider.groups[index];
                                return SharedGroupCard(
                                  group: group,
                                  onTap: () =>
                                      context.push('/groups/${group.id}'),
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
