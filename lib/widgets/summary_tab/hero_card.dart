import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../utils/bill_utils.dart';

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
    final settings = bill.settings;
    final memberCount = bill.members.isNotEmpty ? bill.members.length : 1;
    final emoji = getTotalEmoji(calc.total);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.blue400, AppColors.blue500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ยอดรวมทั้งสิ้น',
            style: GoogleFonts.notoSansThai(
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
                  style: GoogleFonts.notoSansThai(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(emoji, style: const TextStyle(fontSize: 28)),
            ],
          ),
          if (settings.isService) ...[
            const SizedBox(height: 4),
            Text(
              'รวม Service Charge ${settings.serviceCharge.toStringAsFixed(0)}%',
              style: GoogleFonts.notoSansThai(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
          if (settings.isVat) ...[
            const SizedBox(height: 2),
            Text(
              'รวม VAT ${settings.vat.toStringAsFixed(0)}%',
              style: GoogleFonts.notoSansThai(
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
                  'สถานะการชำระ',
                  style: GoogleFonts.notoSansThai(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                Text(
                  '$paidCount/$memberCount คน',
                  style: GoogleFonts.notoSansThai(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
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
                      color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'ทุกคนจ่ายแล้ว!',
                    style: GoogleFonts.notoSansThai(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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
