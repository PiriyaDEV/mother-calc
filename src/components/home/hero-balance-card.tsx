'use client'

import { useTranslations } from 'next-intl'
import { NumberTicker } from '@/components/magic/number-ticker'
import { getTotalEmoji } from '@/lib/utils/bill-utils'

interface HeroBalanceCardProps {
  name: string
  owe: number
  receive: number
}

export function HeroBalanceCard({ name, owe, receive }: HeroBalanceCardProps) {
  const t = useTranslations('home')
  const emoji = getTotalEmoji(Math.max(owe, receive))

  return (
    <div className="relative overflow-hidden rounded-3xl bg-gradient-to-br from-primary-500 to-primary-700 p-6 text-white shadow-lg">
      <div className="flex items-center justify-between">
        <div>
          <p className="text-sm text-white/80">{t('greeting')}</p>
          <p className="text-xl font-bold">{name}</p>
        </div>
        <span className="text-4xl">{emoji}</span>
      </div>

      <div className="mt-6 grid grid-cols-2 gap-4">
        <div>
          <p className="text-xs text-white/70">{t('balance_owe')}</p>
          <p className="amount text-2xl font-bold">
            ฿<NumberTicker value={owe} decimals={0} />
          </p>
        </div>
        <div>
          <p className="text-xs text-white/70">{t('balance_receive')}</p>
          <p className="amount text-2xl font-bold">
            ฿<NumberTicker value={receive} decimals={0} />
          </p>
        </div>
      </div>
    </div>
  )
}
