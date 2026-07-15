import type { SupabaseClient } from '@supabase/supabase-js'
import type { Profile } from '@/types/profile'
import { mapProfile } from './mappers'

export async function fetchProfile(
  supabase: SupabaseClient,
  id: string
): Promise<Profile | null> {
  const { data, error } = await supabase
    .from('profiles')
    .select('*')
    .eq('id', id)
    .maybeSingle()
  if (error) throw error
  return data ? mapProfile(data) : null
}

export async function searchProfilesByUsername(
  supabase: SupabaseClient,
  query: string
): Promise<Profile[]> {
  if (!query.trim()) return []
  const { data, error } = await supabase
    .from('profiles')
    .select('*')
    .ilike('username', `%${query.trim()}%`)
    .limit(10)
  if (error) throw error
  return (data ?? []).map(mapProfile)
}
