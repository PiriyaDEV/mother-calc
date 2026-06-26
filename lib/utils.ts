import {
  Bill,
  BillItem,
  CurrencyCode,
  CURRENCY_SYMBOLS,
  DebtMatrix,
  DebtTransaction,
  Member,
  MemberSummary,
  RoundingMode,
} from "./types";
import { THAI_ID_REGEX, THAI_PHONE_REGEX } from "./constants";

// ============================================================
// Price Calculation
// ============================================================

/** คำนวณ multiplier สำหรับ VAT+SC */
export function getItemMultiplier(item: BillItem): number {
  let m = 1;
  if (item.isService) m *= 1 + item.serviceCharge / 100;
  if (item.isVat) m *= 1 + item.vat / 100;
  return m;
}

/** คำนวณราคาสุทธิของ item (รวม VAT และ Service Charge) */
export function getItemNetAmount(item: BillItem): number {
  return item.totalAmount * getItemMultiplier(item);
}

/** คำนวณยอดที่ member คนนึงต้องจ่ายใน item นั้น (รวม VAT/SC แล้ว) */
export function getMemberAmountInItem(item: BillItem, memberId: string): number {
  const share = item.shares.find((s) => s.memberId === memberId);
  if (!share) return 0;
  return share.amount * getItemMultiplier(item);
}

/** Apply rounding to a number */
export function applyRounding(amount: number, mode: RoundingMode): number {
  switch (mode) {
    case "up":
      return Math.ceil(amount);
    case "down":
      return Math.floor(amount);
    case "nearest":
      return Math.round(amount);
    default:
      return Math.round(amount * 100) / 100;
  }
}

// ============================================================
// Bill Total (including tip & discount)
// ============================================================

export function getBillSubtotal(bill: Bill): number {
  return bill.items.reduce((sum, item) => sum + getItemNetAmount(item), 0);
}

export function getBillTotal(bill: Bill): number {
  const subtotal = getBillSubtotal(bill);
  return Math.max(0, subtotal + (bill.tip || 0) - (bill.discount || 0));
}

// ============================================================
// Summary Calculation
// ============================================================

export function calculateSummary(bill: Bill): MemberSummary[] {
  const { members, items, tip = 0, discount = 0 } = bill;

  const subtotal = getBillSubtotal(bill);
  const adjustment = tip - discount; // can be negative

  return members.map((member) => {
    let totalOwed = 0;
    let totalPaid = 0;

    items.forEach((item) => {
      const netAmount = getItemNetAmount(item);
      totalOwed += getMemberAmountInItem(item, member.id);
      if (item.paidBy === member.id) {
        totalPaid += netAmount;
      }
    });

    // Distribute tip/discount proportionally
    if (subtotal > 0 && adjustment !== 0) {
      const ratio = totalOwed / subtotal;
      totalOwed += adjustment * ratio;
    }

    return {
      memberId: member.id,
      memberName: member.name,
      color: member.color,
      totalOwed: Math.max(0, totalOwed),
      totalPaid,
      netBalance: totalPaid - Math.max(0, totalOwed),
    };
  });
}

// ============================================================
// Debt Matrix & Simplified Debt
// ============================================================

export function buildDebtMatrix(bill: Bill): DebtMatrix {
  const { members, items, tip = 0, discount = 0 } = bill;
  const matrix: DebtMatrix = {};

  members.forEach((m) => {
    matrix[m.id] = {};
    members.forEach((n) => {
      if (m.id !== n.id) matrix[m.id][n.id] = 0;
    });
  });

  const subtotal = getBillSubtotal(bill);
  const adjustment = tip - discount;

  items.forEach((item) => {
    const paidBy = item.paidBy;
    item.shares.forEach((share) => {
      if (share.memberId === paidBy) return;
      const multiplier = getItemMultiplier(item);
      let amount = share.amount * multiplier;

      // Add proportional tip/discount
      if (subtotal > 0 && adjustment !== 0) {
        const itemNet = getItemNetAmount(item);
        const memberRatio = (share.amount * multiplier) / itemNet;
        const itemAdjustment = (itemNet / subtotal) * adjustment * memberRatio;
        amount += itemAdjustment;
      }

      if (amount > 0) {
        matrix[share.memberId][paidBy] =
          (matrix[share.memberId][paidBy] || 0) + amount;
      }
    });
  });

  return matrix;
}

export function simplifyDebts(
  matrix: DebtMatrix,
  members: Member[],
  roundingMode: RoundingMode = "none"
): DebtTransaction[] {
  const balance: Record<string, number> = {};
  members.forEach((m) => (balance[m.id] = 0));

  members.forEach((from) => {
    members.forEach((to) => {
      if (from.id === to.id) return;
      const amount = matrix[from.id]?.[to.id] || 0;
      if (amount > 0) {
        balance[from.id] -= amount;
        balance[to.id] += amount;
      }
    });
  });

  const creditors = members
    .filter((m) => balance[m.id] > 0.005)
    .map((m) => ({ ...m, balance: balance[m.id] }));
  const debtors = members
    .filter((m) => balance[m.id] < -0.005)
    .map((m) => ({ ...m, balance: balance[m.id] }));

  const transactions: DebtTransaction[] = [];
  let i = 0, j = 0;

  while (i < debtors.length && j < creditors.length) {
    const debtor = debtors[i];
    const creditor = creditors[j];
    const rawAmount = Math.min(-debtor.balance, creditor.balance);
    const amount = applyRounding(rawAmount, roundingMode);

    if (amount > 0.005) {
      transactions.push({
        fromId: debtor.id,
        fromName: debtor.name,
        toId: creditor.id,
        toName: creditor.name,
        toPromptpay: creditor.promptpay,
        amount,
        isPaid: false,
      });
    }

    debtor.balance += rawAmount;
    creditor.balance -= rawAmount;

    if (Math.abs(debtor.balance) < 0.005) i++;
    if (Math.abs(creditor.balance) < 0.005) j++;
  }

  return transactions;
}

// ============================================================
// Validation
// ============================================================

export function validatePromptpay(value: string): boolean {
  if (!value) return true;
  return THAI_PHONE_REGEX.test(value) || THAI_ID_REGEX.test(value);
}

export function maskPromptpay(value: string): string {
  if (!value) return "";
  if (THAI_PHONE_REGEX.test(value)) {
    return value.slice(0, 3) + "-xxx-x" + value.slice(-3);
  }
  if (THAI_ID_REGEX.test(value)) {
    return value.slice(0, 1) + "-xxxx-xxxxx-" + value.slice(-2) + "-x";
  }
  return value;
}

// ============================================================
// URL State Encoding/Decoding (with compression)
// ============================================================

export function encodeState(bill: Bill): string {
  try {
    const json = JSON.stringify(bill);
    return btoa(encodeURIComponent(json));
  } catch {
    return "";
  }
}

export function decodeState(encoded: string): Bill | null {
  try {
    const json = decodeURIComponent(atob(encoded));
    return JSON.parse(json) as Bill;
  } catch {
    return null;
  }
}

// ============================================================
// Formatting
// ============================================================

export function formatCurrency(amount: number, currency: CurrencyCode = "THB"): string {
  const symbol = CURRENCY_SYMBOLS[currency] || "฿";
  const decimals = currency === "JPY" || currency === "KRW" ? 0 : 2;
  const formatted = amount.toLocaleString("th-TH", {
    minimumFractionDigits: decimals,
    maximumFractionDigits: decimals,
  });
  return `${symbol}${formatted}`;
}

export function formatDate(timestamp: number): string {
  return new Date(timestamp).toLocaleDateString("th-TH", {
    day: "numeric",
    month: "short",
    year: "2-digit",
  });
}

export function generateId(): string {
  return Math.random().toString(36).slice(2, 10);
}
