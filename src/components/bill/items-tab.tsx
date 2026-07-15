'use client'

import { useMemo, useState } from 'react'
import { Plus, Trash2, Pencil } from 'lucide-react'
import { useTranslations } from 'next-intl'
import { createClient } from '@/lib/supabase/client'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import { Tabs, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { toast } from '@/components/ui/toast'
import { calculateBill } from '@/lib/utils/bill-utils'
import { formatCurrency } from '@/lib/utils/format'
import { cn } from '@/lib/utils/cn'
import type { Bill, BillItem } from '@/types/bill'

export function ItemsTab({
  bill,
  editable,
  onChange,
}: {
  bill: Bill
  editable: boolean
  onChange: () => void
}) {
  const t = useTranslations('bills')
  const [editing, setEditing] = useState<BillItem | null>(null)
  const [open, setOpen] = useState(false)
  const supabase = createClient()

  const calc = calculateBill(bill)

  async function removeItem(id: string) {
    const { error } = await supabase.from('bill_items').delete().eq('id', id)
    if (error) return toast(error.message, 'error')
    onChange()
  }

  return (
    <div className="flex flex-col gap-3 pb-40">
      {bill.items.length === 0 && (
        <p className="py-8 text-center text-sm text-muted-foreground">{t('no_items')}</p>
      )}

      {bill.items.map((item) => {
        const payer = bill.members.find((m) => m.id === item.paidBy)
        return (
          <div key={item.id} className="card-surface flex items-center gap-3 p-3">
            <div className="min-w-0 flex-1">
              <p className="truncate font-medium">{item.name}</p>
              <p className="text-xs text-muted-foreground">
                {item.memberIds.length} {t('tab_members')}
                {payer ? ` · ${t('paid_by')}: ${payer.name}` : ''}
              </p>
            </div>
            <p className="amount font-bold">{formatCurrency(item.price, bill.settings.currency)}</p>
            {editable && (
              <div className="flex gap-1">
                <button
                  onClick={() => {
                    setEditing(item)
                    setOpen(true)
                  }}
                  className="text-muted-foreground"
                >
                  <Pencil className="h-4 w-4" />
                </button>
                <button onClick={() => removeItem(item.id)} className="text-destructive">
                  <Trash2 className="h-4 w-4" />
                </button>
              </div>
            )}
          </div>
        )
      })}

      {editable && (
        <Button
          variant="secondary"
          onClick={() => {
            setEditing(null)
            setOpen(true)
          }}
        >
          <Plus className="h-4 w-4" /> {t('add_item')}
        </Button>
      )}

      {/* Sticky summary bar */}
      <div className="fixed inset-x-0 bottom-24 z-30 mx-auto max-w-md px-4">
        <div className="card-surface flex flex-col gap-1 p-4 text-sm">
          <Row label={t('subtotal')} value={formatCurrency(calc.subtotal, bill.settings.currency)} />
          {calc.serviceAmount > 0 && (
            <Row label={t('service_charge')} value={formatCurrency(calc.serviceAmount, bill.settings.currency)} />
          )}
          {calc.vatAmount > 0 && (
            <Row label={t('vat')} value={formatCurrency(calc.vatAmount, bill.settings.currency)} />
          )}
          {calc.tipAmount > 0 && (
            <Row label={t('tip')} value={formatCurrency(calc.tipAmount, bill.settings.currency)} />
          )}
          {calc.discountAmount > 0 && (
            <Row label={t('discount')} value={`-${formatCurrency(calc.discountAmount, bill.settings.currency)}`} />
          )}
          <div className="mt-1 flex justify-between border-t border-border pt-2 font-bold">
            <span>{t('total')}</span>
            <span className="amount">{formatCurrency(calc.total, bill.settings.currency)}</span>
          </div>
        </div>
      </div>

      {open && (
        <ItemFormModal
          bill={bill}
          item={editing}
          onClose={() => setOpen(false)}
          onSaved={() => {
            setOpen(false)
            onChange()
          }}
        />
      )}
    </div>
  )
}

function Row({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex justify-between text-muted-foreground">
      <span>{label}</span>
      <span className="amount">{value}</span>
    </div>
  )
}

function ItemFormModal({
  bill,
  item,
  onClose,
  onSaved,
}: {
  bill: Bill
  item: BillItem | null
  onClose: () => void
  onSaved: () => void
}) {
  const t = useTranslations('bills')
  const supabase = createClient()

  const [name, setName] = useState(item?.name ?? '')
  const [price, setPrice] = useState(item?.price?.toString() ?? '')
  const [mode, setMode] = useState<'equal' | 'unequal'>(
    item && Object.keys(item.customShares).length > 0 ? 'unequal' : 'equal'
  )
  const [memberIds, setMemberIds] = useState<string[]>(
    item?.memberIds ?? bill.members.map((m) => m.id)
  )
  const [shares, setShares] = useState<Record<string, number>>(item?.customShares ?? {})
  const [paidBy, setPaidBy] = useState<string | null>(item?.paidBy ?? bill.members[0]?.id ?? null)
  const [saving, setSaving] = useState(false)

  const priceNum = parseFloat(price) || 0

  const perPersonPreview = useMemo(() => {
    if (mode === 'equal') {
      const n = memberIds.length || 1
      return priceNum / n
    }
    return 0
  }, [mode, memberIds, priceNum])

  function toggleMember(id: string) {
    setMemberIds((prev) => (prev.includes(id) ? prev.filter((x) => x !== id) : [...prev, id]))
  }

  async function save() {
    if (!name.trim() || priceNum <= 0) return
    setSaving(true)
    const payload = {
      bill_id: bill.id,
      name: name.trim(),
      price: priceNum,
      quantity: 1,
      member_ids: mode === 'unequal' ? Object.keys(shares) : memberIds,
      custom_shares: mode === 'unequal' ? shares : {},
      paid_by: paidBy,
    }
    const { error } = item
      ? await supabase.from('bill_items').update(payload).eq('id', item.id)
      : await supabase.from('bill_items').insert(payload)
    setSaving(false)
    if (error) return toast(error.message, 'error')
    onSaved()
  }

  return (
    <Dialog open onOpenChange={(o) => !o && onClose()}>
      <DialogContent className="max-h-[85vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>{item ? t('edit_title') : t('add_item')}</DialogTitle>
        </DialogHeader>
        <div className="flex flex-col gap-4">
          <div>
            <Label>{t('item_name')}</Label>
            <Input value={name} onChange={(e) => setName(e.target.value)} />
          </div>
          <div>
            <Label>{t('price')}</Label>
            <Input type="number" value={price} onChange={(e) => setPrice(e.target.value)} />
          </div>

          <Tabs value={mode} onValueChange={(v) => setMode(v as 'equal' | 'unequal')}>
            <TabsList className="w-full">
              <TabsTrigger value="equal" className="flex-1">
                {t('split_equal')}
              </TabsTrigger>
              <TabsTrigger value="unequal" className="flex-1">
                {t('split_unequal')}
              </TabsTrigger>
            </TabsList>
          </Tabs>

          <div className="flex flex-col gap-2">
            {bill.members.map((m) => {
              const included = mode === 'equal' ? memberIds.includes(m.id) : (shares[m.id] ?? 0) > 0
              return (
                <div
                  key={m.id}
                  className={cn(
                    'flex items-center gap-3 rounded-xl border px-3 py-2',
                    included ? 'border-primary bg-primary-50' : 'border-border'
                  )}
                >
                  {mode === 'equal' ? (
                    <input
                      type="checkbox"
                      checked={memberIds.includes(m.id)}
                      onChange={() => toggleMember(m.id)}
                      className="h-5 w-5 accent-primary"
                    />
                  ) : (
                    <Input
                      type="number"
                      className="w-16"
                      value={shares[m.id] ?? ''}
                      placeholder="0"
                      onChange={(e) =>
                        setShares((s) => ({ ...s, [m.id]: parseFloat(e.target.value) || 0 }))
                      }
                    />
                  )}
                  <span className="flex-1 text-sm font-medium">{m.name}</span>
                </div>
              )
            })}
          </div>

          {mode === 'equal' && memberIds.length > 0 && priceNum > 0 && (
            <p className="text-center text-sm text-muted-foreground">
              {t('per_person', {
                amount: formatCurrency(perPersonPreview, bill.settings.currency),
                count: memberIds.length,
              })}
            </p>
          )}

          <div>
            <Label>{t('paid_by')}</Label>
            <div className="mt-2 flex flex-wrap gap-2">
              {bill.members.map((m) => (
                <button
                  key={m.id}
                  onClick={() => setPaidBy(m.id)}
                  className={cn(
                    'rounded-full px-3 py-1.5 text-sm font-medium',
                    paidBy === m.id ? 'bg-primary text-white' : 'bg-muted'
                  )}
                >
                  {m.name}
                </button>
              ))}
            </div>
          </div>

          <Button onClick={save} disabled={saving}>
            {saving ? '...' : t('add_item')}
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  )
}
