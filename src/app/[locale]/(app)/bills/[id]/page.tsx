import { notFound } from 'next/navigation'
import { setRequestLocale } from 'next-intl/server'
import { createClient } from '@/lib/supabase/server'
import { fetchBill } from '@/repositories/bills-repository'
import { BillDetail } from '@/components/bill/bill-detail'

export default async function BillDetailPage({
  params,
  searchParams,
}: {
  params: Promise<{ locale: string; id: string }>
  searchParams: Promise<{ tab?: string }>
}) {
  const { locale, id } = await params
  const { tab } = await searchParams
  setRequestLocale(locale)

  const supabase = await createClient()
  const {
    data: { user },
  } = await supabase.auth.getUser()

  const bill = await fetchBill(supabase, id).catch(() => null)
  if (!bill) notFound()

  return <BillDetail initialBill={bill} myUserId={user?.id ?? ''} initialTab={tab ?? 'members'} />
}
