// ============================================================
// Kidtang — TypeScript Types v2
// ============================================================

export type CurrencyCode = "THB" | "USD" | "EUR" | "JPY" | "SGD" | "GBP" | "CNY" | "KRW";
export type RoundingMode = "none" | "nearest" | "up" | "down";
export type MemberRole = "owner" | "member";
export type MemberStatus = "pending" | "accepted" | "declined";
export type NotificationType = "group_invite";

// ── Settings ──────────────────────────────────────────────────
export interface Settings {
  vat: number;
  serviceCharge: number;
  isVat: boolean;
  isService: boolean;
  roundingMode: RoundingMode;
  currency: CurrencyCode;
}

// ── Profile ───────────────────────────────────────────────────
export interface Profile {
  id: string;
  username: string;       // stored without @
  display_name: string | null;
  avatar_url: string | null;
  created_at: string;
  updated_at: string;
}

// ── Group ─────────────────────────────────────────────────────
export interface Group {
  id: string;
  name: string;
  description: string | null;
  owner_id: string;
  created_at: string;
  updated_at: string;
  // joined via query
  member_count?: number;
  my_role?: MemberRole;
}

// ── Group Member ──────────────────────────────────────────────
export interface GroupMember {
  id: string;
  group_id: string;
  user_id: string;
  role: MemberRole;
  status: MemberStatus;
  invited_by: string | null;
  created_at: string;
  // joined via query
  profile?: Profile;
  invited_by_profile?: Profile;
}

// ── Notification ──────────────────────────────────────────────
export interface Notification {
  id: string;
  user_id: string;
  type: NotificationType;
  data: NotificationData;
  read: boolean;
  created_at: string;
}

export interface NotificationData {
  group_id: string;
  group_name: string;
  invited_by_username: string;
  invited_by_display_name?: string;
  group_member_id: string;
}

// ── Trip ──────────────────────────────────────────────────────
export interface Trip {
  id: string;
  name: string;
  group_id: string | null;
  owner_id: string;
  created_at: string;
  updated_at: string;
  // joined via query
  bill_count?: number;
}

// ── Bill ──────────────────────────────────────────────────────
export interface Bill {
  id: string;
  title: string;
  trip_id: string | null;
  group_id: string | null;
  owner_id: string;
  settings: Settings;
  tip: number;
  discount: number;
  created_at: string;
  updated_at: string;
  // joined via query
  members?: BillMember[];
  items?: BillItem[];
  owner?: Profile;
}

// ── Bill Member ───────────────────────────────────────────────
export interface BillMember {
  id: string;
  bill_id: string;
  user_id: string | null;    // null = external person
  name: string;
  color: string;
  promptpay: string | null;
  is_external: boolean;
  created_at: string;
  // joined via query
  profile?: Profile;
}

// ── Bill Item ─────────────────────────────────────────────────
export interface BillItem {
  id: string;
  bill_id: string;
  name: string;
  price: number;
  shares: Record<string, number>;  // { bill_member_id: weight }
  created_at: string;
}

// ── Computed types for UI ─────────────────────────────────────

/** Per-member summary after calculation */
export interface MemberSummary {
  member: BillMember;
  subtotal: number;   // before tax/service
  total: number;      // final amount to pay
  items: { item: BillItem; amount: number }[];
}

/** Full bill calculation result */
export interface BillCalculation {
  subtotal: number;
  vatAmount: number;
  serviceAmount: number;
  tipAmount: number;
  discountAmount: number;
  total: number;
  memberSummaries: MemberSummary[];
}

// ── Form types ────────────────────────────────────────────────

export interface CreateBillInput {
  title: string;
  trip_id?: string | null;
  group_id?: string | null;
  settings?: Partial<Settings>;
}

export interface CreateGroupInput {
  name: string;
  description?: string;
}

export interface CreateTripInput {
  name: string;
  group_id?: string | null;
}

export interface AddBillMemberInput {
  bill_id: string;
  user_id?: string | null;
  name: string;
  color: string;
  promptpay?: string;
  is_external?: boolean;
}

export interface AddBillItemInput {
  bill_id: string;
  name: string;
  price: number;
  shares: Record<string, number>;
}

// ── App Tab ───────────────────────────────────────────────────
export type AppTab = "members" | "items" | "summary";

// ── Home context ──────────────────────────────────────────────
export type HomeContext = "groups" | "individual";
