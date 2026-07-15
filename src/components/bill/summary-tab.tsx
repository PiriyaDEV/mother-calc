'use client'

import { useMemo, useRef, useState } from 'react'
import { Copy, QrCode, Share2, ImageDown, FileDown } from 'lucide-react'
import { useTranslations } from 'next-intl'
import { toPng } from 'html-to-image'
import { calculateBill, simplifyDebts } from '@/lib/utils/bill-utils'
import { formatCurrency } from '@/lib/utils/format'
import { AnimatedList } from '@/components/magic/animated-list'
import { AvatarCircles } from '@/components/magic/avatar-circles'
import { ShimmerButton } from '@/components/magic/shimmer-button'
import { PromptPayQR } from '@/components/shared/promptpay-qr'
import { Button } from '@/components/ui/button'
import { Switch } from '@/components/ui/switch'
import { toast } from '@/components/ui/toast'
import { cn } from '@/lib/utils/cn'
import type { Bill, DebtTransaction } from '@/types/bill'

export function SummaryTab({
  bill,
  myUserId,
}: {
  bill: Bill
  myUserId: string
  onChange: () => void
}) {
  const t = useTranslations('bills')
  const tc = useTranslations('common')
  const captureRef = useRef<HTMLDivElement>(null)
  const [myViewOnly, setMyViewOnly] = useState(false)
  const [qr, setQr] = useState<DebtTransaction | null>(null)

  const calc = useMemo(() => calculateBill(bill), [bill])
  const debts = useMemo(
    () => simplifyDebts(calc.memberSummaries, bill.members, undefined, bill.ownerId),
    [calc, bill]
  )

  const myMemberIds = new Set(bill.members.filter((m) => m.userId === myUserId).map((m) => m.id))
  const filtered = myViewOnly
    ? debts.filter((d) => myMemberIds.has(d.from.id) || myMemberIds.has(d.to.id))
    : debts

  async function copyLink() {
    const url = `${window.location.origin}/bills/${bill.id}/share`
    await navigator.clipboard.writeText(url)
    toast(tc('copied'))
  }

  function copyTransfer(d: DebtTransaction) {
    const msg = t('copy_transfer', {
      amount: formatCurrency(d.amount, bill.settings.currency),
      name: d.to.name,
      promptpay: d.to.promptpay ?? '-',
    })
    navigator.clipboard.writeText(msg)
    toast(tc('copied'))
  }

  async function exportPng() {
    if (!captureRef.current) return
    try {
      const dataUrl = await toPng(captureRef.current, { pixelRatio: 2, backgroundColor: '#ffffff' })
      const a = document.createElement('a')
      a.href = dataUrl
      a.download = `${bill.title}.png`
      a.click()
    } catch {
      toast('export failed', 'error')
    }
  }

  async function exportPdf() {
    const [{ pdf }, { BillPdf }] = await Promise.all([
      import('@react-pdf/renderer'),
      import('@/components/bill/bill-pdf'),
    ])
    const blob = await pdf(<BillPdf bill={bill} calc={calc} debts={debts} />).toBlob()
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = `${bill.title}.pdf`
    a.click()
    URL.revokeObjectURL(url)
  }

  return (
    <div className="flex flex-col gap-4">
      <div ref={captureRef} className="flex flex-col gap-4 bg-background">
        {/* Breakdown */}
        <div className="card-surface p-5">
          <h3 className="mb-3 font-bold">{t('breakdown')}</h3>
          <div className="flex flex-col gap-1 text-sm">
            <BreakRow label={t('subtotal')} value={formatCurrency(calc.subtotal, bill.settings.currency)} />
            {calc.serviceAmount > 0 && (
              <BreakRow label={t('service_charge')} value={formatCurrency(calc.serviceAmount, bill.settings.currency)} />
            )}
            {calc.vatAmount > 0 && (
              <BreakRow label={t('vat')} value={formatCurrency(calc.vatAmount, bill.settings.currency)} />
            )}
            {calc.tipAmount > 0 && (
              <BreakRow label={t('tip')} value={formatCurrency(calc.tipAmount, bill.settings.currency)} />
            )}
            {calc.discountAmount > 0 && (
              <BreakRow label={t('discount')} value={`-${formatCurrency(calc.discountAmount, bill.settings.currency)}`} />
            )}
            <div className="mt-1 flex justify-between border-t border-border pt-2 font-bold">
              <span>{t('total')}</span>
              <span className="amount">{formatCurrency(calc.total, bill.settings.currency)}</span>
            </div>
          </div>
        </div>

        {/* Transfers */}
        <div className="card-surface p-5">
          <div className="mb-3 flex items-center justify-between">
            <h3 className="font-bold">💸 {t('transfers')}</h3>
            <label className="flex items-center gap-2 text-xs font-medium">
              {t('my_view')}
              <Switch checked={myViewOnly} onCheckedChange={setMyViewOnly} />
            </label>
          </div>

          {filtered.length === 0 ? (
            <p className="py-4 text-center text-sm text-muted-foreground">{t('paid')} ✅</p>
          ) : (
            <AnimatedList>
              {filtered.map((d, i) => {
                const mine = myMemberIds.has(d.from.id) || myMemberIds.has(d.to.id)
                return (
                  <div
                    key={i}
                    className={cn(
                      'flex items-center gap-2 rounded-xl p-2',
                      mine && 'border-l-4 border-primary bg-primary-50'
                    )}
                  >
                    <AvatarCircles avatars={[{ name: d.from.name, color: d.from.color }]} size={30} />
                    <span className="text-xs text-muted-foreground">→</span>
                    <AvatarCircles avatars={[{ name: d.to.name, color: d.to.color }]} size={30} />
                    <span className="flex-1 truncate text-sm">
                      {d.from.name} → {d.to.name}
                    </span>
                    <span className="amount text-sm font-bold">
                      {formatCurrency(d.amount, bill.settings.currency)}
                    </span>
                    <button onClick={() => setQr(d)} className="text-primary">
                      <QrCode className="h-4 w-4" />
                    </button>
                    <button onClick={() => copyTransfer(d)} className="text-muted-foreground">
                      <Copy className="h-4 w-4" />
                    </button>
                  </div>
                )
              })}
            </AnimatedList>
          )}
        </div>
      </div>

      <ShimmerButton onClick={copyLink} className="w-full">
        <Share2 className="h-4 w-4" /> {t('share_link')}
      </ShimmerButton>

      <div className="grid grid-cols-2 gap-2">
        <Button variant="outline" onClick={exportPng}>
          <ImageDown className="h-4 w-4" /> {t('export_png')}
        </Button>
        <Button variant="outline" onClick={exportPdf}>
          <FileDown className="h-4 w-4" /> {t('export_pdf')}
        </Button>
      </div>

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

function BreakRow({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex justify-between text-muted-foreground">
      <span>{label}</span>
      <span className="amount">{value}</span>
    </div>
  )
}
