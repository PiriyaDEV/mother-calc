import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kidtang_flutter/models/models.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';
import 'package:kidtang_flutter/utils/bill_utils.dart';

// ─── Full Bill Summary Image ──────────────────────────────────────────────────
// Shows: bill title, total, all members with their share, all debt transactions
class BillFullSummaryImage extends StatelessWidget {
  final Bill bill;
  final BillCalculation calc;
  final List<DebtTransaction> allDebts;

  const BillFullSummaryImage({
    super.key,
    required this.bill,
    required this.calc,
    required this.allDebts,
  });

  @override
  Widget build(BuildContext context) {
    final currency = bill.settings.currency;

    return Container(
      width: 360,
      color: AppColors.surface,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bill title
          Row(
            children: [
              Text(bill.emoji ?? '🧾', style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  bill.title,
                  style: GoogleFonts.sarabun(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'สรุปบิลทั้งหมด',
            style: GoogleFonts.sarabun(
              fontSize: 12,
              color: AppColors.textTertiaryLight,
            ),
          ),
          const SizedBox(height: 16),

          // Grand total
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ยอดรวมทั้งสิ้น',
                  style: GoogleFonts.sarabun(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  '${formatNumber(calc.total)} $currency',
                  style: GoogleFonts.sarabun(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Members section
          Text(
            'ส่วนแบ่งแต่ละคน',
            style: GoogleFonts.sarabun(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textTertiaryLight,
            ),
          ),
          const SizedBox(height: 8),
          ...calc.memberSummaries.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: colorFromHex(s.member.color),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s.member.name,
                        style: GoogleFonts.sarabun(
                          fontSize: 13,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                    ),
                    Text(
                      '${formatNumber(s.total)} $currency',
                      style: GoogleFonts.sarabun(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
              )),

          if (allDebts.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.borderLight),
            const SizedBox(height: 12),
            Text(
              'ใครโอนให้ใคร',
              style: GoogleFonts.sarabun(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textTertiaryLight,
              ),
            ),
            const SizedBox(height: 8),
            ...allDebts.map((d) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Text(
                        d.from.name,
                        style: GoogleFonts.sarabun(
                          fontSize: 13,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: AppColors.textTertiaryLight,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          d.to.name,
                          style: GoogleFonts.sarabun(
                            fontSize: 13,
                            color: AppColors.textPrimaryLight,
                          ),
                        ),
                      ),
                      Text(
                        '${formatNumber(d.amount)} $currency',
                        style: GoogleFonts.sarabun(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                    ],
                  ),
                )),
          ],

          const SizedBox(height: 20),
          _KidtangBranding(),
        ],
      ),
    );
  }
}

// ─── Member Summary Image ─────────────────────────────────────────────────────
// Shows: bill title, member name, items ordered, total, debts (no QR)
class BillMemberSummaryImage extends StatelessWidget {
  final Bill bill;
  final MemberSummary summary;
  final List<DebtTransaction> memberDebts;

  const BillMemberSummaryImage({
    super.key,
    required this.bill,
    required this.summary,
    required this.memberDebts,
  });

  @override
  Widget build(BuildContext context) {
    final currency = bill.settings.currency;
    final member = summary.member;

    return Container(
      width: 360,
      color: AppColors.surface,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bill title
          Row(
            children: [
              Text(bill.emoji ?? '🧾', style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  bill.title,
                  style: GoogleFonts.sarabun(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Member name
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: colorFromHex(member.color),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'สรุปของ ${member.name}',
                style: GoogleFonts.sarabun(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Items ordered
          if (summary.items.isNotEmpty) ...[
            Text(
              'รายการที่สั่ง',
              style: GoogleFonts.sarabun(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textTertiaryLight,
              ),
            ),
            const SizedBox(height: 6),
            ...summary.items.map((itemShare) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Text('• ',
                          style: TextStyle(color: AppColors.textTertiaryLight)),
                      Expanded(
                        child: Text(
                          itemShare.item.name,
                          style: GoogleFonts.sarabun(
                            fontSize: 13,
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ),
                      Text(
                        '${formatNumber(itemShare.amount)} $currency',
                        style: GoogleFonts.sarabun(
                          fontSize: 13,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 8),
            const Divider(height: 1, color: AppColors.borderLight),
            const SizedBox(height: 8),
          ],

          // Total
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'รวม (รวม VAT/SC)',
                  style: GoogleFonts.sarabun(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  '${formatNumber(summary.total)} $currency',
                  style: GoogleFonts.sarabun(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),

          // Debts
          if (memberDebts.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'ต้องโอนให้',
              style: GoogleFonts.sarabun(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textTertiaryLight,
              ),
            ),
            const SizedBox(height: 6),
            ...memberDebts.map((d) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.bgSubtle,
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.arrow_forward_rounded,
                            size: 14, color: AppColors.textTertiaryLight),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            d.to.name,
                            style: GoogleFonts.sarabun(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimaryLight,
                            ),
                          ),
                        ),
                        Text(
                          '${formatNumber(d.amount)} $currency',
                          style: GoogleFonts.sarabun(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
          ],

          const SizedBox(height: 20),
          _KidtangBranding(),
        ],
      ),
    );
  }
}

// ─── QR Card Image ────────────────────────────────────────────────────────────
// Shows: bill title, promptpay owner name, QR code, promptpay number
// Optional: fromName + amount (for per-member mode)
class BillQrCardImage extends StatelessWidget {
  final Bill bill;
  final BillMember toMember; // the one receiving money
  final double amount;
  final String? fromName; // null = full bill mode (just show "PromptPay ของ X")

  const BillQrCardImage({
    super.key,
    required this.bill,
    required this.toMember,
    required this.amount,
    this.fromName,
  });

  @override
  Widget build(BuildContext context) {
    final currency = bill.settings.currency;
    final promptpay = toMember.promptpay ?? '';
    // ignore: unused_local_variable — currency used in amount badge below

    return Container(
      width: 320,
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Bill title
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(bill.emoji ?? '🧾', style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  bill.title,
                  style: GoogleFonts.sarabun(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondaryLight,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // From → To label (per-member mode only)
          if (fromName != null)
            Text(
              '$fromName → ${toMember.name}',
              style: GoogleFonts.sarabun(
                fontSize: 12,
                color: AppColors.textTertiaryLight,
              ),
              textAlign: TextAlign.center,
            ),

          const SizedBox(height: 14),

          // QR Code
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: SizedBox(
              width: 200,
              height: 200,
              child: Image.network(
                '/promptpay-qr/$promptpay/${amount.toStringAsFixed(2)}.png',
                width: 200,
                height: 200,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                },
                errorBuilder: (context, error, stack) {
                  return const Center(
                    child: Icon(Icons.qr_code_rounded,
                        size: 80, color: Colors.grey),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Recipient name
          Text(
            'PromptPay ของ ${toMember.name}',
            style: GoogleFonts.sarabun(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            promptpay,
            style: GoogleFonts.sarabun(
              fontSize: 13,
              color: AppColors.textTertiaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Amount badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppRadii.xl),
            ),
            child: Text(
              '${formatNumber(amount)} $currency',
              style: GoogleFonts.sarabun(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),

          const SizedBox(height: 16),
          _KidtangBranding(),
        ],
      ),
    );
  }
}

// ─── Shared Branding Footer ───────────────────────────────────────────────────
class _KidtangBranding extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/logo.png', width: 18, height: 18),
            const SizedBox(width: 6),
            Text(
              'Kidtang',
              style: GoogleFonts.sarabun(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
