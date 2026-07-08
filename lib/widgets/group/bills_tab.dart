import 'package:provider/provider.dart';
import 'package:kidtang_flutter/providers/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kidtang_flutter/models/models.dart';
import 'package:kidtang_flutter/stores/friends_store.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';
import 'package:kidtang_flutter/widgets/shared/shared_bill_card.dart';

class GroupBillsTab extends StatelessWidget {
  final Group group;
  final List<Bill> bills;
  final bool isDark;

  const GroupBillsTab({
    super.key,
    required this.group,
    required this.bills,
    required this.isDark,
  });

  void _createBill(BuildContext context) {
    context.push('/bills/create?groupId=${group.id}');
  }

  // Layout: index 0 is the "สร้างบิลใหม่" button + empty state (if no
  // bills), indices 1..N are the bill rows — built lazily via
  // ListView.builder so an unbounded bills list doesn't build off-screen
  // rows up front.
  @override
  Widget build(BuildContext context) {
    final l = context.watch<LocaleProvider>();
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final friendUserIds = context
        .read<FriendsStore>()
        .friends
        .map((f) =>
            f.requesterId == currentUserId ? f.addresseeId : f.requesterId)
        .toSet();
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: 1 + bills.length,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _createBill(context),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(
                    l.t('group_bills_create_new'),
                    style: GoogleFonts.sarabun(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Empty State ──
              if (bills.isEmpty)
                GestureDetector(
                  onTap: () => _createBill(context),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadii.lg),
                      border: Border.all(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius:
                                BorderRadius.circular(AppRadii.md),
                          ),
                          child: const Icon(Icons.receipt_outlined,
                              color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l.t('group_bills_create_first'),
                                style: GoogleFonts.sarabun(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimaryLight,
                                ),
                              ),
                              Text(
                                l.t('group_bills_start'),
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
                        Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.all(
                                Radius.circular(AppRadii.sm)),
                          ),
                          child: const Icon(Icons.add_rounded,
                              color: AppColors.surface, size: 18),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        }

        final bill = bills[index - 1];
        return RepaintBoundary(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SharedBillCard(
              bill: bill,
              onTap: () => context.push('/bills/${bill.id}'),
              currentUserId: currentUserId,
              friendUserIds: friendUserIds,
            ),
          ),
        );
      },
    );
  }
}
