import 'package:provider/provider.dart';
import 'package:kidtang_flutter/providers/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kidtang_flutter/models/models.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';
import 'package:kidtang_flutter/utils/bill_utils.dart';
import 'package:kidtang_flutter/widgets/shared/emoji_text.dart';

class HeroCard extends StatelessWidget {
  final BillCalculation calc;
  final Bill bill;
  final int paidCount;
  final bool allPaid;
  final bool isCompleted;

  const HeroCard({
    super.key,
    required this.calc,
    required this.bill,
    required this.paidCount,
    required this.allPaid,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
      final l = context.watch<LocaleProvider>();
    final settings = bill.settings;
    final memberCount = bill.members.isNotEmpty ? bill.members.length : 1;
    final emoji = getTotalEmoji(calc.total);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.t('hero_grand_total'),
            style: GoogleFonts.sarabun(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  '${formatNumber(calc.total)} ${settings.currency}',
                  style: GoogleFonts.sarabun(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.surface,
                  ),
                ),
              ),
              EmojiText(emoji, fontSize: 28),
            ],
          ),
          if (settings.isService) ...[
            const SizedBox(height: 4),
            Text(
              l.t('hero_service_charge').replaceAll('{pct}', settings.serviceCharge.toStringAsFixed(0)),
              style: GoogleFonts.sarabun(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
          if (settings.isVat) ...[
            const SizedBox(height: 2),
            Text(
              l.t('hero_vat').replaceAll('{pct}', settings.vat.toStringAsFixed(0)),
              style: GoogleFonts.sarabun(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
          if (isCompleted) ...[
            const SizedBox(height: 14),
            Divider(color: Colors.white.withValues(alpha: 0.3), height: 1),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l.t('summary_payment_status'),
                  style: GoogleFonts.sarabun(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                Text(
                  '$paidCount/$memberCount คน',
                  style: GoogleFonts.sarabun(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.surface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.xs),
              child: LinearProgressIndicator(
                value: memberCount > 0 ? paidCount / memberCount : 0,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 6,
              ),
            ),
            if (allPaid) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.surface, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    l.t('summary_all_paid'),
                    style: GoogleFonts.sarabun(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.surface,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}
