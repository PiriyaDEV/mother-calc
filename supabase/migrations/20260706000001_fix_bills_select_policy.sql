-- Fix: bills_select policy did not allow access to personal bills where
-- the current user is a bill_member (but not the owner and not in a group).
-- This caused "เพื่อนสร้างบิลที่มีเราอยู่มองไม่เห็น" — a friend's personal
-- bill that includes you as a member was invisible to you.

-- Update can_access_bill() to also check bill_members.user_id
create or replace function public.can_access_bill(p_bill_id uuid)
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

-- Drop and recreate bills_select policy to include bill_member access.
drop policy if exists "bills_select" on public.bills;

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
