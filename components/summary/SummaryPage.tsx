"use client";

import { useMemo } from "react";
import { IoArrowForward, IoQrCodeOutline } from "react-icons/io5";
import { Bill, BillMember } from "@/lib/types";
import { calculateBill, formatCurrency } from "@/lib/utils";

interface SummaryPageProps {
  bill: Bill;
}

export default function SummaryPage({ bill }: SummaryPageProps) {
  const calc = useMemo(() => calculateBill(bill), [bill]);
  const currency = bill.settings?.currency ?? "THB";

  if ((bill.members ?? []).length === 0) {
    return (
      <div className="flex flex-col items-center gap-3 py-10 text-center">
        <p className="text-sm text-gray-500 dark:text-gray-400">เพิ่มสมาชิกและรายการก่อน</p>
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-4">
      {/* Bill totals card */}
      <div className="bg-gray-50 dark:bg-gray-800/60 rounded-2xl p-4 flex flex-col gap-2">
        <h3 className="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wide mb-1">
          สรุปบิล
        </h3>
        <Row label="ยอดรวม" value={formatCurrency(calc.subtotal, currency)} />
        {calc.serviceAmount > 0 && (
          <Row label={`Service Charge (${bill.settings.serviceCharge}%)`} value={formatCurrency(calc.serviceAmount, currency)} />
        )}
        {calc.vatAmount > 0 && (
          <Row label={`VAT (${bill.settings.vat}%)`} value={formatCurrency(calc.vatAmount, currency)} />
        )}
        {calc.tipAmount > 0 && (
          <Row label="ทิป" value={formatCurrency(calc.tipAmount, currency)} />
        )}
        {calc.discountAmount > 0 && (
          <Row label="ส่วนลด" value={`-${formatCurrency(calc.discountAmount, currency)}`} negative />
        )}
        <div className="border-t border-gray-200 dark:border-gray-700 pt-2 mt-1">
          <Row label="รวมทั้งสิ้น" value={formatCurrency(calc.total, currency)} bold />
        </div>
      </div>

      {/* Per-member breakdown */}
      <div className="flex flex-col gap-2">
        <h3 className="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wide px-1">
          แต่ละคนจ่าย
        </h3>
        {calc.memberSummaries.map(({ member, total, items }) => (
          <div key={member.id} className="bg-gray-50 dark:bg-gray-800/60 rounded-2xl overflow-hidden">
            {/* Member header */}
            <div className="flex items-center gap-3 px-4 py-3">
              <div
                className="w-9 h-9 rounded-full flex items-center justify-center text-white text-sm font-bold flex-shrink-0"
                style={{ backgroundColor: member.color }}
              >
                {member.name.charAt(0).toUpperCase()}
              </div>
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-1.5">
                  <p className="text-sm font-semibold text-gray-900 dark:text-white">{member.name}</p>
                  {member.is_external && (
                    <span className="text-[10px] px-1.5 py-0.5 bg-gray-200 dark:bg-gray-700 text-gray-500 rounded-full">
                      ภายนอก
                    </span>
                  )}
                </div>
                {member.promptpay && (
                  <p className="text-xs text-gray-400">พร้อมเพย์: {member.promptpay}</p>
                )}
              </div>
              <div className="text-right">
                <p className="text-base font-bold text-gray-900 dark:text-white">
                  {formatCurrency(total, currency)}
                </p>
              </div>
            </div>

            {/* Item breakdown */}
            {items.length > 0 && (
              <div className="border-t border-gray-100 dark:border-gray-700/50 px-4 py-2 flex flex-col gap-1">
                {items.map(({ item, amount }) => (
                  <div key={item.id} className="flex items-center justify-between">
                    <span className="text-xs text-gray-500 dark:text-gray-400 truncate flex-1">{item.name}</span>
                    <span className="text-xs text-gray-600 dark:text-gray-300 flex-shrink-0 ml-2">
                      {formatCurrency(amount, currency)}
                    </span>
                  </div>
                ))}
              </div>
            )}

            {/* PromptPay QR hint */}
            {member.promptpay && (
              <div className="border-t border-gray-100 dark:border-gray-700/50 px-4 py-2 flex items-center gap-2">
                <IoQrCodeOutline size={14} className="text-gray-400" />
                <span className="text-xs text-gray-400">สแกน QR เพื่อโอน</span>
              </div>
            )}
          </div>
        ))}
      </div>

      {/* Debt arrows */}
      {calc.memberSummaries.length > 1 && (
        <div className="flex flex-col gap-2">
          <h3 className="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wide px-1">
            ใครโอนให้ใคร
          </h3>
          <div className="bg-gray-50 dark:bg-gray-800/60 rounded-2xl p-4 flex flex-col gap-2">
            {calc.memberSummaries
              .filter((s) => s.total > 0)
              .sort((a, b) => b.total - a.total)
              .map(({ member, total }) => {
                const maxPayer = calc.memberSummaries.reduce((max, s) =>
                  s.total > max.total ? s : max
                );
                if (member.id === maxPayer.member.id) return null;
                return (
                  <div key={member.id} className="flex items-center gap-2">
                    <div
                      className="w-6 h-6 rounded-full flex items-center justify-center text-white text-[10px] font-bold flex-shrink-0"
                      style={{ backgroundColor: member.color }}
                    >
                      {member.name.charAt(0).toUpperCase()}
                    </div>
                    <span className="text-xs text-gray-600 dark:text-gray-300 truncate">{member.name}</span>
                    <IoArrowForward size={12} className="text-gray-400 flex-shrink-0" />
                    <div
                      className="w-6 h-6 rounded-full flex items-center justify-center text-white text-[10px] font-bold flex-shrink-0"
                      style={{ backgroundColor: maxPayer.member.color }}
                    >
                      {maxPayer.member.name.charAt(0).toUpperCase()}
                    </div>
                    <span className="text-xs text-gray-600 dark:text-gray-300 truncate">{maxPayer.member.name}</span>
                    <span className="text-xs font-semibold text-gray-900 dark:text-white ml-auto flex-shrink-0">
                      {formatCurrency(total, currency)}
                    </span>
                  </div>
                );
              })}
          </div>
        </div>
      )}
    </div>
  );
}

function Row({
  label,
  value,
  bold,
  negative,
}: {
  label: string;
  value: string;
  bold?: boolean;
  negative?: boolean;
}) {
  return (
    <div className="flex items-center justify-between">
      <span className={`text-sm ${bold ? "font-semibold text-gray-900 dark:text-white" : "text-gray-500 dark:text-gray-400"}`}>
        {label}
      </span>
      <span className={`text-sm ${bold ? "font-bold text-gray-900 dark:text-white" : negative ? "text-green-600 dark:text-green-400" : "text-gray-700 dark:text-gray-300"}`}>
        {value}
      </span>
    </div>
  );
}
