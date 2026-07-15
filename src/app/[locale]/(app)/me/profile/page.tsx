'use client'

import { useEffect, useState } from 'react'
import { ArrowLeft } from 'lucide-react'
import { useTranslations } from 'next-intl'
import { createClient } from '@/lib/supabase/client'
import { useRouter } from '@/i18n/navigation'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { toast } from '@/components/ui/toast'

export default function EditProfilePage() {
  const t = useTranslations('auth')
  const tm = useTranslations('me')
  const tc = useTranslations('common')
  const router = useRouter()
  const supabase = createClient()

  const [displayName, setDisplayName] = useState('')
  const [username, setUsername] = useState('')
  const [promptpay, setPromptpay] = useState('')
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)

  useEffect(() => {
    ;(async () => {
      const {
        data: { user },
      } = await supabase.auth.getUser()
      if (!user) return
      const { data } = await supabase
        .from('profiles')
        .select('display_name, username, promptpay')
        .eq('id', user.id)
        .maybeSingle()
      if (data) {
        setDisplayName(data.display_name ?? '')
        setUsername(data.username ?? '')
        setPromptpay(data.promptpay ?? '')
      }
      setLoading(false)
    })()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  async function save() {
    setSaving(true)
    const {
      data: { user },
    } = await supabase.auth.getUser()
    if (!user) return
    const { error } = await supabase
      .from('profiles')
      .update({ display_name: displayName, username, promptpay: promptpay || null })
      .eq('id', user.id)
    setSaving(false)
    if (error) return toast(error.message, 'error')
    toast(tm('saved'))
    router.push('/me')
    router.refresh()
  }

  if (loading) return <p className="py-16 text-center text-sm text-muted-foreground">{tc('loading')}</p>

  return (
    <div className="flex flex-col gap-5">
      <div className="flex items-center gap-2">
        <button onClick={() => router.back()} className="rounded-full p-2 hover:bg-muted">
          <ArrowLeft className="h-5 w-5" />
        </button>
        <h1 className="text-2xl font-bold">{tm('edit_profile')}</h1>
      </div>

      <div>
        <Label>{t('display_name')}</Label>
        <Input value={displayName} onChange={(e) => setDisplayName(e.target.value)} />
      </div>
      <div>
        <Label>{t('username')}</Label>
        <Input value={username} onChange={(e) => setUsername(e.target.value)} />
      </div>
      <div>
        <Label>{t('promptpay')}</Label>
        <Input value={promptpay} onChange={(e) => setPromptpay(e.target.value)} inputMode="numeric" />
      </div>

      <Button size="lg" onClick={save} disabled={saving}>
        {saving ? '...' : tc('save')}
      </Button>
    </div>
  )
}
