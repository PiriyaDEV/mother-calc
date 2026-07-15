import type { MembershipStatus } from './group'

export interface Friend {
  id: string
  requesterId: string
  addresseeId: string
  status: MembershipStatus
  // joined profile of the *other* person
  userId: string
  displayName: string | null
  username: string | null
  avatarUrl: string | null
  createdAt: string
}
