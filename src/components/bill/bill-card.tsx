'use client'

import { useTranslations } from 'next-intl'
import { Link } from '@/i18n/navigation'
import { AvatarCircles } from '@/components/magic/avatar-circles'
import { MagicCard } from '@/components/magic/misc'
import { StatusBadge } from '@/components/shared/status-badge'
import { formatCurrency, formatDate } from '@/lib/utils/format'
import type { Bill } from '@/types/bill'

export function BillCard({ bill }: { bill: Bill }) {
  const t = useTranslations('common')
  return (
    <Link href={`/bills/${bill.id}`} className="block">
      <MagicCard className="card-surface p-4">
        <div className="flex items-center gap-3">
          <span className="text-4xl">{bill.emoji}</span>
          <div className="min-w-0 flex-1">
            <p className="truncate font-bold">{bill.title}</p>
            <p className="text-xs text-muted-foreground">{formatDate(bill.createdAt)}</p>
          </div>
          <StatusBadge status={bill.status} />
        </div>
        <div className="mt-3 flex items-center justify-between">
          <AvatarCircles
            avatars={bill.members.map((m) => ({
              name: m.name,
              avatarUrl: m.profile?.avatarUrl,
              color: m.color,
            }))}
            size={32}
          />
          <p className="amount font-bold">
            {formatCurrency(bill.total, bill.settings.currency)}
          </p>
        </div>
        {bill.members.length > 0 && (
          <p className="mt-1 text-right text-[10px] text-muted-foreground">
            {bill.members.length} {t('person')}
          </p>
        )}
      </MagicCard>
    </Link>
  )
}
