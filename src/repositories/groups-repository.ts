import type { SupabaseClient } from '@supabase/supabase-js'
import type { Group } from '@/types/group'
import { mapGroup } from './mappers'

const GROUP_SELECT = `
  *,
  group_members ( *, profiles ( display_name, username, avatar_url ) )
`

export async function fetchGroups(supabase: SupabaseClient): Promise<Group[]> {
  const { data, error } = await supabase
    .from('groups')
    .select(GROUP_SELECT)
    .order('created_at', { ascending: false })
  if (error) throw error
  return (data ?? []).map(mapGroup)
}

export async function fetchGroup(
  supabase: SupabaseClient,
  id: string
): Promise<Group | null> {
  const { data, error } = await supabase
    .from('groups')
    .select(GROUP_SELECT)
    .eq('id', id)
    .maybeSingle()
  if (error) throw error
  return data ? mapGroup(data) : null
}
