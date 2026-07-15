'use client'

import { useTranslations } from 'next-intl'
import { Badge } from '@/components/ui/badge'
import type { BillStatus } from '@/types/bill'

const MAP: Record<BillStatus, { variant: 'draft' | 'open' | 'settled'; key: string }> = {
  draft: { variant: 'draft', key: 'status_draft' },
  pending_payment: { variant: 'open', key: 'status_open' },
  completed: { variant: 'settled', key: 'status_settled' },
}

export function StatusBadge({ status }: { status: BillStatus }) {
  const t = useTranslations('bills')
  const cfg = MAP[status] ?? MAP.draft
  return <Badge variant={cfg.variant}>{t(cfg.key)}</Badge>
}
