import 'package:kidtang_flutter/providers/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kidtang_flutter/models/models.dart';
import 'package:kidtang_flutter/stores/friends_store.dart';
import 'package:kidtang_flutter/stores/groups_store.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';
import 'package:kidtang_flutter/widgets/shared/member_avatar.dart';

class ManageMembersSheet extends StatefulWidget {
  final Group group;
  final List<GroupMember> acceptedMembers;
  final bool isDark;

  const ManageMembersSheet({
    super.key,
    required this.group,
    required this.acceptedMembers,
    required this.isDark,
  });

  @override
  State<ManageMembersSheet> createState() => _ManageMembersSheetState();
}

class _ManageMembersSheetState extends State<ManageMembersSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _externalNameCtrl = TextEditingController();
  bool _invitingFriend = false;
  bool _addingExternal = false;
  String? _externalError;
  String? _externalSuccess;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _externalNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _inviteFriend(Profile profile) async {
    final username = profile.username;
    if (username == null) return;
    setState(() => _invitingFriend = true);
    final gp = context.read<GroupsStore>();
    await gp.inviteMember(widget.group.id, username);
    if (mounted) setState(() => _invitingFriend = false);
  }

  Future<void> _addExternal() async {
      final l = context.read<LocaleProvider>();
    final name = _externalNameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _addingExternal = true;
      _externalError = null;
      _externalSuccess = null;
    });
    final gp = context.read<GroupsStore>();
    final err = await gp.addExternalMember(widget.group.id, name);
    if (!mounted) return;
    setState(() {
      _addingExternal = false;
      if (err != null) {
        _externalError = err;
      } else {
        _externalSuccess = l.t('group_external_added').replaceAll('{name}', name);
        _externalNameCtrl.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
      final l = context.watch<LocaleProvider>();
    final isDark = widget.isDark;
    final currentUserId =
        Supabase.instance.client.auth.currentUser?.id ?? '';

    // Friends not yet in this group
    final groupUserIds = widget.acceptedMembers
        .where((m) => m.userId != null)
        .map((m) => m.userId!)
        .toSet();
    final friendsProvider = context.read<FriendsStore>();
    final availableFriends = friendsProvider.friends
        .where((f) {
          final p = f.otherProfile(currentUserId);
          return p != null && !groupUserIds.contains(p.id);
        })
        .map((f) => f.otherProfile(currentUserId)!)
        .toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.xl),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Text(
              l.t('group_manage_members'),
              style: GoogleFonts.sarabun(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Tab bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.neutral100,
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: TabBar(
              controller: _tabCtrl,
              indicator: BoxDecoration(
                color: isDark ? AppColors.borderDark : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadii.sm),
                boxShadow: const [AppShadows.subtle],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: AppColors.primary,
              unselectedLabelColor: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.neutral600,
              labelStyle: GoogleFonts.sarabun(
                  fontSize: 13, fontWeight: FontWeight.w600),
              unselectedLabelStyle: GoogleFonts.sarabun(fontSize: 13),
              tabs: [
                Tab(text: l.t('group_invite_friend')),
                Tab(text: l.t('group_add_external')),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildFriendsTab(isDark, availableFriends),
                _buildExternalTab(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsTab(bool isDark, List<Profile> available) {
    if (available.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            context.read<LocaleProvider>().t('group_no_friends_to_invite'),
            style: GoogleFonts.sarabun(
              fontSize: 14,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      itemCount: available.length,
      itemBuilder: (ctx, i) {
        final profile = available[i];
        final name =
            profile.displayName ?? profile.username ?? context.read<LocaleProvider>().t('friends_fallback_name');

        return GestureDetector(
          onTap: _invitingFriend ? null : () => _inviteFriend(profile),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.neutral50,
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(
                color: isDark
                    ? AppColors.borderDark
                    : AppColors.borderLight,
              ),
            ),
            child: Row(
              children: [
                MemberAvatar(
                  name: name,
                  color: AppColors.primary,
                  size: 36,
                  avatarUrl: profile.avatarUrl,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.sarabun(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                      if (profile.username != null)
                        Text(
                          '@${profile.username}',
                          style: GoogleFonts.sarabun(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiaryLight,
                          ),
                        ),
                    ],
                  ),
                ),
                if (_invitingFriend)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary),
                  )
                else
                  const Icon(Icons.person_add_outlined,
                      color: AppColors.primary, size: 22),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExternalTab(bool isDark) {
    final l = context.read<LocaleProvider>();
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: 32 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.t('group_external_member_desc'),
            style: GoogleFonts.sarabun(
              fontSize: 13,
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiaryLight,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _externalNameCtrl,
                  decoration: InputDecoration(
                    hintText: l.t('member_name_hint'),
                    hintStyle: GoogleFonts.sarabun(fontSize: 13),
                  ),
                  onSubmitted: (_) => _addExternal(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _addingExternal ? null : _addExternal,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  backgroundColor: AppColors.emerald,
                ),
                child: _addingExternal
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                     : Text(
                        l.t('common_add'),
                        style: GoogleFonts.sarabun(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
              ),
            ],
          ),
          if (_externalError != null) ...[
            const SizedBox(height: 6),
            Text(
              _externalError!,
              style: GoogleFonts.sarabun(
                  fontSize: 12, color: AppColors.red),
            ),
          ],
          if (_externalSuccess != null) ...[
            const SizedBox(height: 6),
            Text(
              _externalSuccess!,
              style: GoogleFonts.sarabun(
                  fontSize: 12, color: AppColors.emerald),
            ),
          ],
        ],
      ),
    );
  }
}
