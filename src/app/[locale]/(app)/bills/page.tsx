import { setRequestLocale } from 'next-intl/server'
import { createClient } from '@/lib/supabase/server'
import { fetchBills } from '@/repositories/bills-repository'
import { BillsList } from '@/components/bill/bills-list'

export default async function BillsPage({
  params,
}: {
  params: Promise<{ locale: string }>
}) {
  const { locale } = await params
  setRequestLocale(locale)

  const supabase = await createClient()
  const bills = await fetchBills(supabase).catch(() => [])

  return <BillsList initialBills={bills} />
}
