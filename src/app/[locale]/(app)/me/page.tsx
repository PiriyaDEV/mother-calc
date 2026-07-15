import { setRequestLocale } from 'next-intl/server'
import { createClient } from '@/lib/supabase/server'
import { fetchProfile } from '@/repositories/profile-repository'
import { MeView } from '@/components/me/me-view'

export default async function MePage({
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

  const profile = user ? await fetchProfile(supabase, user.id).catch(() => null) : null

  return <MeView profile={profile} />
}
