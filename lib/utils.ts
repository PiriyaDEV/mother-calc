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
  const decimals = currency === "JPY" || currency === "KRW" ? 0 : 2;
  const formatted = amount.toFixed(decimals).replace(/\B(?=(\d{3})+(?!\d))/g, ",");
  if (currency === "THB") {
    return `${formatted} บาท`;
  }
  const symbol = CURRENCY_SYMBOLS[currency] ?? "฿";
  return `${symbol}${formatted}`;
}

/** Format number with commas only (no currency symbol) */
export function formatNumber(amount: number, decimals = 2): string {
  return amount.toFixed(decimals).replace(/\B(?=(\d{3})+(?!\d))/g, ",");
}

/** Emoji reaction based on total amount */
export function getTotalEmoji(total: number): string {
  if (total >= 150_000) return "💀";
  if (total >= 100_000) return "🤯";
  if (total >= 50_000) return "😱";
  if (total >= 10_000) return "🤑";
  if (total >= 5_000) return "😵‍💫";
  if (total >= 3_000) return "🫠";
  if (total >= 1_000) return "😅";
  if (total >= 500) return "🥱";
  return "😍";
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

/**
 * Compute debts when each item may have its own paid_by.
 * Items without paid_by fall back to globalPaidById.
 * Returns net amounts: who owes whom.
 */
export function simplifyDebtsPerItem(
  memberSummaries: MemberSummary[],
  members: BillMember[],
  globalPaidById?: string | null
): DebtTransaction[] {
  // net[memberId] = how much they are owed (positive) or owe (negative)
  const net: Record<string, number> = {};
  for (const m of members) net[m.id] = 0;

  for (const summary of memberSummaries) {
    for (const { item, amount } of summary.items) {
      const payerId = item.paid_by ?? globalPaidById ?? null;
      if (!payerId) continue;
      if (payerId === summary.member.id) continue; // payer doesn't owe themselves
      // summary.member owes payerId `amount`
      net[summary.member.id] = (net[summary.member.id] ?? 0) - amount;
      net[payerId] = (net[payerId] ?? 0) + amount;
    }
  }

  // Simplify: match debtors with creditors
  const debtors = members
    .filter((m) => (net[m.id] ?? 0) < -0.005)
    .map((m) => ({ member: m, amount: -(net[m.id] ?? 0) }));
  const creditors = members
    .filter((m) => (net[m.id] ?? 0) > 0.005)
    .map((m) => ({ member: m, amount: net[m.id] ?? 0 }));

  const transactions: DebtTransaction[] = [];
  let di = 0;
  let ci = 0;
  while (di < debtors.length && ci < creditors.length) {
    const d = debtors[di];
    const c = creditors[ci];
    const amount = Math.min(d.amount, c.amount);
    if (amount > 0.005) {
      transactions.push({ from: d.member, to: c.member, amount });
    }
    d.amount -= amount;
    c.amount -= amount;
    if (d.amount < 0.005) di++;
    if (c.amount < 0.005) ci++;
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
