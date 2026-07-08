import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kidtang_flutter/models/models.dart';
import 'package:kidtang_flutter/providers/locale_provider.dart';
import 'package:kidtang_flutter/stores/bills_store.dart';
import 'package:kidtang_flutter/stores/friends_store.dart';
import 'package:kidtang_flutter/stores/groups_store.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';
import 'package:kidtang_flutter/utils/bill_utils.dart';
import 'package:kidtang_flutter/widgets/shared/member_avatar.dart';

/// Shared "Add Member" bottom sheet used by both bill and group contexts.
///
/// - **Bill context**: pass [bill] + [billsStore]. Friends tab adds the friend
///   directly to the bill; Outsider tab adds by name/promptpay/color.
/// - **Group context**: pass [group] + [groupsStore]. Friends tab adds the
///   friend directly as an accepted member; Outsider tab adds by name only
///   (color/promptpay are bill-specific and not stored on group_members).
class AddMemberSheet extends StatefulWidget {
  // Bill context
  final Bill? bill;
  final BillsStore? billsStore;

  // Group context
  final Group? group;
  final GroupsStore? groupsStore;
  /// Already-accepted group members — used to filter the friends list.
  final List<GroupMember>? existingGroupMembers;

  const AddMemberSheet({
    super.key,
    // Bill
    this.bill,
    this.billsStore,
    // Group
    this.group,
    this.groupsStore,
    this.existingGroupMembers,
  }) : assert(
          (bill != null && billsStore != null) ||
              (group != null && groupsStore != null),
          'Either bill+billsStore or group+groupsStore must be provided',
        );

  @override
  State<AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends State<AddMemberSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  // Outsider tab state
  final _nameCtrl = TextEditingController();
  final _promptpayCtrl = TextEditingController();
  String _color = '#4366F4';
  bool _loadingOutsider = false;
  String? _outsiderError;
  String? _outsiderSuccess;

  // Friends tab state
  bool _loadingFriend = false;
  String? _friendError;

  static const _colorOptions = [
    '#4366F4', '#10B981', '#F59E0B', '#EF4444',
    '#8B5CF6', '#EC4899', '#06B6D4', '#84CC16',
  ];

  bool get _isBillContext => widget.bill != null;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _nameCtrl.dispose();
    _promptpayCtrl.dispose();
    super.dispose();
  }

  // ── Friends tab actions ──────────────────────────────────────

  Future<void> _addFriend(Profile profile) async {
    setState(() {
      _loadingFriend = true;
      _friendError = null;
    });
    final nav = Navigator.of(context);
    try {
      if (_isBillContext) {
        await widget.billsStore!.addMemberFromGroupMember(
          widget.bill!.id,
          userId: profile.id,
          name: profile.displayName ?? profile.username ?? profile.id,
          color: _color,
        );
      } else {
        final err = await widget.groupsStore!.addDirectMember(
          widget.group!.id,
          profile.id,
          profile.displayName ?? profile.username ?? profile.id,
        );
        if (err != null) {
          if (mounted) setState(() { _loadingFriend = false; _friendError = err; });
          return;
        }
      }
      if (!mounted) return;
      nav.pop();
    } catch (e) {
      if (mounted) setState(() { _loadingFriend = false; _friendError = 'เกิดข้อผิดพลาด กรุณาลองใหม่'; });
    }
  }

  // ── Outsider tab actions ─────────────────────────────────────

  Future<void> _addOutsider() async {
    final l = context.read<LocaleProvider>();
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final promptpay = _promptpayCtrl.text.trim().isEmpty
        ? null
        : _promptpayCtrl.text.trim();

    setState(() {
      _loadingOutsider = true;
      _outsiderError = null;
      _outsiderSuccess = null;
    });

    try {
      if (_isBillContext) {
        await widget.billsStore!.addMember(
          widget.bill!.id,
          name: name,
          color: _color,
          promptpay: promptpay,
        );
        if (mounted) Navigator.pop(context);
      } else {
        final err = await widget.groupsStore!.addExternalMember(
          widget.group!.id,
          name,
        );
        if (!mounted) return;
        setState(() {
          _loadingOutsider = false;
          if (err != null) {
            _outsiderError = err;
          } else {
            _outsiderSuccess = l.t('group_external_added').replaceAll('{name}', name);
            _nameCtrl.clear();
            _promptpayCtrl.clear();
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() { _loadingOutsider = false; _outsiderError = 'เกิดข้อผิดพลาด กรุณาลองใหม่'; });
    }
  }

  // ── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = context.watch<LocaleProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';

    // Build the set of user IDs already in the bill/group to filter friends
    final Set<String> existingUserIds;
    if (_isBillContext) {
      existingUserIds = widget.bill!.members
          .map((m) => m.userId)
          .whereType<String>()
          .toSet();
    } else {
      existingUserIds = (widget.existingGroupMembers ?? [])
          .where((m) => m.userId != null)
          .map((m) => m.userId!)
          .toSet();
    }

    // Friends not yet in the bill/group
    final friendsStore = context.read<FriendsStore>();
    final availableFriends = friendsStore.friends
        .where((f) {
          final p = f.otherProfile(currentUserId);
          return p != null && !existingUserIds.contains(p.id);
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
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Text(
              l.t('add_member_title'),
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
                color: isDark ? AppColors.borderDark : Colors.white,
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
                Tab(text: l.t('add_member_tab_friends')),
                Tab(text: l.t('add_member_tab_outsider')),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildFriendsTab(isDark, availableFriends, l),
                _buildOutsiderTab(isDark, l),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Friends tab ──────────────────────────────────────────────

  Widget _buildFriendsTab(
      bool isDark, List<Profile> available, LocaleProvider l) {
    if (available.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            l.t('add_member_no_friends'),
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

    return Column(
      children: [
        if (_friendError != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Text(
              _friendError!,
              style: GoogleFonts.sarabun(
                  fontSize: 12, color: AppColors.red),
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            itemCount: available.length,
            itemBuilder: (ctx, i) {
              final profile = available[i];
              final name = profile.displayName ??
                  profile.username ??
                  l.t('friends_fallback_name');

              return GestureDetector(
                onTap: _loadingFriend ? null : () => _addFriend(profile),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfaceDark
                        : AppColors.neutral50,
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
                      if (_loadingFriend)
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
          ),
        ),
      ],
    );
  }

  // ── Outsider tab ─────────────────────────────────────────────

  Widget _buildOutsiderTab(bool isDark, LocaleProvider l) {
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
            l.t('add_member_outsider_desc'),
            style: GoogleFonts.sarabun(
              fontSize: 13,
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiaryLight,
            ),
          ),
          const SizedBox(height: 16),
          // Name field
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              hintText: l.t('member_form_name_hint'),
              hintStyle: GoogleFonts.sarabun(fontSize: 13),
            ),
          ),
          const SizedBox(height: 12),
          // PromptPay field
          TextField(
            controller: _promptpayCtrl,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: l.t('member_form_promptpay_hint'),
              hintStyle: GoogleFonts.sarabun(fontSize: 13),
            ),
          ),
          const SizedBox(height: 16),
          // Color picker
          Text(
            l.t('member_form_color_label'),
            style: GoogleFonts.sarabun(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            children: _colorOptions.map((c) {
              final isSelected = _color == c;
              return GestureDetector(
                onTap: () => setState(() => _color = c),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colorFromHex(c),
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(
                            color:
                                isDark ? Colors.white : Colors.black87,
                            width: 2.5)
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check_rounded,
                          color: AppColors.surface, size: 16)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          // Error / success messages
          if (_outsiderError != null) ...[
            Text(
              _outsiderError!,
              style: GoogleFonts.sarabun(
                  fontSize: 12, color: AppColors.red),
            ),
            const SizedBox(height: 8),
          ],
          if (_outsiderSuccess != null) ...[
            Text(
              _outsiderSuccess!,
              style: GoogleFonts.sarabun(
                  fontSize: 12, color: AppColors.emerald),
            ),
            const SizedBox(height: 8),
          ],
          ElevatedButton(
            onPressed: _loadingOutsider ? null : _addOutsider,
            child: _loadingOutsider
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    l.t('member_form_add_btn'),
                    style: GoogleFonts.sarabun(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
          ),
        ],
      ),
    );
  }
}
