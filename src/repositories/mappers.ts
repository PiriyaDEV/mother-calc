import type { Bill, BillItem, BillMember, BillSettings } from '@/types/bill'
import type { Friend } from '@/types/friend'
import type { Group, GroupMember } from '@/types/group'
import type { Profile } from '@/types/profile'

/* eslint-disable @typescript-eslint/no-explicit-any */

const DEFAULT_SETTINGS: BillSettings = {
  serviceCharge: 10,
  vat: 7,
  isService: false,
  isVat: false,
  roundingMode: 'none',
  currency: 'THB',
}

function asArray<T>(v: unknown): T[] {
  if (Array.isArray(v)) return v as T[]
  if (typeof v === 'string') {
    try {
      const p = JSON.parse(v)
      return Array.isArray(p) ? p : []
    } catch {
      return []
    }
  }
  return []
}

export function mapProfile(row: any): Profile {
  return {
    id: row.id,
    username: row.username,
    displayName: row.display_name,
    avatarUrl: row.avatar_url,
    promptpay: row.promptpay,
    onboardingCompleted: !!row.onboarding_completed,
    locale: row.locale ?? 'th',
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  }
}

export function mapMember(row: any): BillMember {
  return {
    id: row.id,
    billId: row.bill_id,
    userId: row.user_id,
    name: row.name,
    color: row.color ?? '#3b82f6',
    promptpay: row.promptpay ?? row.profiles?.promptpay ?? null,
    isExternal: !!row.is_external,
    profile: row.profiles ? { avatarUrl: row.profiles.avatar_url ?? null } : undefined,
  }
}

export function mapItem(row: any): BillItem {
  return {
    id: row.id,
    billId: row.bill_id,
    name: row.name,
    price: Number(row.price ?? 0),
    quantity: Number(row.quantity ?? 1),
    memberIds: asArray<string>(row.member_ids),
    customShares: (row.custom_shares && typeof row.custom_shares === 'object'
      ? row.custom_shares
      : {}) as Record<string, number>,
    paidBy: row.paid_by ?? null,
  }
}

export function mapBill(row: any): Bill {
  const settings = { ...DEFAULT_SETTINGS, ...(row.settings ?? {}) } as BillSettings
  return {
    id: row.id,
    title: row.title,
    emoji: row.emoji ?? '🧾',
    tags: asArray<string>(row.tags),
    status: row.status ?? 'draft',
    ownerId: row.owner_id,
    groupId: row.group_id ?? null,
    settings,
    tip: Number(row.tip ?? 0),
    discount: Number(row.discount ?? 0),
    paidMemberIds: asArray<string>(row.paid_member_ids),
    total: Number(row.total ?? 0),
    itemCount: Number(row.item_count ?? 0),
    members: (row.bill_members ?? []).map(mapMember),
    items: (row.bill_items ?? []).map(mapItem),
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  }
}

export function mapGroupMember(row: any): GroupMember {
  return {
    id: row.id,
    groupId: row.group_id,
    userId: row.user_id,
    role: row.role ?? 'member',
    status: row.status ?? 'pending',
    invitedBy: row.invited_by ?? null,
    displayName: row.profiles?.display_name ?? null,
    username: row.profiles?.username ?? null,
    avatarUrl: row.profiles?.avatar_url ?? null,
  }
}

export function mapGroup(row: any): Group {
  return {
    id: row.id,
    name: row.name,
    description: row.description ?? null,
    emoji: row.emoji ?? '👥',
    tags: asArray<string>(row.tags),
    ownerId: row.owner_id,
    members: (row.group_members ?? []).map(mapGroupMember),
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  }
}

/** Map a friends row into the perspective of `me` (the other party's profile). */
export function mapFriend(row: any, myId: string): Friend {
  const other = row.requester_id === myId ? row.addressee : row.requester
  return {
    id: row.id,
    requesterId: row.requester_id,
    addresseeId: row.addressee_id,
    status: row.status,
    userId: other?.id ?? '',
    displayName: other?.display_name ?? null,
    username: other?.username ?? null,
    avatarUrl: other?.avatar_url ?? null,
    createdAt: row.created_at,
  }
}
