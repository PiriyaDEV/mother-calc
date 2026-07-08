import 'package:provider/provider.dart';
import 'package:kidtang_flutter/providers/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kidtang_flutter/models/models.dart';
import 'package:kidtang_flutter/stores/bills_store.dart';
import 'package:kidtang_flutter/utils/bill_utils.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';
import 'package:kidtang_flutter/widgets/shared/member_avatar.dart';
import 'stacked_avatars.dart';
import 'item_form_sheet.dart';

class ItemTile extends StatelessWidget {
  final BillItem item;
  final List<BillMember> members;
  final Bill bill;
  final BillsStore billsStore;
  final bool readOnly;

  const ItemTile({
    super.key,
    required this.item,
    required this.members,
    required this.bill,
    required this.billsStore,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
      final l = context.watch<LocaleProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final assignedMembers = members
        .where((m) =>
            item.splitWeights.containsKey(m.id) &&
            item.splitWeights[m.id]! > 0)
        .toList();
    final paidByMember = item.paidBy != null
        ? members.where((m) => m.id == item.paidBy).firstOrNull
        : null;

    return RepaintBoundary(
      child: GestureDetector(
        onTap: readOnly ? null : () => _showEditItemSheet(context),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      style: GoogleFonts.sarabun(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                  ),
                  if (item.isUnequalSplit) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                      ),
                      child: Text(
                        l.t('item_tile_unequal'),
                        style: GoogleFonts.sarabun(
                          fontSize: 10,
                          color: AppColors.amber,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    formatNumber(item.price),
                    style: GoogleFonts.sarabun(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  if (!readOnly) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                    ),
                  ],
                ],
              ),
              if (assignedMembers.isNotEmpty || paidByMember != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    StackedAvatars(members: assignedMembers),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${assignedMembers.length} คน'
                        '${!item.isUnequalSplit && assignedMembers.isNotEmpty ? ' · ฿${formatNumber(item.price / assignedMembers.length)}/คน' : ''}',
                        style: GoogleFonts.sarabun(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textTertiaryLight,
                        ),
                      ),
                    ),
                    if (paidByMember != null) ...[
                      Text(
                        l.t('item_tile_paid_by'),
                        style: GoogleFonts.sarabun(
                          fontSize: 10,
                          color: isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textTertiaryLight,
                        ),
                      ),
                      const SizedBox(width: 4),
                      MemberAvatar(
                        name: paidByMember.name,
                        color: colorFromHex(paidByMember.color),
                        size: 20,
                        avatarUrl: paidByMember.profile?.avatarUrl,
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showEditItemSheet(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ItemFormSheet(
          bill: bill,
          billsStore: billsStore,
          members: members,
          editItem: item,
        ),
      ),
    );
  }
}
