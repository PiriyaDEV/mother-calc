/// Server-side aggregate over every bill the current user can see —
/// returned by the `get_bill_aggregate_stats` RPC. Lets the home screen and
/// bills list show accurate totals/tab counts while only ever fetching a
/// page of bills at a time (see [BillsRepository.fetchPage]).
class BillAggregateStats {
  final int totalCount;
  final int draftCount;
  final int pendingPaymentCount;
  final int completedCount;
  final double grandTotal;
  final int totalItems;
  final String? biggestBillId;
  final String? biggestBillTitle;
  final String? biggestBillEmoji;
  final double biggestBillTotal;

  const BillAggregateStats({
    this.totalCount = 0,
    this.draftCount = 0,
    this.pendingPaymentCount = 0,
    this.completedCount = 0,
    this.grandTotal = 0,
    this.totalItems = 0,
    this.biggestBillId,
    this.biggestBillTitle,
    this.biggestBillEmoji,
    this.biggestBillTotal = 0,
  });

  factory BillAggregateStats.fromJson(Map<String, dynamic> json) {
    return BillAggregateStats(
      totalCount: (json['total_count'] as num?)?.toInt() ?? 0,
      draftCount: (json['draft_count'] as num?)?.toInt() ?? 0,
      pendingPaymentCount: (json['pending_payment_count'] as num?)?.toInt() ?? 0,
      completedCount: (json['completed_count'] as num?)?.toInt() ?? 0,
      grandTotal: (json['grand_total'] as num?)?.toDouble() ?? 0,
      totalItems: (json['total_items'] as num?)?.toInt() ?? 0,
      biggestBillId: json['biggest_bill_id'] as String?,
      biggestBillTitle: json['biggest_bill_title'] as String?,
      biggestBillEmoji: json['biggest_bill_emoji'] as String?,
      biggestBillTotal: (json['biggest_bill_total'] as num?)?.toDouble() ?? 0,
    );
  }
}
