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

  @override
  Widget build(BuildContext context) {
      final l = context.watch<LocaleProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = bill.items;
    final members = bill.members;
    final currency = bill.settings.currency;

    // Index 0 = summary card, 1..n = item tiles, last = add button (if not readOnly)
    final extraCount = readOnly ? 0 : 1;
    final itemCount = 1 + items.length + extraCount;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: itemCount,
      itemBuilder: (ctx, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: BillSummaryCard(calc: calc, currency: currency),
          );
        }
        final itemIndex = index - 1;
        if (itemIndex < items.length) {
          return RepaintBoundary(
            child: ItemTile(
              key: ValueKey(items[itemIndex].id),
              item: items[itemIndex],
              members: members,
              bill: bill,
              billsStore: billsStore,
              readOnly: readOnly,
            ),
          );
        }
        // Add item button
        return Padding(
          padding: const EdgeInsets.only(top: 4),
          child: OutlinedButton.icon(
            onPressed: () => showDialog(
              context: context,
              barrierDismissible: true,
              builder: (ctx) => Dialog(
                backgroundColor: Colors.transparent,
                insetPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: ItemFormSheet(
                  bill: bill,
                  billsStore: billsStore,
                  members: members,
                ),
              ),
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(
              l.t('items_tab_add'),
              style: GoogleFonts.notoSansThai(fontSize: 14),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        );
      },
    );
  }
}
