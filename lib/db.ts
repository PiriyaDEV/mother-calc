// ============================================================
// Kidtang — Supabase DB helpers v2
// ============================================================
import { createClient } from "@/lib/supabase";
import {
  Profile,
  Group,
  GroupMember,
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
  const { data, error } = await supabase
    .from("profiles")
    .upsert(profile, { onConflict: "id" })
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

export async function updateGroup(groupId: string, updates: Partial<Pick<Group, "name" | "description">>): Promise<void> {
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
  if (target.id === user.id) return { error: "ไม่สามารถเชิญตัวเองได้" };

  // Check already member
  const { data: existing } = await supabase
    .from("group_members")
    .select("id, status")
    .eq("group_id", groupId)
    .eq("user_id", target.id)
    .maybeSingle();

  if (existing) {
    if (existing.status === "accepted") return { error: "ผู้ใช้นี้เป็นสมาชิกอยู่แล้ว" };
    if (existing.status === "pending") return { error: "ส่งคำเชิญไปแล้ว รอการตอบรับ" };
  }

  // Get group info for notification
  const group = await getGroup(groupId);
  if (!group) return { error: "ไม่พบกลุ่ม" };

  // Get inviter profile
  const inviterProfile = await getMyProfile();

  // Insert group_member (pending)
  const { data: member, error: memberError } = await supabase
    .from("group_members")
    .insert({
      group_id: groupId,
      user_id: target.id,
      role: "member",
      status: "pending",
      invited_by: user.id,
    })
    .select()
    .single();

  if (memberError) return { error: memberError.message };

  // Create notification
  await supabase.from("notifications").insert({
    user_id: target.id,
    type: "group_invite",
    data: {
      group_id: groupId,
      group_name: group.name,
      invited_by_username: inviterProfile?.username ?? "",
      invited_by_display_name: inviterProfile?.display_name ?? "",
      group_member_id: member.id,
    },
  });

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

  let query = supabase.from("bills").select("*");

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
    .select("*")
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
  updates: Partial<Pick<Bill, "title" | "settings" | "tip" | "discount">>
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
    })
    .select()
    .single();
  if (error) throw error;
  return data as BillItem;
}

export async function updateBillItem(
  itemId: string,
  updates: Partial<Pick<BillItem, "name" | "price" | "shares">>
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
