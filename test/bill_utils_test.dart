import 'package:flutter_test/flutter_test.dart';
import 'package:kidtang_flutter/utils/bill_utils.dart';
import 'package:kidtang_flutter/models/models.dart';

// Helper to build a Bill without repeating boilerplate
Bill makeBill({
  required List<BillMember> members,
  required List<BillItem> items,
  BillSettings settings = const BillSettings(),
}) =>
    Bill(
      id: 'bill1',
      title: 'Test',
      emoji: '🍜',
      status: 'draft',
      ownerId: 'owner1',
      settings: settings,
      members: members,
      items: items,
    );

BillMember makeMember(String id, String name) => BillMember(
      id: id,
      billId: 'bill1',
      name: name,
      color: '#10B981',
      isExternal: true,
    );

BillItem makeItem(String id, double price, Map<String, double> shares) =>
    BillItem(
      id: id,
      billId: 'bill1',
      name: 'Item $id',
      price: price,
      shares: shares,
    );

void main() {
  // ── formatNumber ──────────────────────────────────────────────
  group('formatNumber', () {
    test('whole number has no decimals', () {
      expect(formatNumber(100), '100');
      expect(formatNumber(1000), '1,000');
      expect(formatNumber(1234567), '1,234,567');
    });

    test('decimal number shows up to 2 decimal places', () {
      expect(formatNumber(99.5), '99.5');
      expect(formatNumber(99.99), '99.99');
      expect(formatNumber(1234.5), '1,234.5');
    });
  });

  // ── formatCurrency ────────────────────────────────────────────
  group('formatCurrency', () {
    test('appends currency symbol', () {
      expect(formatCurrency(100, 'THB'), '100 THB');
      expect(formatCurrency(1500.5, 'USD'), '1,500.5 USD');
    });
  });

  // ── getTotalEmoji ─────────────────────────────────────────────
  group('getTotalEmoji', () {
    test('returns correct emoji for ranges', () {
      expect(getTotalEmoji(50), '🍜');
      expect(getTotalEmoji(200), '🍱');
      expect(getTotalEmoji(400), '🍣');
      expect(getTotalEmoji(800), '🥩');
      expect(getTotalEmoji(1500), '🦞');
      expect(getTotalEmoji(3000), '🎉');
      expect(getTotalEmoji(10000), '💸');
    });
  });

  // ── isValidUsername ───────────────────────────────────────────
  group('isValidUsername', () {
    test('valid usernames pass', () {
      expect(isValidUsername('piriya'), isTrue);
      expect(isValidUsername('user_123'), isTrue);
      expect(isValidUsername('ABC'), isTrue);
    });

    test('invalid usernames fail', () {
      expect(isValidUsername('ab'), isFalse); // too short
      expect(isValidUsername('has space'), isFalse);
      expect(isValidUsername('has-dash'), isFalse);
      expect(isValidUsername(''), isFalse);
    });
  });

  // ── formatDate ────────────────────────────────────────────────
  group('formatDate', () {
    test('null returns empty string', () {
      expect(formatDate(null), '');
    });

    test('recent time returns relative string', () {
      final now = DateTime.now();
      expect(formatDate(now.subtract(const Duration(minutes: 2))), '2 นาทีที่แล้ว');
      expect(formatDate(now.subtract(const Duration(hours: 3))), '3 ชั่วโมงที่แล้ว');
      expect(formatDate(now.subtract(const Duration(days: 1))), 'เมื่อวาน');
      expect(formatDate(now.subtract(const Duration(days: 3))), '3 วันที่แล้ว');
    });
  });

  // ── calculateBill ─────────────────────────────────────────────
  group('calculateBill', () {
    test('simple equal split between 2 members', () {
      final bill = makeBill(
        members: [makeMember('a', 'Alice'), makeMember('b', 'Bob')],
        items: [makeItem('i1', 200, {'a': 1, 'b': 1})],
      );

      final calc = calculateBill(bill);
      expect(calc.subtotal, 200);
      expect(calc.total, 200);
      expect(calc.memberSummaries.length, 2);
      expect(calc.memberSummaries[0].total, closeTo(100, 0.01));
      expect(calc.memberSummaries[1].total, closeTo(100, 0.01));
    });

    test('VAT is applied correctly', () {
      final bill = makeBill(
        members: [makeMember('a', 'Alice')],
        items: [makeItem('i1', 100, {'a': 1})],
        settings: const BillSettings(vat: 7),
      );

      final calc = calculateBill(bill);
      expect(calc.vatAmount, closeTo(7, 0.01));
      expect(calc.total, closeTo(107, 0.01));
      expect(calc.memberSummaries[0].total, closeTo(107, 0.01));
    });

    test('service charge + VAT stacked correctly', () {
      final bill = makeBill(
        members: [makeMember('a', 'Alice')],
        items: [makeItem('i1', 100, {'a': 1})],
        settings: const BillSettings(serviceCharge: 10, vat: 7),
      );

      final calc = calculateBill(bill);
      // service = 10, vatBase = 110, vat = 7.7
      expect(calc.serviceAmount, closeTo(10, 0.01));
      expect(calc.vatAmount, closeTo(7.7, 0.01));
      expect(calc.total, closeTo(117.7, 0.01));
    });

    test('discount reduces total', () {
      final bill = makeBill(
        members: [makeMember('a', 'Alice')],
        items: [makeItem('i1', 200, {'a': 1})],
        settings: const BillSettings(discount: 50),
      );

      final calc = calculateBill(bill);
      expect(calc.total, closeTo(150, 0.01));
    });

    test('tip is added to total', () {
      final bill = makeBill(
        members: [makeMember('a', 'Alice')],
        items: [makeItem('i1', 100, {'a': 1})],
        settings: const BillSettings(tip: 20),
      );

      final calc = calculateBill(bill);
      expect(calc.total, closeTo(120, 0.01));
    });

    test('unequal weight split 3:1', () {
      final bill = makeBill(
        members: [makeMember('a', 'Alice'), makeMember('b', 'Bob')],
        items: [makeItem('i1', 100, {'a': 3, 'b': 1})],
      );

      final calc = calculateBill(bill);
      final aTotal = calc.memberSummaries.firstWhere((s) => s.member.id == 'a').total;
      final bTotal = calc.memberSummaries.firstWhere((s) => s.member.id == 'b').total;
      expect(aTotal, closeTo(75, 0.01));
      expect(bTotal, closeTo(25, 0.01));
    });

    test('member with no items has zero total', () {
      final bill = makeBill(
        members: [makeMember('a', 'Alice'), makeMember('b', 'Bob')],
        // Only Alice is in the item
        items: [makeItem('i1', 100, {'a': 1})],
      );

      final calc = calculateBill(bill);
      final bTotal = calc.memberSummaries.firstWhere((s) => s.member.id == 'b').total;
      expect(bTotal, closeTo(0, 0.01));
    });

    test('empty bill has zero totals', () {
      final bill = makeBill(members: [], items: []);
      final calc = calculateBill(bill);
      expect(calc.subtotal, 0);
      expect(calc.total, 0);
      expect(calc.memberSummaries, isEmpty);
    });
  });

  // ── generatePromptPayPayload ──────────────────────────────────
  group('generatePromptPayPayload', () {
    test('generates non-empty payload for phone number', () {
      final payload = generatePromptPayPayload('0812345678', 100);
      expect(payload, isNotEmpty);
      expect(payload.length, greaterThan(20));
    });

    test('generates non-empty payload for national ID', () {
      final payload = generatePromptPayPayload('1234567890123', 250);
      expect(payload, isNotEmpty);
    });

    test('payload ends with 4-char CRC hex', () {
      final payload = generatePromptPayPayload('0812345678', 100);
      final crc = payload.substring(payload.length - 4);
      expect(RegExp(r'^[0-9A-F]{4}$').hasMatch(crc), isTrue);
    });

    test('payload contains KIDTANG reference', () {
      final payload = generatePromptPayPayload('0812345678', 100);
      expect(payload.contains('KIDTANG'), isTrue);
    });

    test('zero amount omits amount field', () {
      final payload = generatePromptPayPayload('0812345678', 0);
      // Amount TLV tag '54' should not appear when amount is 0
      expect(payload, isNotEmpty);
    });
  });
}
