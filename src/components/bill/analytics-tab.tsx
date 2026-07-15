'use client'

import { useMemo } from 'react'
import { useTranslations } from 'next-intl'
import { BarChart, Bar, XAxis, ResponsiveContainer, Cell } from 'recharts'
import { calculateBill } from '@/lib/utils/bill-utils'
import { formatCurrency } from '@/lib/utils/format'
import type { Bill } from '@/types/bill'

export function AnalyticsTab({ bill }: { bill: Bill }) {
  const t = useTranslations('bills')
  const calc = useMemo(() => calculateBill(bill), [bill])

  if (bill.items.length === 0 || bill.members.length === 0) {
    return <p className="py-8 text-center text-sm text-muted-foreground">{t('no_items')}</p>
  }

  const summaries = [...calc.memberSummaries].sort((a, b) => b.total - a.total)
  const biggest = summaries[0]
  const frugal = summaries[summaries.length - 1]

  // top payer by fronted amount
  const paidByTotals: Record<string, number> = {}
  for (const item of bill.items) {
    if (item.paidBy) paidByTotals[item.paidBy] = (paidByTotals[item.paidBy] ?? 0) + item.price
  }
  const topPayerId = Object.entries(paidByTotals).sort((a, b) => b[1] - a[1])[0]?.[0]
  const topPayer = bill.members.find((m) => m.id === topPayerId)

  const topItems = [...bill.items].sort((a, b) => b.price - a.price).slice(0, 5)

  const chartData = summaries.map((s) => ({
    name: s.member.name,
    value: Math.round(s.total),
    color: s.member.color,
  }))

  return (
    <div className="flex flex-col gap-3">
      <div className="grid grid-cols-2 gap-3">
        <StatCard emoji="🏆" label={t('biggest_spender')} name={biggest?.member.name} value={formatCurrency(biggest?.total ?? 0, bill.settings.currency)} />
        <StatCard emoji="🥗" label={t('most_frugal')} name={frugal?.member.name} value={formatCurrency(frugal?.total ?? 0, bill.settings.currency)} />
        {topPayer && (
          <StatCard emoji="💸" label={t('top_payer')} name={topPayer.name} value={formatCurrency(paidByTotals[topPayerId] ?? 0, bill.settings.currency)} />
        )}
      </div>

      <div className="card-surface p-5">
        <h3 className="mb-3 font-bold">{t('member_spending')}</h3>
        <ResponsiveContainer width="100%" height={180}>
          <BarChart data={chartData}>
            <XAxis dataKey="name" tick={{ fontSize: 11 }} axisLine={false} tickLine={false} />
            <Bar dataKey="value" radius={[8, 8, 0, 0]}>
              {chartData.map((d, i) => (
                <Cell key={i} fill={d.color} />
              ))}
            </Bar>
          </BarChart>
        </ResponsiveContainer>
      </div>

      <div className="card-surface p-5">
        <h3 className="mb-3 font-bold">🍽️ {t('top_items')}</h3>
        <div className="flex flex-col gap-2">
          {topItems.map((it, i) => (
            <div key={it.id} className="flex items-center justify-between text-sm">
              <span>
                {i + 1}. {it.name}
              </span>
              <span className="amount font-semibold">
                {formatCurrency(it.price, bill.settings.currency)}
              </span>
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}

function StatCard({
  emoji,
  label,
  name,
  value,
}: {
  emoji: string
  label: string
  name?: string
  value: string
}) {
  return (
    <div className="card-surface flex flex-col gap-1 p-4">
      <span className="text-2xl">{emoji}</span>
      <span className="text-[10px] text-muted-foreground">{label}</span>
      <span className="truncate font-bold">{name ?? '-'}</span>
      <span className="amount text-xs text-primary">{value}</span>
    </div>
  )
}
