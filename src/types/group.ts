export type GroupRole = 'owner' | 'member'
export type MembershipStatus = 'pending' | 'accepted' | 'declined'

export interface GroupMember {
  id: string
  groupId: string
  userId: string
  role: GroupRole
  status: MembershipStatus
  invitedBy: string | null
  // joined profile
  displayName?: string | null
  username?: string | null
  avatarUrl?: string | null
}

export interface Group {
  id: string
  name: string
  description: string | null
  emoji: string
  tags: string[]
  ownerId: string
  members: GroupMember[]
  createdAt: string
  updatedAt: string
}
