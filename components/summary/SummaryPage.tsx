"use client";

import { useState } from "react";
import {
  IoCheckmarkCircle,
  IoEllipseOutline,
  IoQrCode,
  IoArrowForward,
  IoBarChart,
} from "react-icons/io5";
import {
  PieChart,
  Pie,
  Cell,
  Tooltip,
  ResponsiveContainer,
} from "recharts";
import { Bill, DebtTransaction } from "@/lib/types";
import {
  buildDebtMatrix,
  calculateSummary,
  formatCurrency,
  getBillTotal,
  simplifyDebts,
} from "@/lib/utils";
import Modal from "@/components/ui/Modal";
import Button from "@/components/ui/Button";

interface SummaryPageProps {
  bill: Bill;
  getShareUrl: () => string;
}

export default function SummaryPage({ bill }: SummaryPageProps) {
  const [paidMap, setPaidMap] = useState<Record<string, boolean>>({});
  const [qrTarget, setQrTarget] = useState<DebtTransaction | null>(null);

  const { members, settings } = bill;
  const summaries = calculateSummary(bill);
  const matrix = buildDebtMatrix(bill);
  const transactions = simplifyDebts(matrix, members, settings.roundingMode);
  const total = getBillTotal(bill);

  const txKey = (tx: DebtTransaction) => `${tx.fromId}-${tx.toId}`;

  const togglePaid = (tx: DebtTransaction) => {
    const key = txKey(tx);
    setPaidMap((prev) => ({ ...prev, [key]: !prev[key] }));
  };

  const getQrUrl = (promptpay: string, amount: number) => {
    const clean = promptpay.replace(/-/g, "");
    return `https://promptpay.io/${clean}/${amount.toFixed(2)}`;
  };

  const pendingCount = transactions.filter((tx) => !paidMap[txKey(tx)]).length;

  // Pie chart data
  const pieData = summaries
    .filter((s) => s.totalOwed > 0)
    .map((s) => ({
      name: s.memberName,
      value: Math.round(s.totalOwed * 100) / 100,
      color: s.color,
    }));

  if (members.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center py-16 gap-3">
        <div className="w-16 h-16 rounded-2xl bg-blue-50 dark:bg-blue-900/20 flex items-center justify-center">
          <IoBarChart size={32} className="text-[#4366f4]" />
        </div>
        <p className="text-sm text-gray-500 dark:text-gray-400 text-center">
          เพิ่มสมาชิกและรายการ
          <br />
          เพื่อดูสรุปการหารบิล
        </p>
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-5">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-lg font-bold text-gray-900 dark:text-white">สรุป</h1>
          <p className="text-xs text-gray-400 mt-0.5">
            {pendingCount > 0
              ? `รอชำระ ${pendingCount} รายการ`
              : "ชำระครบแล้ว 🎉"}
          </p>
        </div>
      </div>

      {/* Bill total card */}
      <div className="p-4 bg-gradient-to-br from-[#4366f4] to-[#6b8af7] rounded-2xl text-white">
        <p className="text-xs opacity-80 mb-1">ยอดรวมทั้งหมด</p>
        <p className="text-3xl font-bold">
          {formatCurrency(total, settings.currency)}
        </p>
        {(bill.tip > 0 || bill.discount > 0) && (
          <div className="flex gap-3 mt-2 text-xs opacity-80">
            {bill.tip > 0 && (
              <span>+ ทิป {formatCurrency(bill.tip, settings.currency)}</span>
            )}
            {bill.discount > 0 && (
              <span>- ส่วนลด {formatCurrency(bill.discount, settings.currency)}</span>
            )}
          </div>
        )}
      </div>

      {/* Pie Chart */}
      {pieData.length > 0 && total > 0 && (
        <div className="bg-white dark:bg-gray-900 rounded-2xl border border-gray-100 dark:border-gray-800 p-4">
          <h2 className="text-sm font-semibold text-gray-700 dark:text-gray-300 mb-3">
            สัดส่วนค่าใช้จ่าย
          </h2>
          <div className="flex items-center gap-4">
            <div className="w-36 h-36 flex-shrink-0">
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie
                    data={pieData}
                    cx="50%"
                    cy="50%"
                    innerRadius={36}
                    outerRadius={60}
                    paddingAngle={2}
                    dataKey="value"
                  >
                    {pieData.map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={entry.color} />
                    ))}
                  </Pie>
                  <Tooltip
                    formatter={(value) =>
                      formatCurrency(Number(value) || 0, settings.currency)
                    }
                    contentStyle={{
                      borderRadius: "12px",
                      border: "1px solid #e5e7eb",
                      fontSize: "12px",
                    }}
                  />
                </PieChart>
              </ResponsiveContainer>
            </div>
            <div className="flex flex-col gap-1.5 flex-1 min-w-0">
              {pieData.map((entry) => (
                <div key={entry.name} className="flex items-center gap-2">
                  <div
                    className="w-2.5 h-2.5 rounded-full flex-shrink-0"
                    style={{ backgroundColor: entry.color }}
                  />
                  <span className="text-xs text-gray-600 dark:text-gray-400 truncate flex-1">
                    {entry.name}
                  </span>
                  <span className="text-xs font-semibold text-gray-900 dark:text-white flex-shrink-0">
                    {formatCurrency(entry.value, settings.currency)}
                  </span>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* Per-person summary */}
      <div className="flex flex-col gap-2">
        <h2 className="text-sm font-semibold text-gray-700 dark:text-gray-300">
          ยอดแต่ละคน
        </h2>
        {summaries.map((s) => (
          <div
            key={s.memberId}
            className="flex items-center gap-3 p-3 bg-white dark:bg-gray-900 rounded-xl border border-gray-100 dark:border-gray-800"
          >
            <div
              className="w-8 h-8 rounded-lg flex items-center justify-center text-white text-xs font-bold flex-shrink-0"
              style={{ backgroundColor: s.color }}
            >
              {s.memberName.slice(0, 1).toUpperCase()}
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-sm font-medium text-gray-900 dark:text-white truncate">
                {s.memberName}
              </p>
              <p className="text-xs text-gray-400">
                ต้องจ่าย {formatCurrency(s.totalOwed, settings.currency)}
              </p>
            </div>
            <div className="text-right">
              <p
                className={`text-sm font-bold ${
                  s.netBalance >= 0
                    ? "text-emerald-600 dark:text-emerald-400"
                    : "text-red-500 dark:text-red-400"
                }`}
              >
                {s.netBalance >= 0 ? "+" : ""}
                {formatCurrency(s.netBalance, settings.currency)}
              </p>
              <p className="text-[10px] text-gray-400">
                {s.netBalance >= 0 ? "ได้คืน" : "ต้องโอน"}
              </p>
            </div>
          </div>
        ))}
      </div>

      {/* Transactions */}
      {transactions.length > 0 && (
        <div className="flex flex-col gap-2">
          <h2 className="text-sm font-semibold text-gray-700 dark:text-gray-300">
            การโอนเงิน
          </h2>
          {transactions.map((tx) => {
            const key = txKey(tx);
            const isPaid = paidMap[key] || false;
            return (
              <div
                key={key}
                className={`p-3.5 rounded-2xl border transition-all ${
                  isPaid
                    ? "bg-gray-50 dark:bg-gray-800/50 border-gray-100 dark:border-gray-800 opacity-60"
                    : "bg-white dark:bg-gray-900 border-gray-100 dark:border-gray-800 shadow-sm"
                }`}
              >
                <div className="flex items-center gap-3">
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-1.5">
                      <span className="text-sm font-semibold text-gray-900 dark:text-white truncate">
                        {tx.fromName}
                      </span>
                      <IoArrowForward
                        size={12}
                        className="text-gray-400 flex-shrink-0"
                      />
                      <span className="text-sm font-semibold text-gray-900 dark:text-white truncate">
                        {tx.toName}
                      </span>
                    </div>
                    <p className="text-base font-bold text-[#4366f4] mt-0.5">
                      {formatCurrency(tx.amount, settings.currency)}
                    </p>
                  </div>

                  <div className="flex items-center gap-2 flex-shrink-0">
                    {tx.toPromptpay && !isPaid && (
                      <button
                        onClick={() => setQrTarget(tx)}
                        className="w-8 h-8 flex items-center justify-center rounded-xl bg-blue-50 dark:bg-blue-900/20 text-[#4366f4] hover:bg-blue-100 transition-colors"
                      >
                        <IoQrCode size={16} />
                      </button>
                    )}

                    <button
                      onClick={() => togglePaid(tx)}
                      className={`w-8 h-8 flex items-center justify-center rounded-xl transition-colors ${
                        isPaid
                          ? "text-emerald-500"
                          : "text-gray-300 dark:text-gray-600 hover:text-emerald-400"
                      }`}
                    >
                      {isPaid ? (
                        <IoCheckmarkCircle size={22} />
                      ) : (
                        <IoEllipseOutline size={22} />
                      )}
                    </button>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* All settled */}
      {transactions.length === 0 && bill.items.length > 0 && (
        <div className="p-4 bg-emerald-50 dark:bg-emerald-900/20 rounded-2xl border border-emerald-200 dark:border-emerald-800 text-center">
          <p className="text-sm font-medium text-emerald-700 dark:text-emerald-400">
            🎉 ไม่มีการโอนเงิน ทุกคนจ่ายเท่ากัน!
          </p>
        </div>
      )}

      {/* QR Modal */}
      <Modal
        isOpen={!!qrTarget}
        onClose={() => setQrTarget(null)}
        title="QR PromptPay"
        size="sm"
      >
        {qrTarget && (
          <div className="flex flex-col items-center gap-4">
            <p className="text-sm text-gray-600 dark:text-gray-400 text-center">
              <span className="font-semibold text-gray-900 dark:text-white">
                {qrTarget.fromName}
              </span>{" "}
              โอนให้{" "}
              <span className="font-semibold text-gray-900 dark:text-white">
                {qrTarget.toName}
              </span>
            </p>
            <p className="text-2xl font-bold text-[#4366f4]">
              {formatCurrency(qrTarget.amount, bill.settings.currency)}
            </p>
            {qrTarget.toPromptpay && (
              // eslint-disable-next-line @next/next/no-img-element
              <img
                src={getQrUrl(qrTarget.toPromptpay, qrTarget.amount)}
                alt="QR PromptPay"
                className="w-48 h-48 rounded-xl"
              />
            )}
            <p className="text-xs text-gray-400">
              PromptPay: {qrTarget.toPromptpay}
            </p>
            <Button
              fullWidth
              onClick={() => {
                togglePaid(qrTarget);
                setQrTarget(null);
              }}
            >
              <IoCheckmarkCircle size={16} />
              ทำเครื่องหมายว่าจ่ายแล้ว
            </Button>
          </div>
        )}
      </Modal>
    </div>
  );
}
