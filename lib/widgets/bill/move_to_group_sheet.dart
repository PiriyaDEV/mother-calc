import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:kidtang_flutter/models/models.dart';
import 'package:kidtang_flutter/stores/bills_store.dart';
import 'package:kidtang_flutter/stores/groups_store.dart';
import 'package:kidtang_flutter/providers/locale_provider.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';
import 'package:kidtang_flutter/widgets/shared/app_bottom_sheet.dart';

/// Bottom sheet that lets the bill owner move a draft bill into one of their
/// groups (or detach it from its current group).
class MoveToGroupSheet extends StatefulWidget {
  const MoveToGroupSheet({super.key, required this.bill});

  final Bill bill;

  /// Convenience helper — opens the sheet and returns true if the move was
  /// performed successfully.
  static Future<bool> show(BuildContext context, {required Bill bill}) async {
    final result = await AppBottomSheet.showScrollable<bool>(
      context,
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      builder: (ctx, scrollController) => MoveToGroupSheet(bill: bill),
    );
    return result == true;
  }

  @override
  State<MoveToGroupSheet> createState() => _MoveToGroupSheetState();
}

class _MoveToGroupSheetState extends State<MoveToGroupSheet> {
  bool _loading = false;

  Future<void> _move(BuildContext context, Group group) async {
    final t = context.read<LocaleProvider>().t;
    final billsStore = context.read<BillsStore>();

    setState(() => _loading = true);
    try {
      await billsStore.moveBillToGroup(
        widget.bill.id,
        groupId: group.id,
        groupName: group.name,
        groupEmoji: group.emoji,
      );
      if (context.mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t('bill_move_to_group_success')),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t('common_error')),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _detach(BuildContext context) async {
    final t = context.read<LocaleProvider>().t;
    final billsStore = context.read<BillsStore>();

    setState(() => _loading = true);
    try {
      await billsStore.moveBillToGroup(
        widget.bill.id,
        groupId: null,
        groupName: null,
        groupEmoji: null,
      );
      if (context.mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t('bill_remove_from_group_success')),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t('common_error')),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = context.read<LocaleProvider>().t;
    final groups = context.watch<GroupsStore>().groups;
    final currentGroupId = widget.bill.groupId;

    return AbsorbPointer(
      absorbing: _loading,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              t('bill_move_to_group_title'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: ThemeColors.textPrimary(isDark),
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),

            // Warning banner
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(
                  color: AppColors.amber.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 16, color: AppColors.amber),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      t('bill_move_to_group_warning'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.amberText,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Empty state
            if (groups.isEmpty) ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: Column(
                    children: [
                      Icon(
                        Icons.group_off_outlined,
                        size: 48,
                        color: ThemeColors.textSecondary(isDark),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        t('bill_no_groups'),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: ThemeColors.textSecondary(isDark),
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          context.push('/groups/create');
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(t('group_create_title')),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // Group list
              ...groups.map((group) {
                final isSelected = group.id == currentGroupId;
                return _GroupTile(
                  group: group,
                  isSelected: isSelected,
                  isDark: isDark,
                  onTap: _loading ? null : () => _move(context, group),
                );
              }),

              // Detach option — only shown when bill is already in a group
              if (currentGroupId != null) ...[
                const Divider(height: AppSpacing.lg),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    child: const Icon(Icons.link_off_rounded,
                        color: AppColors.red, size: 20),
                  ),
                  title: Text(
                    t('bill_remove_from_group'),
                    style: const TextStyle(
                      color: AppColors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: _loading ? null : () => _detach(context),
                ),
              ],
            ],

            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: AppSpacing.md),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}

class _GroupTile extends StatelessWidget {
  const _GroupTile({
    required this.group,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  final Group group;
  final bool isSelected;
  final bool isDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final memberCount =
        group.members.where((m) => m.status == 'accepted').length;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xs / 2,
      ),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : ThemeColors.surface(isDark),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: isSelected
              ? Border.all(color: AppColors.primary, width: 1.5)
              : null,
        ),
        child: Center(
          child: Text(
            group.emoji ?? '👥',
            style: const TextStyle(fontSize: 22),
          ),
        ),
      ),
      title: Text(
        group.name,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? AppColors.primary
                  : ThemeColors.textPrimary(isDark),
            ),
      ),
      subtitle: Text(
        '$memberCount คน',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: ThemeColors.textSecondary(isDark),
            ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle_rounded,
              color: AppColors.primary, size: 22)
          : Icon(Icons.chevron_right_rounded,
              color: ThemeColors.textSecondary(isDark), size: 22),
      onTap: onTap,
    );
  }
}
