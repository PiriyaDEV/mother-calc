'use client'

import { useState } from 'react'
import { QrCode } from 'lucide-react'
import { useTranslations } from 'next-intl'
import { AnimatedList } from '@/components/magic/animated-list'
import { AvatarCircles } from '@/components/magic/avatar-circles'
import { Ripple } from '@/components/magic/misc'
import { PromptPayQR } from '@/components/shared/promptpay-qr'
import { formatCurrency } from '@/lib/utils/format'
import type { MyDebtEntry } from '@/lib/utils/bill-utils'

interface MyDebtsCardProps {
  iOwe: MyDebtEntry[]
  owedToMe: MyDebtEntry[]
}

export function MyDebtsCard({ iOwe, owedToMe }: MyDebtsCardProps) {
  const t = useTranslations('home')
  const [qr, setQr] = useState<{ pp: string | null | undefined; amount: number; name: string } | null>(
    null
  )

  if (iOwe.length === 0 && owedToMe.length === 0) {
    return (
      <div className="card-surface relative flex flex-col items-center justify-center gap-2 overflow-hidden p-8">
        <Ripple />
        <span className="relative z-10 text-3xl">✅</span>
        <p className="relative z-10 font-semibold">{t('no_debts')}</p>
      </div>
    )
  }

  return (
    <div className="card-surface p-5">
      <h3 className="mb-3 font-bold">💰 {t('my_debts')}</h3>

      {iOwe.length > 0 && (
        <div className="mb-4">
          <p className="mb-2 text-xs font-semibold text-muted-foreground">{t('i_owe')}</p>
          <AnimatedList>
            {iOwe.map((d) => (
              <Row
                key={d.userId}
                entry={d}
                fromLabel={t('from_bills', { count: d.billCount })}
                onQr={() => setQr({ pp: d.promptpay, amount: d.amount, name: d.name })}
                showQr
              />
            ))}
          </AnimatedList>
        </div>
      )}

      {owedToMe.length > 0 && (
        <div>
          <p className="mb-2 text-xs font-semibold text-muted-foreground">{t('owed_to_me')}</p>
          <AnimatedList>
            {owedToMe.map((d) => (
              <Row key={d.userId} entry={d} fromLabel={t('from_bills', { count: d.billCount })} />
            ))}
          </AnimatedList>
        </div>
      )}

      <PromptPayQR
        open={!!qr}
        onOpenChange={(o) => !o && setQr(null)}
        promptpay={qr?.pp}
        amount={qr?.amount ?? 0}
        name={qr?.name ?? ''}
      />
    </div>
  )
}

function Row({
  entry,
  fromLabel,
  onQr,
  showQr,
}: {
  entry: MyDebtEntry
  fromLabel: string
  onQr?: () => void
  showQr?: boolean
}) {
  return (
    <div className="flex items-center gap-3">
      <AvatarCircles avatars={[{ name: entry.name, avatarUrl: entry.avatarUrl }]} size={40} />
      <div className="min-w-0 flex-1">
        <p className="truncate font-medium">{entry.name}</p>
        <p className="text-xs text-muted-foreground">{fromLabel}</p>
      </div>
      <p className="amount font-bold">{formatCurrency(entry.amount)}</p>
      {showQr && (
        <button
          onClick={onQr}
          className="flex h-9 w-9 items-center justify-center rounded-full bg-primary-50 text-primary-600"
        >
          <QrCode className="h-4 w-4" />
        </button>
      )}
    </div>
  )
}
