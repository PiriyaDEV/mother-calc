import 'package:provider/provider.dart';
import 'package:kidtang_flutter/providers/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kidtang_flutter/models/models.dart';
import 'package:kidtang_flutter/stores/bills_store.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';
import 'bill_summary_card.dart';
import 'item_form_sheet.dart';
import 'item_tile.dart';

class ItemsTab extends StatelessWidget {
  final Bill bill;
  final BillsStore billsStore;
  final BillCalculation calc;
  final bool readOnly;

  const ItemsTab({
    super.key,
    required this.bill,
    required this.billsStore,
    required this.calc,
    this.readOnly = false,
  });

  void _openAddItem(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ItemFormSheet(
          bill: bill,
          billsStore: billsStore,
          members: bill.members,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.watch<LocaleProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = bill.items;
    final currency = bill.settings.currency;

    return Stack(
      children: [
        // Scrollable list: add button (top) + item tiles
        ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          itemCount: (readOnly ? 0 : 1) + items.length,
          itemBuilder: (ctx, index) {
            // Add button at top (index 0) when not readOnly
            if (!readOnly && index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: OutlinedButton.icon(
                  onPressed: () => _openAddItem(context),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(
                    l.t('items_tab_add'),
                    style: GoogleFonts.sarabun(fontSize: 14),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.md)),
                  ),
                ),
              );
            }

            final itemIndex = readOnly ? index : index - 1;
            return RepaintBoundary(
              child: ItemTile(
                key: ValueKey(items[itemIndex].id),
                item: items[itemIndex],
                members: bill.members,
                bill: bill,
                billsStore: billsStore,
                readOnly: readOnly,
              ),
            );
          },
        ),

        // Sticky summary card at bottom
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            decoration: BoxDecoration(
              color: ThemeColors.bg(isDark),
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: BillSummaryCard(calc: calc, currency: currency),
          ),
        ),
      ],
    );
  }
}
