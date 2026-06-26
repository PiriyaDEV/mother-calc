// ============================================================
// Core Types for Kidtang Bill Splitting App
// ============================================================

export interface Member {
  id: string;
  name: string;
  color: string;
  promptpay?: string; // เบอร์โทร หรือ Thai ID 13 หลัก
}

export type SplitType = "equal" | "unequal";
export type RoundingMode = "none" | "up" | "down" | "nearest";
export type CurrencyCode = "THB" | "USD" | "EUR" | "JPY" | "SGD" | "GBP" | "CNY" | "KRW";

export interface ItemShare {
  memberId: string;
  amount: number; // จำนวนเงินที่แต่ละคนต้องจ่ายในรายการนี้ (ก่อน VAT/SC)
}

export interface BillItem {
  id: string;
  name: string;
  splitType: SplitType;
  totalAmount: number; // ราคารวมของรายการ (ก่อน VAT/SC)
  shares: ItemShare[]; // สัดส่วนของแต่ละคน
  selectedMemberIds: string[]; // สมาชิกที่ร่วมในรายการนี้ (สำหรับ equal split)
  paidBy: string; // memberId ของคนที่จ่ายเงินไปก่อน
  vat: number; // % VAT
  serviceCharge: number; // % Service Charge
  isVat: boolean;
  isService: boolean;
}

export interface Settings {
  vat: number;
  serviceCharge: number;
  isVat: boolean;
  isService: boolean;
  roundingMode: RoundingMode;
  currency: CurrencyCode;
}

export interface Bill {
  id: string;
  title: string;
  createdAt: number; // timestamp
  updatedAt: number; // timestamp
  members: Member[];
  items: BillItem[];
  settings: Settings;
  tip: number; // บาท (absolute amount)
  discount: number; // บาท (absolute amount)
}

// Legacy alias for single-bill usage
export type BillState = Bill;

// สำหรับ Summary
export interface MemberSummary {
  memberId: string;
  memberName: string;
  color: string;
  totalOwed: number; // ยอดที่ต้องจ่ายทั้งหมด
  totalPaid: number; // ยอดที่จ่ายไปแล้ว (paidBy)
  netBalance: number; // totalPaid - totalOwed (บวก = ได้คืน, ลบ = ต้องจ่าย)
}

// debt[from][to] = amount → "from" ต้องจ่าย "to" เท่าไหร่
export type DebtMatrix = Record<string, Record<string, number>>;

// Simplified debt transactions
export interface DebtTransaction {
  fromId: string;
  fromName: string;
  toId: string;
  toName: string;
  toPromptpay?: string;
  amount: number;
  isPaid?: boolean; // mark as paid
}

export type AppTab = "members" | "items" | "summary";

export interface AppState {
  bills: Bill[];
  activeBillId: string | null;
}

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
