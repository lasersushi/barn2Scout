-- Points betting: one row per scout per match. Run once in the Supabase SQL
-- editor before shipping the Points tab. Balances are never stored — every
-- client derives them from reports, these bets, and TBA results
-- (lib/features/points/points.dart).

create table if not exists public.match_bets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid()
    references auth.users (id) on delete cascade,
  event_key text not null,
  match_key text not null,
  alliance text not null check (alliance in ('red', 'blue')),
  stake integer not null check (stake > 0),
  -- Always the server's clock (see trigger below). Clients compare it with
  -- TBA's actual match start time, so a bet placed after the start is
  -- refunded no matter what the device clock says.
  placed_at timestamptz not null default now(),
  constraint match_bets_match_in_event
    check (starts_with(match_key, event_key || '_')),
  constraint match_bets_one_per_match unique (user_id, match_key)
);

create index if not exists match_bets_event_key_idx
  on public.match_bets (event_key);

-- Ignore any client-supplied placed_at.
create or replace function public.match_bets_stamp_placed_at()
returns trigger
language plpgsql
as $$
begin
  new.placed_at := now();
  return new;
end;
$$;

drop trigger if exists match_bets_stamp_placed_at on public.match_bets;
create trigger match_bets_stamp_placed_at
  before insert on public.match_bets
  for each row execute function public.match_bets_stamp_placed_at();

alter table public.match_bets enable row level security;

-- Everyone signed in sees every bet: pools and standings are public.
drop policy if exists "match_bets_select" on public.match_bets;
create policy "match_bets_select" on public.match_bets
  for select to authenticated
  using (true);

-- You can only bet as yourself. There are no update or delete policies, so
-- bets are final.
drop policy if exists "match_bets_insert_own" on public.match_bets;
create policy "match_bets_insert_own" on public.match_bets
  for insert to authenticated
  with check (user_id = (select auth.uid()));
