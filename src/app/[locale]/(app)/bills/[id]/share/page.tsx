import { notFound } from 'next/navigation'
import Image from 'next/image'
import { setRequestLocale } from 'next-intl/server'
import { createServiceClient } from '@/lib/supabase/server'
import { fetchBill } from '@/repositories/bills-repository'
import { calculateBill, simplifyDebts } from '@/lib/utils/bill-utils'
import { formatCurrency } from '@/lib/utils/format'
import { AvatarCircles } from '@/components/magic/avatar-circles'

// Public, no-auth read-only view. Uses the service-role client to bypass RLS.
export default async function ShareBillPage({
  params,
}: {
  params: Promise<{ locale: string; id: string }>
}) {
  const { locale, id } = await params
  setRequestLocale(locale)

  const supabase = createServiceClient()
  const bill = await fetchBill(supabase, id).catch(() => null)
  if (!bill) notFound()

  const calc = calculateBill(bill)
  const debts = simplifyDebts(calc.memberSummaries, bill.members, undefined, bill.ownerId)
  const cur = bill.settings.currency

  return (
    <main className="mx-auto min-h-dvh max-w-md px-4 py-8">
      <div className="mb-6 flex items-center gap-3">
        <Image src="/logo.png" alt="Kidtang" width={40} height={40} className="rounded-xl" />
        <div>
          <p className="text-xs text-muted-foreground">กิดตัง</p>
          <h1 className="text-xl font-bold">
            {bill.emoji} {bill.title}
          </h1>
        </div>
      </div>

      <div className="card-surface mb-4 p-5">
        <h3 className="mb-3 font-bold">รายละเอียดยอด</h3>
        <div className="flex flex-col gap-1 text-sm">
          <Row label="ยอดรวมย่อย" value={formatCurrency(calc.subtotal, cur)} />
          {calc.serviceAmount > 0 && <Row label="ค่าบริการ" value={formatCurrency(calc.serviceAmount, cur)} />}
          {calc.vatAmount > 0 && <Row label="VAT" value={formatCurrency(calc.vatAmount, cur)} />}
          {calc.tipAmount > 0 && <Row label="ทิป" value={formatCurrency(calc.tipAmount, cur)} />}
          {calc.discountAmount > 0 && <Row label="ส่วนลด" value={`-${formatCurrency(calc.discountAmount, cur)}`} />}
          <div className="mt-1 flex justify-between border-t border-border pt-2 font-bold">
            <span>รวมทั้งหมด</span>
            <span className="amount">{formatCurrency(calc.total, cur)}</span>
          </div>
        </div>
      </div>

      <div className="card-surface mb-4 p-5">
        <h3 className="mb-3 font-bold">รายการ</h3>
        <div className="flex flex-col gap-2 text-sm">
          {bill.items.map((it) => (
            <div key={it.id} className="flex justify-between">
              <span>{it.name}</span>
              <span className="amount">{formatCurrency(it.price, cur)}</span>
            </div>
          ))}
        </div>
      </div>

      <div className="card-surface p-5">
        <h3 className="mb-3 font-bold">💸 สรุปการโอนเงิน</h3>
        <div className="flex flex-col gap-2">
          {debts.map((d, i) => (
            <div key={i} className="flex items-center gap-2 text-sm">
              <AvatarCircles avatars={[{ name: d.from.name, color: d.from.color }]} size={28} />
              <span className="text-xs">→</span>
              <AvatarCircles avatars={[{ name: d.to.name, color: d.to.color }]} size={28} />
              <span className="flex-1 truncate">
                {d.from.name} → {d.to.name}
              </span>
              <span className="amount font-bold">{formatCurrency(d.amount, cur)}</span>
            </div>
          ))}
          {debts.length === 0 && <p className="text-center text-muted-foreground">✅</p>}
        </div>
      </div>
    </main>
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
