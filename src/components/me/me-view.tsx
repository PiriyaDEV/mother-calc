'use client'

import { useTheme } from 'next-themes'
import { Moon, Globe, LogOut, ChevronRight, Pencil } from 'lucide-react'
import { useTranslations, useLocale } from 'next-intl'
import { createClient } from '@/lib/supabase/client'
import { Link, useRouter, usePathname } from '@/i18n/navigation'
import { AvatarCircles } from '@/components/magic/avatar-circles'
import { Switch } from '@/components/ui/switch'
import type { Profile } from '@/types/profile'

export function MeView({ profile }: { profile: Profile | null }) {
  const t = useTranslations('me')
  const locale = useLocale()
  const router = useRouter()
  const pathname = usePathname()
  const { theme, setTheme } = useTheme()

  async function signOut() {
    const supabase = createClient()
    await supabase.auth.signOut()
    router.push('/login')
    router.refresh()
  }

  function switchLocale() {
    router.replace(pathname, { locale: locale === 'th' ? 'en' : 'th' })
  }

  return (
    <div className="flex flex-col gap-5">
      <h1 className="text-2xl font-bold">{t('title')}</h1>

      {/* Profile header */}
      <div className="card-surface flex items-center gap-4 p-5">
        <AvatarCircles
          avatars={[{ name: profile?.displayName ?? '?', avatarUrl: profile?.avatarUrl }]}
          size={64}
        />
        <div className="min-w-0 flex-1">
          <p className="truncate text-lg font-bold">{profile?.displayName}</p>
          <p className="truncate text-sm text-muted-foreground">@{profile?.username}</p>
        </div>
        <Link href="/me/profile" className="rounded-full p-2 hover:bg-muted">
          <Pencil className="h-4 w-4" />
        </Link>
      </div>

      {/* Account */}
      <Section title={t('account')}>
        <Link href="/me/profile" className="flex items-center justify-between px-4 py-3">
          <span>{t('edit_profile')}</span>
          <ChevronRight className="h-4 w-4 text-muted-foreground" />
        </Link>
      </Section>

      {/* Settings */}
      <Section title={t('settings')}>
        <button onClick={switchLocale} className="flex w-full items-center justify-between px-4 py-3">
          <span className="flex items-center gap-3">
            <Globe className="h-4 w-4 text-muted-foreground" />
            {t('language')}
          </span>
          <span className="text-sm font-medium text-primary">
            {locale === 'th' ? t('language_th') : t('language_en')}
          </span>
        </button>
        <div className="flex items-center justify-between border-t border-border px-4 py-3">
          <span className="flex items-center gap-3">
            <Moon className="h-4 w-4 text-muted-foreground" />
            {t('dark_mode')}
          </span>
          <Switch
            checked={theme === 'dark'}
            onCheckedChange={(v) => setTheme(v ? 'dark' : 'light')}
          />
        </div>
      </Section>

      <button
        onClick={signOut}
        className="flex items-center justify-center gap-2 rounded-2xl bg-red-50 py-3 font-bold text-destructive"
      >
        <LogOut className="h-4 w-4" /> {t('sign_out')}
      </button>
    </div>
  )
}

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div>
      <p className="mb-2 px-1 text-xs font-semibold uppercase text-muted-foreground">{title}</p>
      <div className="card-surface overflow-hidden">{children}</div>
    </div>
  )
}
