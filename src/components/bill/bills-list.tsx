'use client'

import { useEffect, useMemo, useState } from 'react'
import { Plus } from 'lucide-react'
import { useTranslations } from 'next-intl'
import { Link } from '@/i18n/navigation'
import { BillCard } from '@/components/bill/bill-card'
import { AnimatedList } from '@/components/magic/animated-list'
import { ShimmerButton } from '@/components/magic/shimmer-button'
import { Tabs, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { useBillsStore } from '@/stores/bills-store'
import { createClient } from '@/lib/supabase/client'
import type { Bill, BillStatus } from '@/types/bill'

const FILTERS: { key: string; status: BillStatus | 'all' }[] = [
  { key: 'filter_all', status: 'all' },
  { key: 'status_draft', status: 'draft' },
  { key: 'status_open', status: 'pending_payment' },
  { key: 'status_settled', status: 'completed' },
]

export function BillsList({ initialBills }: { initialBills: Bill[] }) {
  const t = useTranslations('bills')
  const { setBills, list } = useBillsStore()
  const [filter, setFilter] = useState<BillStatus | 'all'>('all')

  useEffect(() => {
    setBills(initialBills)
  }, [initialBills, setBills])

  // Realtime sync
  useEffect(() => {
    const supabase = createClient()
    const channel = supabase
      .channel('bills-list')
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'bills' },
        () => {
          // A full refetch keeps joined members/items consistent.
          window.location.reload()
        }
      )
      .subscribe()
    return () => {
      supabase.removeChannel(channel)
    }
  }, [])

  const bills = list()
  const filtered = useMemo(
    () => (filter === 'all' ? bills : bills.filter((b) => b.status === filter)),
    [bills, filter]
  )

  return (
    <div className="flex flex-col gap-4">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">{t('title')}</h1>
        <Link href="/bills/create">
          <ShimmerButton className="px-4 py-2">
            <Plus className="h-4 w-4" /> {t('create_title')}
          </ShimmerButton>
        </Link>
      </div>

      <Tabs value={filter} onValueChange={(v) => setFilter(v as BillStatus | 'all')}>
        <TabsList className="w-full">
          {FILTERS.map((f) => (
            <TabsTrigger key={f.status} value={f.status} className="flex-1">
              {t(f.key)}
            </TabsTrigger>
          ))}
        </TabsList>
      </Tabs>

      {filtered.length === 0 ? (
        <p className="py-16 text-center text-sm text-muted-foreground">{t('empty_title')}</p>
      ) : (
        <AnimatedList className="gap-3">
          {filtered.map((bill) => (
            <BillCard key={bill.id} bill={bill} />
          ))}
        </AnimatedList>
      )}
    </div>
  )
}
