-- FIX-03: the Dart model uses 'pending_payment' as a bill status, but the
-- DB check constraint only allowed ('draft', 'completed') — any attempt to
-- save 'pending_payment' throws a constraint violation.
alter table public.bills
  drop constraint if exists bills_status_check;

alter table public.bills
  add constraint bills_status_check
  check (status in ('draft', 'pending_payment', 'completed'));
