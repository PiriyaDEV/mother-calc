-- ============================================================
-- Kidtang — Supabase Schema v7
-- Safe to run on an existing DB — drops everything first,
-- then recreates from scratch.
-- ============================================================

-- ============================================================
-- DROP (reverse dependency order)
-- ============================================================

-- Triggers
drop trigger if exists on_auth_user_created       on auth.users;
drop trigger if exists profiles_updated_at        on public.profiles;
drop trigger if exists groups_updated_at          on public.groups;
drop trigger if exists trips_updated_at           on public.trips;
drop trigger if exists bills_updated_at           on public.bills;
drop trigger if exists profiles_sync_names        on public.profiles;
drop trigger if exists push_on_notification_insert on public.notifications;

-- Functions
drop function if exists public.handle_new_user()             cascade;
drop function if exists public.handle_updated_at()            cascade;
drop function if exists public.can_access_bill(uuid)          cascade;
drop function if exists public.is_group_member(uuid)          cascade;
drop function if exists public.is_group_owner(uuid)           cascade;
drop function if exists public.sync_bill_member_names()       cascade;
drop function if exists public.trigger_push_on_notification() cascade;
drop function if exists public.get_line_login_handoff(text)   cascade;
-- Tables (child -> parent order)
drop table if exists public.bill_items          cascade;
drop table if exists public.bill_members        cascade;
drop table if exists public.bills               cascade;
drop table if exists public.trips               cascade;
drop table if exists public.notifications       cascade;
drop table if exists public.friends             cascade;
drop table if exists public.group_members       cascade;
drop table if exists public.groups              cascade;
drop table if exists public.app_config          cascade;
drop table if exists public.line_login_handoffs cascade;
drop table if exists public.profiles            cascade;

-- ============================================================
-- Extensions
-- ============================================================
create extension if not exists "uuid-ossp";
create extension if not exists "pg_net"; -- HTTP calls from Postgres (push notification trigger)

-- ============================================================
-- Tables
-- ============================================================

-- User profiles — one row per auth.users entry.
-- Auto-created by the handle_new_user trigger on signup.
-- username is nullable to support LINE (no email) and other social providers.
create table public.profiles (
  id                   uuid primary key references auth.users(id) on delete cascade,
  username             text unique,
  display_name         text,
  avatar_url           text,
  promptpay            text,
  onboarding_completed boolean not null default false,
  fcm_token            text,                          -- Firebase push notification token
  -- ── i18n preference ─────────────────────────────────────────
  locale               text    not null default 'th',  -- 'th' | 'en'
  created_at           timestamptz not null default now(),
  updated_at           timestamptz not null default now()
);

-- Groups — a shared space that can contain multiple bills/trips.
create table public.groups (
  id          uuid primary key default uuid_generate_v4(),
  name        text not null,
  description text,
  emoji       text,
  tags        text[] not null default '{}',
  owner_id    uuid not null references public.profiles(id) on delete cascade,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- Group membership — links profiles to groups with role & invite status.
create table public.group_members (
  id          uuid primary key default uuid_generate_v4(),
  group_id    uuid not null references public.groups(id) on delete cascade,
  user_id     uuid not null references public.profiles(id) on delete cascade,
  role        text not null default 'member' check (role in ('owner', 'member')), -- 'owner' | 'member'
  status      text not null default 'pending' check (status in ('pending', 'accepted', 'declined')), -- invite lifecycle
  invited_by  uuid references public.profiles(id), -- who sent the invite (nullable)
  created_at  timestamptz not null default now(),
  unique(group_id, user_id)
);

-- Friends — bidirectional friend relationships between users.
-- requester sends request → addressee accepts/declines.
create table public.friends (
  id           uuid primary key default uuid_generate_v4(),
  requester_id uuid not null references public.profiles(id) on delete cascade,
  addressee_id uuid not null references public.profiles(id) on delete cascade,
  status       text not null default 'pending' check (status in ('pending', 'accepted', 'declined')),
  created_at   timestamptz not null default now(),
  unique(requester_id, addressee_id)
);

-- In-app notifications (e.g. group invites).
create table public.notifications (
  id          uuid primary key default uuid_generate_v4(),
  user_id     uuid not null references public.profiles(id) on delete cascade, -- recipient
  type        text not null default 'group_invite', -- notification type key
  data        jsonb not null default '{}',           -- arbitrary payload (group_id, inviter, etc.)
  read        boolean not null default false,        -- whether the user has seen it
  created_at  timestamptz not null default now()
);

-- Trips — optional grouping of bills under a named trip.
create table public.trips (
  id          uuid primary key default uuid_generate_v4(),
  name        text not null,               -- trip name (e.g. "Tokyo 2025")
  group_id    uuid references public.groups(id) on delete cascade, -- optional group scope
  owner_id    uuid not null references public.profiles(id) on delete cascade,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- Bills — the core entity: a single expense-splitting session.
create table public.bills (
  id               uuid primary key default uuid_generate_v4(),
  title            text not null default 'บิลใหม่',  -- bill display name
  emoji            text,                              -- optional emoji icon
  tags             text[] not null default '{}',      -- freeform tags
  trip_id          uuid references public.trips(id) on delete set null,   -- optional trip
  group_id         uuid references public.groups(id) on delete cascade,   -- optional group
  owner_id         uuid not null references public.profiles(id) on delete cascade, -- creator
  settings         jsonb not null default '{"vat":7,"serviceCharge":10,"isVat":false,"isService":false,"roundingMode":"none","currency":"THB"}',
                                                      -- bill-level settings: VAT, service charge, rounding, currency
  tip              numeric not null default 0,        -- tip amount (absolute, not %)
  discount         numeric not null default 0,        -- discount amount (absolute)
  status           text not null default 'draft' check (status in ('draft', 'pending_payment', 'completed')),
                                                      -- 'draft' = editable | 'completed' = locked, payment tracking enabled
  paid_member_ids  jsonb not null default '[]',       -- [uuid] list of bill_member IDs who have paid (updated via toggleMemberPaid)
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

-- Bill members — participants in a specific bill.
-- Can be linked to a real profile (user_id) or be an external guest.
create table public.bill_members (
  id          uuid primary key default uuid_generate_v4(),
  bill_id     uuid not null references public.bills(id) on delete cascade,
  user_id     uuid references public.profiles(id) on delete set null, -- null for external/guest members
  name        text not null,                          -- display name inside the bill
  color       text not null default '#4366f4',        -- avatar color (hex)
  promptpay   text,                                   -- PromptPay ID (phone / national ID) for QR generation
  is_external boolean not null default false,         -- true = guest not linked to any account
  created_at  timestamptz not null default now()
);

-- Bill items — individual line items in a bill.
create table public.bill_items (
  id          uuid primary key default uuid_generate_v4(),
  bill_id     uuid not null references public.bills(id) on delete cascade,
  name        text not null,
  price       numeric not null default 0,
  quantity    numeric not null default 1,
  member_ids  jsonb not null default '[]',
  custom_shares jsonb not null default '{}',
  paid_by     text,
  created_at  timestamptz not null default now()
);

-- LINE web login iOS PWA handoff — the PWA saves a loginId in its own
-- localStorage before redirecting to LINE.  When LINE's callback lands in
-- a plain Safari tab, the completed session is stored here keyed by
-- loginId.  The PWA polls get_line_login_handoff() until it appears.
-- iOS shares neither localStorage nor cookies between a standalone PWA
-- and Safari (confirmed iOS 17+), so the DB is the only shared channel.
create table public.line_login_handoffs (
  pairing_id text primary key,
  session    jsonb not null,
  created_at timestamptz not null default now()
);
alter table public.line_login_handoffs enable row level security;

-- Remote feature flags — toggle without releasing a new app version
-- (e.g. ads_enabled). Anyone can read; only service_role can write.
create table public.app_config (
  key        text primary key,
  value      text not null,
  updated_at timestamptz not null default now()
);
insert into public.app_config (key, value)
values ('ads_enabled', 'false')
on conflict (key) do nothing;

-- ============================================================
-- Indexes
-- ============================================================
create index profiles_username_idx      on public.profiles(username);
create index group_members_user_id_idx  on public.group_members(user_id);
create index group_members_group_id_idx on public.group_members(group_id);
create index notifications_user_id_idx  on public.notifications(user_id);
create index notifications_read_idx     on public.notifications(user_id, read);
create index friends_requester_idx      on public.friends(requester_id);
create index friends_addressee_idx      on public.friends(addressee_id);
create index bills_owner_id_idx         on public.bills(owner_id);
create index bills_group_id_idx         on public.bills(group_id);
create index bills_trip_id_idx          on public.bills(trip_id);
create index bill_members_bill_id_idx   on public.bill_members(bill_id);
create index bill_items_bill_id_idx     on public.bill_items(bill_id);
create index trips_owner_id_idx         on public.trips(owner_id);
create index trips_group_id_idx         on public.trips(group_id);

-- ============================================================
-- Enable RLS
-- ============================================================
alter table public.profiles      enable row level security;
alter table public.groups        enable row level security;
alter table public.group_members enable row level security;
alter table public.notifications enable row level security;
alter table public.friends       enable row level security;
alter table public.trips         enable row level security;
alter table public.bills         enable row level security;
alter table public.bill_members  enable row level security;
alter table public.bill_items    enable row level security;
alter table public.app_config    enable row level security;

-- ============================================================
-- Security Definer Helper Functions
-- MUST be created BEFORE policies that use them.
-- SECURITY DEFINER = runs as function owner (bypasses RLS),
-- preventing cross-table infinite recursion.
-- ============================================================

-- Returns true if the current user is an accepted member of the given group.
-- Queries group_members directly (bypasses RLS → no recursion).
create function public.is_group_member(p_group_id uuid)
returns boolean language sql security definer stable set search_path = public as $$
  select exists (
    select 1 from public.group_members
    where group_id = p_group_id
      and user_id   = auth.uid()
      and status    = 'accepted'
  );
$$;

-- Returns true if the current user owns the given group.
-- Queries groups directly (bypasses RLS → no recursion).
create function public.is_group_owner(p_group_id uuid)
returns boolean language sql security definer stable set search_path = public as $$
  select exists (
    select 1 from public.groups
    where id       = p_group_id
      and owner_id = auth.uid()
  );
$$;

-- Returns true if the current user can access the given bill.
-- Checks: owner, group member, or direct bill_member (for personal bills
-- shared by a friend who added the current user as a member).
create function public.can_access_bill(p_bill_id uuid)
returns boolean language sql security definer stable set search_path = public as $$
  select exists (
    select 1 from public.bills b
    where b.id = p_bill_id
      and (
        b.owner_id = auth.uid()
        or (b.group_id is not null and public.is_group_member(b.group_id))
        or exists (
          select 1 from public.bill_members bm
          where bm.bill_id = b.id
            and bm.user_id = auth.uid()
        )
      )
  );
$$;

-- ============================================================
-- Policies — profiles
-- ============================================================
create policy "profiles_select" on public.profiles
  for select to authenticated using (true);

-- Allow authenticated users to insert their own profile row.
-- Also covers the ON CONFLICT DO NOTHING path from upsert.
create policy "profiles_insert" on public.profiles
  for insert to authenticated with check (auth.uid() = id);

-- Allow users to update their own profile.
-- Required for upsert (even with ignoreDuplicates=true, Supabase
-- checks UPDATE policy when the row already exists).
create policy "profiles_update" on public.profiles
  for update to authenticated using (auth.uid() = id)
  with check (auth.uid() = id);

-- ============================================================
-- Policies — groups
-- Uses is_group_member() helper to avoid querying group_members
-- directly inside a policy (which would cause cross-table recursion
-- because group_members policies query groups).
-- ============================================================
create policy "groups_select" on public.groups
  for select using (
    auth.uid() = owner_id
    or public.is_group_member(id)
  );

create policy "groups_insert" on public.groups
  for insert with check (auth.uid() = owner_id);

create policy "groups_update" on public.groups
  for update using (auth.uid() = owner_id);

create policy "groups_delete" on public.groups
  for delete using (auth.uid() = owner_id);

-- ============================================================
-- Policies — group_members
-- Uses is_group_owner() helper to avoid querying groups directly
-- (which would trigger groups policy → is_group_member → recursion).
-- ============================================================
create policy "group_members_select" on public.group_members
  for select using (
    auth.uid() = user_id
    or public.is_group_member(group_id)
    or public.is_group_owner(group_id)
  );

-- Allow group owner OR the user themselves (for accepting invites) to insert
create policy "group_members_insert" on public.group_members
  for insert with check (
    public.is_group_owner(group_id)
    or auth.uid() = user_id
  );

create policy "group_members_update" on public.group_members
  for update using (auth.uid() = user_id);

create policy "group_members_delete" on public.group_members
  for delete using (
    auth.uid() = user_id
    or public.is_group_owner(group_id)
  );

-- ============================================================
-- Policies — friends
-- ============================================================
create policy "friends_select" on public.friends
  for select using (auth.uid() = requester_id or auth.uid() = addressee_id);

create policy "friends_insert" on public.friends
  for insert with check (auth.uid() = requester_id);

create policy "friends_update" on public.friends
  for update using (auth.uid() = addressee_id or auth.uid() = requester_id);

create policy "friends_delete" on public.friends
  for delete using (auth.uid() = requester_id or auth.uid() = addressee_id);

-- ============================================================
-- Policies — notifications
-- ============================================================
create policy "notifications_select" on public.notifications
  for select using (auth.uid() = user_id);

create policy "notifications_insert" on public.notifications
  for insert to authenticated with check (true);

create policy "notifications_update" on public.notifications
  for update using (auth.uid() = user_id);

-- ============================================================
-- Policies — trips
-- ============================================================
create policy "trips_select" on public.trips
  for select using (
    auth.uid() = owner_id
    or (group_id is not null and public.is_group_member(group_id))
  );

create policy "trips_insert" on public.trips
  for insert with check (auth.uid() = owner_id);

create policy "trips_update" on public.trips
  for update using (auth.uid() = owner_id);

create policy "trips_delete" on public.trips
  for delete using (auth.uid() = owner_id);

-- ============================================================
-- Policies — bills
-- ============================================================
create policy "bills_select" on public.bills
  for select using (
    auth.uid() = owner_id
    or (group_id is not null and public.is_group_member(group_id))
    or exists (
      select 1 from public.bill_members bm
      where bm.bill_id = id
        and bm.user_id = auth.uid()
    )
  );

create policy "bills_insert" on public.bills
  for insert with check (auth.uid() = owner_id);

create policy "bills_update" on public.bills
  for update using (auth.uid() = owner_id);

create policy "bills_delete" on public.bills
  for delete using (auth.uid() = owner_id);

-- ============================================================
-- Policies — bill_members
-- ============================================================
create policy "bill_members_select" on public.bill_members
  for select using (public.can_access_bill(bill_id));

create policy "bill_members_insert" on public.bill_members
  for insert with check (
    exists (select 1 from public.bills where id = bill_id and owner_id = auth.uid())
  );

create policy "bill_members_update" on public.bill_members
  for update using (
    exists (select 1 from public.bills where id = bill_id and owner_id = auth.uid())
  );

create policy "bill_members_delete" on public.bill_members
  for delete using (
    exists (select 1 from public.bills where id = bill_id and owner_id = auth.uid())
  );

-- ============================================================
-- Policies — bill_items
-- ============================================================
create policy "bill_items_select" on public.bill_items
  for select using (public.can_access_bill(bill_id));

create policy "bill_items_insert" on public.bill_items
  for insert with check (
    exists (select 1 from public.bills where id = bill_id and owner_id = auth.uid())
  );

create policy "bill_items_update" on public.bill_items
  for update using (
    exists (select 1 from public.bills where id = bill_id and owner_id = auth.uid())
  );

create policy "bill_items_delete" on public.bill_items
  for delete using (
    exists (select 1 from public.bills where id = bill_id and owner_id = auth.uid())
  );

-- ============================================================
-- Policies — line_login_handoffs
-- pairing_id is a 256-bit random token — it IS the authorization.
-- Reads go through get_line_login_handoff() RPC (security definer)
-- so clients can never enumerate the table.
-- ============================================================
create policy "line_login_handoffs_insert" on public.line_login_handoffs
  for insert with check (pairing_id ~ '^[A-Za-z0-9_-]{16,64}$');

-- ============================================================
-- Policies — app_config
-- ============================================================
create policy "app_config_select" on public.app_config
  for select using (true);
-- Writes are service_role-only (no insert/update/delete policy for
-- other roles — service_role bypasses RLS entirely).

-- ============================================================
-- Functions & Triggers
-- ============================================================

-- Auto-update updated_at on any UPDATE.
create function public.handle_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_updated_at before update on public.profiles
  for each row execute procedure public.handle_updated_at();
create trigger groups_updated_at   before update on public.groups
  for each row execute procedure public.handle_updated_at();
create trigger trips_updated_at    before update on public.trips
  for each row execute procedure public.handle_updated_at();
create trigger bills_updated_at    before update on public.bills
  for each row execute procedure public.handle_updated_at();

-- Auto-create profile row when a new auth user signs up.
-- Works for email, Google, and LINE (email may be null for LINE).
create function public.handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into public.profiles (id, username, display_name, avatar_url)
  values (
    new.id,
    coalesce(
      nullif(trim(new.raw_user_meta_data->>'username'), ''),
      'user_' || substr(replace(new.id::text, '-', ''), 1, 8)
    ),
    coalesce(
      nullif(trim(new.raw_user_meta_data->>'full_name'), ''),
      nullif(trim(new.raw_user_meta_data->>'name'), ''),
      nullif(split_part(coalesce(new.email, ''), '@', 1), ''),
      'user_' || substr(replace(new.id::text, '-', ''), 1, 8)
    ),
    coalesce(
      new.raw_user_meta_data->>'avatar_url',
      new.raw_user_meta_data->>'picture'
    )
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Keep bill_members.name in sync with profiles.display_name so a display
-- name change shows up everywhere a user appears as a bill member,
-- atomically with the profile update itself (see docs/FIXES.md FIX-13).
create function public.sync_bill_member_names()
returns trigger language plpgsql as $$
begin
  if new.display_name is distinct from old.display_name then
    update public.bill_members
    set name = new.display_name
    where user_id = new.id and is_external = false;
  end if;
  return new;
end;
$$;

create trigger profiles_sync_names
  after update of display_name on public.profiles
  for each row execute procedure public.sync_bill_member_names();

-- Fires after every INSERT into notifications and calls the send-push
-- Edge Function (fire-and-forget via pg_net). Requires two DB-level
-- settings this script can't set for you (they're secrets) — run once
-- per project, replacing the placeholders:
--   alter database postgres set app.supabase_url = 'https://YOUR_PROJECT_REF.supabase.co';
--   alter database postgres set app.service_role_key = 'YOUR_SERVICE_ROLE_KEY';
-- See supabase/migrations/20240701000000_add_fcm_token_and_push_trigger.sql.
create function public.trigger_push_on_notification()
returns trigger language plpgsql security definer as $$
declare
  v_title text;
  v_body  text;
begin
  case new.type
    when 'group_invite' then
      v_title := 'คำเชิญกลุ่ม 👥';
      v_body  := coalesce(
        (new.data->>'invited_by_display_name'),
        '@' || coalesce(new.data->>'invited_by_username', 'ผู้ใช้')
      ) || ' เชิญคุณเข้าร่วมกลุ่ม ' ||
        coalesce(new.data->>'group_name', '');
    when 'friend_request' then
      v_title := 'คำขอเป็นเพื่อน 🤝';
      v_body  := coalesce(
        new.data->>'display_name',
        '@' || coalesce(new.data->>'username', 'ผู้ใช้')
      ) || ' ส่งคำขอเป็นเพื่อน';
    when 'friend_accepted' then
      v_title := 'ยอมรับคำขอเป็นเพื่อน ✅';
      v_body  := coalesce(
        new.data->>'display_name',
        '@' || coalesce(new.data->>'username', 'ผู้ใช้')
      ) || ' ยอมรับคำขอเป็นเพื่อนของคุณแล้ว';
    when 'bill_paid' then
      v_title := 'มีคนจ่ายบิล 💸';
      v_body  := coalesce(new.data->>'payer_name', 'สมาชิก') ||
        ' จ่ายเงินในบิล ' || coalesce(new.data->>'bill_name', '') || ' แล้ว';
    when 'bill_completed' then
      v_title := 'บิลจ่ายครบแล้ว 🎉';
      v_body  := 'สมาชิกทุกคนจ่ายเงินครบในบิล ' ||
        coalesce(new.data->>'bill_name', '') || ' แล้ว';
    else
      v_title := 'การแจ้งเตือนใหม่';
      v_body  := coalesce(new.data->>'message', '');
  end case;

  perform net.http_post(
    url     := current_setting('app.supabase_url') || '/functions/v1/send-push',
    headers := jsonb_build_object(
                 'Content-Type', 'application/json',
                 'Authorization', 'Bearer ' || current_setting('app.service_role_key')
               ),
    body    := jsonb_build_object(
                 'userId', new.user_id,
                 'title',  v_title,
                 'body',   v_body,
                 'data',   jsonb_build_object('type', new.type)
               )::text
  );

  return new;
end;
$$;

create trigger push_on_notification_insert
  after insert on public.notifications
  for each row execute procedure public.trigger_push_on_notification();

-- ============================================================
-- LINE login handoff RPC
-- ============================================================

-- Returns the session JSON for the given pairing_id and deletes the row
-- so it can only be consumed once.  No RLS needed — the function is
-- security definer and the pairing_id is a 256-bit random token that
-- only the originating PWA instance knows.
create function public.get_line_login_handoff(p_pairing_id text)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_session jsonb;
begin
  select session into v_session
  from public.line_login_handoffs
  where pairing_id = p_pairing_id
    and created_at > now() - interval '10 minutes';

  if v_session is not null then
    delete from public.line_login_handoffs where pairing_id = p_pairing_id;
  end if;

  return v_session;
end;
$$;

-- Allow anon + authenticated to call the RPC and to insert handoff rows.
-- The Safari tab that completes LINE login may not yet have a Supabase
-- session (it signs in during _completeLineWebLogin), so anon access is
-- required for the insert.
grant execute on function public.get_line_login_handoff(text) to anon, authenticated;
grant insert on public.line_login_handoffs to anon, authenticated;

