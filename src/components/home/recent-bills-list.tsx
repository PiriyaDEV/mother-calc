'use client'

import { useTranslations } from 'next-intl'
import { Link } from '@/i18n/navigation'
import { BillCard } from '@/components/bill/bill-card'
import type { Bill } from '@/types/bill'

export function RecentBillsList({ bills }: { bills: Bill[] }) {
  const t = useTranslations('home')
  if (bills.length === 0) return null
  return (
    <div>
      <div className="mb-2 flex items-center justify-between">
        <h3 className="font-bold">{t('recent_bills')}</h3>
        <Link href="/bills" className="text-sm font-semibold text-primary">
          {t('view_all')}
        </Link>
      </div>
      <div className="flex flex-col gap-3">
        {bills.slice(0, 3).map((bill) => (
          <BillCard key={bill.id} bill={bill} />
        ))}
      </div>
    </div>
  )
}
