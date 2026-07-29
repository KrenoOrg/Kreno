-- Public directory data used by the anonymous website must not be served by
-- SECURITY DEFINER views.  Keep a minimal, purpose-built projection instead:
-- no phone number, e-mail, subscription IDs or waitlist data can ever be read
-- through these tables.
drop view if exists public.collaborators_directory;
drop view if exists public.public_plan;
drop view if exists public.provider_directory;

create table public.provider_directory (
  id uuid primary key references public.profiles(id) on delete cascade,
  name text not null check (char_length(trim(name)) between 2 and 120),
  type text,
  address text,
  updated_at timestamptz not null default now()
);

create table public.collaborators_directory (
  id uuid primary key references public.collaborators(id) on delete cascade,
  account_id uuid not null references public.profiles(id) on delete cascade,
  name text not null check (char_length(trim(name)) between 2 and 120),
  updated_at timestamptz not null default now()
);

create table public.public_plan (
  account_id uuid primary key references public.profiles(id) on delete cascade,
  plan public.kreno_plan not null,
  updated_at timestamptz not null default now()
);

alter table public.provider_directory enable row level security;
alter table public.collaborators_directory enable row level security;
alter table public.public_plan enable row level security;

create policy "public reads provider directory" on public.provider_directory
  for select to anon, authenticated using (true);
create policy "public reads collaborators directory" on public.collaborators_directory
  for select to anon, authenticated using (true);
create policy "public reads active plan" on public.public_plan
  for select to anon, authenticated using (true);

grant select on public.provider_directory, public.collaborators_directory, public.public_plan
  to anon, authenticated;

create or replace function public.sync_provider_directory()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'DELETE' then
    delete from provider_directory where id = old.id;
    return old;
  end if;
  insert into provider_directory(id, name, type, address, updated_at)
  values (new.id, new.name, new.type, new.address, now())
  on conflict (id) do update set
    name = excluded.name, type = excluded.type, address = excluded.address,
    updated_at = excluded.updated_at;
  return new;
end;
$$;

create or replace function public.sync_collaborator_directory()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'DELETE' then
    delete from collaborators_directory where id = old.id;
    return old;
  end if;
  insert into collaborators_directory(id, account_id, name, updated_at)
  values (new.id, new.account_id, new.name, now())
  on conflict (id) do update set
    account_id = excluded.account_id, name = excluded.name, updated_at = excluded.updated_at;
  return new;
end;
$$;

create or replace function public.sync_public_plan()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'DELETE' or new.status not in ('trialing', 'active') then
    delete from public_plan where account_id = coalesce(new.account_id, old.account_id);
    return coalesce(new, old);
  end if;
  insert into public_plan(account_id, plan, updated_at)
  values (new.account_id, new.plan, now())
  on conflict (account_id) do update set plan = excluded.plan, updated_at = excluded.updated_at;
  return new;
end;
$$;

revoke all on function public.sync_provider_directory() from public;
revoke all on function public.sync_collaborator_directory() from public;
revoke all on function public.sync_public_plan() from public;

create trigger profiles_sync_provider_directory
  after insert or update of name, type, address or delete on public.profiles
  for each row execute function public.sync_provider_directory();
create trigger collaborators_sync_directory
  after insert or update of account_id, name or delete on public.collaborators
  for each row execute function public.sync_collaborator_directory();
create trigger subscriptions_sync_public_plan
  after insert or update of plan, status or delete on public.subscriptions
  for each row execute function public.sync_public_plan();

-- Backfill existing accounts before the views are replaced in production.
insert into public.provider_directory(id, name, type, address)
  select id, name, type, address from public.profiles
  on conflict (id) do update set name = excluded.name, type = excluded.type,
    address = excluded.address, updated_at = now();
insert into public.collaborators_directory(id, account_id, name)
  select id, account_id, name from public.collaborators
  on conflict (id) do update set account_id = excluded.account_id,
    name = excluded.name, updated_at = now();
-- There are no active remote subscriptions before Stripe is configured. Future
-- subscription inserts and updates are covered by the trigger above.
