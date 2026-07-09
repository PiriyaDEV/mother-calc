import 'package:kidtang_flutter/providers/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:kidtang_flutter/models/models.dart';
import 'package:kidtang_flutter/stores/bills_store.dart';
import 'package:kidtang_flutter/stores/friends_store.dart';
import 'package:kidtang_flutter/stores/groups_store.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';
import 'package:kidtang_flutter/widgets/shared/banner_ad_widget.dart';
import 'package:kidtang_flutter/widgets/shared/skeleton_loader.dart';
import 'package:kidtang_flutter/widgets/group/index.dart';
import 'package:kidtang_flutter/widgets/shared/emoji_text.dart';

// ─────────────────────────────────────────────────────────────
class GroupDetailScreen extends StatefulWidget {
  final String groupId;
  const GroupDetailScreen({super.key, required this.groupId});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

// ── Lazy tab body ─────────────────────────────────────────────
// Defers building the child until the tab is first selected.
// Once built, the child is kept alive so it is not rebuilt on
// every tab switch.
class _LazyTabBody extends StatefulWidget {
  final TabController tabController;
  final int tabIndex;
  final Widget child;

  const _LazyTabBody({
    required this.tabController,
    required this.tabIndex,
    required this.child,
  });

  @override
  State<_LazyTabBody> createState() => _LazyTabBodyState();
}

class _LazyTabBodyState extends State<_LazyTabBody>
    with AutomaticKeepAliveClientMixin {
  bool _built = false;

  @override
  bool get wantKeepAlive => _built;

  @override
  void initState() {
    super.initState();
    if (widget.tabController.index == widget.tabIndex) {
      _built = true;
    } else {
      widget.tabController.addListener(_onTabChanged);
    }
  }

  void _onTabChanged() {
    if (!_built && widget.tabController.index == widget.tabIndex) {
      setState(() => _built = true);
      widget.tabController.removeListener(_onTabChanged);
    }
  }

  @override
  void dispose() {
    widget.tabController.removeListener(_onTabChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (!_built) return const SizedBox.shrink();
    return widget.child;
  }
}

class _GroupDetailScreenState extends State<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  Future<void> _onRefresh() async {
    await Future.wait([
      context.read<GroupsStore>().loadGroupDetail(widget.groupId),
      context.read<BillsStore>().loadForGroup(widget.groupId),
    ]);
  }

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
                style: GoogleFonts.sarabun(fontSize: 16)),
          ),
        ),
      );
    }

    final acceptedMembers =
        group.members.where((m) => m.isAccepted).toList();
    final pendingMembers =
        group.members.where((m) => m.isPending).toList();

    // Build friend user-id set for member sorting (O(1) lookup)
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final friendUserIds = context
        .read<FriendsStore>()
        .friends
        .map((f) => f.requesterId == currentUserId
            ? f.addresseeId
            : f.requesterId)
        .toSet();

    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? AppGradients.backgroundDark
            : AppGradients.backgroundLight,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        bottomNavigationBar: const BannerAdWidget(),
        body: RefreshIndicator(
          onRefresh: _onRefresh,
          color: AppColors.primary,
          notificationPredicate: (notification) => notification.depth == 2,
          child: NestedScrollView(
            headerSliverBuilder: (context, _) => [
              SliverAppBar(
                pinned: true,
                expandedHeight: 0,
                backgroundColor: Colors.transparent,
                flexibleSpace: Container(
                  decoration: BoxDecoration(
                    gradient: isDark
                        ? AppGradients.backgroundDark
                        : AppGradients.backgroundLight,
                  ),
                ),
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
                    EmojiText(group.emoji ?? '👥', fontSize: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            group.name,
                            style: GoogleFonts.sarabun(
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
                              style: GoogleFonts.sarabun(
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
              physics: const NeverScrollableScrollPhysics(),
              children: [
                // Each tab is wrapped in _LazyTabBody so it is only built
                // the first time the user navigates to it.  The default tab
                // is index 1 (Bills), so tabs 0, 2, and 3 are deferred.
                _LazyTabBody(
                  tabController: _tabController,
                  tabIndex: 0,
                  child: GroupMembersTab(
                    group: group,
                    acceptedMembers: acceptedMembers,
                    pendingMembers: pendingMembers,
                    isDark: isDark,
                    currentUserId: currentUserId,
                    friendUserIds: friendUserIds,
                  ),
                ),
                _LazyTabBody(
                  tabController: _tabController,
                  tabIndex: 1,
                  child: GroupBillsTab(
                    group: group,
                    bills: bills,
                    isDark: isDark,
                  ),
                ),
                _LazyTabBody(
                  tabController: _tabController,
                  tabIndex: 2,
                  child: GroupSummaryTab(
                    bills: bills,
                    isDark: isDark,
                  ),
                ),
                _LazyTabBody(
                  tabController: _tabController,
                  tabIndex: 3,
                  child: GroupAnalyticsTab(
                    bills: bills,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
