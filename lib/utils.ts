import {
  BillItem,
  BillState,
  DebtMatrix,
  DebtTransaction,
  Member,
  MemberSummary,
} from "./types";
import { THAI_ID_REGEX, THAI_PHONE_REGEX } from "./constants";

// ============================================================
// Price Calculation
// ============================================================

/** คำนวณราคาสุทธิของ item (รวม VAT และ Service Charge) */
export function getItemNetAmount(item: BillItem): number {
  let amount = item.totalAmount;
  if (item.isService) {
    amount = amount * (1 + item.serviceCharge / 100);
  }
  if (item.isVat) {
    amount = amount * (1 + item.vat / 100);
  }
  return amount;
}

/** คำนวณ multiplier สำหรับ VAT+SC */
export function getItemMultiplier(item: BillItem): number {
  let m = 1;
  if (item.isService) m *= 1 + item.serviceCharge / 100;
  if (item.isVat) m *= 1 + item.vat / 100;
  return m;
}

/** คำนวณยอดที่ member คนนึงต้องจ่ายใน item นั้น (รวม VAT/SC แล้ว) */
export function getMemberAmountInItem(item: BillItem, memberId: string): number {
  const share = item.shares.find((s) => s.memberId === memberId);
  if (!share) return 0;
  const multiplier = getItemMultiplier(item);
  return share.amount * multiplier;
}

// ============================================================
// Summary Calculation
// ============================================================

export function calculateSummary(state: BillState): MemberSummary[] {
  const { members, items } = state;

  return members.map((member) => {
    let totalOwed = 0;
    let totalPaid = 0;

    items.forEach((item) => {
      const netAmount = getItemNetAmount(item);
      // ยอดที่ member คนนี้ต้องจ่าย
      totalOwed += getMemberAmountInItem(item, member.id);
      // ยอดที่ member คนนี้จ่ายแทนคนอื่น
      if (item.paidBy === member.id) {
        totalPaid += netAmount;
      }
    });

    return {
      memberId: member.id,
      memberName: member.name,
      color: member.color,
      totalOwed,
      totalPaid,
      netBalance: totalPaid - totalOwed,
    };
  });
}

// ============================================================
// Debt Matrix & Simplified Debt
// ============================================================

/** สร้าง debt matrix: debt[fromId][toId] = amount */
export function buildDebtMatrix(state: BillState): DebtMatrix {
  const { members, items } = state;
  const matrix: DebtMatrix = {};

  members.forEach((m) => {
    matrix[m.id] = {};
    members.forEach((n) => {
      if (m.id !== n.id) matrix[m.id][n.id] = 0;
    });
  });

  items.forEach((item) => {
    const paidBy = item.paidBy;
    item.shares.forEach((share) => {
      if (share.memberId === paidBy) return;
      const multiplier = getItemMultiplier(item);
      const amount = share.amount * multiplier;
      if (amount > 0) {
        matrix[share.memberId][paidBy] =
          (matrix[share.memberId][paidBy] || 0) + amount;
      }
    });
  });

  return matrix;
}

/** Simplify debts: หักลบหนี้ที่ตัดกันได้ */
export function simplifyDebts(
  matrix: DebtMatrix,
  members: Member[]
): DebtTransaction[] {
  // คำนวณ net balance ของแต่ละคน
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

  let i = 0,
    j = 0;
  while (i < debtors.length && j < creditors.length) {
    const debtor = debtors[i];
    const creditor = creditors[j];
    const amount = Math.min(-debtor.balance, creditor.balance);

    if (amount > 0.005) {
      transactions.push({
        fromId: debtor.id,
        fromName: debtor.name,
        toId: creditor.id,
        toName: creditor.name,
        toPromptpay: creditor.promptpay,
        amount: Math.round(amount * 100) / 100,
      });
    }

    debtor.balance += amount;
    creditor.balance -= amount;

    if (Math.abs(debtor.balance) < 0.005) i++;
    if (Math.abs(creditor.balance) < 0.005) j++;
  }

  return transactions;
}

// ============================================================
// Validation
// ============================================================

export function validatePromptpay(value: string): boolean {
  if (!value) return true; // optional
  return THAI_PHONE_REGEX.test(value) || THAI_ID_REGEX.test(value);
}

export function maskPromptpay(value: string): string {
  if (!value) return "";
  if (THAI_PHONE_REGEX.test(value)) {
    // 081-xxx-x678
    return value.slice(0, 3) + "-xxx-x" + value.slice(-3);
  }
  if (THAI_ID_REGEX.test(value)) {
    return value.slice(0, 1) + "-xxxx-xxxxx-" + value.slice(-2) + "-x";
  }
  return value;
}

// ============================================================
// URL State Encoding/Decoding
// ============================================================

export function encodeState(state: BillState): string {
  try {
    const json = JSON.stringify(state);
    return btoa(encodeURIComponent(json));
  } catch {
    return "";
  }
}

export function decodeState(encoded: string): BillState | null {
  try {
    const json = decodeURIComponent(atob(encoded));
    return JSON.parse(json) as BillState;
  } catch {
    return null;
  }
}

// ============================================================
// Formatting
// ============================================================

export function formatCurrency(amount: number): string {
  return amount.toLocaleString("th-TH", {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  });
}

export function generateId(): string {
  return Math.random().toString(36).slice(2, 10);
}
