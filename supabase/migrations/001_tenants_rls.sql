-- Multi-tenant schema with row-level security.
-- Illustrative example written for this repository.

create schema if not exists app;

create table public.tenants (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_at timestamptz not null default now()
);

create table public.memberships (
  user_id uuid not null references auth.users (id) on delete cascade,
  tenant_id uuid not null references public.tenants (id) on delete cascade,
  role text not null check (role in ('owner', 'staff', 'client')),
  primary key (user_id, tenant_id)
);

create table public.bookings (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants (id) on delete cascade,
  client_id uuid not null references auth.users (id) on delete cascade,
  starts_at timestamptz not null,
  status text not null default 'booked' check (status in ('booked', 'cancelled', 'done')),
  created_at timestamptz not null default now()
);

create index bookings_tenant_starts_idx on public.bookings (tenant_id, starts_at);

alter table public.tenants enable row level security;
alter table public.memberships enable row level security;
alter table public.bookings enable row level security;

-- True when the signed-in user has one of the given roles in the tenant.
-- Security definer so the policy can read memberships; search_path is pinned.
create function app.has_role(p_tenant uuid, p_roles text[])
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.memberships m
    where m.user_id = auth.uid()
      and m.tenant_id = p_tenant
      and m.role = any (p_roles)
  );
$$;

revoke all on function app.has_role(uuid, text[]) from public, anon;
grant execute on function app.has_role(uuid, text[]) to authenticated;
grant usage on schema app to authenticated;

create policy tenants_read on public.tenants
  for select to authenticated
  using (app.has_role(id, array['owner', 'staff', 'client']));

create policy memberships_read_own on public.memberships
  for select to authenticated
  using (user_id = auth.uid());

create policy bookings_staff_read on public.bookings
  for select to authenticated
  using (app.has_role(tenant_id, array['owner', 'staff']));

create policy bookings_client_read on public.bookings
  for select to authenticated
  using (client_id = auth.uid() and app.has_role(tenant_id, array['client']));

create policy bookings_client_insert on public.bookings
  for insert to authenticated
  with check (client_id = auth.uid() and app.has_role(tenant_id, array['client']));

create policy bookings_staff_update on public.bookings
  for update to authenticated
  using (app.has_role(tenant_id, array['owner', 'staff']))
  with check (app.has_role(tenant_id, array['owner', 'staff']));
