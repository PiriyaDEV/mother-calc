'use client'

import { useState } from 'react'
import { Plus, Trash2, Check } from 'lucide-react'
import { useTranslations } from 'next-intl'
import { createClient } from '@/lib/supabase/client'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Badge } from '@/components/ui/badge'
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import { AvatarCircles } from '@/components/magic/avatar-circles'
import { toast } from '@/components/ui/toast'
import { calculateBill } from '@/lib/utils/bill-utils'
import { formatCurrency } from '@/lib/utils/format'
import type { Bill } from '@/types/bill'

const COLORS = ['#3b82f6', '#ef4444', '#22c55e', '#f59e0b', '#8b5cf6', '#ec4899', '#14b8a6', '#f97316']

export function MembersTab({
  bill,
  myUserId,
  editable,
  onChange,
}: {
  bill: Bill
  myUserId: string
  editable: boolean
  onChange: () => void
}) {
  const t = useTranslations('bills')
  const [open, setOpen] = useState(false)
  const [name, setName] = useState('')
  const [color, setColor] = useState(COLORS[0])
  const [promptpay, setPromptpay] = useState('')
  const supabase = createClient()

  const calc = calculateBill(bill)
  const totalById = Object.fromEntries(calc.memberSummaries.map((s) => [s.member.id, s.total]))

  // self first, then others
  const sorted = [...bill.members].sort((a, b) => {
    if (a.userId === myUserId) return -1
    if (b.userId === myUserId) return 1
    return 0
  })

  async function addMember() {
    if (!name.trim()) return
    const { error } = await supabase.from('bill_members').insert({
      bill_id: bill.id,
      name: name.trim(),
      color,
      promptpay: promptpay || null,
      is_external: true,
    })
    if (error) return toast(error.message, 'error')
    setName('')
    setPromptpay('')
    setOpen(false)
    onChange()
  }

  async function removeMember(id: string) {
    const { error } = await supabase.from('bill_members').delete().eq('id', id)
    if (error) return toast(error.message, 'error')
    onChange()
  }

  async function togglePaid(memberId: string) {
    const paid = bill.paidMemberIds.includes(memberId)
    const next = paid
      ? bill.paidMemberIds.filter((x) => x !== memberId)
      : [...bill.paidMemberIds, memberId]
    const { error } = await supabase.from('bills').update({ paid_member_ids: next }).eq('id', bill.id)
    if (error) return toast(error.message, 'error')
    onChange()
  }

  return (
    <div className="flex flex-col gap-3">
      {sorted.length === 0 && (
        <p className="py-8 text-center text-sm text-muted-foreground">{t('no_members')}</p>
      )}

      {sorted.map((m) => {
        const isPaid = bill.paidMemberIds.includes(m.id)
        return (
          <div key={m.id} className="card-surface flex items-center gap-3 p-3">
            <AvatarCircles avatars={[{ name: m.name, avatarUrl: m.profile?.avatarUrl, color: m.color }]} size={40} />
            <div className="min-w-0 flex-1">
              <p className="truncate font-medium">
                {m.name}
                {m.userId === myUserId && <span className="ml-1 text-xs text-primary">(คุณ)</span>}
              </p>
              <p className="amount text-xs text-muted-foreground">
                {formatCurrency(totalById[m.id] ?? 0, bill.settings.currency)}
              </p>
            </div>
            <button onClick={() => togglePaid(m.id)}>
              {isPaid ? (
                <Badge variant="settled">
                  <Check className="mr-1 h-3 w-3" />
                  {t('paid')}
                </Badge>
              ) : (
                <Badge variant="muted">{t('unpaid')}</Badge>
              )}
            </button>
            {editable && (
              <button onClick={() => removeMember(m.id)} className="text-destructive">
                <Trash2 className="h-4 w-4" />
              </button>
            )}
          </div>
        )
      })}

      {editable && (
        <Button variant="secondary" onClick={() => setOpen(true)}>
          <Plus className="h-4 w-4" /> {t('add_member')}
        </Button>
      )}

      <Dialog open={open} onOpenChange={setOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>{t('add_member')}</DialogTitle>
          </DialogHeader>
          <div className="flex flex-col gap-4">
            <div>
              <Label>{t('member_name')}</Label>
              <Input value={name} onChange={(e) => setName(e.target.value)} />
            </div>
            <div>
              <Label>{t('member_color')}</Label>
              <div className="mt-2 flex flex-wrap gap-2">
                {COLORS.map((c) => (
                  <button
                    key={c}
                    onClick={() => setColor(c)}
                    className="h-8 w-8 rounded-full border-2"
                    style={{ backgroundColor: c, borderColor: color === c ? '#000' : 'transparent' }}
                  />
                ))}
              </div>
            </div>
            <div>
              <Label>{t('promptpay')}</Label>
              <Input value={promptpay} onChange={(e) => setPromptpay(e.target.value)} inputMode="numeric" />
            </div>
            <Button onClick={addMember}>{t('add_member')}</Button>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  )
}
