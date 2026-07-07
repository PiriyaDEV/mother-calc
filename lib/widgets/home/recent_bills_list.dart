import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../stores/bills_store.dart';
import '../../widgets/shared_bill_card.dart';

class RecentBillsList extends StatelessWidget {
  const RecentBillsList({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<BillsStore, List<Bill>>(
      selector: (_, s) => s.all,
      builder: (context, allBills, _) {
        final recentBills = ([...allBills]
              ..sort((a, b) {
                final aTime = a.updatedAt ?? DateTime(0);
                final bTime = b.updatedAt ?? DateTime(0);
                return bTime.compareTo(aTime);
              }))
            .take(3)
            .toList();
        if (recentBills.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final bill = recentBills[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SharedBillCard(
                    bill: bill,
                    onTap: () => context.push('/bills/${bill.id}'),
                  ),
                );
              },
              childCount: recentBills.length,
            ),
          ),
        );
      },
    );
  }
}
