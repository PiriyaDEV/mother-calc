import { notFound } from 'next/navigation'
import { setRequestLocale } from 'next-intl/server'
import { createClient } from '@/lib/supabase/server'
import { fetchGroup } from '@/repositories/groups-repository'
import { fetchGroupBills } from '@/repositories/bills-repository'
import { GroupDetail } from '@/components/group/group-detail'

export default async function GroupDetailPage({
  params,
}: {
  params: Promise<{ locale: string; id: string }>
}) {
  const { locale, id } = await params
  setRequestLocale(locale)

  const supabase = await createClient()
  const {
    data: { user },
  } = await supabase.auth.getUser()

  const [group, bills] = await Promise.all([
    fetchGroup(supabase, id).catch(() => null),
    fetchGroupBills(supabase, id).catch(() => []),
  ])
  if (!group) notFound()

  return <GroupDetail group={group} bills={bills} myUserId={user?.id ?? ''} />
}
