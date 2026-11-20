-- AI assistant: access flag, per-user usage, shared result cache, and the
-- budget checks the `ai` Edge Function runs before every Claude call.
--
-- Apply with `supabase db push`. Only the `ai` Edge Function (service role)
-- touches ai_usage / ai_cache; the app reaches them through that function.
-- The one RPC the app calls directly is set_ai_access (admins only).

-- ── Access flag ──────────────────────────────────────────────────────────────
-- "AI role": unlimited AI, plus chat and match briefs. Admins and super admins
-- get the same without the flag.
alter table public.profiles
  add column if not exists ai_access boolean not null default false;

-- ── Usage: one row per user per day ──────────────────────────────────────────
create table if not exists public.ai_usage (
  user_id  uuid          not null references auth.users (id) on delete cascade,
  day      date          not null,
  requests integer       not null default 0,
  cost_usd numeric(12,6) not null default 0,
  primary key (user_id, day)
);
alter table public.ai_usage enable row level security;
-- No policies on purpose: clients can't read or write it directly.

-- ── Shared cache of generated summaries / briefs / reviews ───────────────────
-- Keyed by a hash of (prompt version, kind, model, event, payload), so a result
-- is reused only when the scouting data behind it is unchanged.
create table if not exists public.ai_cache (
  cache_key  text        primary key,
  kind       text        not null,
  event_key  text        not null,
  model      text        not null,
  content    text        not null,
  created_at timestamptz not null default now()
);
alter table public.ai_cache enable row level security;
create index if not exists ai_cache_event_idx on public.ai_cache (event_key);

-- ── Admins grant or revoke the AI role ───────────────────────────────────────
create or replace function public.set_ai_access(target uuid, enabled boolean)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (
    select 1 from public.profiles
    where id = auth.uid() and role in ('admin', 'super_admin')
  ) then
    raise exception 'Only admins can change AI access'
      using errcode = '42501';
  end if;

  update public.profiles set ai_access = enabled where id = target;
  if not found then
    raise exception 'No profile for %', target using errcode = 'P0002';
  end if;
end;
$$;

revoke all on function public.set_ai_access(uuid, boolean) from public, anon;
grant execute on function public.set_ai_access(uuid, boolean) to authenticated;

-- ── Budget check + request count, atomically ─────────────────────────────────
-- Returns 'ok', 'daily_limit' or 'budget_reached'. p_daily_limit null means
-- unlimited (admins and the AI role). The caps apply to everyone: they are what
-- keeps the yearly bill under budget.
--
-- Cost is recorded after each call (ai_record_cost), so concurrent requests can
-- overshoot a cap by at most one request each, a few cents.
create or replace function public.ai_try_consume(
  p_user        uuid,
  p_daily_limit integer,
  p_month_cap   numeric,
  p_year_cap    numeric
)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  today       date := (now() at time zone 'utc')::date;
  month_spend numeric;
  year_spend  numeric;
  used_today  integer;
begin
  -- Serialise budget checks so two requests can't both pass at the edge.
  perform pg_advisory_xact_lock(hashtext('ai_budget'));

  select coalesce(sum(cost_usd), 0) into month_spend
  from public.ai_usage
  where day >= date_trunc('month', today)::date;

  select coalesce(sum(cost_usd), 0) into year_spend
  from public.ai_usage
  where day >= date_trunc('year', today)::date;

  if month_spend >= p_month_cap or year_spend >= p_year_cap then
    return 'budget_reached';
  end if;

  select coalesce(requests, 0) into used_today
  from public.ai_usage
  where user_id = p_user and day = today;

  if p_daily_limit is not null and coalesce(used_today, 0) >= p_daily_limit then
    return 'daily_limit';
  end if;

  insert into public.ai_usage (user_id, day, requests)
  values (p_user, today, 1)
  on conflict (user_id, day)
  do update set requests = public.ai_usage.requests + 1;

  return 'ok';
end;
$$;

-- Adds a finished call's cost. p_refund gives back the request count when the
-- call produced nothing (Claude API error), so a failure doesn't use up a slot.
create or replace function public.ai_record_cost(
  p_user   uuid,
  p_cost   numeric,
  p_refund boolean default false
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  today date := (now() at time zone 'utc')::date;
begin
  insert into public.ai_usage (user_id, day, requests, cost_usd)
  values (p_user, today, 0, p_cost)
  on conflict (user_id, day)
  do update set
    cost_usd = public.ai_usage.cost_usd + excluded.cost_usd,
    requests = greatest(
      public.ai_usage.requests - (case when p_refund then 1 else 0 end), 0);
end;
$$;

-- Only the Edge Function (service role) may run the accounting functions.
revoke all on function public.ai_try_consume(uuid, integer, numeric, numeric)
  from public, anon, authenticated;
revoke all on function public.ai_record_cost(uuid, numeric, boolean)
  from public, anon, authenticated;
grant execute on function public.ai_try_consume(uuid, integer, numeric, numeric)
  to service_role;
grant execute on function public.ai_record_cost(uuid, numeric, boolean)
  to service_role;
