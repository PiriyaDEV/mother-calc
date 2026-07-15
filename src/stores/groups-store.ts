import { create } from 'zustand'
import type { Group } from '@/types/group'

interface GroupsStore {
  groups: Record<string, Group>
  setGroups: (groups: Group[]) => void
  upsertGroup: (group: Group) => void
  deleteGroup: (id: string) => void
  list: () => Group[]
}

export const useGroupsStore = create<GroupsStore>((set, get) => ({
  groups: {},
  setGroups: (groups) =>
    set({ groups: Object.fromEntries(groups.map((g) => [g.id, g])) }),
  upsertGroup: (group) =>
    set((s) => ({ groups: { ...s.groups, [group.id]: group } })),
  deleteGroup: (id) =>
    set((s) => {
      const next = { ...s.groups }
      delete next[id]
      return { groups: next }
    }),
  list: () =>
    Object.values(get().groups).sort(
      (a, b) => +new Date(b.createdAt) - +new Date(a.createdAt)
    ),
}))
