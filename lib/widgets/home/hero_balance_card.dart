import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../stores/bills_store.dart';
import '../../stores/groups_store.dart';
import '../../theme/app_theme.dart';
import '../../utils/bill_utils.dart';

double _billTotal(Bill b) => b.items.fold(0.0, (s, i) => s + i.price);

class HeroBalanceCard extends StatelessWidget {
  const HeroBalanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector2<BillsStore, GroupsStore, (List<Bill>, int, bool)>(
      selector: (_, billsStore, groupsStore) => (
        billsStore.all,
        groupsStore.groups.length,
        (billsStore.loading && !billsStore.hasLoaded) ||
            (groupsStore.loading && !groupsStore.hasLoaded),
      ),
      builder: (context, data, _) {
        final (allBills, groupsCount, dataLoading) = data;
        final grandTotal =
            allBills.fold<double>(0, (s, b) => s + _billTotal(b));
        final totalItems =
            allBills.fold<int>(0, (s, b) => s + b.items.length);

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF2D5BFF),
                  Color(0xFF1A3FCC),
                  Color(0xFF0B1E3D)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [0.0, 0.55, 1.0],
              ),
              borderRadius: BorderRadius.circular(AppRadii.lg),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2D5BFF).withValues(alpha: 0.40),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Decorative circles
                Positioned(
                  right: -24,
                  top: -32,
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                ),
                Positioned(
                  right: 30,
                  bottom: -50,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.04),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ยอดรวมทั้งหมด',
                      style: GoogleFonts.notoSansThai(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.65),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (dataLoading)
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    else
                      Text(
                        '฿${formatNumber(grandTotal)}',
                        style: GoogleFonts.anuphan(
                          fontSize: 38,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -1,
                          height: 1.1,
                        ),
                      ),
                    const SizedBox(height: 20),
                    if (!dataLoading)
                      Row(
                        children: [
                          HeroPill(
                            label: '$groupsCount กลุ่ม',
                            icon: Icons.people_rounded,
                          ),
                          const SizedBox(width: 8),
                          HeroPill(
                            label: '${allBills.length} บิล',
                            icon: Icons.receipt_rounded,
                          ),
                          const SizedBox(width: 8),
                          HeroPill(
                            label: '$totalItems รายการ',
                            icon: Icons.list_rounded,
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class HeroPill extends StatelessWidget {
  final String label;
  final IconData icon;

  const HeroPill({super.key, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadii.full),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.9)),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.notoSansThai(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}
