import type { SupabaseClient } from '@supabase/supabase-js'
import type { Bill } from '@/types/bill'
import { mapBill } from './mappers'

const BILL_SELECT = `
  *,
  bill_members ( *, profiles ( avatar_url, promptpay ) ),
  bill_items ( * )
`

export async function fetchBills(supabase: SupabaseClient): Promise<Bill[]> {
  const { data, error } = await supabase
    .from('bills')
    .select(BILL_SELECT)
    .order('created_at', { ascending: false })
  if (error) throw error
  return (data ?? []).map(mapBill)
}

export async function fetchBill(
  supabase: SupabaseClient,
  id: string
): Promise<Bill | null> {
  const { data, error } = await supabase
    .from('bills')
    .select(BILL_SELECT)
    .eq('id', id)
    .maybeSingle()
  if (error) throw error
  return data ? mapBill(data) : null
}

export async function fetchGroupBills(
  supabase: SupabaseClient,
  groupId: string
): Promise<Bill[]> {
  const { data, error } = await supabase
    .from('bills')
    .select(BILL_SELECT)
    .eq('group_id', groupId)
    .order('created_at', { ascending: false })
  if (error) throw error
  return (data ?? []).map(mapBill)
}
