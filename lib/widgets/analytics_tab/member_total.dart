import '../../models/models.dart';

/// Simple data class carrying per-member analytics totals.
class MemberTotal {
  final BillMember member;
  final double total;
  final int itemCount;

  const MemberTotal({
    required this.member,
    required this.total,
    required this.itemCount,
  });
}
