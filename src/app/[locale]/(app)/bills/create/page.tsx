'use client'

import { useState } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { ArrowLeft } from 'lucide-react'
import { useTranslations } from 'next-intl'
import { createClient } from '@/lib/supabase/client'
import { useRouter } from '@/i18n/navigation'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Switch } from '@/components/ui/switch'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import { EmojiPicker } from '@/components/shared/emoji-picker'
import { toast } from '@/components/ui/toast'
import { CURRENCIES } from '@/types/bill'

const schema = z.object({
  title: z.string().min(1),
  isVat: z.boolean(),
  vat: z.coerce.number().min(0).max(100),
  isService: z.boolean(),
  serviceCharge: z.coerce.number().min(0).max(100),
  tip: z.coerce.number().min(0),
  discount: z.coerce.number().min(0),
  currency: z.enum(CURRENCIES),
})
type FormValues = z.infer<typeof schema>

export default function CreateBillPage() {
  const t = useTranslations('bills')
  const tc = useTranslations('common')
  const router = useRouter()
  const [emoji, setEmoji] = useState('🧾')
  const [emojiOpen, setEmojiOpen] = useState(false)
  const [saving, setSaving] = useState(false)

  const {
    register,
    handleSubmit,
    watch,
    setValue,
    formState: { errors },
  } = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: {
      title: '',
      isVat: false,
      vat: 7,
      isService: false,
      serviceCharge: 10,
      tip: 0,
      discount: 0,
      currency: 'THB',
    },
  })

  const isVat = watch('isVat')
  const isService = watch('isService')

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

    const { data, error } = await supabase
      .from('bills')
      .insert({
        title: values.title,
        emoji,
        owner_id: user.id,
        status: 'draft',
        tip: values.tip,
        discount: values.discount,
        settings: {
          vat: values.vat,
          serviceCharge: values.serviceCharge,
          isVat: values.isVat,
          isService: values.isService,
          roundingMode: 'none',
          currency: values.currency,
        },
      })
      .select('id')
      .single()

    setSaving(false)
    if (error || !data) {
      toast(error?.message ?? 'error', 'error')
      return
    }
    router.push(`/bills/${data.id}?tab=members`)
  }

  return (
    <div className="flex flex-col gap-5">
      <div className="flex items-center gap-2">
        <button onClick={() => router.back()} className="rounded-full p-2 hover:bg-muted">
          <ArrowLeft className="h-5 w-5" />
        </button>
        <h1 className="text-2xl font-bold">{t('create_title')}</h1>
      </div>

      <form onSubmit={handleSubmit(onSubmit)} className="flex flex-col gap-5">
        <div className="flex items-end gap-3">
          <button
            type="button"
            onClick={() => setEmojiOpen(true)}
            className="flex h-16 w-16 items-center justify-center rounded-2xl border border-border bg-card text-3xl"
          >
            {emoji}
          </button>
          <div className="flex-1">
            <Label htmlFor="title">{t('name')}</Label>
            <Input id="title" placeholder={t('name_placeholder')} {...register('title')} />
            {errors.title && <p className="mt-1 text-xs text-destructive">{tc('retry')}</p>}
          </div>
        </div>

        <ToggleRow
          label={t('vat')}
          checked={isVat}
          onCheck={(v) => setValue('isVat', v)}
          input={<Input type="number" className="w-20" {...register('vat')} />}
        />
        <ToggleRow
          label={t('service_charge')}
          checked={isService}
          onCheck={(v) => setValue('isService', v)}
          input={<Input type="number" className="w-20" {...register('serviceCharge')} />}
        />

        <div className="grid grid-cols-2 gap-3">
          <div>
            <Label>{t('tip')}</Label>
            <Input type="number" {...register('tip')} />
          </div>
          <div>
            <Label>{t('discount')}</Label>
            <Input type="number" {...register('discount')} />
          </div>
        </div>

        <div>
          <Label>{t('currency')}</Label>
          <Select
            defaultValue="THB"
            onValueChange={(v) => setValue('currency', v as FormValues['currency'])}
          >
            <SelectTrigger>
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              {CURRENCIES.map((c) => (
                <SelectItem key={c} value={c}>
                  {c}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>

        <Button type="submit" size="lg" disabled={saving} className="mt-2">
          {saving ? '...' : tc('create')}
        </Button>
      </form>

      <EmojiPicker open={emojiOpen} onOpenChange={setEmojiOpen} onSelect={setEmoji} />
    </div>
  )
}

function ToggleRow({
  label,
  checked,
  onCheck,
  input,
}: {
  label: string
  checked: boolean
  onCheck: (v: boolean) => void
  input: React.ReactNode
}) {
  return (
    <div className="flex items-center justify-between rounded-xl border border-border bg-card px-4 py-3">
      <div className="flex items-center gap-3">
        <Switch checked={checked} onCheckedChange={onCheck} />
        <span className="text-sm font-medium">{label}</span>
      </div>
      {checked && input}
    </div>
  )
}
