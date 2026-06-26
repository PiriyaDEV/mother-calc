"use client";

import { useMemo, useState } from "react";
import { IoCopy, IoCheckmark, IoShare } from "react-icons/io5";
import { BillState, DebtTransaction } from "@/lib/types";
import {
  buildDebtMatrix,
  formatCurrency,
  simplifyDebts,
} from "@/lib/utils";

interface PaymentPageProps {
  state: BillState;
  getShareUrl: (mode: "view" | "edit") => string;
}

function generatePromptPayQR(promptpay: string, amount: number): string {
  // ใช้ promptpay.io API สำหรับ generate QR
  const encoded = encodeURIComponent(promptpay);
  return `https://promptpay.io/${encoded}/${amount.toFixed(2)}.png`;
}

function TransactionCard({
  transaction,
}: {
  transaction: DebtTransaction;
}) {
  const [copied, setCopied] = useState(false);

  const copyAmount = () => {
    navigator.clipboard.writeText(transaction.amount.toFixed(2)).then(() => {
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    });
  };

  return (
    <div className="bg-white rounded-2xl border border-gray-100 shadow-sm overflow-hidden">
      {/* Header */}
      <div className="px-4 pt-4 pb-3 flex items-center justify-between">
        <div>
          <p className="text-sm text-gray-500">
            <span className="font-semibold text-gray-900">{transaction.fromName}</span>
            {" โอนให้ "}
            <span className="font-semibold text-gray-900">{transaction.toName}</span>
          </p>
          <div className="flex items-center gap-2 mt-1">
            <p className="text-xl font-bold text-gray-900">
              ฿{formatCurrency(transaction.amount)}
            </p>
            <button
              onClick={copyAmount}
              className="flex items-center gap-1 text-xs text-[#4366f4] hover:text-[#3355e0] transition-colors"
            >
              {copied ? <IoCheckmark size={13} /> : <IoCopy size={13} />}
              {copied ? "คัดลอกแล้ว" : "คัดลอก"}
            </button>
          </div>
        </div>
      </div>

      {/* QR Code */}
      {transaction.toPromptpay ? (
        <div className="px-4 pb-4 flex flex-col items-center gap-3">
          <div className="bg-gray-50 rounded-2xl p-4 flex flex-col items-center gap-2">
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img
              src={generatePromptPayQR(transaction.toPromptpay, transaction.amount)}
              alt={`QR PromptPay ${transaction.toName}`}
              className="w-44 h-44 object-contain"
              loading="lazy"
            />
            <p className="text-xs text-gray-500">
              PromptPay: {transaction.toName}
            </p>
          </div>
        </div>
      ) : (
        <div className="px-4 pb-4">
          <p className="text-xs text-gray-400 text-center py-3 bg-gray-50 rounded-xl">
            ไม่มีข้อมูล PromptPay ของ {transaction.toName}
          </p>
        </div>
      )}
    </div>
  );
}

export default function PaymentPage({ state, getShareUrl }: PaymentPageProps) {
  const { members, items } = state;
  const [copiedShare, setCopiedShare] = useState(false);

  const matrix = useMemo(() => buildDebtMatrix(state), [state]);
  const transactions = useMemo(
    () => simplifyDebts(matrix, members),
    [matrix, members]
  );

  const handleShare = async () => {
    const url = getShareUrl("view");
    try {
      if (navigator.share) {
        await navigator.share({ title: "Kidtang — หารบิล", url });
      } else {
        await navigator.clipboard.writeText(url);
        setCopiedShare(true);
        setTimeout(() => setCopiedShare(false), 2000);
      }
    } catch {
      // ignore
    }
  };

  if (members.length === 0 || items.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center py-16 gap-3">
        <div className="w-16 h-16 rounded-2xl bg-gray-100 flex items-center justify-center text-2xl">
          💸
        </div>
        <p className="text-sm text-gray-500 text-center">
          ยังไม่มีข้อมูลการชำระเงิน
          <br />
          <span className="text-gray-400">เพิ่มสมาชิกและรายการก่อน</span>
        </p>
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-5">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-base font-semibold text-gray-900">ชำระเงิน</h2>
          <p className="text-xs text-gray-400 mt-0.5">
            {transactions.length} รายการโอน
          </p>
        </div>
        <button
          onClick={handleShare}
          className="flex items-center gap-1.5 text-sm text-[#4366f4] font-medium hover:text-[#3355e0] transition-colors"
        >
          {copiedShare ? <IoCheckmark size={16} /> : <IoShare size={16} />}
          {copiedShare ? "คัดลอกแล้ว" : "แชร์"}
        </button>
      </div>

      {transactions.length === 0 ? (
        <div className="bg-emerald-50 border border-emerald-200 rounded-2xl px-4 py-4 text-center">
          <p className="text-sm text-emerald-700 font-medium">✅ ทุกคนจ่ายเท่ากัน ไม่ต้องโอนเงิน</p>
        </div>
      ) : (
        <div className="flex flex-col gap-3">
          {transactions.map((t, i) => (
            <TransactionCard key={i} transaction={t} />
          ))}
        </div>
      )}

      {/* Share section */}
      <div className="bg-gray-50 rounded-2xl p-4 flex flex-col gap-3">
        <p className="text-sm font-medium text-gray-700">แชร์บิลให้เพื่อน</p>
        <div className="flex gap-2">
          <button
            onClick={() => {
              const url = getShareUrl("view");
              navigator.clipboard.writeText(url);
              setCopiedShare(true);
              setTimeout(() => setCopiedShare(false), 2000);
            }}
            className="flex-1 flex items-center justify-center gap-2 py-2.5 text-sm bg-white border border-gray-200 rounded-xl hover:border-[#4366f4]/40 transition-colors text-gray-700"
          >
            {copiedShare ? <IoCheckmark size={15} className="text-emerald-500" /> : <IoCopy size={15} />}
            {copiedShare ? "คัดลอกแล้ว!" : "คัดลอกลิงก์"}
          </button>
          <button
            onClick={handleShare}
            className="flex-1 flex items-center justify-center gap-2 py-2.5 text-sm bg-[#4366f4] text-white rounded-xl hover:bg-[#3355e0] transition-colors"
          >
            <IoShare size={15} />
            แชร์
          </button>
        </div>
      </div>
    </div>
  );
}
