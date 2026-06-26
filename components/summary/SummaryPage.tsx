"use client";

import { useMemo } from "react";
import { BillState } from "@/lib/types";
import {
  buildDebtMatrix,
  calculateSummary,
  formatCurrency,
  simplifyDebts,
} from "@/lib/utils";

interface SummaryPageProps {
  state: BillState;
}

export default function SummaryPage({ state }: SummaryPageProps) {
  const { members, items } = state;

  const summaries = useMemo(() => calculateSummary(state), [state]);
  const matrix = useMemo(() => buildDebtMatrix(state), [state]);
  const transactions = useMemo(
    () => simplifyDebts(matrix, members),
    [matrix, members]
  );

  if (members.length === 0 || items.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center py-16 gap-3">
        <div className="w-16 h-16 rounded-2xl bg-gray-100 flex items-center justify-center text-2xl">
          📊
        </div>
        <p className="text-sm text-gray-500 text-center">
          ยังไม่มีข้อมูลสรุป
          <br />
          <span className="text-gray-400">เพิ่มสมาชิกและรายการก่อน</span>
        </p>
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-5">
      <div>
        <h2 className="text-base font-semibold text-gray-900">สรุปค่าใช้จ่าย</h2>
        <p className="text-xs text-gray-400 mt-0.5">{members.length} คน · {items.length} รายการ</p>
      </div>

      {/* Per-member summary */}
      <div className="flex flex-col gap-2">
        {summaries.map((s) => (
          <div
            key={s.memberId}
            className="bg-white rounded-2xl border border-gray-100 shadow-sm px-4 py-3"
          >
            <div className="flex items-center gap-3">
              <div
                className="w-10 h-10 rounded-full flex items-center justify-center text-white font-semibold text-sm flex-shrink-0"
                style={{ backgroundColor: s.color }}
              >
                {s.memberName.slice(0, 1).toUpperCase()}
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-sm font-semibold text-gray-900">{s.memberName}</p>
                <div className="flex gap-3 mt-0.5">
                  <span className="text-xs text-gray-400">
                    ค่าใช้จ่าย ฿{formatCurrency(s.totalOwed)}
                  </span>
                  <span className="text-xs text-gray-400">
                    จ่ายไป ฿{formatCurrency(s.totalPaid)}
                  </span>
                </div>
              </div>
              <div className="text-right flex-shrink-0">
                <p
                  className={`text-sm font-bold ${
                    s.netBalance >= 0 ? "text-emerald-600" : "text-red-500"
                  }`}
                >
                  {s.netBalance >= 0 ? "+" : ""}฿{formatCurrency(s.netBalance)}
                </p>
                <p className="text-xs text-gray-400">
                  {s.netBalance >= 0 ? "ได้คืน" : "ต้องจ่าย"}
                </p>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Simplified debt transactions */}
      {transactions.length > 0 && (
        <div>
          <h3 className="text-sm font-semibold text-gray-700 mb-2">สรุปการโอนเงิน</h3>
          <div className="flex flex-col gap-2">
            {transactions.map((t, i) => {
              const fromMember = members.find((m) => m.id === t.fromId);
              const toMember = members.find((m) => m.id === t.toId);
              return (
                <div
                  key={i}
                  className="bg-white rounded-2xl border border-gray-100 shadow-sm px-4 py-3 flex items-center gap-3"
                >
                  <div
                    className="w-8 h-8 rounded-full flex items-center justify-center text-white text-xs font-semibold flex-shrink-0"
                    style={{ backgroundColor: fromMember?.color }}
                  >
                    {t.fromName.slice(0, 1).toUpperCase()}
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm text-gray-700">
                      <span className="font-semibold" style={{ color: fromMember?.color }}>
                        {t.fromName}
                      </span>
                      {" → "}
                      <span className="font-semibold" style={{ color: toMember?.color }}>
                        {t.toName}
                      </span>
                    </p>
                  </div>
                  <p className="text-sm font-bold text-gray-900 flex-shrink-0">
                    ฿{formatCurrency(t.amount)}
                  </p>
                </div>
              );
            })}
          </div>
        </div>
      )}

      {transactions.length === 0 && (
        <div className="bg-emerald-50 border border-emerald-200 rounded-2xl px-4 py-3">
          <p className="text-sm text-emerald-700 font-medium">✅ ทุกคนจ่ายเท่ากัน ไม่ต้องโอนเงิน</p>
        </div>
      )}
    </div>
  );
}
