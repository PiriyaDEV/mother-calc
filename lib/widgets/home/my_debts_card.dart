import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kidtang_flutter/providers/locale_provider.dart';
import 'package:kidtang_flutter/stores/bills_store.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';
import 'package:kidtang_flutter/utils/bill_utils.dart';

/// Aggregated debt row: how much the current user owes to one creditor.
class _DebtRow {
  final String creditorName;
  final String billId;
  final String billTitle;
  final String billEmoji;
  final double amount;
  final String currency;

  const _DebtRow({
    required this.creditorName,
    required this.billId,
    required this.billTitle,
    required this.billEmoji,
    required this.amount,
    required this.currency,
  });
}

/// Shows a summary of all unpaid debts the current user owes across all
/// pending_payment bills that are loaded in [BillsStore].
class MyDebtsCard extends StatelessWidget {
  const MyDebtsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.watch<LocaleProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    // Collect all pending_payment bills from the store
    final billsStore = context.watch<BillsStore>();
    final pendingBills = billsStore.viewFor('pending_payment').items;

    if (currentUserId == null || pendingBills.isEmpty) {
      return const SizedBox.shrink();
    }

    // Compute debts: for each pending bill, run calculateBill and find
    // DebtTransactions where the current user is the debtor (from).
    final debts = <_DebtRow>[];
    for (final bill in pendingBills) {
      // Find the BillMember that corresponds to the current user
      final myMember = bill.members.where((m) => m.userId == currentUserId).firstOrNull;
      if (myMember == null) continue;
      // Skip if already marked paid
      if (bill.paidMemberIds.contains(myMember.id)) continue;

      final calc = calculateBill(bill);
      final transactions = simplifyDebts(calc.memberSummaries, bill.members, null);
      for (final tx in transactions) {
        if (tx.from.id == myMember.id && tx.amount > 0.005) {
          debts.add(_DebtRow(
            creditorName: tx.to.name,
            billId: bill.id,
            billTitle: bill.title,
            billEmoji: bill.emoji ?? '🧾',
            amount: tx.amount,
            currency: bill.settings.currency,
          ));
        }
      }
    }

    if (debts.isEmpty) return const SizedBox.shrink();

    // Group by creditor name + currency for a compact summary
    final Map<String, double> totalByCurrency = {};
    for (final d in debts) {
      final key = d.currency;
      totalByCurrency[key] = (totalByCurrency[key] ?? 0) + d.amount;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        0,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          boxShadow: isDark ? null : const [AppShadows.card],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: AppColors.amberFaint,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 16,
                      color: AppColors.amber,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.t('home_my_debts_title'),
                          style: GoogleFonts.sarabun(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.neutral900Dark
                                : AppColors.neutral900,
                          ),
                        ),
                        Text(
                          l.t('home_my_debts_subtitle')
                              .replaceFirst('{count}', '${debts.length}'),
                          style: GoogleFonts.sarabun(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Total summary badge
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: totalByCurrency.entries.map((e) {
                      return Text(
                        formatCurrency(e.value, e.key),
                        style: GoogleFonts.sarabun(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.amber,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            // ── Divider ──────────────────────────────────────────
            Divider(
              height: 1,
              thickness: 1,
              color: isDark
                  ? AppColors.borderDark
                  : AppColors.borderLight,
            ),

            // ── Debt rows ────────────────────────────────────────
            ...debts.map((d) => _DebtRowTile(
                  debt: d,
                  isDark: isDark,
                  onTap: () => context.push('/bills/${d.billId}'),
                )),
          ],
        ),
      ),
    );
  }
}

class _DebtRowTile extends StatelessWidget {
  final _DebtRow debt;
  final bool isDark;
  final VoidCallback onTap;

  const _DebtRowTile({
    required this.debt,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.watch<LocaleProvider>();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        child: Row(
          children: [
            // Bill emoji
            Text(debt.billEmoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: AppSpacing.sm),
            // Bill + creditor info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    debt.billTitle,
                    style: GoogleFonts.sarabun(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    l.t('home_my_debts_owe_to')
                        .replaceFirst('{name}', debt.creditorName),
                    style: GoogleFonts.sarabun(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                    ),
                  ),
                ],
              ),
            ),
            // Amount
            Text(
              formatCurrency(debt.amount, debt.currency),
              style: GoogleFonts.sarabun(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.amber
                    : AppColors.amberText,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiaryLight,
            ),
          ],
        ),
      ),
    );
  }
}
