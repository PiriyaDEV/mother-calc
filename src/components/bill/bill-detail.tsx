'use client'

import { useCallback, useEffect, useState } from 'react'
import { ArrowLeft, Trash2 } from 'lucide-react'
import { useTranslations } from 'next-intl'
import { useRouter } from '@/i18n/navigation'
import { createClient } from '@/lib/supabase/client'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Button } from '@/components/ui/button'
import { StatusBadge } from '@/components/shared/status-badge'
import { toast } from '@/components/ui/toast'
import { MembersTab } from '@/components/bill/members-tab'
import { ItemsTab } from '@/components/bill/items-tab'
import { SummaryTab } from '@/components/bill/summary-tab'
import { AnalyticsTab } from '@/components/bill/analytics-tab'
import type { Bill, BillStatus } from '@/types/bill'
import { fetchBill } from '@/repositories/bills-repository'

interface BillDetailProps {
  initialBill: Bill
  myUserId: string
  initialTab: string
}

const TABS = [
  { id: 'members', key: 'tab_members' },
  { id: 'items', key: 'tab_items' },
  { id: 'summary', key: 'tab_summary' },
  { id: 'analytics', key: 'tab_analytics' },
]

export function BillDetail({ initialBill, myUserId, initialTab }: BillDetailProps) {
  const t = useTranslations('bills')
  const router = useRouter()
  const [bill, setBill] = useState(initialBill)
  const [tab, setTab] = useState(TABS.some((x) => x.id === initialTab) ? initialTab : 'members')

  const supabase = createClient()

  const reload = useCallback(async () => {
    const fresh = await fetchBill(supabase, bill.id).catch(() => null)
    if (fresh) setBill(fresh)
  }, [supabase, bill.id])

  useEffect(() => {
    const url = new URL(window.location.href)
    url.searchParams.set('tab', tab)
    window.history.replaceState({}, '', url)
  }, [tab])

  const editable = bill.status !== 'completed'

  async function advanceStatus(next: BillStatus) {
    const { error } = await supabase.from('bills').update({ status: next }).eq('id', bill.id)
    if (error) return toast(error.message, 'error')
    setBill({ ...bill, status: next })
  }

  async function deleteBill() {
    const { error } = await supabase.from('bills').delete().eq('id', bill.id)
    if (error) return toast(error.message, 'error')
    router.push('/bills')
    router.refresh()
  }

  return (
    <div className="flex flex-col gap-4">
      <div className="flex items-center gap-2">
        <button onClick={() => router.push('/bills')} className="rounded-full p-2 hover:bg-muted">
          <ArrowLeft className="h-5 w-5" />
        </button>
        <span className="text-3xl">{bill.emoji}</span>
        <div className="min-w-0 flex-1">
          <h1 className="truncate text-xl font-bold">{bill.title}</h1>
        </div>
        <StatusBadge status={bill.status} />
      </div>

      <Tabs value={tab} onValueChange={setTab}>
        <TabsList className="w-full">
          {TABS.map((x) => (
            <TabsTrigger key={x.id} value={x.id} className="flex-1 text-xs">
              {t(x.key)}
            </TabsTrigger>
          ))}
        </TabsList>

        <TabsContent value="members">
          <MembersTab bill={bill} myUserId={myUserId} editable={editable} onChange={reload} />
        </TabsContent>
        <TabsContent value="items">
          <ItemsTab bill={bill} editable={editable} onChange={reload} />
        </TabsContent>
        <TabsContent value="summary">
          <SummaryTab bill={bill} myUserId={myUserId} onChange={reload} />
        </TabsContent>
        <TabsContent value="analytics">
          <AnalyticsTab bill={bill} />
        </TabsContent>
      </Tabs>

      <div className="mt-2 flex flex-col gap-2">
        {bill.status === 'draft' && (
          <Button onClick={() => advanceStatus('pending_payment')} size="lg">
            {t('send_bill')}
          </Button>
        )}
        {bill.status === 'pending_payment' && (
          <Button onClick={() => advanceStatus('completed')} size="lg">
            {t('close_bill')}
          </Button>
        )}
        <Button onClick={deleteBill} variant="destructive">
          <Trash2 className="h-4 w-4" /> {t('delete_bill')}
        </Button>
      </div>
    </div>
  )
}
