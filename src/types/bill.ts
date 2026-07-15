export const CURRENCIES = [
  'THB', 'USD', 'EUR', 'JPY', 'GBP', 'SGD', 'CNY', 'KRW', 'AUD', 'HKD', 'MYR',
] as const
export type Currency = (typeof CURRENCIES)[number]

/**
 * Bill status. The database uses draft | pending_payment | completed;
 * the UI/spec talks about draft | open | settled. We keep the DB values as
 * the source of truth and map labels in the UI layer.
 */
export type BillStatus = 'draft' | 'pending_payment' | 'completed'

export interface BillSettings {
  serviceCharge: number // percent
  vat: number // percent
  isService: boolean
  isVat: boolean
  roundingMode?: 'none' | 'up' | 'down'
  currency: Currency
}

export interface BillMemberProfile {
  avatarUrl: string | null
}

export interface BillMember {
  id: string
  billId: string
  userId: string | null // null = external guest
  name: string
  color: string
  promptpay: string | null
  isExternal: boolean
  profile?: BillMemberProfile
}

export interface BillItem {
  id: string
  billId: string
  name: string
  price: number
  quantity: number
  memberIds: string[]
  customShares: Record<string, number> // memberId -> weight
  paidBy: string | null // bill_member.id who fronted this item
}

export interface Bill {
  id: string
  title: string
  emoji: string
  tags: string[]
  status: BillStatus
  ownerId: string
  groupId: string | null
  settings: BillSettings
  tip: number
  discount: number
  paidMemberIds: string[]
  total: number
  itemCount: number
  members: BillMember[]
  items: BillItem[]
  createdAt: string
  updatedAt: string
}

// ---- Calculation result shapes ----

export interface MemberItemShare {
  item: BillItem
  amount: number
}

export interface MemberSummary {
  member: BillMember
  total: number
  items: MemberItemShare[]
}

export interface BillCalculation {
  subtotal: number
  serviceAmount: number
  vatAmount: number
  tipAmount: number
  discountAmount: number
  total: number
  memberSummaries: MemberSummary[]
}

export interface DebtTransaction {
  from: BillMember
  to: BillMember
  amount: number
}
