import 'bill_member.dart';
import 'bill_item.dart';

class MemberItemShare {
  final BillItem item;
  final double amount;

  const MemberItemShare({required this.item, required this.amount});
}

class MemberSummary {
  final BillMember member;
  final double total;
  final List<MemberItemShare> items;

  const MemberSummary({
    required this.member,
    required this.total,
    required this.items,
  });
}

class BillCalculation {
  final double subtotal;
  final double serviceAmount;
  final double vatAmount;
  final double tipAmount;
  final double discountAmount;
  final double total;
  final List<MemberSummary> memberSummaries;

  const BillCalculation({
    required this.subtotal,
    required this.serviceAmount,
    required this.vatAmount,
    required this.tipAmount,
    required this.discountAmount,
    required this.total,
    required this.memberSummaries,
  });
}

class DebtTransaction {
  final BillMember from;
  final BillMember to;
  final double amount;

  const DebtTransaction({
    required this.from,
    required this.to,
    required this.amount,
  });
}
