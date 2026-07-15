import { setRequestLocale, getTranslations } from 'next-intl/server'
import { Plus } from 'lucide-react'
import { createClient } from '@/lib/supabase/server'
import { fetchGroups } from '@/repositories/groups-repository'
import { Link } from '@/i18n/navigation'
import { GroupCard } from '@/components/group/group-card'

export default async function GroupsPage({
  params,
}: {
  params: Promise<{ locale: string }>
}) {
  const { locale } = await params
  setRequestLocale(locale)
  const t = await getTranslations('groups')

  const supabase = await createClient()
  const groups = await fetchGroups(supabase).catch(() => [])

  return (
    <div className="flex flex-col gap-4">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">{t('title')}</h1>
        <Link
          href="/groups/create"
          className="flex h-10 w-10 items-center justify-center rounded-full bg-primary text-white"
        >
          <Plus className="h-5 w-5" />
        </Link>
      </div>

      {groups.length === 0 ? (
        <p className="py-16 text-center text-sm text-muted-foreground">{t('empty_title')}</p>
      ) : (
        <div className="flex flex-col gap-3">
          {groups.map((g) => (
            <GroupCard key={g.id} group={g} />
          ))}
        </div>
      )}
    </div>
  )
}
