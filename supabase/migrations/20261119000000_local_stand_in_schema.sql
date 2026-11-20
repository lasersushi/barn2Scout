-- LOCAL TESTING ONLY: stand-ins for the tables the app already uses in the
-- real Supabase project, which were made in its dashboard and have no
-- migration here.
--
-- Everything is inside one guard: it runs only on a database with no
-- `profiles` table, i.e. a fresh `supabase start`. On the real project
-- `profiles` exists, so this whole file does nothing there.
--
-- The column names match what the app reads and writes
-- (lib/data/repositories/sync_repository.dart, assignment_repository.dart,
-- lib/data/models/*). The access rules are loose on purpose: any signed-in
-- user can read and write. They are not the real project's policies.

do $guard$
begin
  if to_regclass('public.profiles') is not null then
    raise notice 'profiles exists: skipping local stand-in schema';
    return;
  end if;

  -- ── profiles: one row per account, created on sign-up ─────────────────────
  create table public.profiles (
    id           uuid primary key references auth.users (id) on delete cascade,
    email        text not null default '',
    display_name text,
    role         text not null default 'scout'
  );
  alter table public.profiles enable row level security;
  create policy "signed-in users read profiles"
    on public.profiles for select to authenticated using (true);

  create function public.handle_new_user()
  returns trigger
  language plpgsql
  security definer
  set search_path = public
  as $fn$
  begin
    insert into public.profiles (id, email, display_name)
    values (new.id, coalesce(new.email, ''), split_part(coalesce(new.email, ''), '@', 1))
    on conflict (id) do nothing;
    return new;
  end;
  $fn$;

  create trigger on_auth_user_created
    after insert on auth.users
    for each row execute function public.handle_new_user();

  -- ── scouting records ──────────────────────────────────────────────────────
  create table public.scouting_records (
    id           uuid primary key,
    user_id      uuid references auth.users (id) on delete set null,
    team_number  integer not null,
    match_number integer not null,
    event_key    text not null,
    scouter_name text not null default '',
    "timestamp"  timestamptz not null default now(),
    auto_data    jsonb not null default '{}',
    teleop_data  jsonb not null default '{}',
    endgame_data jsonb not null default '{}',
    notes        text not null default ''
  );
  create index scouting_records_event_idx on public.scouting_records (event_key);

  create table public.pit_scouting_records (
    id           uuid primary key,
    user_id      uuid references auth.users (id) on delete set null,
    team_number  integer not null,
    event_key    text not null,
    scouter_name text not null default '',
    "timestamp"  timestamptz not null default now(),
    pit_data     jsonb not null default '{}',
    notes        text not null default ''
  );
  create index pit_scouting_records_event_idx on public.pit_scouting_records (event_key);

  create table public.picklists (
    id         text primary key,
    name       text not null,
    picks      jsonb not null default '[]',
    vetoes     jsonb not null default '[]',
    updated_at timestamptz not null default now()
  );

  create table public.pit_assignments (
    event_key   text not null,
    team_number integer not null,
    user_id     uuid not null references auth.users (id) on delete cascade,
    assigned_by uuid references auth.users (id) on delete set null,
    updated_at  timestamptz not null default now(),
    primary key (event_key, team_number)
  );

  alter table public.scouting_records enable row level security;
  alter table public.pit_scouting_records enable row level security;
  alter table public.picklists enable row level security;
  alter table public.pit_assignments enable row level security;
  create policy "local: signed-in full access" on public.scouting_records
    for all to authenticated using (true) with check (true);
  create policy "local: signed-in full access" on public.pit_scouting_records
    for all to authenticated using (true) with check (true);
  create policy "local: signed-in full access" on public.picklists
    for all to authenticated using (true) with check (true);
  create policy "local: signed-in full access" on public.pit_assignments
    for all to authenticated using (true) with check (true);

  -- ── RPCs the app calls when a scouter deletes a record ────────────────────
  create function public.delete_scouting_record(record_id uuid)
  returns void language sql security invoker as $fn$
    delete from public.scouting_records where id = record_id;
  $fn$;

  create function public.delete_pit_record(record_id uuid)
  returns void language sql security invoker as $fn$
    delete from public.pit_scouting_records where id = record_id;
  $fn$;
end;
$guard$;
