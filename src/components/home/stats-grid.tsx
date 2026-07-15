'use client'

import { useTranslations } from 'next-intl'
import { formatNumber } from '@/lib/utils/format'

interface StatsGridProps {
  bills: number
  total: number
  groups: number
  friends: number
}

export function StatsGrid({ bills, total, groups, friends }: StatsGridProps) {
  const t = useTranslations('home')
  const stats = [
    { label: t('stats_bills'), value: bills.toString() },
    { label: t('stats_total'), value: `฿${formatNumber(total)}` },
    { label: t('stats_groups'), value: groups.toString() },
    { label: t('stats_friends'), value: friends.toString() },
  ]
  return (
    <div className="grid grid-cols-4 gap-2">
      {stats.map((s) => (
        <div key={s.label} className="card-surface flex flex-col items-center gap-0.5 p-3">
          <span className="amount text-lg font-bold">{s.value}</span>
          <span className="text-[10px] text-muted-foreground">{s.label}</span>
        </div>
      ))}
    </div>
  )
}
