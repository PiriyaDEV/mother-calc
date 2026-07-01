-- FIX-13: AuthProvider.updateProfile() synced display_name into
-- bill_members via a separate, non-transactional client call — if it
-- failed, profiles and bill_members could drift out of sync. This
-- trigger makes the sync atomic with the profile update itself, so it
-- can never be skipped by a client-side bug (the client keeps a
-- best-effort fallback of the same update for defense in depth).
create or replace function public.sync_bill_member_names()
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

drop trigger if exists profiles_sync_names on public.profiles;
create trigger profiles_sync_names
  after update of display_name on public.profiles
  for each row execute procedure public.sync_bill_member_names();
