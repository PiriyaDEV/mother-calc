import { Bill, BillItem, BillMember, BillCalculation, MemberSummary, Settings, CurrencyCode } from "./types";
import { DEFAULT_SETTINGS } from "./constants";

// ── Currency formatting ────────────────────────────────────────
export const CURRENCY_SYMBOLS: Record<CurrencyCode, string> = {
  THB: "฿",
  USD: "$",
  EUR: "€",
  JPY: "¥",
  SGD: "S$",
  GBP: "£",
  CNY: "¥",
  KRW: "₩",
};

export function formatCurrency(amount: number, currency: CurrencyCode = "THB"): string {
  const symbol = CURRENCY_SYMBOLS[currency] ?? "฿";
  const decimals = currency === "JPY" || currency === "KRW" ? 0 : 2;
  return `${symbol}${amount.toFixed(decimals).replace(/\B(?=(\d{3})+(?!\d))/g, ",")}`;
}

// ── Rounding ───────────────────────────────────────────────────
export function applyRounding(amount: number, mode: Settings["roundingMode"]): number {
  switch (mode) {
    case "up":      return Math.ceil(amount);
    case "down":    return Math.floor(amount);
    case "nearest": return Math.round(amount);
    default:        return amount;
  }
}

// ── Bill total ─────────────────────────────────────────────────
export function getBillTotal(bill: Bill): number {
  const calc = calculateBill(bill);
  return calc.total;
}

// ── Main bill calculation ──────────────────────────────────────
export function calculateBill(bill: Bill): BillCalculation {
  const members = bill.members ?? [];
  const items = bill.items ?? [];
  const settings = bill.settings ?? DEFAULT_SETTINGS;
  const tip = bill.tip ?? 0;
  const discount = bill.discount ?? 0;

  // Subtotal = sum of all item prices
  const subtotal = items.reduce((sum, item) => sum + item.price, 0);

  // Service charge applies to subtotal
  const serviceAmount = settings.isService
    ? subtotal * (settings.serviceCharge / 100)
    : 0;

  // VAT applies to subtotal + service
  const vatBase = subtotal + serviceAmount;
  const vatAmount = settings.isVat ? vatBase * (settings.vat / 100) : 0;

  const discountAmount = discount;
  const tipAmount = tip;

  const rawTotal = subtotal + serviceAmount + vatAmount + tipAmount - discountAmount;
  const total = applyRounding(rawTotal, settings.roundingMode);

  // ── Per-member calculation ──────────────────────────────────
  // For each item, distribute cost among members based on shares
  const memberTotals: Record<string, number> = {};
  const memberSubtotals: Record<string, number> = {};
  const memberItems: Record<string, { item: BillItem; amount: number }[]> = {};

  for (const member of members) {
    memberTotals[member.id] = 0;
    memberSubtotals[member.id] = 0;
    memberItems[member.id] = [];
  }

  for (const item of items) {
    const shares = item.shares ?? {};
    const shareEntries = Object.entries(shares);
    if (shareEntries.length === 0) continue;

    const totalWeight = shareEntries.reduce((sum, [, w]) => sum + w, 0);
    if (totalWeight === 0) continue;

    for (const [memberId, weight] of shareEntries) {
      if (!(memberId in memberSubtotals)) continue;
      const itemShare = (item.price * weight) / totalWeight;
      memberSubtotals[memberId] += itemShare;
      if (!memberItems[memberId]) memberItems[memberId] = [];
      memberItems[memberId].push({ item, amount: itemShare });
    }
  }

  // Apply tax/service/tip/discount proportionally
  const multiplier = subtotal > 0 ? total / subtotal : 1;

  for (const memberId of Object.keys(memberTotals)) {
    memberTotals[memberId] = applyRounding(
      memberSubtotals[memberId] * multiplier,
      settings.roundingMode
    );
  }

  const memberSummaries: MemberSummary[] = members.map((member) => ({
    member,
    subtotal: memberSubtotals[member.id] ?? 0,
    total: memberTotals[member.id] ?? 0,
    items: memberItems[member.id] ?? [],
  }));

  return {
    subtotal,
    vatAmount,
    serviceAmount,
    tipAmount,
    discountAmount,
    total,
    memberSummaries,
  };
}

// ── Debt simplification ────────────────────────────────────────
export interface DebtTransaction {
  from: BillMember;
  to: BillMember;
  amount: number;
}

export function simplifyDebts(
  memberSummaries: MemberSummary[],
  paidByMemberId?: string
): DebtTransaction[] {
  if (!paidByMemberId) return [];

  const payer = memberSummaries.find((s) => s.member.id === paidByMemberId);
  if (!payer) return [];

  const transactions: DebtTransaction[] = [];
  for (const summary of memberSummaries) {
    if (summary.member.id === paidByMemberId) continue;
    if (summary.total <= 0) continue;
    transactions.push({
      from: summary.member,
      to: payer.member,
      amount: summary.total,
    });
  }
  return transactions;
}

// ── Username validation ────────────────────────────────────────
export function isValidUsername(username: string): boolean {
  return /^[a-z0-9_]{3,30}$/.test(username);
}

export function formatUsername(username: string): string {
  return `@${username}`;
}
