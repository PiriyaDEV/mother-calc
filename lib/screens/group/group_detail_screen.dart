import 'package:kidtang_flutter/providers/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:kidtang_flutter/models/models.dart';
import 'package:kidtang_flutter/stores/bills_store.dart';
import 'package:kidtang_flutter/stores/groups_store.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';
import 'package:kidtang_flutter/widgets/shared/banner_ad_widget.dart';
import 'package:kidtang_flutter/widgets/shared/skeleton_loader.dart';
import 'package:kidtang_flutter/widgets/group/index.dart';

// ─────────────────────────────────────────────────────────────
class GroupDetailScreen extends StatefulWidget {
  final String groupId;
  const GroupDetailScreen({super.key, required this.groupId});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: 1, // default = bills (ตรงกับ Next.js)
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GroupsStore>().loadGroupDetail(widget.groupId);
      context.read<BillsStore>().loadForGroup(widget.groupId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
      final l = context.watch<LocaleProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // context.select — only rebuilds when THIS group's data changes.
    final group = context.select<GroupsStore, Group?>(
        (s) => s.getById(widget.groupId));
    final gp = context.read<GroupsStore>();

    // Use context.select so only mutations to THIS group's bills trigger a
    // rebuild of this screen.
    final bills = context.select<BillsStore, List<Bill>>(
      (s) => s.forGroup(widget.groupId),
    );

    if (gp.isDetailLoading(widget.groupId)) {
      return Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppGradients.backgroundDark
              : AppGradients.backgroundLight,
        ),
        child: const Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(child: GroupDetailSkeleton()),
        ),
      );
    }

    if (group == null) {
      return Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppGradients.backgroundDark
              : AppGradients.backgroundLight,
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
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
          ),
          body: Center(
            child: Text(l.t('groups_not_found'),
                style: GoogleFonts.notoSansThai(fontSize: 16)),
          ),
        ),
      );
    }

    final acceptedMembers =
        group.members.where((m) => m.isAccepted).toList();
    final pendingMembers =
        group.members.where((m) => m.isPending).toList();

    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? AppGradients.backgroundDark
            : AppGradients.backgroundLight,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        bottomNavigationBar: const BannerAdWidget(),
        body: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverAppBar(
              pinned: true,
              expandedHeight: 0,
              backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
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
              title: Row(
                children: [
                  Text(group.emoji ?? '👥',
                      style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          group.name,
                          style: GoogleFonts.notoSansThai(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.neutral900Dark
                                : AppColors.neutral900,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (group.description != null &&
                            group.description!.isNotEmpty)
                          Text(
                            group.description!,
                            style: GoogleFonts.notoSansThai(
                              fontSize: 11,
                              color: isDark
                                  ? AppColors.neutral400Dark
                                  : AppColors.neutral400,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () =>
                      context.push('/groups/${group.id}/edit'),
                ),
                const SizedBox(width: 4),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: GroupTabBar(
                  controller: _tabController,
                  isDark: isDark,
                  acceptedCount: acceptedMembers.length,
                  billsCount: bills.length,
                ),
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              // Tab 0: Members
              GroupMembersTab(
                group: group,
                acceptedMembers: acceptedMembers,
                pendingMembers: pendingMembers,
                isDark: isDark,
              ),
              // Tab 1: Bills
              GroupBillsTab(
                group: group,
                bills: bills,
                isDark: isDark,
              ),
              // Tab 2: Summary — Stateful, owns _expandedBillId
              GroupSummaryTab(
                bills: bills,
                isDark: isDark,
              ),
              // Tab 3: Analytics — Stateful, caches derived data
              GroupAnalyticsTab(
                bills: bills,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
