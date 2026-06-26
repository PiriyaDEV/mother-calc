"use client";

import { useMemo, useState, useEffect, useRef } from "react";
import { IoArrowForward, IoQrCodeOutline } from "react-icons/io5";
import { Bill, BillMember } from "@/lib/types";
import { calculateBill, formatCurrency, formatNumber, getTotalEmoji, simplifyDebtsPerItem } from "@/lib/utils";
import QRCode from "qrcode";

interface SummaryPageProps {
  bill: Bill;
  members?: BillMember[];
}

// ── PromptPay QR helpers ──────────────────────────────────────
function generatePromptPayPayload(target: string, amount: number): string {
  const isPhone = /^0\d{9}$/.test(target.replace(/-/g, ""));
  const isNationalId = /^\d{13}$/.test(target.replace(/-/g, ""));

  let targetFormatted = target.replace(/-/g, "");
  let targetTag = "01";
  if (isNationalId) {
    targetTag = "02";
  } else if (isPhone) {
    targetFormatted = "66" + targetFormatted.slice(1);
  }

  const amountStr = amount.toFixed(2);

  function tlv(tag: string, value: string): string {
    const len = value.length.toString().padStart(2, "0");
    return `${tag}${len}${value}`;
  }

  const merchantInfo = tlv("00", "01") + tlv("01", "A000000677010111") + tlv(targetTag, targetFormatted);
  const payload =
    tlv("00", "01") +
    tlv("01", "12") +
    tlv("29", merchantInfo) +
    tlv("53", "764") +
    (amount > 0 ? tlv("54", amountStr) : "") +
    tlv("58", "TH") +
    tlv("62", tlv("07", "KIDTANG"));

  const withCrc = payload + "6304";
  let crc = 0xffff;
  for (let i = 0; i < withCrc.length; i++) {
    crc ^= withCrc.charCodeAt(i) << 8;
    for (let j = 0; j < 8; j++) {
      crc = crc & 0x8000 ? (crc << 1) ^ 0x1021 : crc << 1;
    }
  }
  return withCrc + (crc & 0xffff).toString(16).toUpperCase().padStart(4, "0");
}

function PromptPayQR({ promptpay, amount, name }: { promptpay: string; amount: number; name: string }) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const [error, setError] = useState(false);

  useEffect(() => {
    if (!canvasRef.current) return;
    try {
      const payload = generatePromptPayPayload(promptpay, amount);
      QRCode.toCanvas(canvasRef.current, payload, {
        width: 180,
        margin: 1,
        color: { dark: "#1a1d2e", light: "#ffffff" },
      });
    } catch {
      setError(true);
    }
  }, [promptpay, amount]);

  if (error) return null;

  return (
    <div className="flex flex-col items-center gap-2 py-3">
      <canvas ref={canvasRef} className="rounded-xl" />
      <p className="text-xs text-gray-500 dark:text-gray-400">
        สแกนโอนให้ <span className="font-semibold text-gray-700 dark:text-gray-300">{name}</span>
      </p>
      <p className="text-xs text-gray-400">{promptpay}</p>
    </div>
  );
}

export default function SummaryPage({ bill, members: membersProp }: SummaryPageProps) {
  // Prefer explicit members prop (always up-to-date from parent state)
  const members = membersProp ?? bill.members ?? [];
  // Build a bill object with the correct members + items for calculation
  const billItems = bill.items ?? [];
  const billForCalc = useMemo(
    () => ({ ...bill, members, items: billItems }),
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [bill, members, billItems]
  );
  const calc = useMemo(() => calculateBill(billForCalc), [billForCalc]);
  const currency = bill.settings?.currency ?? "THB";

  const [expandedQR, setExpandedQR] = useState<string | null>(null);

  const debts = useMemo(
    () => simplifyDebtsPerItem(calc.memberSummaries, members, null),
    [calc.memberSummaries, members]
  );

  const totalEmoji = getTotalEmoji(calc.total);

  if (members.length === 0) {
    return (
      <div className="flex flex-col items-center gap-3 py-10 text-center">
        <p className="text-sm text-gray-500 dark:text-gray-400">เพิ่มสมาชิกและรายการก่อน</p>
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-4">
      {/* Hero total */}
      <div className="bg-gradient-to-br from-[#4366f4] to-[#6b8aff] rounded-3xl p-5 text-white">
        <p className="text-sm font-medium opacity-80">ยอดรวมทั้งสิ้น</p>
        <div className="flex items-end gap-3 mt-1">
          <p className="text-3xl font-bold tracking-tight">
            {formatNumber(calc.total)} บาท
          </p>
          <span className="text-2xl mb-0.5">{totalEmoji}</span>
        </div>
        {calc.serviceAmount > 0 && (
          <p className="text-xs opacity-70 mt-1">รวม Service Charge {bill.settings.serviceCharge}%</p>
        )}
        {calc.vatAmount > 0 && (
          <p className="text-xs opacity-70">รวม VAT {bill.settings.vat}%</p>
        )}
      </div>

      {/* Bill breakdown */}
      <div className="bg-gray-50 dark:bg-gray-800/60 rounded-2xl p-4 flex flex-col gap-2">
        <h3 className="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wide mb-1">
          รายละเอียดบิล
        </h3>
        <Row label="ยอดรวมสินค้า" value={formatCurrency(calc.subtotal, currency)} />
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


      {/* Debt arrows — show when any item has paid_by OR global paidBy is set */}
      {debts.length > 0 && (
        <div className="flex flex-col gap-2">
          <h3 className="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wide px-1">
            ใครโอนให้ใคร
          </h3>
          <div className="bg-gray-50 dark:bg-gray-800/60 rounded-2xl p-4 flex flex-col gap-3">
            {debts.map(({ from, to, amount }: { from: BillMember; to: BillMember; amount: number }) => (
              <div key={`${from.id}-${to.id}`} className="flex items-center gap-2">
                <div
                  className="w-7 h-7 rounded-full flex items-center justify-center text-white text-[10px] font-bold flex-shrink-0"
                  style={{ backgroundColor: from.color }}
                >
                  {from.name.charAt(0).toUpperCase()}
                </div>
                <span className="text-sm text-gray-700 dark:text-gray-300 font-medium truncate">{from.name}</span>
                <IoArrowForward size={14} className="text-gray-400 flex-shrink-0" />
                <div
                  className="w-7 h-7 rounded-full flex items-center justify-center text-white text-[10px] font-bold flex-shrink-0"
                  style={{ backgroundColor: to.color }}
                >
                  {to.name.charAt(0).toUpperCase()}
                </div>
                <span className="text-sm text-gray-700 dark:text-gray-300 font-medium truncate">{to.name}</span>
                <span className="text-sm font-bold text-gray-900 dark:text-white ml-auto flex-shrink-0">
                  {formatNumber(amount)} บาท
                </span>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Per-member breakdown */}
      <div className="flex flex-col gap-2">
        <h3 className="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wide px-1">
          แต่ละคนจ่าย
        </h3>
        {calc.memberSummaries.map(({ member, total, items }) => (
          <div key={member.id} className="bg-gray-50 dark:bg-gray-800/60 rounded-2xl overflow-hidden">
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
              <div className="text-right flex items-center gap-2">
                <div>
                  <p className="text-base font-bold text-gray-900 dark:text-white">
                    {formatNumber(total)} บาท
                  </p>
                  <p className="text-[10px] text-gray-400">{getTotalEmoji(total)}</p>
                </div>
                {member.promptpay && (
                  <button
                    onClick={() => setExpandedQR(expandedQR === member.id ? null : member.id)}
                    className={`w-8 h-8 flex items-center justify-center rounded-xl transition-colors ${
                      expandedQR === member.id
                        ? "bg-[#4366f4] text-white"
                        : "text-gray-400 hover:text-[#4366f4] hover:bg-blue-50 dark:hover:bg-blue-900/20"
                    }`}
                  >
                    <IoQrCodeOutline size={16} />
                  </button>
                )}
              </div>
            </div>

            {expandedQR === member.id && member.promptpay && (
              <div className="border-t border-gray-100 dark:border-gray-700/50">
                <PromptPayQR promptpay={member.promptpay} amount={total} name={member.name} />
              </div>
            )}

            {items.length > 0 && (
              <div className="border-t border-gray-100 dark:border-gray-700/50 px-4 py-2 flex flex-col gap-1">
                {items.map(({ item, amount }) => (
                  <div key={item.id} className="flex items-center justify-between">
                    <span className="text-xs text-gray-500 dark:text-gray-400 truncate flex-1">{item.name}</span>
                    <span className="text-xs text-gray-600 dark:text-gray-300 flex-shrink-0 ml-2">
                      {formatNumber(amount)} บาท
                    </span>
                  </div>
                ))}
              </div>
            )}
          </div>
        ))}
      </div>
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
