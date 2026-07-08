import 'package:provider/provider.dart';
import 'package:kidtang_flutter/providers/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kidtang_flutter/models/models.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';
import 'package:kidtang_flutter/utils/bill_utils.dart';
import 'package:kidtang_flutter/widgets/shared/member_avatar.dart';

class SharedBillCard extends StatelessWidget {
  final Bill bill;
  final VoidCallback onTap;

  const SharedBillCard({super.key, required this.bill, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l = context.watch<LocaleProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = bill.total;
    final isCompleted = bill.isCompleted;
    final isPending = bill.isPendingPayment;

    return Material(
      color: isDark ? AppColors.surfaceDark : Colors.white,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.neutral100,
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: const Color(0xFF2D5BFF).withValues(alpha: 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Row(
            children: [
              // ── Emoji icon ──────────────────────────────────────
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.accentIceDark : AppColors.accentIce,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Center(
                  child: Text(
                    bill.emoji ?? '🧾',
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // ── Title + meta ────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bill.title,
                      style: GoogleFonts.notoSansThai(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.neutral900Dark
                            : AppColors.neutral900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Date
                        Text(
                          formatDate(bill.updatedAt ?? bill.createdAt),
                          style: GoogleFonts.notoSansThai(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.neutral400Dark
                                : AppColors.neutral400,
                          ),
                        ),
                        // Member count
                        if (bill.members.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.neutral400Dark
                                  : AppColors.neutral400,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          MemberAvatarStack(
                            members: bill.members
                                .take(3)
                                .map((m) => (
                                      name: m.name,
                                      color: colorFromHex(m.color),
                                      avatarUrl: m.profile?.avatarUrl,
                                    ))
                                .toList(),
                            size: 18,
                            maxVisible: 3,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            l.t('unit_people').replaceFirst('{count}', '${bill.members.length}'),
                            style: GoogleFonts.notoSansThai(
                              fontSize: 11,
                              color: isDark
                                  ? AppColors.neutral400Dark
                                  : AppColors.neutral400,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // ── Amount + status ─────────────────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatCurrency(total, bill.settings.currency),
                    style: GoogleFonts.anuphan(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.neutral900Dark
                          : AppColors.neutral900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _StatusBadge(
                    isCompleted: isCompleted,
                    isPending: isPending,
                    completedLabel: l.t('bill_status_completed'),
                    pendingLabel: l.t('bill_status_pending'),
                    draftLabel: l.t('bill_status_draft'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Status badge — 3 states ──────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final bool isCompleted;
  final bool isPending;
  final String completedLabel;
  final String pendingLabel;
  final String draftLabel;

  const _StatusBadge({
    required this.isCompleted,
    required this.isPending,
    required this.completedLabel,
    required this.pendingLabel,
    required this.draftLabel,
  });

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    final Color dotColor;
    final Color textColor;
    final String label;

    if (isCompleted) {
      bgColor = AppColors.emeraldLight;
      dotColor = AppColors.emerald;
      textColor = AppColors.emeraldText;
      label = completedLabel;
    } else if (isPending) {
      bgColor = AppColors.accentSky.withValues(alpha: 0.15);
      dotColor = AppColors.accentSky;
      textColor = AppColors.accentSky;
      label = pendingLabel;
    } else {
      bgColor = AppColors.amberLight;
      dotColor = AppColors.amber;
      textColor = AppColors.amberText;
      label = draftLabel;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadii.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.notoSansThai(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
