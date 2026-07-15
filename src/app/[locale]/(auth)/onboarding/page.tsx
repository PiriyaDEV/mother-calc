'use client'

import { useState } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { useTranslations } from 'next-intl'
import { createClient } from '@/lib/supabase/client'
import { useRouter } from '@/i18n/navigation'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { toast } from '@/components/ui/toast'

const schema = z.object({
  username: z
    .string()
    .regex(/^[a-zA-Z0-9_]{3,30}$/, 'invalid'),
  displayName: z.string().min(1),
  promptpay: z.string().optional(),
})
type FormValues = z.infer<typeof schema>

export default function OnboardingPage() {
  const t = useTranslations('auth')
  const router = useRouter()
  const [saving, setSaving] = useState(false)
  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<FormValues>({ resolver: zodResolver(schema) })

  async function onSubmit(values: FormValues) {
    setSaving(true)
    const supabase = createClient()
    const {
      data: { user },
    } = await supabase.auth.getUser()
    if (!user) {
      setSaving(false)
      return
    }

    const { error } = await supabase
      .from('profiles')
      .update({
        username: values.username,
        display_name: values.displayName,
        promptpay: values.promptpay || null,
        onboarding_completed: true,
      })
      .eq('id', user.id)

    setSaving(false)
    if (error) {
      toast(error.code === '23505' ? t('username_taken') : error.message, 'error')
      return
    }
    router.push('/home')
    router.refresh()
  }

  return (
    <main className="mx-auto flex min-h-dvh max-w-md flex-col justify-center px-6 py-12">
      <h1 className="text-2xl font-bold">{t('onboarding_title')}</h1>
      <form onSubmit={handleSubmit(onSubmit)} className="mt-8 flex flex-col gap-5">
        <div className="flex flex-col gap-1.5">
          <Label htmlFor="username">{t('username')}</Label>
          <Input id="username" placeholder="username" {...register('username')} />
          <p className="text-xs text-muted-foreground">{t('username_hint')}</p>
          {errors.username && (
            <p className="text-xs text-destructive">{t('username_invalid')}</p>
          )}
        </div>

        <div className="flex flex-col gap-1.5">
          <Label htmlFor="displayName">{t('display_name')}</Label>
          <Input id="displayName" {...register('displayName')} />
        </div>

        <div className="flex flex-col gap-1.5">
          <Label htmlFor="promptpay">{t('promptpay')}</Label>
          <Input id="promptpay" inputMode="numeric" {...register('promptpay')} />
        </div>

        <Button type="submit" size="lg" disabled={saving} className="mt-2">
          {saving ? '...' : t('finish')}
        </Button>
      </form>
    </main>
  )
}
