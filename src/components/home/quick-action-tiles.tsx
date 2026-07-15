'use client'

import { Receipt, Users, UserPlus } from 'lucide-react'
import { useTranslations } from 'next-intl'
import { Link } from '@/i18n/navigation'

const ACTIONS = [
  { href: '/bills/create', icon: Receipt, key: 'quick_create_bill', color: 'bg-primary-500' },
  { href: '/groups/create', icon: Users, key: 'quick_create_group', color: 'bg-emerald-500' },
  { href: '/friends', icon: UserPlus, key: 'quick_add_friend', color: 'bg-amber-500' },
] as const

export function QuickActionTiles() {
  const t = useTranslations('home')
  return (
    <div className="grid grid-cols-3 gap-3">
      {ACTIONS.map((a) => {
        const Icon = a.icon
        return (
          <Link
            key={a.href}
            href={a.href}
            className="flex flex-col items-center gap-2"
          >
            <span
              className={`flex h-14 w-14 items-center justify-center rounded-full ${a.color} text-white shadow-md transition-transform active:scale-90`}
            >
              <Icon className="h-6 w-6" />
            </span>
            <span className="text-xs font-medium text-muted-foreground">{t(a.key)}</span>
          </Link>
        )
      })}
    </div>
  )
}
