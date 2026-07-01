-- FIX-01: customShares was only applied in-memory client-side and never
-- persisted, so unequal-split data was lost whenever a bill was reopened.
alter table public.bill_items
  add column if not exists custom_shares jsonb not null default '{}';
