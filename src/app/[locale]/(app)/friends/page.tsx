import { setRequestLocale } from 'next-intl/server'
import { createClient } from '@/lib/supabase/server'
import { fetchFriends } from '@/repositories/friends-repository'
import { FriendsView } from '@/components/friends/friends-view'

export default async function FriendsPage({
  params,
}: {
  params: Promise<{ locale: string }>
}) {
  const { locale } = await params
  setRequestLocale(locale)

  const supabase = await createClient()
  const {
    data: { user },
  } = await supabase.auth.getUser()

  const friends = user ? await fetchFriends(supabase, user.id).catch(() => []) : []

  return <FriendsView initialFriends={friends} myUserId={user?.id ?? ''} />
}
