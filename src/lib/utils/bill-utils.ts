import type {
  Bill,
  BillCalculation,
  BillItem,
  BillMember,
  DebtTransaction,
  MemberItemShare,
  MemberSummary,
} from '@/types/bill'

const EPS = 0.005

/** Resolve the per-member weights for an item (equal split unless customShares set). */
export function splitWeights(item: BillItem): Record<string, number> {
  if (item.customShares && Object.keys(item.customShares).length > 0) {
    return item.customShares
  }
  return Object.fromEntries((item.memberIds ?? []).map((id) => [id, 1]))
}

/** Full bill calculation: totals + per-member breakdown. */
export function calculateBill(bill: Bill): BillCalculation {
  const subtotal = bill.items.reduce((sum, item) => sum + item.price, 0)
  const serviceAmount = subtotal * ((bill.settings.serviceCharge || 0) / 100)
  const vatBase = subtotal + serviceAmount
  const vatAmount = vatBase * ((bill.settings.vat || 0) / 100)
  const tipAmount = bill.tip || 0
  const discountAmount = bill.discount || 0
  const total = subtotal + serviceAmount + vatAmount + tipAmount - discountAmount
  const multiplier = subtotal > 0 ? total / subtotal : 1

  const memberSummaries: MemberSummary[] = bill.members.map((member) => {
    let rawTotal = 0
    const itemShares: MemberItemShare[] = []

    for (const item of bill.items) {
      const weights = splitWeights(item)
      if (!weights[member.id]) continue
      const totalWeight = Object.values(weights).reduce((s, w) => s + w, 0)
      if (totalWeight <= 0) continue
      const rawAmount = (weights[member.id] / totalWeight) * item.price
      rawTotal += rawAmount
      itemShares.push({ item, amount: rawAmount * multiplier })
    }

    return { member, total: rawTotal * multiplier, items: itemShares }
  })

  return { subtotal, serviceAmount, vatAmount, tipAmount, discountAmount, total, memberSummaries }
}

/**
 * Minimum-transactions debt simplification for a single bill.
 * Mode 1 (per-item paidBy): whoever fronted each item is credited.
 * Mode 2 (no paidBy): the owner (or first member) fronted everything.
 */
export function simplifyDebts(
  summaries: MemberSummary[],
  members: BillMember[],
  excludeMemberId?: string,
  ownerUserId?: string
): DebtTransaction[] {
  const net: Record<string, number> = {}
  members.forEach((m) => (net[m.id] = 0))

  const hasPaidBy = summaries.some((s) => s.items.some((i) => i.item.paidBy))

  if (hasPaidBy) {
    for (const summary of summaries) {
      for (const itemShare of summary.items) {
        const payerId = itemShare.item.paidBy
        if (!payerId || payerId === summary.member.id) continue
        net[summary.member.id] -= itemShare.amount
        net[payerId] = (net[payerId] ?? 0) + itemShare.amount
      }
    }
  } else {
    const payer = members.find((m) => m.userId === ownerUserId) ?? members[0]
    if (!payer) return []
    for (const summary of summaries) {
      if (summary.member.id === payer.id || summary.total <= 0) continue
      net[summary.member.id] -= summary.total
      net[payer.id] += summary.total
    }
  }

  return settleNet(net, members, excludeMemberId)
}

/** Greedy minimum-transaction settlement over a net-balance map keyed by member id. */
function settleNet(
  net: Record<string, number>,
  members: BillMember[],
  excludeMemberId?: string
): DebtTransaction[] {
  const byId = (id: string) => members.find((m) => m.id === id)!

  const debtors = Object.entries(net)
    .filter(([id, amt]) => id !== excludeMemberId && amt < -EPS)
    .map(([id, amt]) => ({ member: byId(id), amount: -amt }))
    .sort((a, b) => b.amount - a.amount)

  const creditors = Object.entries(net)
    .filter(([id, amt]) => id !== excludeMemberId && amt > EPS)
    .map(([id, amt]) => ({ member: byId(id), amount: amt }))
    .sort((a, b) => b.amount - a.amount)

  const debts: DebtTransaction[] = []
  let di = 0
  let ci = 0
  while (di < debtors.length && ci < creditors.length) {
    const transfer = Math.min(debtors[di].amount, creditors[ci].amount)
    if (transfer > EPS) {
      debts.push({ from: debtors[di].member, to: creditors[ci].member, amount: transfer })
    }
    debtors[di].amount -= transfer
    creditors[ci].amount -= transfer
    if (debtors[di].amount < EPS) di++
    if (creditors[ci].amount < EPS) ci++
  }
  return debts
}

/**
 * Settle a net-balance map keyed by userId across bills. Produces synthetic
 * BillMember-shaped nodes so downstream UI can render avatars/names uniformly.
 */
export function simplifyNetBalance(
  netBalance: Record<string, number>,
  groupMembers: { userId: string; name: string; avatarUrl?: string }[]
): DebtTransaction[] {
  const toMember = (userId: string): BillMember => {
    const gm = groupMembers.find((g) => g.userId === userId)
    return {
      id: userId,
      billId: '',
      userId,
      name: gm?.name ?? 'Unknown',
      color: '#3b82f6',
      promptpay: null,
      isExternal: false,
      profile: { avatarUrl: gm?.avatarUrl ?? null },
    }
  }

  const members = Object.keys(netBalance).map(toMember)
  const netById: Record<string, number> = {}
  members.forEach((m) => (netById[m.id] = netBalance[m.id] ?? 0))
  return settleNet(netById, members)
}

/** Aggregate net balances across all non-settled bills in a group. */
export function calculateGroupSettlement(
  bills: Bill[],
  groupMembers: { userId: string; name: string; avatarUrl?: string }[]
): DebtTransaction[] {
  const netBalance: Record<string, number> = {}
  groupMembers.forEach((m) => (netBalance[m.userId] = 0))

  for (const bill of bills) {
    if (bill.status === 'completed') continue
    const calc = calculateBill(bill)
    const debts = simplifyDebts(calc.memberSummaries, bill.members, undefined, bill.ownerId)
    for (const debt of debts) {
      const fromUserId = debt.from.userId
      const toUserId = debt.to.userId
      if (!fromUserId || !toUserId) continue
      netBalance[fromUserId] = (netBalance[fromUserId] ?? 0) - debt.amount
      netBalance[toUserId] = (netBalance[toUserId] ?? 0) + debt.amount
    }
  }

  return simplifyNetBalance(netBalance, groupMembers)
}

export interface MyDebtEntry {
  userId: string
  name: string
  avatarUrl?: string
  promptpay?: string | null
  amount: number
  billCount: number
}

/** Net a user's debts across every open bill, split into owe / owed-to-me. */
export function calculateMyDebts(
  bills: Bill[],
  myUserId: string
): { iOwe: MyDebtEntry[]; owedToMe: MyDebtEntry[] } {
  const owe: Record<string, MyDebtEntry> = {}
  const recv: Record<string, MyDebtEntry> = {}

  for (const bill of bills) {
    if (bill.status !== 'pending_payment') continue
    const calc = calculateBill(bill)
    const debts = simplifyDebts(calc.memberSummaries, bill.members, undefined, bill.ownerId)

    for (const debt of debts) {
      if (debt.from.userId === myUserId && debt.to.userId) {
        const key = debt.to.userId
        owe[key] = {
          userId: key,
          name: debt.to.name,
          avatarUrl: debt.to.profile?.avatarUrl ?? undefined,
          promptpay: debt.to.promptpay,
          amount: (owe[key]?.amount ?? 0) + debt.amount,
          billCount: (owe[key]?.billCount ?? 0) + 1,
        }
      } else if (debt.to.userId === myUserId && debt.from.userId) {
        const key = debt.from.userId
        recv[key] = {
          userId: key,
          name: debt.from.name,
          avatarUrl: debt.from.profile?.avatarUrl ?? undefined,
          promptpay: debt.from.promptpay,
          amount: (recv[key]?.amount ?? 0) + debt.amount,
          billCount: (recv[key]?.billCount ?? 0) + 1,
        }
      }
    }
  }

  return { iOwe: Object.values(owe), owedToMe: Object.values(recv) }
}

export function getTotalEmoji(total: number): string {
  if (total < 100) return '🤏'
  if (total < 500) return '💸'
  if (total < 1000) return '💰'
  if (total < 3000) return '🤑'
  return '🏦'
}
