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
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'กลุ่มของฉัน',
                          style: GoogleFonts.anuphan(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.neutral900Dark
                                : AppColors.neutral900,
                            height: 1.1,
                          ),
                        ),
                        if (provider.groups.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${provider.groups.length} กลุ่มทั้งหมด',
                            style: GoogleFonts.notoSansThai(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.neutral400Dark
                                  : AppColors.neutral400,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Add button
                  GestureDetector(
                    onTap: _showCreateGroupSheet,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: AppGradients.primaryButtonLight,
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryBlue.withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Content ──────────────────────────────────────────
            Expanded(
              child: provider.loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2,
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => provider.loadGroups(),
                      color: AppColors.primary,
                      child: provider.groups.isEmpty
                          ? EmptyStateWidget(
                              emoji: '👥',
                              title: 'ยังไม่มีกลุ่ม',
                              subtitle:
                                  'สร้างกลุ่มและเชิญเพื่อนมาหารค่าใช้จ่ายด้วยกัน',
                              ctaLabel: 'สร้างกลุ่มแรก',
                              onCta: _showCreateGroupSheet,
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                  20, 16, 20, 110),
                              itemCount: provider.groups.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
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
