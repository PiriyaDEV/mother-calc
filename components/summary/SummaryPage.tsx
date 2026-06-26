"use client";

import { useMemo, useState, useEffect, useRef } from "react";
import {
  IoArrowForward,
  IoQrCodeOutline,
  IoChevronDown,
  IoChevronUp,
  IoCheckmarkCircle,
  IoEllipseOutline,
} from "react-icons/io5";
import { Bill, BillMember } from "@/lib/types";
import { calculateBill, formatCurrency, formatNumber, getTotalEmoji, simplifyDebtsPerItem } from "@/lib/utils";
import { toggleMemberPaid } from "@/lib/db";
import QRCode from "qrcode";

interface SummaryPageProps {
  bill: Bill;
  members?: BillMember[];
  currentUserId?: string | null;
  /** Called after paid_member_ids changes so parent can update local state */
  onPaidIdsChange?: (newIds: string[]) => void;
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

export default function SummaryPage({ bill, members: membersProp, currentUserId, onPaidIdsChange }: SummaryPageProps) {
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

  // ── Paid member IDs (local mirror of bill.paid_member_ids) ──
  const [paidIds, setPaidIds] = useState<string[]>(bill.paid_member_ids ?? []);
  const [togglingId, setTogglingId] = useState<string | null>(null);

  // Sync when bill prop changes (e.g. after reopen)
  useEffect(() => {
    setPaidIds(bill.paid_member_ids ?? []);
  }, [bill.paid_member_ids]);

  const handleTogglePaid = async (memberId: string) => {
    if (togglingId) return;
    setTogglingId(memberId);
    try {
      const newIds = await toggleMemberPaid(bill.id, memberId, paidIds);
      setPaidIds(newIds);
      onPaidIdsChange?.(newIds);
    } catch (e) {
      console.error(e);
    } finally {
      setTogglingId(null);
    }
  };

  // ── Selected member (default = current user's bill member) ──
  const defaultMemberId = useMemo(() => {
    if (!currentUserId) return members[0]?.id ?? null;
    const match = members.find((m) => m.user_id === currentUserId);
    return match?.id ?? members[0]?.id ?? null;
  }, [currentUserId, members]);

  const [selectedMemberId, setSelectedMemberId] = useState<string | null>(defaultMemberId);

  // Update selected when members change (e.g. first load)
  useEffect(() => {
    setSelectedMemberId(defaultMemberId);
  }, [defaultMemberId]);

  const [expandedQR, setExpandedQR] = useState<string | null>(null);

  // Global simplified debts (for AllMembersSection overview)
  const debts = useMemo(
    () => simplifyDebtsPerItem(calc.memberSummaries, members, null),
    [calc.memberSummaries, members]
  );

  const totalEmoji = getTotalEmoji(calc.total);

  // ── Selected member data ──────────────────────────────────
  const selectedSummary = useMemo(
    () => calc.memberSummaries.find((s) => s.member.id === selectedMemberId) ?? null,
    [calc.memberSummaries, selectedMemberId]
  );

  // ── Per-payer debts for selected member ──────────────────
  // Compute directly from items: for each item with paid_by,
  // the selected member owes that payer their share of that item.
  // Group by payer and sum — no greedy simplification.
  const myDebts = useMemo(() => {
    if (!selectedMemberId) return [];
    const selectedMs = calc.memberSummaries.find((s) => s.member.id === selectedMemberId);
    if (!selectedMs) return [];

    // Accumulate amount owed to each payer
    const owedTo: Record<string, number> = {};
    for (const { item, amount } of selectedMs.items) {
      const payerId = item.paid_by ?? null;
      if (!payerId) continue;
      if (payerId === selectedMemberId) continue; // don't owe yourself
      owedTo[payerId] = (owedTo[payerId] ?? 0) + amount;
    }

    // Build DebtTransaction list
    return Object.entries(owedTo)
      .filter(([, amt]) => amt > 0.005)
      .map(([payerId, rawAmount]) => {
        const payer = members.find((m) => m.id === payerId)!;
        // Apply the same multiplier as calculateBill (tax/SC/tip/discount)
        const multiplier = calc.subtotal > 0 ? calc.total / calc.subtotal : 1;
        const amount = rawAmount * multiplier;
        return { from: selectedMs.member, to: payer, amount };
      })
      .filter((d) => d.to != null);
  }, [selectedMemberId, calc, members]);

  // Count paid members (those who have debts and are marked paid)
  const membersWithDebts = useMemo(() => {
    const ids = new Set(debts.map((d) => d.from.id));
    return members.filter((m) => ids.has(m.id));
  }, [debts, members]);

  const paidCount = membersWithDebts.filter((m) => paidIds.includes(m.id)).length;
  const allPaid = membersWithDebts.length > 0 && paidCount === membersWithDebts.length;

  const isCompleted = bill.status === "completed";

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
        {/* Payment progress */}
        {isCompleted && membersWithDebts.length > 0 && (
          <div className="mt-3 pt-3 border-t border-white/20">
            <div className="flex items-center justify-between mb-1.5">
              <p className="text-xs opacity-80">สถานะการชำระ</p>
              <p className="text-xs font-bold">
                {paidCount}/{membersWithDebts.length} คน
              </p>
            </div>
            <div className="w-full bg-white/20 rounded-full h-1.5">
              <div
                className="bg-white rounded-full h-1.5 transition-all"
                style={{ width: `${membersWithDebts.length > 0 ? (paidCount / membersWithDebts.length) * 100 : 0}%` }}
              />
            </div>
            {allPaid && (
              <p className="text-xs font-semibold mt-1.5 opacity-90">✅ ทุกคนจ่ายแล้ว!</p>
            )}
          </div>
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

      {/* ── Member selector ─────────────────────────────────── */}
      <div className="flex flex-col gap-2">
        <h3 className="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wide px-1">
          ดูสรุปของ
        </h3>
        <div className="flex gap-2 overflow-x-auto pb-1 scrollbar-hide">
          {members.map((m) => {
            const isSelected = m.id === selectedMemberId;
            const isCurrentUser = m.user_id === currentUserId;
            const isPaid = paidIds.includes(m.id);
            return (
              <button
                key={m.id}
                onClick={() => {
                  setSelectedMemberId(m.id);
                  setExpandedQR(null);
                }}
                className={`flex items-center gap-2 px-3 py-2 rounded-2xl text-sm font-semibold flex-shrink-0 transition-all ${
                  isSelected
                    ? "bg-[#4366f4] text-white shadow-sm"
                    : isPaid
                    ? "bg-emerald-50 dark:bg-emerald-900/20 text-emerald-700 dark:text-emerald-400 border border-emerald-200 dark:border-emerald-800"
                    : "bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-700"
                }`}
              >
                <div
                  className="w-5 h-5 rounded-full flex items-center justify-center text-white text-[9px] font-bold flex-shrink-0"
                  style={{ backgroundColor: isSelected ? "rgba(255,255,255,0.3)" : m.color }}
                >
                  {m.name.charAt(0).toUpperCase()}
                </div>
                <span>{m.name}</span>
                {isCurrentUser && (
                  <span className={`text-[9px] px-1 py-0.5 rounded-full font-bold ${
                    isSelected ? "bg-white/20 text-white" : "bg-blue-100 dark:bg-blue-900/30 text-[#4366f4]"
                  }`}>
                    คุณ
                  </span>
                )}
                {isPaid && !isSelected && (
                  <IoCheckmarkCircle size={13} className="text-emerald-500 flex-shrink-0" />
                )}
              </button>
            );
          })}
        </div>
      </div>

      {/* ── Selected member detail ───────────────────────────── */}
      {selectedSummary && (
        <div className="flex flex-col gap-3">
          {/* Member header card */}
          <div className="bg-gray-50 dark:bg-gray-800/60 rounded-2xl overflow-hidden">
            <div className="flex items-center gap-3 px-4 py-4">
              <div
                className="w-11 h-11 rounded-full flex items-center justify-center text-white text-base font-bold flex-shrink-0"
                style={{ backgroundColor: selectedSummary.member.color }}
              >
                {selectedSummary.member.name.charAt(0).toUpperCase()}
              </div>
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-1.5 flex-wrap">
                  <p className="text-base font-bold text-gray-900 dark:text-white">
                    {selectedSummary.member.name}
                  </p>
                  {selectedSummary.member.is_external && (
                    <span className="text-[10px] px-1.5 py-0.5 bg-gray-200 dark:bg-gray-700 text-gray-500 rounded-full">
                      ภายนอก
                    </span>
                  )}
                  {selectedSummary.member.user_id === currentUserId && (
                    <span className="text-[10px] px-1.5 py-0.5 bg-blue-50 dark:bg-blue-900/30 text-[#4366f4] rounded-full font-semibold">
                      คุณ
                    </span>
                  )}
                  {/* Paid badge */}
                  {paidIds.includes(selectedSummary.member.id) && (
                    <span className="flex items-center gap-0.5 text-[10px] px-1.5 py-0.5 bg-emerald-50 dark:bg-emerald-900/20 text-emerald-600 dark:text-emerald-400 rounded-full font-semibold border border-emerald-200 dark:border-emerald-800">
                      <IoCheckmarkCircle size={10} /> จ่ายแล้ว
                    </span>
                  )}
                </div>
                {selectedSummary.member.promptpay && (
                  <p className="text-xs text-gray-400 mt-0.5">พร้อมเพย์: {selectedSummary.member.promptpay}</p>
                )}
              </div>
              <div className="text-right">
                <p className="text-xl font-bold text-gray-900 dark:text-white">
                  {formatNumber(selectedSummary.total)} บาท
                </p>
                <p className="text-xs text-gray-400">{getTotalEmoji(selectedSummary.total)} ส่วนของฉัน</p>
              </div>
            </div>

            {/* Item breakdown for selected member */}
            {selectedSummary.items.length > 0 && (
              <div className="border-t border-gray-100 dark:border-gray-700/50 px-4 py-3 flex flex-col gap-1.5">
                <p className="text-[10px] font-semibold text-gray-400 uppercase tracking-wide mb-1">รายการที่สั่ง</p>
                {selectedSummary.items.map(({ item, amount }) => (
                  <div key={item.id} className="flex items-center justify-between">
                    <span className="text-sm text-gray-600 dark:text-gray-300 truncate flex-1">{item.name}</span>
                    <span className="text-sm font-semibold text-gray-800 dark:text-gray-200 flex-shrink-0 ml-2">
                      {formatNumber(amount)} บาท
                    </span>
                  </div>
                ))}
                <div className="border-t border-gray-100 dark:border-gray-700/50 pt-1.5 mt-0.5 flex items-center justify-between">
                  <span className="text-xs font-semibold text-gray-500 dark:text-gray-400">รวม (รวม VAT/SC)</span>
                  <span className="text-sm font-bold text-gray-900 dark:text-white">
                    {formatNumber(selectedSummary.total)} บาท
                  </span>
                </div>
              </div>
            )}
          </div>

          {/* ── Debts for selected member (who they owe) ──────── */}
          {myDebts.length > 0 && (
            <div className="flex flex-col gap-2">
              <h3 className="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wide px-1">
                {selectedSummary.member.user_id === currentUserId ? "ฉันต้องโอนให้" : `${selectedSummary.member.name} ต้องโอนให้`}
              </h3>
              <div className="flex flex-col gap-2">
                {myDebts.map(({ from, to, amount }) => {
                  const qrKey = `${from.id}-${to.id}`;
                  const isExpanded = expandedQR === qrKey;
                  const isMemberPaid = paidIds.includes(from.id);
                  return (
                    <div
                      key={qrKey}
                      className={`rounded-2xl overflow-hidden transition-colors ${
                        isMemberPaid
                          ? "bg-emerald-50 dark:bg-emerald-900/20 border border-emerald-200 dark:border-emerald-800"
                          : "bg-gray-50 dark:bg-gray-800/60"
                      }`}
                    >
                      <div className="flex items-center gap-3 px-4 py-3">
                        {/* From */}
                        <div
                          className="w-8 h-8 rounded-full flex items-center justify-center text-white text-[11px] font-bold flex-shrink-0"
                          style={{ backgroundColor: from.color }}
                        >
                          {from.name.charAt(0).toUpperCase()}
                        </div>
                        <IoArrowForward size={14} className="text-gray-400 flex-shrink-0" />
                        {/* To */}
                        <div
                          className="w-8 h-8 rounded-full flex items-center justify-center text-white text-[11px] font-bold flex-shrink-0"
                          style={{ backgroundColor: to.color }}
                        >
                          {to.name.charAt(0).toUpperCase()}
                        </div>
                        <div className="flex-1 min-w-0">
                          <p className="text-sm font-semibold text-gray-900 dark:text-white truncate">{to.name}</p>
                          {to.promptpay && (
                            <p className="text-xs text-gray-400">พร้อมเพย์: {to.promptpay}</p>
                          )}
                        </div>
                        <div className="flex items-center gap-2 flex-shrink-0">
                          <p className={`text-base font-bold ${isMemberPaid ? "text-emerald-600 dark:text-emerald-400 line-through opacity-60" : "text-gray-900 dark:text-white"}`}>
                            {formatNumber(amount)} บาท
                          </p>
                          {to.promptpay && !isMemberPaid && (
                            <button
                              onClick={() => setExpandedQR(isExpanded ? null : qrKey)}
                              className={`w-8 h-8 flex items-center justify-center rounded-xl transition-colors ${
                                isExpanded
                                  ? "bg-[#4366f4] text-white"
                                  : "text-gray-400 hover:text-[#4366f4] hover:bg-blue-50 dark:hover:bg-blue-900/20"
                              }`}
                            >
                              {isExpanded ? <IoChevronUp size={15} /> : <IoQrCodeOutline size={15} />}
                            </button>
                          )}
                        </div>
                      </div>

                      {/* QR Code for this debt */}
                      {isExpanded && to.promptpay && !isMemberPaid && (
                        <div className="border-t border-gray-100 dark:border-gray-700/50">
                          <PromptPayQR promptpay={to.promptpay} amount={amount} name={to.name} />
                        </div>
                      )}

                      {/* จ่ายแล้ว button — only when bill is completed */}
                      {isCompleted && (
                        <div className="border-t border-gray-100 dark:border-gray-700/30 px-4 py-2.5 flex items-center justify-between">
                          {isMemberPaid ? (
                            <div className="flex items-center gap-1.5 text-emerald-600 dark:text-emerald-400">
                              <IoCheckmarkCircle size={15} />
                              <span className="text-xs font-semibold">จ่ายแล้ว</span>
                            </div>
                          ) : (
                            <div className="flex items-center gap-1.5 text-gray-400">
                              <IoEllipseOutline size={15} />
                              <span className="text-xs">ยังไม่ได้จ่าย</span>
                            </div>
                          )}
                          <button
                            onClick={() => handleTogglePaid(from.id)}
                            disabled={togglingId === from.id}
                            className={`flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-semibold transition-all disabled:opacity-60 ${
                              isMemberPaid
                                ? "bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600"
                                : "bg-emerald-500 hover:bg-emerald-600 text-white"
                            }`}
                          >
                            {togglingId === from.id ? (
                              <span className="w-3 h-3 border border-current border-t-transparent rounded-full animate-spin" />
                            ) : isMemberPaid ? (
                              "ยกเลิก"
                            ) : (
                              <>
                                <IoCheckmarkCircle size={12} /> จ่ายแล้ว
                              </>
                            )}
                          </button>
                        </div>
                      )}
                    </div>
                  );
                })}
              </div>
            </div>
          )}

          {/* No debts message */}
          {myDebts.length === 0 && debts.length > 0 && (
            <div className="bg-emerald-50 dark:bg-emerald-900/20 rounded-2xl px-4 py-3 flex items-center gap-2">
              <span className="text-lg">✅</span>
              <p className="text-sm font-medium text-emerald-700 dark:text-emerald-400">
                {selectedSummary.member.user_id === currentUserId
                  ? "คุณไม่ต้องโอนให้ใคร"
                  : `${selectedSummary.member.name} ไม่ต้องโอนให้ใคร`}
              </p>
            </div>
          )}
        </div>
      )}

      {/* ── All members overview (collapsed) ────────────────── */}
      <AllMembersSection
        calc={calc}
        debts={debts}
        currency={currency}
        currentUserId={currentUserId}
        paidIds={paidIds}
        isCompleted={isCompleted}
        onTogglePaid={handleTogglePaid}
        togglingId={togglingId}
      />
    </div>
  );
}

// ── All members collapsible section ──────────────────────────
function AllMembersSection({
  calc,
  debts,
  currency,
  currentUserId,
  paidIds,
  isCompleted,
  onTogglePaid,
  togglingId,
}: {
  calc: ReturnType<typeof calculateBill>;
  debts: ReturnType<typeof simplifyDebtsPerItem>;
  currency: string;
  currentUserId?: string | null;
  paidIds: string[];
  isCompleted: boolean;
  onTogglePaid: (memberId: string) => void;
  togglingId: string | null;
}) {
  const [open, setOpen] = useState(false);
  const [expandedQR, setExpandedQR] = useState<string | null>(null);

  return (
    <div className="flex flex-col gap-2">
      <button
        onClick={() => setOpen((v) => !v)}
        className="flex items-center justify-between px-1 py-1 group"
      >
        <h3 className="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wide">
          สรุปทุกคน
        </h3>
        <span className="text-gray-400 group-hover:text-gray-600 dark:group-hover:text-gray-300 transition-colors">
          {open ? <IoChevronUp size={14} /> : <IoChevronDown size={14} />}
        </span>
      </button>

      {open && (
        <>
          {/* Debt arrows */}
          {debts.length > 0 && (
            <div className="flex flex-col gap-2 mb-1">
              <p className="text-[10px] font-semibold text-gray-400 uppercase tracking-wide px-1">ใครโอนให้ใคร</p>
              <div className="bg-gray-50 dark:bg-gray-800/60 rounded-2xl p-4 flex flex-col gap-3">
                {debts.map(({ from, to, amount }: { from: BillMember; to: BillMember; amount: number }) => {
                  const isPaid = paidIds.includes(from.id);
                  return (
                    <div key={`${from.id}-${to.id}`} className="flex items-center gap-2">
                      <div
                        className="w-7 h-7 rounded-full flex items-center justify-center text-white text-[10px] font-bold flex-shrink-0"
                        style={{ backgroundColor: from.color }}
                      >
                        {from.name.charAt(0).toUpperCase()}
                      </div>
                      <span className={`text-sm font-medium truncate ${isPaid ? "text-gray-400 line-through" : "text-gray-700 dark:text-gray-300"}`}>{from.name}</span>
                      <IoArrowForward size={14} className="text-gray-400 flex-shrink-0" />
                      <div
                        className="w-7 h-7 rounded-full flex items-center justify-center text-white text-[10px] font-bold flex-shrink-0"
                        style={{ backgroundColor: to.color }}
                      >
                        {to.name.charAt(0).toUpperCase()}
                      </div>
                      <span className={`text-sm font-medium truncate ${isPaid ? "text-gray-400 line-through" : "text-gray-700 dark:text-gray-300"}`}>{to.name}</span>
                      <span className={`text-sm font-bold ml-auto flex-shrink-0 ${isPaid ? "text-emerald-500 line-through opacity-60" : "text-gray-900 dark:text-white"}`}>
                        {formatNumber(amount)} บาท
                      </span>
                      {isPaid && (
                        <IoCheckmarkCircle size={14} className="text-emerald-500 flex-shrink-0" />
                      )}
                    </div>
                  );
                })}
              </div>
            </div>
          )}

          {/* Per-member breakdown */}
          <div className="flex flex-col gap-2">
            {calc.memberSummaries.map(({ member, total, items }) => {
              const isPaid = paidIds.includes(member.id);
              return (
                <div
                  key={member.id}
                  className={`rounded-2xl overflow-hidden transition-colors ${
                    isPaid
                      ? "bg-emerald-50 dark:bg-emerald-900/20 border border-emerald-200 dark:border-emerald-800"
                      : "bg-gray-50 dark:bg-gray-800/60"
                  }`}
                >
                  <div className="flex items-center gap-3 px-4 py-3">
                    <div
                      className="w-9 h-9 rounded-full flex items-center justify-center text-white text-sm font-bold flex-shrink-0"
                      style={{ backgroundColor: member.color }}
                    >
                      {member.name.charAt(0).toUpperCase()}
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-1.5 flex-wrap">
                        <p className="text-sm font-semibold text-gray-900 dark:text-white">{member.name}</p>
                        {member.is_external && (
                          <span className="text-[10px] px-1.5 py-0.5 bg-gray-200 dark:bg-gray-700 text-gray-500 rounded-full">
                            ภายนอก
                          </span>
                        )}
                        {member.user_id === currentUserId && (
                          <span className="text-[10px] px-1.5 py-0.5 bg-blue-50 dark:bg-blue-900/30 text-[#4366f4] rounded-full font-semibold">
                            คุณ
                          </span>
                        )}
                        {isPaid && (
                          <span className="flex items-center gap-0.5 text-[10px] px-1.5 py-0.5 bg-emerald-100 dark:bg-emerald-900/30 text-emerald-600 dark:text-emerald-400 rounded-full font-semibold">
                            <IoCheckmarkCircle size={9} /> จ่ายแล้ว
                          </span>
                        )}
                      </div>
                      {member.promptpay && (
                        <p className="text-xs text-gray-400">พร้อมเพย์: {member.promptpay}</p>
                      )}
                    </div>
                    <div className="text-right flex items-center gap-2">
                      <div>
                        <p className={`text-base font-bold ${isPaid ? "text-emerald-600 dark:text-emerald-400" : "text-gray-900 dark:text-white"}`}>
                          {formatNumber(total)} บาท
                        </p>
                        <p className="text-[10px] text-gray-400">{getTotalEmoji(total)}</p>
                      </div>
                      {member.promptpay && !isPaid && (
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

                  {expandedQR === member.id && member.promptpay && !isPaid && (
                    <div className="border-t border-gray-100 dark:border-gray-700/50">
                      <PromptPayQR promptpay={member.promptpay} amount={total} name={member.name} />
                    </div>
                  )}

                  {/* จ่ายแล้ว toggle — only when bill is completed */}
                  {isCompleted && debts.some((d) => d.from.id === member.id) && (
                    <div className="border-t border-gray-100 dark:border-gray-700/30 px-4 py-2.5 flex items-center justify-between">
                      {isPaid ? (
                        <div className="flex items-center gap-1.5 text-emerald-600 dark:text-emerald-400">
                          <IoCheckmarkCircle size={14} />
                          <span className="text-xs font-semibold">จ่ายแล้ว</span>
                        </div>
                      ) : (
                        <div className="flex items-center gap-1.5 text-gray-400">
                          <IoEllipseOutline size={14} />
                          <span className="text-xs">ยังไม่ได้จ่าย</span>
                        </div>
                      )}
                      <button
                        onClick={() => onTogglePaid(member.id)}
                        disabled={togglingId === member.id}
                        className={`flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-semibold transition-all disabled:opacity-60 ${
                          isPaid
                            ? "bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600"
                            : "bg-emerald-500 hover:bg-emerald-600 text-white"
                        }`}
                      >
                        {togglingId === member.id ? (
                          <span className="w-3 h-3 border border-current border-t-transparent rounded-full animate-spin" />
                        ) : isPaid ? (
                          "ยกเลิก"
                        ) : (
                          <>
                            <IoCheckmarkCircle size={12} /> จ่ายแล้ว
                          </>
                        )}
                      </button>
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
              );
            })}
          </div>
        </>
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
