import { create } from 'zustand'
import type { Bill } from '@/types/bill'

interface BillsStore {
  bills: Record<string, Bill>
  setBills: (bills: Bill[]) => void
  upsertBill: (bill: Bill) => void
  updateBill: (id: string, updates: Partial<Bill>) => void
  deleteBill: (id: string) => void
  list: () => Bill[]
  optimisticUpdate: <T>(
    id: string,
    update: Partial<Bill>,
    persist: () => Promise<T>
  ) => Promise<T>
}

export const useBillsStore = create<BillsStore>((set, get) => ({
  bills: {},
  setBills: (bills) =>
    set({ bills: Object.fromEntries(bills.map((b) => [b.id, b])) }),
  upsertBill: (bill) =>
    set((s) => ({ bills: { ...s.bills, [bill.id]: bill } })),
  updateBill: (id, updates) =>
    set((s) =>
      s.bills[id]
        ? { bills: { ...s.bills, [id]: { ...s.bills[id], ...updates } } }
        : s
    ),
  deleteBill: (id) =>
    set((s) => {
      const next = { ...s.bills }
      delete next[id]
      return { bills: next }
    }),
  list: () =>
    Object.values(get().bills).sort(
      (a, b) => +new Date(b.createdAt) - +new Date(a.createdAt)
    ),
  optimisticUpdate: async (id, update, persist) => {
    const prev = get().bills[id]
    set((s) => ({ bills: { ...s.bills, [id]: { ...prev, ...update } } }))
    try {
      return await persist()
    } catch (e) {
      if (prev) set((s) => ({ bills: { ...s.bills, [id]: prev } }))
      throw e
    }
  },
}))
