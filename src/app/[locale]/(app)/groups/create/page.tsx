'use client'

import { useState } from 'react'
import { ArrowLeft } from 'lucide-react'
import { useTranslations } from 'next-intl'
import { createClient } from '@/lib/supabase/client'
import { useRouter } from '@/i18n/navigation'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { EmojiPicker } from '@/components/shared/emoji-picker'
import { toast } from '@/components/ui/toast'

export default function CreateGroupPage() {
  const t = useTranslations('groups')
  const tc = useTranslations('common')
  const router = useRouter()
  const [emoji, setEmoji] = useState('👥')
  const [emojiOpen, setEmojiOpen] = useState(false)
  const [name, setName] = useState('')
  const [description, setDescription] = useState('')
  const [saving, setSaving] = useState(false)

  async function save() {
    if (!name.trim()) return
    setSaving(true)
    const supabase = createClient()
    const {
      data: { user },
    } = await supabase.auth.getUser()
    if (!user) {
      setSaving(false)
      return
    }

    const { data, error } = await supabase
      .from('groups')
      .insert({ name: name.trim(), description: description || null, emoji, owner_id: user.id })
      .select('id')
      .single()

    if (error || !data) {
      setSaving(false)
      return toast(error?.message ?? 'error', 'error')
    }

    // owner membership
    await supabase.from('group_members').insert({
      group_id: data.id,
      user_id: user.id,
      role: 'owner',
      status: 'accepted',
      invited_by: user.id,
    })

    setSaving(false)
    router.push(`/groups/${data.id}`)
  }

  return (
    <div className="flex flex-col gap-5">
      <div className="flex items-center gap-2">
        <button onClick={() => router.back()} className="rounded-full p-2 hover:bg-muted">
          <ArrowLeft className="h-5 w-5" />
        </button>
        <h1 className="text-2xl font-bold">{t('create_title')}</h1>
      </div>

      <div className="flex items-end gap-3">
        <button
          type="button"
          onClick={() => setEmojiOpen(true)}
          className="flex h-16 w-16 items-center justify-center rounded-2xl border border-border bg-card text-3xl"
        >
          {emoji}
        </button>
        <div className="flex-1">
          <Label>{t('name')}</Label>
          <Input value={name} onChange={(e) => setName(e.target.value)} />
        </div>
      </div>

      <div>
        <Label>{t('description')}</Label>
        <Input value={description} onChange={(e) => setDescription(e.target.value)} />
      </div>

      <Button size="lg" onClick={save} disabled={saving}>
        {saving ? '...' : tc('create')}
      </Button>

      <EmojiPicker open={emojiOpen} onOpenChange={setEmojiOpen} onSelect={setEmoji} />
    </div>
  )
}
