import { create } from 'zustand'
import type { Friend } from '@/types/friend'

interface FriendsStore {
  friends: Friend[]
  setFriends: (friends: Friend[]) => void
  removeFriend: (id: string) => void
  accepted: () => Friend[]
  pending: (myId: string) => Friend[]
}

export const useFriendsStore = create<FriendsStore>((set, get) => ({
  friends: [],
  setFriends: (friends) => set({ friends }),
  removeFriend: (id) => set((s) => ({ friends: s.friends.filter((f) => f.id !== id) })),
  accepted: () => get().friends.filter((f) => f.status === 'accepted'),
  // Incoming requests I need to respond to.
  pending: (myId) =>
    get().friends.filter((f) => f.status === 'pending' && f.addresseeId === myId),
}))
