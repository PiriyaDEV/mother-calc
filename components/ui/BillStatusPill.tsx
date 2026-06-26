"use client";

import { Bill } from "@/lib/types";

interface BillStatusPillProps {
  bill: Bill;
  className?: string;
}

/**
 * Shows a pill for completed bills:
 * - ✅ จ่ายครบแล้ว  — all members have paid
 * - ⏳ รอจ่าย       — some members haven't paid yet
 *
 * Returns null if the bill is still a draft.
 */
export default function BillStatusPill({ bill, className = "" }: BillStatusPillProps) {
  if (bill.status !== "completed") return null;

  const memberCount = bill.members?.length ?? 0;
  const paidCount = bill.paid_member_ids?.length ?? 0;
  const allPaid = memberCount === 0 ? false : paidCount >= memberCount;

  if (allPaid) {
    return (
      <span
        className={`inline-flex items-center gap-0.5 px-2 py-0.5 rounded-full text-[10px] font-semibold bg-emerald-100 dark:bg-emerald-900/30 text-emerald-600 dark:text-emerald-400 ${className}`}
      >
        ✅ จ่ายครบแล้ว
      </span>
    );
  }

  return (
    <span
      className={`inline-flex items-center gap-0.5 px-2 py-0.5 rounded-full text-[10px] font-semibold bg-amber-100 dark:bg-amber-900/30 text-amber-600 dark:text-amber-400 ${className}`}
    >
      ⏳ รอจ่าย
    </span>
  );
}
