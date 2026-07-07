-- PERF: home_screen and bills_screen loaded every bill the user could see
-- (with full bill_members/bill_items joins) just to render a few stat
-- numbers and tab counts. This adds a trigger-maintained `total`/
-- `item_count` on bills (mirroring calculateBill() in bill_utils.dart) and
-- an RLS-scoped aggregate RPC, so the Dart app can page through bills with
-- .range() while still showing correct totals/counts without fetching
-- every row.

alter table public.bills
  add column total      numeric not null default 0,
  add column item_count integer not null default 0;

create index bills_status_updated_at_idx on public.bills(status, updated_at desc);
create index bill_members_user_id_idx    on public.bill_members(user_id);

-- Recomputes bills.total/item_count for one bill from its current
-- bill_items + settings. Mirrors calculateBill()'s formula exactly:
-- subtotal (sum of item price, NOT price*quantity — the Dart app never
-- multiplies by quantity) -> + service% -> + vat% (on subtotal+service)
-- -> + flat tip -> - flat discount. isVat/isService are intentionally NOT
-- checked, same as calculateBill() (service/vat always apply).
create or replace function public.recalc_bill_total(p_bill_id uuid)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_subtotal numeric;
  v_count    integer;
  v_settings jsonb;
  v_service  numeric;
begin
  select coalesce(sum(price), 0), count(*)
    into v_subtotal, v_count
    from public.bill_items
    where bill_id = p_bill_id;

  select settings into v_settings from public.bills where id = p_bill_id;
  if v_settings is null then
    return; -- bill no longer exists (e.g. concurrent delete)
  end if;

  v_service := v_subtotal * coalesce((v_settings->>'serviceCharge')::numeric, 0) / 100;

  update public.bills set
    total = v_subtotal
      + v_service
      + (v_subtotal + v_service) * coalesce((v_settings->>'vat')::numeric, 0) / 100
      + coalesce((v_settings->>'tip')::numeric, 0)
      - coalesce((v_settings->>'discount')::numeric, 0),
    item_count = v_count
  where id = p_bill_id;
end;
$$;

create or replace function public.trg_bill_items_recalc_total()
returns trigger language plpgsql as $$
begin
  if tg_op = 'DELETE' then
    perform public.recalc_bill_total(old.bill_id);
  else
    perform public.recalc_bill_total(new.bill_id);
    if tg_op = 'UPDATE' and old.bill_id is distinct from new.bill_id then
      perform public.recalc_bill_total(old.bill_id);
    end if;
  end if;
  return null;
end;
$$;

drop trigger if exists bill_items_recalc_total on public.bill_items;
create trigger bill_items_recalc_total
  after insert or update or delete on public.bill_items
  for each row execute procedure public.trg_bill_items_recalc_total();

create or replace function public.trg_bills_settings_recalc_total()
returns trigger language plpgsql as $$
begin
  perform public.recalc_bill_total(new.id);
  return null;
end;
$$;

drop trigger if exists bills_settings_recalc_total on public.bills;
create trigger bills_settings_recalc_total
  after update of settings on public.bills
  for each row when (old.settings is distinct from new.settings)
  execute procedure public.trg_bills_settings_recalc_total();

-- One-time backfill for existing rows (same transaction as the column
-- add, so `total` is never in a populated-columns/unpopulated-data limbo).
update public.bills b set
  total = (
    select coalesce(sum(bi.price), 0)
        + coalesce((b.settings->>'serviceCharge')::numeric, 0) / 100 * coalesce(sum(bi.price), 0)
        + (coalesce(sum(bi.price), 0)
            + coalesce((b.settings->>'serviceCharge')::numeric, 0) / 100 * coalesce(sum(bi.price), 0))
          * coalesce((b.settings->>'vat')::numeric, 0) / 100
        + coalesce((b.settings->>'tip')::numeric, 0)
        - coalesce((b.settings->>'discount')::numeric, 0)
    from public.bill_items bi where bi.bill_id = b.id
  ),
  item_count = (select count(*) from public.bill_items where bill_id = b.id);

-- Aggregate stats for the current user's visible bills (draft/pending/
-- completed counts, grand total, total items, biggest bill) — replaces
-- client-side folding over the full bill list. SECURITY INVOKER (default)
-- so it's automatically scoped by the existing bills_select RLS policy
-- instead of re-implementing that access logic.
create or replace function public.get_bill_aggregate_stats()
returns table (
  total_count           integer,
  draft_count           integer,
  pending_payment_count integer,
  completed_count       integer,
  grand_total           numeric,
  total_items           bigint,
  biggest_bill_id       uuid,
  biggest_bill_title    text,
  biggest_bill_emoji    text,
  biggest_bill_total    numeric
) language sql stable as $$
  select
    count(*)::int,
    count(*) filter (where status = 'draft')::int,
    count(*) filter (where status = 'pending_payment')::int,
    count(*) filter (where status = 'completed')::int,
    coalesce(sum(total), 0),
    coalesce(sum(item_count), 0),
    (select id    from public.bills order by total desc limit 1),
    (select title from public.bills order by total desc limit 1),
    (select emoji from public.bills order by total desc limit 1),
    coalesce(max(total), 0)
  from public.bills;
$$;

grant execute on function public.get_bill_aggregate_stats() to authenticated;
