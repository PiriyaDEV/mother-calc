// ============================================================
// Kidtang — Supabase DB helpers v2
// ============================================================
import { createClient } from "@/lib/supabase";
import {
  Profile,
  Group,
  GroupMember,
  Friend,
  Trip,
  Bill,
  BillMember,
  BillItem,
  Notification,
  CreateGroupInput,
  CreateTripInput,
  CreateBillInput,
  AddBillMemberInput,
  AddBillItemInput,
  Settings,
} from "@/lib/types";

// ── Profiles ──────────────────────────────────────────────────

/**
 * Ensure a profile row exists for the current user.
 * Uses upsert with ignoreDuplicates so it's always safe to call.
 */
export async function ensureMyProfile(): Promise<void> {
  const supabase = createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return;

  // Check if profile already exists first (cheapest path)
  const { data: existing } = await supabase
    .from("profiles")
    .select("id")
    .eq("id", user.id)
    .maybeSingle();

  if (existing) return; // already exists, nothing to do

  const username =
    (user.user_metadata?.username as string | undefined)?.toLowerCase().trim() ||
    "user_" + user.id.replace(/-/g, "").slice(0, 8);
  const displayName =
    (user.user_metadata?.full_name as string | undefined) ||
    user.email?.split("@")[0] ||
    username;
  const avatarUrl = (user.user_metadata?.avatar_url as string | undefined) ?? null;

  // Try insert; ignore any duplicate errors (race condition safe)
  const { error } = await supabase.from("profiles").insert({
    id: user.id,
    username,
    display_name: displayName,
    avatar_url: avatarUrl,
  });

  if (error && error.code !== "23505") {
    // username conflict: retry with unique suffix
    if (error.message?.includes("username")) {
      const fallback = "user_" + user.id.replace(/-/g, "").slice(0, 12);
      await supabase.from("profiles").insert({
        id: user.id,
        username: fallback,
        display_name: displayName,
        avatar_url: avatarUrl,
      });
    }
    // else: ignore other errors silently (e.g. RLS, network)
  }
}

export async function getMyProfile(): Promise<Profile | null> {
  const supabase = createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return null;
  const { data } = await supabase
    .from("profiles")
    .select("*")
    .eq("id", user.id)
    .single();
  return data ?? null;
}

export async function upsertProfile(profile: Partial<Profile> & { id: string }): Promise<Profile | null> {
  const supabase = createClient();
  const { id, ...updates } = profile;
  // Always UPDATE (never INSERT) — profile row must already exist.
  // This avoids NOT NULL constraint errors on username when only updating avatar_url etc.
  const { data, error } = await supabase
    .from("profiles")
    .update(updates)
    .eq("id", id)
    .select()
    .single();
  if (error) throw error;
  return data;
}

export async function searchProfileByUsername(username: string): Promise<Profile | null> {
  const supabase = createClient();
  const { data } = await supabase
    .from("profiles")
    .select("*")
    .eq("username", username.toLowerCase().replace(/^@/, ""))
    .single();
  return data ?? null;
}

export async function isUsernameTaken(username: string): Promise<boolean> {
  const supabase = createClient();
  const { data: { user } } = await supabase.auth.getUser();
  const { data } = await supabase
    .from("profiles")
    .select("id")
    .eq("username", username.toLowerCase())
    .neq("id", user?.id ?? "")
    .maybeSingle();
  return !!data;
}

// ── Groups ────────────────────────────────────────────────────

export async function getMyGroups(): Promise<Group[]> {
  const supabase = createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return [];

  // Groups I own
  const { data: owned } = await supabase
    .from("groups")
    .select("*")
    .eq("owner_id", user.id)
    .order("created_at", { ascending: false });

  // Groups I'm a member of (accepted)
  const { data: memberships } = await supabase
    .from("group_members")
    .select("group_id, groups(*)")
    .eq("user_id", user.id)
    .eq("status", "accepted");

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const memberGroups = (memberships ?? [])
    .map((m: any) => m.groups as Group | null)
    .filter(Boolean) as Group[];

  const allGroups = [...(owned ?? []), ...memberGroups];
  // Deduplicate
  const seen = new Set<string>();
  return allGroups.filter((g) => {
    if (seen.has(g.id)) return false;
    seen.add(g.id);
    return true;
  });
}

export async function createGroup(input: CreateGroupInput): Promise<Group> {
  const supabase = createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) throw new Error("Not authenticated");

  // Ensure profile row exists before FK reference
  await ensureMyProfile();

  const { data, error } = await supabase
    .from("groups")
    .insert({ ...input, owner_id: user.id })
    .select()
    .single();
  if (error) throw error;

  // Add owner as accepted member
  await supabase.from("group_members").insert({
    group_id: data.id,
    user_id: user.id,
    role: "owner",
    status: "accepted",
  });

  return data;
}

export async function getGroup(groupId: string): Promise<Group | null> {
  const supabase = createClient();
  const { data } = await supabase
    .from("groups")
    .select("*")
    .eq("id", groupId)
    .single();
  return data ?? null;
}

export async function updateGroup(groupId: string, updates: Partial<Pick<Group, "name" | "description" | "emoji" | "tags">>): Promise<void> {
  const supabase = createClient();
  const { error } = await supabase
    .from("groups")
    .update(updates)
    .eq("id", groupId);
  if (error) throw error;
}

export async function deleteGroup(groupId: string): Promise<void> {
  const supabase = createClient();
  const { error } = await supabase.from("groups").delete().eq("id", groupId);
  if (error) throw error;
}

// ── Group Members ─────────────────────────────────────────────

export async function getGroupMembers(groupId: string): Promise<GroupMember[]> {
  const supabase = createClient();
  const { data } = await supabase
    .from("group_members")
    .select("*, profile:profiles!group_members_user_id_fkey(*), invited_by_profile:profiles!group_members_invited_by_fkey(*)")
    .eq("group_id", groupId)
    .order("created_at", { ascending: true });
  return (data ?? []) as GroupMember[];
}

export async function inviteMemberByUsername(groupId: string, username: string): Promise<{ error?: string }> {
  const supabase = createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: "Not authenticated" };

  // Find target user
  const target = await searchProfileByUsername(username);
  if (!target) return { error: `ไม่พบผู้ใช้ @${username}` };
  if (target.id === user.id) return { error: "ไม่สามารถเพิ่มตัวเองได้" };

  // Check already member
  const { data: existing } = await supabase
    .from("group_members")
    .select("id, status")
    .eq("group_id", groupId)
    .eq("user_id", target.id)
    .maybeSingle();

  if (existing) {
    if (existing.status === "accepted") return { error: "ผู้ใช้นี้เป็นสมาชิกอยู่แล้ว" };
    // If pending/declined, update to accepted directly
    await supabase.from("group_members").update({ status: "accepted" }).eq("id", existing.id);
    return {};
  }

  // Insert group_member as accepted directly (no invite flow)
  const { error: memberError } = await supabase
    .from("group_members")
    .insert({
      group_id: groupId,
      user_id: target.id,
      role: "member",
      status: "accepted",
      invited_by: user.id,
    });

  if (memberError) return { error: memberError.message };
  return {};
}

export async function respondToGroupInvite(
  groupMemberId: string,
  accept: boolean
): Promise<void> {
  const supabase = createClient();
  const { error } = await supabase
    .from("group_members")
    .update({ status: accept ? "accepted" : "declined" })
    .eq("id", groupMemberId);
  if (error) throw error;
}

export async function removeGroupMember(groupMemberId: string): Promise<void> {
  const supabase = createClient();
  const { error } = await supabase
    .from("group_members")
    .delete()
    .eq("id", groupMemberId);
  if (error) throw error;
}

// ── Friends ───────────────────────────────────────────────────

/** Get all accepted friends of the current user */
export async function getMyFriends(): Promise<Friend[]> {
  const supabase = createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return [];
  const { data } = await supabase
    .from("friends")
    .select("*, requester:profiles!friends_requester_id_fkey(*), addressee:profiles!friends_addressee_id_fkey(*)")
    .or(`requester_id.eq.${user.id},addressee_id.eq.${user.id}`)
    .eq("status", "accepted")
    .order("created_at", { ascending: false });
  return (data ?? []) as Friend[];
}

/** Get pending friend requests sent TO the current user */
export async function getPendingFriendRequests(): Promise<Friend[]> {
  const supabase = createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return [];
  const { data } = await supabase
    .from("friends")
    .select("*, requester:profiles!friends_requester_id_fkey(*), addressee:profiles!friends_addressee_id_fkey(*)")
    .eq("addressee_id", user.id)
    .eq("status", "pending")
    .order("created_at", { ascending: false });
  return (data ?? []) as Friend[];
}

/** Send a friend request by username */
export async function sendFriendRequest(username: string): Promise<{ error?: string }> {
  const supabase = createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: "Not authenticated" };

  const target = await searchProfileByUsername(username);
  if (!target) return { error: `ไม่พบผู้ใช้ @${username}` };
  if (target.id === user.id) return { error: "ไม่สามารถเพิ่มตัวเองเป็นเพื่อนได้" };

  // Check existing relationship (either direction)
  const { data: existing } = await supabase
    .from("friends")
    .select("id, status")
    .or(`and(requester_id.eq.${user.id},addressee_id.eq.${target.id}),and(requester_id.eq.${target.id},addressee_id.eq.${user.id})`)
    .maybeSingle();

  if (existing) {
    if (existing.status === "accepted") return { error: "เป็นเพื่อนกันอยู่แล้ว" };
    if (existing.status === "pending") return { error: "ส่งคำขอไปแล้ว หรือมีคำขอรอการตอบรับ" };
  }

  const { error } = await supabase.from("friends").insert({
    requester_id: user.id,
    addressee_id: target.id,
    status: "pending",
  });

  if (error) return { error: error.message };
  return {};
}

/** Accept a friend request */
export async function acceptFriendRequest(friendId: string): Promise<void> {
  const supabase = createClient();
  await supabase.from("friends").update({ status: "accepted" }).eq("id", friendId);
}

/** Decline a friend request */
export async function declineFriendRequest(friendId: string): Promise<void> {
  const supabase = createClient();
  await supabase.from("friends").update({ status: "declined" }).eq("id", friendId);
}

/** Remove a friend (delete the row) */
export async function removeFriend(friendId: string): Promise<void> {
  const supabase = createClient();
  await supabase.from("friends").delete().eq("id", friendId);
}

// ── Notifications ─────────────────────────────────────────────

export async function getMyNotifications(): Promise<Notification[]> {
  const supabase = createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return [];
  const { data } = await supabase
    .from("notifications")
    .select("*")
    .eq("user_id", user.id)
    .order("created_at", { ascending: false })
    .limit(50);
  return (data ?? []) as Notification[];
}

export async function getUnreadNotificationCount(): Promise<number> {
  const supabase = createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return 0;
  const { count } = await supabase
    .from("notifications")
    .select("*", { count: "exact", head: true })
    .eq("user_id", user.id)
    .eq("read", false);
  return count ?? 0;
}

export async function markNotificationRead(notificationId: string): Promise<void> {
  const supabase = createClient();
  await supabase
    .from("notifications")
    .update({ read: true })
    .eq("id", notificationId);
}

export async function markAllNotificationsRead(): Promise<void> {
  const supabase = createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return;
  await supabase
    .from("notifications")
    .update({ read: true })
    .eq("user_id", user.id)
    .eq("read", false);
}

// ── Trips ─────────────────────────────────────────────────────

export async function getTrips(groupId?: string | null): Promise<Trip[]> {
  const supabase = createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return [];

  let query = supabase.from("trips").select("*");

  if (groupId) {
    query = query.eq("group_id", groupId);
  } else {
    query = query.eq("owner_id", user.id).is("group_id", null);
  }

  const { data } = await query.order("created_at", { ascending: false });
  return (data ?? []) as Trip[];
}

export async function createTrip(input: CreateTripInput): Promise<Trip> {
  const supabase = createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) throw new Error("Not authenticated");

  const { data, error } = await supabase
    .from("trips")
    .insert({ ...input, owner_id: user.id })
    .select()
    .single();
  if (error) throw error;
  return data;
}

export async function updateTrip(tripId: string, updates: Partial<Pick<Trip, "name">>): Promise<void> {
  const supabase = createClient();
  const { error } = await supabase.from("trips").update(updates).eq("id", tripId);
  if (error) throw error;
}

export async function deleteTrip(tripId: string): Promise<void> {
  const supabase = createClient();
  const { error } = await supabase.from("trips").delete().eq("id", tripId);
  if (error) throw error;
}

// ── Bills ─────────────────────────────────────────────────────

export async function getBills(opts: {
  groupId?: string | null;
  tripId?: string | null;
  individual?: boolean;
}): Promise<Bill[]> {
  const supabase = createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return [];

  let query = supabase
    .from("bills")
    .select("*, members:bill_members(*, profile:profiles(*)), items:bill_items(*)");

  if (opts.tripId) {
    query = query.eq("trip_id", opts.tripId);
  } else if (opts.groupId) {
    query = query.eq("group_id", opts.groupId).is("trip_id", null);
  } else if (opts.individual) {
    query = query.eq("owner_id", user.id).is("group_id", null).is("trip_id", null);
  }

  const { data } = await query.order("created_at", { ascending: false });
  return (data ?? []) as Bill[];
}

export async function getIndividualBills(): Promise<Bill[]> {
  const supabase = createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return [];
  const { data } = await supabase
    .from("bills")
    .select("*, members:bill_members(*, profile:profiles(*)), items:bill_items(*)")
    .eq("owner_id", user.id)
    .is("group_id", null)
    .order("created_at", { ascending: false });
  return (data ?? []) as Bill[];
}

export async function getBill(billId: string): Promise<Bill | null> {
  const supabase = createClient();
  const { data } = await supabase
    .from("bills")
    .select("*, members:bill_members(*, profile:profiles(*)), items:bill_items(*)")
    .eq("id", billId)
    .single();
  return data ?? null;
}

export async function createBill(input: CreateBillInput): Promise<Bill> {
  const supabase = createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) throw new Error("Not authenticated");

  // Ensure profile row exists before FK reference
  await ensureMyProfile();

  const { data, error } = await supabase
    .from("bills")
    .insert({
      title: input.title,
      emoji: input.emoji ?? null,
      tags: input.tags ?? [],
      trip_id: input.trip_id ?? null,
      group_id: input.group_id ?? null,
      owner_id: user.id,
      settings: input.settings ?? {},
    })
    .select()
    .single();
  if (error) throw error;
  return data;
}

export async function updateBill(
  billId: string,
  updates: Partial<Pick<Bill, "title" | "emoji" | "tags" | "settings" | "tip" | "discount">>
): Promise<void> {
  const supabase = createClient();
  const { error } = await supabase.from("bills").update(updates).eq("id", billId);
  if (error) throw error;
}

export async function deleteBill(billId: string): Promise<void> {
  const supabase = createClient();
  const { error } = await supabase.from("bills").delete().eq("id", billId);
  if (error) throw error;
}

// ── Bill Members ──────────────────────────────────────────────

export async function getBillMembers(billId: string): Promise<BillMember[]> {
  const supabase = createClient();
  const { data } = await supabase
    .from("bill_members")
    .select("*, profile:profiles(*)")
    .eq("bill_id", billId)
    .order("created_at", { ascending: true });
  return (data ?? []) as BillMember[];
}

export async function addBillMember(input: AddBillMemberInput): Promise<BillMember> {
  const supabase = createClient();
  const { data, error } = await supabase
    .from("bill_members")
    .insert({
      bill_id: input.bill_id,
      user_id: input.user_id ?? null,
      name: input.name,
      color: input.color,
      promptpay: input.promptpay ?? null,
      is_external: input.is_external ?? !input.user_id,
    })
    .select("*, profile:profiles(*)")
    .single();
  if (error) throw error;
  return data as BillMember;
}

export async function updateBillMember(
  memberId: string,
  updates: Partial<Pick<BillMember, "name" | "color" | "promptpay">>
): Promise<void> {
  const supabase = createClient();
  const { error } = await supabase
    .from("bill_members")
    .update(updates)
    .eq("id", memberId);
  if (error) throw error;
}

export async function removeBillMember(memberId: string): Promise<void> {
  const supabase = createClient();
  const { error } = await supabase.from("bill_members").delete().eq("id", memberId);
  if (error) throw error;
}

// ── Bill Items ────────────────────────────────────────────────

export async function getBillItems(billId: string): Promise<BillItem[]> {
  const supabase = createClient();
  const { data } = await supabase
    .from("bill_items")
    .select("*")
    .eq("bill_id", billId)
    .order("created_at", { ascending: true });
  return (data ?? []) as BillItem[];
}

export async function addBillItem(input: AddBillItemInput): Promise<BillItem> {
  const supabase = createClient();
  const { data, error } = await supabase
    .from("bill_items")
    .insert({
      bill_id: input.bill_id,
      name: input.name,
      price: input.price,
      shares: input.shares,
      paid_by: input.paid_by ?? null,
    })
    .select()
    .single();
  if (error) throw error;
  return data as BillItem;
}

export async function updateBillItem(
  itemId: string,
  updates: Partial<Pick<BillItem, "name" | "price" | "shares" | "paid_by">>
): Promise<void> {
  const supabase = createClient();
  const { error } = await supabase
    .from("bill_items")
    .update(updates)
    .eq("id", itemId);
  if (error) throw error;
}

export async function removeBillItem(itemId: string): Promise<void> {
  const supabase = createClient();
  const { error } = await supabase.from("bill_items").delete().eq("id", itemId);
  if (error) throw error;
}

export async function updateBillSettings(
  billId: string,
  settings: Settings,
  tip: number,
  discount: number
): Promise<void> {
  const supabase = createClient();
  const { error } = await supabase
    .from("bills")
    .update({ settings, tip, discount })
    .eq("id", billId);
  if (error) throw error;
}

// ── Bill status & payment tracking ───────────────────────────

/** Mark a bill as completed (locked for editing). Owner only. */
export async function completeBill(billId: string): Promise<void> {
  const supabase = createClient();
  const { error } = await supabase
    .from("bills")
    .update({ status: "completed" })
    .eq("id", billId);
  if (error) throw error;
}

/** Reopen a completed bill back to draft. Owner only. */
export async function reopenBill(billId: string): Promise<void> {
  const supabase = createClient();
  const { error } = await supabase
    .from("bills")
    .update({ status: "draft" })
    .eq("id", billId);
  if (error) throw error;
}

/**
 * Toggle a bill_member as paid/unpaid.
 * Adds or removes the memberId from the paid_member_ids JSON array.
 * Uses a simple read-modify-write since Supabase JS doesn't support
 * jsonb array operations directly.
 */
export async function toggleMemberPaid(
  billId: string,
  memberId: string,
  currentPaidIds: string[]
): Promise<string[]> {
  const supabase = createClient();
  const alreadyPaid = currentPaidIds.includes(memberId);
  const newPaidIds = alreadyPaid
    ? currentPaidIds.filter((id) => id !== memberId)
    : [...currentPaidIds, memberId];

  const { error } = await supabase
    .from("bills")
    .update({ paid_member_ids: newPaidIds })
    .eq("id", billId);
  if (error) throw error;
  return newPaidIds;
}
