import 'package:flutter/material.dart';

/// BillStatusPill — ตรงกับ BillStatusPill.tsx ใน Next.js
/// status = 'completed' → สีเขียว "เสร็จแล้ว"
/// status = 'draft'     → สีเทา  "ร่าง"
class BillStatusPill extends StatelessWidget {
  final String status;

  const BillStatusPill({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final isCompleted = status == 'completed';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isCompleted
            ? const Color(0xFFD1FAE5) // emerald-100
            : const Color(0xFFF3F4F6), // gray-100
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isCompleted ? 'เสร็จแล้ว' : 'ร่าง',
        style: TextStyle(
          fontSize: 10,
          fontWeight:
              isCompleted ? FontWeight.w600 : FontWeight.w500,
          color: isCompleted
              ? const Color(0xFF059669) // emerald-600
              : const Color(0xFF6B7280), // gray-500
        ),
      ),
    );
  }
}
