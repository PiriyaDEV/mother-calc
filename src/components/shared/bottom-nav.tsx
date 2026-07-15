'use client'

import { Home, Receipt, Users, UserPlus, User } from 'lucide-react'
import { motion } from 'motion/react'
import { useTranslations } from 'next-intl'
import { Link, usePathname } from '@/i18n/navigation'
import { cn } from '@/lib/utils/cn'

const TABS = [
  { id: 'home', href: '/home', icon: Home },
  { id: 'bills', href: '/bills', icon: Receipt },
  { id: 'groups', href: '/groups', icon: Users },
  { id: 'friends', href: '/friends', icon: UserPlus },
  { id: 'me', href: '/me', icon: User },
] as const

export function BottomNav() {
  const pathname = usePathname()
  const t = useTranslations('nav')

  return (
    <nav className="fixed bottom-6 left-1/2 z-40 -translate-x-1/2">
      <div className="flex items-center gap-1 rounded-full border border-white/20 bg-card/80 p-2 shadow-[0_8px_32px_rgba(0,0,0,0.12)] backdrop-blur-xl">
        {TABS.map((tab) => {
          const active = pathname.startsWith(tab.href)
          const Icon = tab.icon
          return (
            <Link
              key={tab.id}
              href={tab.href}
              className={cn(
                'relative flex flex-col items-center gap-0.5 rounded-2xl px-4 py-1.5 text-[10px] font-semibold transition-colors',
                active ? 'text-primary' : 'text-muted-foreground hover:text-foreground'
              )}
            >
              {active && (
                <motion.span
                  layoutId="nav-indicator"
                  className="absolute inset-0 rounded-2xl bg-primary/10"
                  transition={{ type: 'spring', stiffness: 400, damping: 30 }}
                />
              )}
              <Icon className="relative z-10 h-5 w-5" />
              <span className="relative z-10">{t(tab.id)}</span>
            </Link>
          )
        })}
      </div>
    </nav>
  )
}
