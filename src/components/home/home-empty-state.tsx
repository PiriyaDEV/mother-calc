'use client'

import { useTranslations } from 'next-intl'
import { Link } from '@/i18n/navigation'
import { ShimmerButton } from '@/components/magic/shimmer-button'
import { Ripple } from '@/components/magic/misc'

export function HomeEmptyState() {
  const t = useTranslations('home')
  return (
    <div className="card-surface relative flex flex-col items-center gap-4 overflow-hidden p-10 text-center">
      <Ripple />
      <span className="relative z-10 text-5xl">🧾</span>
      <div className="relative z-10">
        <p className="font-bold">{t('empty_title')}</p>
        <p className="text-sm text-muted-foreground">{t('empty_subtitle')}</p>
      </div>
      <Link href="/bills/create" className="relative z-10">
        <ShimmerButton>{t('quick_create_bill')}</ShimmerButton>
      </Link>
    </div>
  )
}
