'use client'

import { useEffect, useState } from 'react'
import { Check, X, Trash2, UserPlus, Search } from 'lucide-react'
import { useTranslations } from 'next-intl'
import { createClient } from '@/lib/supabase/client'
import { useRouter } from '@/i18n/navigation'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { AvatarCircles } from '@/components/magic/avatar-circles'
import { Ripple } from '@/components/magic/misc'
import { toast } from '@/components/ui/toast'
import { useFriendsStore } from '@/stores/friends-store'
import { searchProfilesByUsername } from '@/repositories/profile-repository'
import type { Friend } from '@/types/friend'

export function FriendsView({
  initialFriends,
  myUserId,
}: {
  initialFriends: Friend[]
  myUserId: string
}) {
  const t = useTranslations('friends')
  const tc = useTranslations('common')
  const router = useRouter()
  const supabase = createClient()
  const { friends, setFriends, accepted, pending } = useFriendsStore()
  const [query, setQuery] = useState('')

  useEffect(() => {
    setFriends(initialFriends)
  }, [initialFriends, setFriends])

  const pendingIncoming = pending(myUserId)
  const acceptedList = accepted()

  async function sendRequest() {
    const results = await searchProfilesByUsername(supabase, query).catch(() => [])
    const match = results.find((p) => p.username === query.trim())
    if (!match || match.id === myUserId) return toast(t('search_username'), 'error')
    const { error } = await supabase
      .from('friends')
      .insert({ requester_id: myUserId, addressee_id: match.id, status: 'pending' })
    if (error) return toast(error.message, 'error')
    setQuery('')
    toast(t('request_sent'))
    router.refresh()
  }

  async function respond(f: Friend, status: 'accepted' | 'declined') {
    const { error } = await supabase.from('friends').update({ status }).eq('id', f.id)
    if (error) return toast(error.message, 'error')
    router.refresh()
  }

  async function removeFriend(f: Friend) {
    const { error } = await supabase.from('friends').delete().eq('id', f.id)
    if (error) return toast(error.message, 'error')
    useFriendsStore.getState().removeFriend(f.id)
  }

  return (
    <div className="flex flex-col gap-4">
      <h1 className="text-2xl font-bold">{t('title')}</h1>

      <div className="flex gap-2">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
          <Input
            className="pl-9"
            placeholder={t('search_username')}
            value={query}
            onChange={(e) => setQuery(e.target.value)}
          />
        </div>
        <Button onClick={sendRequest}>
          <UserPlus className="h-4 w-4" /> {t('add_friend')}
        </Button>
      </div>

      {pendingIncoming.length > 0 && (
        <div className="card-surface p-4">
          <h3 className="mb-3 font-bold">{t('pending_requests')}</h3>
          <div className="flex flex-col gap-2">
            {pendingIncoming.map((f) => (
              <div key={f.id} className="flex items-center gap-3">
                <AvatarCircles avatars={[{ name: f.displayName ?? '?', avatarUrl: f.avatarUrl }]} size={36} />
                <div className="flex-1">
                  <p className="font-medium">{f.displayName}</p>
                  <p className="text-xs text-muted-foreground">@{f.username}</p>
                </div>
                <button
                  onClick={() => respond(f, 'accepted')}
                  className="flex h-8 w-8 items-center justify-center rounded-full bg-green-100 text-green-600"
                >
                  <Check className="h-4 w-4" />
                </button>
                <button
                  onClick={() => respond(f, 'declined')}
                  className="flex h-8 w-8 items-center justify-center rounded-full bg-red-100 text-red-600"
                >
                  <X className="h-4 w-4" />
                </button>
              </div>
            ))}
          </div>
        </div>
      )}

      {acceptedList.length === 0 && pendingIncoming.length === 0 ? (
        <div className="card-surface relative flex flex-col items-center gap-3 overflow-hidden p-10 text-center">
          <Ripple />
          <span className="relative z-10 text-5xl">🤝</span>
          <div className="relative z-10">
            <p className="font-bold">{t('empty_title')}</p>
            <p className="text-sm text-muted-foreground">{t('empty_subtitle')}</p>
          </div>
        </div>
      ) : (
        <div className="flex flex-col gap-2">
          {acceptedList.map((f) => (
            <div key={f.id} className="card-surface flex items-center gap-3 p-3">
              <AvatarCircles avatars={[{ name: f.displayName ?? '?', avatarUrl: f.avatarUrl }]} size={40} />
              <div className="flex-1">
                <p className="font-medium">{f.displayName}</p>
                <p className="text-xs text-muted-foreground">@{f.username}</p>
              </div>
              <button onClick={() => removeFriend(f)} className="text-destructive">
                <Trash2 className="h-4 w-4" />
              </button>
            </div>
          ))}
        </div>
      )}

      <p className="sr-only">{tc('loading')}</p>
    </div>
  )
}
