'use client'

import { useMemo, useState } from 'react'
import { ArrowLeft, Plus, QrCode, UserPlus } from 'lucide-react'
import { useTranslations } from 'next-intl'
import { Link, useRouter } from '@/i18n/navigation'
import { createClient } from '@/lib/supabase/client'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Badge } from '@/components/ui/badge'
import { BillCard } from '@/components/bill/bill-card'
import { AvatarCircles } from '@/components/magic/avatar-circles'
import { AnimatedList } from '@/components/magic/animated-list'
import { NumberTicker } from '@/components/magic/number-ticker'
import { Confetti } from '@/components/magic/confetti'
import { PromptPayQR } from '@/components/shared/promptpay-qr'
import { toast } from '@/components/ui/toast'
import { calculateGroupSettlement } from '@/lib/utils/bill-utils'
import { formatCurrency } from '@/lib/utils/format'
import { searchProfilesByUsername } from '@/repositories/profile-repository'
import type { Bill } from '@/types/bill'
import type { Group } from '@/types/group'
import type { DebtTransaction } from '@/types/bill'

export function GroupDetail({
  group,
  bills,
  myUserId,
}: {
  group: Group
  bills: Bill[]
  myUserId: string
}) {
  const t = useTranslations('groups')
  const router = useRouter()
  const supabase = createClient()
  const [qr, setQr] = useState<DebtTransaction | null>(null)
  const [query, setQuery] = useState('')

  const isOwner = group.ownerId === myUserId
  const groupMembers = group.members.map((m) => ({
    userId: m.userId,
    name: m.displayName ?? m.username ?? '?',
    avatarUrl: m.avatarUrl ?? undefined,
  }))

  const settlement = useMemo(
    () => calculateGroupSettlement(bills, groupMembers),
    [bills, groupMembers]
  )
  const grandTotal = bills.reduce((s, b) => s + b.total, 0)
  const openBills = bills.filter((b) => b.status !== 'completed')
  const allSettled = openBills.length > 0 && settlement.length === 0

  async function invite() {
    const results = await searchProfilesByUsername(supabase, query).catch(() => [])
    const match = results.find((p) => p.username === query.trim())
    if (!match) return toast(t('invite_by_username'), 'error')
    const { error } = await supabase.from('group_members').insert({
      group_id: group.id,
      user_id: match.id,
      role: 'member',
      status: 'pending',
      invited_by: myUserId,
    })
    if (error) return toast(error.message, 'error')
    setQuery('')
    toast(t('invite_member'))
    router.refresh()
  }

  async function deleteGroup() {
    const { error } = await supabase.from('groups').delete().eq('id', group.id)
    if (error) return toast(error.message, 'error')
    router.push('/groups')
    router.refresh()
  }

  return (
    <div className="flex flex-col gap-4">
      {allSettled && <Confetti />}

      <div className="flex items-center gap-2">
        <button onClick={() => router.push('/groups')} className="rounded-full p-2 hover:bg-muted">
          <ArrowLeft className="h-5 w-5" />
        </button>
        <span className="text-3xl">{group.emoji}</span>
        <h1 className="flex-1 truncate text-xl font-bold">{group.name}</h1>
      </div>

      <Tabs defaultValue="bills">
        <TabsList className="w-full">
          <TabsTrigger value="bills" className="flex-1">
            {t('tab_bills')}
          </TabsTrigger>
          <TabsTrigger value="members" className="flex-1">
            {t('tab_members')}
          </TabsTrigger>
          <TabsTrigger value="settlement" className="flex-1">
            {t('tab_settlement')}
          </TabsTrigger>
        </TabsList>

        <TabsContent value="bills">
          <div className="flex flex-col gap-3">
            <Link href={`/bills/create?group=${group.id}`}>
              <Button variant="secondary" className="w-full">
                <Plus className="h-4 w-4" /> {t('tab_bills')}
              </Button>
            </Link>
            {bills.map((b) => (
              <BillCard key={b.id} bill={b} />
            ))}
          </div>
        </TabsContent>

        <TabsContent value="members">
          <div className="flex flex-col gap-3">
            {group.members.map((m) => (
              <div key={m.id} className="card-surface flex items-center gap-3 p-3">
                <AvatarCircles
                  avatars={[{ name: m.displayName ?? '?', avatarUrl: m.avatarUrl }]}
                  size={40}
                />
                <div className="flex-1">
                  <p className="font-medium">{m.displayName ?? m.username}</p>
                  <p className="text-xs text-muted-foreground">@{m.username}</p>
                </div>
                <Badge variant={m.role === 'owner' ? 'primary' : 'muted'}>
                  {t(m.role === 'owner' ? 'role_owner' : 'role_member')}
                </Badge>
              </div>
            ))}

            {isOwner && (
              <div className="flex gap-2">
                <Input
                  placeholder={t('invite_by_username')}
                  value={query}
                  onChange={(e) => setQuery(e.target.value)}
                />
                <Button onClick={invite}>
                  <UserPlus className="h-4 w-4" />
                </Button>
              </div>
            )}
          </div>
        </TabsContent>

        <TabsContent value="settlement">
          <div className="flex flex-col gap-4">
            <div className="card-surface flex items-center justify-between p-5">
              <div>
                <p className="text-xs text-muted-foreground">
                  {t('total_bills', { count: bills.length })}
                </p>
                <p className="amount text-2xl font-bold text-primary">
                  ฿<NumberTicker value={grandTotal} />
                </p>
              </div>
              <span className="text-sm text-muted-foreground">{t('grand_total')}</span>
            </div>

            <div className="card-surface p-5">
              <h3 className="mb-3 font-bold">💸 {t('must_transfer')}</h3>
              {settlement.length === 0 ? (
                <p className="py-4 text-center text-sm text-muted-foreground">
                  {t('all_settled')} ✅
                </p>
              ) : (
                <AnimatedList>
                  {settlement.map((d, i) => (
                    <div key={i} className="flex items-center gap-2">
                      <AvatarCircles
                        avatars={[{ name: d.from.name, avatarUrl: d.from.profile?.avatarUrl }]}
                        size={30}
                      />
                      <span className="text-xs">→</span>
                      <AvatarCircles
                        avatars={[{ name: d.to.name, avatarUrl: d.to.profile?.avatarUrl }]}
                        size={30}
                      />
                      <span className="flex-1 truncate text-sm">
                        {d.from.name} → {d.to.name}
                      </span>
                      <span className="amount text-sm font-bold">
                        {formatCurrency(d.amount)}
                      </span>
                      <button onClick={() => setQr(d)} className="text-primary">
                        <QrCode className="h-4 w-4" />
                      </button>
                    </div>
                  ))}
                </AnimatedList>
              )}
            </div>
          </div>
        </TabsContent>
      </Tabs>

      {isOwner && (
        <Button variant="destructive" onClick={deleteGroup}>
          {t('delete_group')}
        </Button>
      )}

      <PromptPayQR
        open={!!qr}
        onOpenChange={(o) => !o && setQr(null)}
        promptpay={qr?.to.promptpay}
        amount={qr?.amount ?? 0}
        name={qr?.to.name ?? ''}
      />
    </div>
  )
}
