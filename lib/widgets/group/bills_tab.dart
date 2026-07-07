import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kidtang_flutter/models/models.dart';
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
                    'สร้างบิลใหม่',
                    style: GoogleFonts.notoSansThai(
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
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(AppRadii.lg),
                      border: Border.all(
                        color: isDark
                            ? AppColors.borderDark
                            : const Color(0xFFE5E7EB),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
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
                                'สร้างบิลแรกของกลุ่ม',
                                style: GoogleFonts.notoSansThai(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimaryLight,
                                ),
                              ),
                              Text(
                                'แตะเพื่อเริ่มหารค่าใช้จ่าย',
                                style: GoogleFonts.notoSansThai(
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
                              color: Colors.white, size: 18),
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
            ),
          ),
        );
      },
    );
  }
}
