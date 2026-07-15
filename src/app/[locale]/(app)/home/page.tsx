import { setRequestLocale } from 'next-intl/server'
import { createClient } from '@/lib/supabase/server'
import { fetchBills } from '@/repositories/bills-repository'
import { fetchGroups } from '@/repositories/groups-repository'
import { fetchFriends } from '@/repositories/friends-repository'
import { fetchProfile } from '@/repositories/profile-repository'
import { calculateMyDebts } from '@/lib/utils/bill-utils'
import { HeroBalanceCard } from '@/components/home/hero-balance-card'
import { QuickActionTiles } from '@/components/home/quick-action-tiles'
import { MyDebtsCard } from '@/components/home/my-debts-card'
import { StatsGrid } from '@/components/home/stats-grid'
import { RecentBillsList } from '@/components/home/recent-bills-list'
import { HomeEmptyState } from '@/components/home/home-empty-state'

export default async function HomePage({
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

  const [bills, groups, friends, profile] = await Promise.all([
    fetchBills(supabase).catch(() => []),
    fetchGroups(supabase).catch(() => []),
    user ? fetchFriends(supabase, user.id).catch(() => []) : Promise.resolve([]),
    user ? fetchProfile(supabase, user.id).catch(() => null) : Promise.resolve(null),
  ])

  const { iOwe, owedToMe } = user
    ? calculateMyDebts(bills, user.id)
    : { iOwe: [], owedToMe: [] }

  const owe = iOwe.reduce((s, d) => s + d.amount, 0)
  const receive = owedToMe.reduce((s, d) => s + d.amount, 0)
  const totalSpent = bills.reduce((s, b) => s + b.total, 0)
  const acceptedFriends = friends.filter((f) => f.status === 'accepted').length

  return (
    <div className="flex flex-col gap-5">
      <HeroBalanceCard
        name={profile?.displayName ?? profile?.username ?? ''}
        owe={owe}
        receive={receive}
      />
      <QuickActionTiles />

      {bills.length === 0 ? (
        <HomeEmptyState />
      ) : (
        <>
          <MyDebtsCard iOwe={iOwe} owedToMe={owedToMe} />
          <StatsGrid
            bills={bills.length}
            total={totalSpent}
            groups={groups.length}
            friends={acceptedFriends}
          />
          <RecentBillsList bills={bills} />
        </>
      )}
    </div>
  )
}
