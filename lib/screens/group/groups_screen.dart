import 'package:kidtang_flutter/providers/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:kidtang_flutter/stores/groups_store.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';
import 'package:kidtang_flutter/widgets/shared/banner_ad_widget.dart';
import 'package:kidtang_flutter/widgets/shared/empty_state.dart';
import 'package:kidtang_flutter/widgets/shared/shared_group_card.dart';
import 'package:kidtang_flutter/widgets/shared/skeleton_loader.dart';

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
      context.read<GroupsStore>().loadGroups();
    });
  }

  void _showCreateGroupSheet() {
    context.push('/groups/create');
  }

  @override
  Widget build(BuildContext context) {
    final l = context.watch<LocaleProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // context.watch — rebuilds when groups list or loading state changes.
    final provider = context.watch<GroupsStore>();

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
                          l.t('groups_title'),
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
                            l.t('unit_groups').replaceFirst('{count}', '${provider.groups.length}'),
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
                  Semantics(
                    label: l.t('groups_create_first'),
                    button: true,
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      child: InkWell(
                        onTap: _showCreateGroupSheet,
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        child: Ink(
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
                    ),
                  ),
                ],
              ),
            ),

            // ── Ad Banner ────────────────────────────────────────
            const BannerAdWidget(),

            // ── Content ──────────────────────────────────────────
            Expanded(
              child: provider.loading
                  ? const GroupsListSkeleton()
                  : RefreshIndicator(
                      onRefresh: () => provider.loadGroups(),
                      color: AppColors.primary,
                      child: provider.groups.isEmpty
                          ? EmptyStateWidget(
                              emoji: '👥',
                              title: l.t('groups_empty_title'),
                              subtitle:
                                  l.t('groups_empty_sub'),
                              ctaLabel: l.t('groups_create_first'),
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
                                  onTap: () => context.push('/groups/${group.id}'),
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
