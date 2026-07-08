import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kidtang_flutter/models/models.dart';
import 'package:kidtang_flutter/stores/bills_store.dart';
import 'package:kidtang_flutter/stores/friends_store.dart';
import 'package:kidtang_flutter/widgets/shared/shared_bill_card.dart';

class RecentBillsList extends StatelessWidget {
  const RecentBillsList({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final friendUserIds = context
        .read<FriendsStore>()
        .friends
        .map((f) =>
            f.requesterId == currentUserId ? f.addresseeId : f.requesterId)
        .toSet();

    return Selector<BillsStore, List<Bill>>(
      selector: (_, s) => s.recentBills,
      builder: (context, recentBills, _) {
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
                    currentUserId: currentUserId,
                    friendUserIds: friendUserIds,
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
