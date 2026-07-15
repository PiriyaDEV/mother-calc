import type { SupabaseClient } from '@supabase/supabase-js'
import type { Friend } from '@/types/friend'
import { mapFriend } from './mappers'

const FRIEND_SELECT = `
  *,
  requester:profiles!friends_requester_id_fkey ( id, display_name, username, avatar_url ),
  addressee:profiles!friends_addressee_id_fkey ( id, display_name, username, avatar_url )
`

export async function fetchFriends(
  supabase: SupabaseClient,
  myId: string
): Promise<Friend[]> {
  const { data, error } = await supabase
    .from('friends')
    .select(FRIEND_SELECT)
    .or(`requester_id.eq.${myId},addressee_id.eq.${myId}`)
    .order('created_at', { ascending: false })
  if (error) throw error
  return (data ?? []).map((row) => mapFriend(row, myId))
}
