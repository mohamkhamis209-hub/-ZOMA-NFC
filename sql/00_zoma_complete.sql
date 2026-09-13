-- =========================================================
-- ZOMA COMPLETE DATABASE — SAFE / RERUN MIGRATION
-- =========================================================
-- This file is designed for:
-- 1) A fresh Supabase project, OR
-- 2) The older ZOMA base schema already used in this project.
--
-- IMPORTANT:
-- - Do NOT use DROP FUNCTION ... CASCADE.
-- - The admin permission function keeps the parameter names
--   requested_module / requested_action to avoid the old 42P13 error.
-- - Existing tables are upgraded with ADD COLUMN IF NOT EXISTS.
-- - Existing card rows get a public_slug before NOT NULL is enforced.
-- =========================================================

create extension if not exists pgcrypto;

-- ---------- base tables ----------
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique not null,
  first_name text,
  middle_name text,
  third_name text,
  last_name text,
  full_name text,
  job_title text,
  bio text,
  phone text,
  whatsapp text,
  whatsapp_2 text,
  whatsapp_2_visible boolean not null default false,
  email text,
  website text,
  location text,
  avatar_url text,
  cover_url text,
  theme text not null default 'default',
  status text not null default 'active',
  is_public boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.design_templates (
  id uuid primary key default gen_random_uuid(),
  code text unique not null,
  name text not null,
  description text,
  config jsonb not null default '{}'::jsonb,
  preview_url text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.designs (
  id uuid primary key default gen_random_uuid(),
  code text unique not null,
  name text not null,
  description text,
  design_type text not null default 'template',
  template_id uuid references public.design_templates(id) on delete set null,
  image_url text,
  preview_url text,
  config jsonb not null default '{}'::jsonb,
  price numeric(12,2) not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.cards (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  profile_id uuid not null references public.profiles(id) on delete cascade,
  order_id uuid,
  card_uid text unique not null,
  public_slug text unique,
  card_name text,
  status text not null default 'active',
  suspended_at timestamptz,
  replaced_by uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.links (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  url text not null,
  icon text,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.social_links (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  platform text not null,
  url text not null,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.leads (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  name text not null,
  phone text,
  email text,
  message text,
  created_at timestamptz not null default now()
);

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  order_number text unique not null,
  customer_id uuid not null references auth.users(id) on delete cascade,
  design_id uuid references public.designs(id) on delete set null,
  customer_name text,
  phone text,
  governorate text,
  city text,
  detailed_address text,
  customer_notes text,
  admin_notes text,
  price numeric(12,2) not null default 0,
  status text not null default 'pending',
  card_id uuid references public.cards(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid references auth.users(id) on delete set null,
  subject text not null,
  message text not null,
  status text not null default 'open',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.admins (
  id uuid primary key default gen_random_uuid(),
  user_id uuid unique not null references auth.users(id) on delete cascade,
  display_name text,
  role text not null default 'support',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.admin_permissions (
  id uuid primary key default gen_random_uuid(),
  admin_id uuid not null references public.admins(id) on delete cascade,
  module text not null,
  can_view boolean not null default false,
  can_edit boolean not null default false,
  unique(admin_id,module)
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  title text not null,
  body text not null,
  type text not null default 'info',
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.analytics (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  card_id uuid references public.cards(id) on delete cascade,
  event_type text not null,
  device text,
  browser text,
  country text,
  referrer text,
  path text,
  created_at timestamptz not null default now()
);

create table if not exists public.activity_logs (
  id uuid primary key default gen_random_uuid(),
  actor_user_id uuid references auth.users(id) on delete set null,
  action text not null,
  module text,
  target_id uuid,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

-- ---------- compatibility: add columns missing from old schema ----------
alter table public.profiles
  add column if not exists first_name text,
  add column if not exists middle_name text,
  add column if not exists third_name text,
  add column if not exists last_name text,
  add column if not exists whatsapp_2 text,
  add column if not exists whatsapp_2_visible boolean default false,
  add column if not exists status text default 'active';

alter table public.design_templates
  add column if not exists description text,
  add column if not exists config jsonb default '{}'::jsonb,
  add column if not exists preview_url text,
  add column if not exists is_active boolean default true,
  add column if not exists updated_at timestamptz default now();

alter table public.designs
  add column if not exists description text,
  add column if not exists design_type text default 'template',
  add column if not exists template_id uuid,
  add column if not exists image_url text,
  add column if not exists preview_url text,
  add column if not exists config jsonb default '{}'::jsonb,
  add column if not exists price numeric(12,2) default 0,
  add column if not exists is_active boolean default true,
  add column if not exists updated_at timestamptz default now();

alter table public.cards
  add column if not exists order_id uuid,
  add column if not exists public_slug text,
  add column if not exists suspended_at timestamptz,
  add column if not exists replaced_by uuid,
  add column if not exists updated_at timestamptz default now();

alter table public.orders
  add column if not exists design_id uuid,
  add column if not exists customer_name text,
  add column if not exists phone text,
  add column if not exists governorate text,
  add column if not exists city text,
  add column if not exists detailed_address text,
  add column if not exists customer_notes text,
  add column if not exists admin_notes text,
  add column if not exists price numeric(12,2) default 0,
  add column if not exists status text default 'pending',
  add column if not exists card_id uuid,
  add column if not exists updated_at timestamptz default now();

alter table public.messages
  add column if not exists customer_id uuid,
  add column if not exists status text default 'open',
  add column if not exists updated_at timestamptz default now();

alter table public.admins
  add column if not exists display_name text,
  add column if not exists role text default 'support',
  add column if not exists is_active boolean default true,
  add column if not exists updated_at timestamptz default now();

alter table public.notifications
  add column if not exists type text default 'info',
  add column if not exists is_read boolean default false;

alter table public.analytics
  add column if not exists card_id uuid,
  add column if not exists path text;

alter table public.activity_logs
  add column if not exists actor_user_id uuid,
  add column if not exists module text,
  add column if not exists target_id uuid,
  add column if not exists metadata jsonb default '{}'::jsonb;

-- ---------- safe defaults for old rows ----------
update public.profiles set whatsapp_2_visible=false where whatsapp_2_visible is null;
update public.profiles set status='active' where status is null or status='';
update public.design_templates set config='{}'::jsonb where config is null;
update public.design_templates set is_active=true where is_active is null;
update public.design_templates set updated_at=now() where updated_at is null;
update public.designs set config='{}'::jsonb where config is null;
update public.designs set is_active=true where is_active is null;
update public.designs set design_type='template' where design_type is null or design_type='';
update public.designs set price=0 where price is null;
update public.designs set updated_at=now() where updated_at is null;
update public.orders set price=0 where price is null;
update public.orders set status='pending' where status is null or status='';
update public.orders set updated_at=now() where updated_at is null;
update public.messages set status='open' where status is null or status='';
update public.messages set updated_at=now() where updated_at is null;
update public.admins set role='support' where role is null or role='';
update public.admins set is_active=true where is_active is null;
update public.admins set updated_at=now() where updated_at is null;
update public.notifications set type='info' where type is null or type='';
update public.notifications set is_read=false where is_read is null;
update public.activity_logs set metadata='{}'::jsonb where metadata is null;

-- ---------- foreign keys that may be missing in the older schema ----------
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname='cards_order_id_fkey'
      and conrelid='public.cards'::regclass
  ) then
    alter table public.cards add constraint cards_order_id_fkey
      foreign key(order_id) references public.orders(id) on delete set null;
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname='orders_design_id_fkey'
      and conrelid='public.orders'::regclass
  ) then
    alter table public.orders add constraint orders_design_id_fkey
      foreign key(design_id) references public.designs(id) on delete set null;
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname='orders_card_id_fkey'
      and conrelid='public.orders'::regclass
  ) then
    alter table public.orders add constraint orders_card_id_fkey
      foreign key(card_id) references public.cards(id) on delete set null;
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname='designs_template_id_fkey'
      and conrelid='public.designs'::regclass
  ) then
    alter table public.designs add constraint designs_template_id_fkey
      foreign key(template_id) references public.design_templates(id) on delete set null;
  end if;
end $$;

-- ---------- cards: backfill public URL slug before NOT NULL ----------
update public.cards
set public_slug = lower(replace(card_uid,'-',''))
where public_slug is null or public_slug='';

create unique index if not exists cards_public_slug_unique_idx
  on public.cards(public_slug);

alter table public.cards alter column public_slug set not null;

-- ---------- indexes ----------
create index if not exists profiles_username_idx on public.profiles(username);
create index if not exists profiles_phone_idx on public.profiles(phone);
create index if not exists cards_user_id_idx on public.cards(user_id);
create index if not exists cards_profile_id_idx on public.cards(profile_id);
create index if not exists cards_public_slug_idx on public.cards(public_slug);
create index if not exists links_profile_id_idx on public.links(profile_id);
create index if not exists social_links_profile_id_idx on public.social_links(profile_id);
create index if not exists leads_profile_id_idx on public.leads(profile_id);
create index if not exists orders_customer_id_idx on public.orders(customer_id);
create index if not exists orders_status_idx on public.orders(status);
create index if not exists analytics_profile_id_idx on public.analytics(profile_id);
create index if not exists analytics_card_id_idx on public.analytics(card_id);
create index if not exists analytics_created_at_idx on public.analytics(created_at);
create index if not exists messages_customer_id_idx on public.messages(customer_id);
create index if not exists activity_logs_created_at_idx on public.activity_logs(created_at);

-- ---------- shared helper ----------
create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at=now();
  return new;
end $$;

-- Recreate update triggers safely.
drop trigger if exists profiles_touch on public.profiles;
create trigger profiles_touch before update on public.profiles
for each row execute function public.touch_updated_at();

drop trigger if exists templates_touch on public.design_templates;
create trigger templates_touch before update on public.design_templates
for each row execute function public.touch_updated_at();

drop trigger if exists designs_touch on public.designs;
create trigger designs_touch before update on public.designs
for each row execute function public.touch_updated_at();

drop trigger if exists cards_touch on public.cards;
create trigger cards_touch before update on public.cards
for each row execute function public.touch_updated_at();

drop trigger if exists orders_touch on public.orders;
create trigger orders_touch before update on public.orders
for each row execute function public.touch_updated_at();

drop trigger if exists messages_touch on public.messages;
create trigger messages_touch before update on public.messages
for each row execute function public.touch_updated_at();

drop trigger if exists admins_touch on public.admins;
create trigger admins_touch before update on public.admins
for each row execute function public.touch_updated_at();

-- ---------- auth profile trigger ----------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path=public
as $$
begin
  insert into public.profiles(id,username,full_name,phone,email)
  values(
    new.id,
    'user_'||substring(new.id::text,1,8),
    coalesce(new.raw_user_meta_data->>'full_name',''),
    new.raw_user_meta_data->>'phone',
    new.email
  )
  on conflict(id) do nothing;
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
for each row execute function public.handle_new_user();

-- ---------- ID helpers ----------
create or replace function public.normalize_phone(p text)
returns text
language sql
immutable
as $$
select regexp_replace(coalesce(p,''),'[^0-9]','','g')
$$;

create or replace function public.generate_card_uid()
returns text
language plpgsql
volatile
as $$
declare x text;
begin
  loop
    x := 'ZM-'||upper(substr(encode(gen_random_bytes(4),'hex'),1,6));
    exit when not exists(select 1 from public.cards where card_uid=x);
  end loop;
  return x;
end $$;

create or replace function public.generate_order_number()
returns text
language plpgsql
volatile
as $$
declare x text;
begin
  loop
    x := 'ZORD-'||to_char(now(),'YYYYMM')||'-'||lpad((floor(random()*999999)+1)::int::text,6,'0');
    exit when not exists(select 1 from public.orders where order_number=x);
  end loop;
  return x;
end $$;

create or replace function public.set_order_number()
returns trigger
language plpgsql
as $$
begin
  if new.order_number is null or new.order_number='' then
    new.order_number:=public.generate_order_number();
  end if;
  return new;
end $$;

drop trigger if exists orders_set_number on public.orders;
create trigger orders_set_number before insert on public.orders
for each row execute function public.set_order_number();

-- ---------- RLS: drop ONLY policies, never functions CASCADE ----------
alter table public.profiles enable row level security;
alter table public.cards enable row level security;
alter table public.links enable row level security;
alter table public.social_links enable row level security;
alter table public.leads enable row level security;
alter table public.design_templates enable row level security;
alter table public.designs enable row level security;
alter table public.orders enable row level security;
alter table public.messages enable row level security;
alter table public.admins enable row level security;
alter table public.admin_permissions enable row level security;
alter table public.notifications enable row level security;
alter table public.analytics enable row level security;
alter table public.activity_logs enable row level security;

do $$
declare r record;
begin
  for r in
    select schemaname,tablename,policyname
    from pg_policies
    where schemaname='public'
      and tablename in (
        'profiles','cards','links','social_links','leads',
        'design_templates','designs','orders','messages','admins',
        'admin_permissions','notifications','analytics','activity_logs'
      )
  loop
    execute format('drop policy if exists %I on %I.%I',r.policyname,r.schemaname,r.tablename);
  end loop;
end $$;

-- IMPORTANT: these are the SAME parameter names used by the already-existing function.
-- This is the fix for ERROR 42P13. No DROP FUNCTION is required.
create or replace function public.has_admin_permission(
  requested_module text,
  requested_action text
)
returns boolean
language sql
stable
security definer
set search_path=public
as $$
  select exists(
    select 1
    from public.admins a
    left join public.admin_permissions p
      on p.admin_id=a.id
     and p.module=requested_module
    where a.user_id=auth.uid()
      and a.is_active=true
      and (
        a.role='owner'
        or (requested_action='view' and coalesce(p.can_view,false))
        or (requested_action='edit' and coalesce(p.can_edit,false))
      )
  )
$$;

-- ---------- policies ----------
create policy profiles_public_select on public.profiles
for select
using ((is_public=true and status='active') or auth.uid()=id or public.has_admin_permission('customers','view'));

create policy profiles_owner_insert on public.profiles
for insert
with check (auth.uid()=id);

create policy profiles_owner_update on public.profiles
for update
using (auth.uid()=id or public.has_admin_permission('customers','edit'))
with check (auth.uid()=id or public.has_admin_permission('customers','edit'));

create policy cards_public_select on public.cards
for select
using (status='active' or auth.uid()=user_id or public.has_admin_permission('cards','view'));

create policy cards_owner_insert on public.cards
for insert
with check (auth.uid()=user_id or public.has_admin_permission('cards','edit'));

create policy cards_owner_update on public.cards
for update
using (auth.uid()=user_id or public.has_admin_permission('cards','edit'))
with check (auth.uid()=user_id or public.has_admin_permission('cards','edit'));

create policy links_public_select on public.links
for select
using (
  (is_active=true and exists(
    select 1 from public.profiles p
    where p.id=links.profile_id and p.is_public=true and p.status='active'
  ))
  or auth.uid()=(select id from public.profiles p where p.id=links.profile_id)
  or public.has_admin_permission('cards','view')
);

create policy links_owner_all on public.links
for all
using (
  auth.uid()=(select id from public.profiles p where p.id=links.profile_id)
  or public.has_admin_permission('cards','edit')
)
with check (
  auth.uid()=(select id from public.profiles p where p.id=links.profile_id)
  or public.has_admin_permission('cards','edit')
);

create policy social_public_select on public.social_links
for select
using (
  (is_active=true and exists(
    select 1 from public.profiles p
    where p.id=social_links.profile_id and p.is_public=true and p.status='active'
  ))
  or auth.uid()=(select id from public.profiles p where p.id=social_links.profile_id)
  or public.has_admin_permission('cards','view')
);

create policy social_owner_all on public.social_links
for all
using (
  auth.uid()=(select id from public.profiles p where p.id=social_links.profile_id)
  or public.has_admin_permission('cards','edit')
)
with check (
  auth.uid()=(select id from public.profiles p where p.id=social_links.profile_id)
  or public.has_admin_permission('cards','edit')
);

create policy leads_insert_public on public.leads
for insert with check (true);

create policy leads_owner_select on public.leads
for select
using (auth.uid()=(select id from public.profiles p where p.id=leads.profile_id) or public.has_admin_permission('customers','view'));

create policy leads_owner_delete on public.leads
for delete
using (auth.uid()=(select id from public.profiles p where p.id=leads.profile_id) or public.has_admin_permission('customers','edit'));

create policy templates_public_select on public.design_templates
for select
using (is_active=true or public.has_admin_permission('designs','view'));

create policy templates_admin_edit on public.design_templates
for all
using (public.has_admin_permission('designs','edit'))
with check (public.has_admin_permission('designs','edit'));

create policy designs_public_select on public.designs
for select
using (is_active=true or public.has_admin_permission('designs','view'));

create policy designs_admin_edit on public.designs
for all
using (public.has_admin_permission('designs','edit'))
with check (public.has_admin_permission('designs','edit'));

create policy orders_customer_select on public.orders
for select
using (auth.uid()=customer_id or public.has_admin_permission('orders','view'));

create policy orders_customer_insert on public.orders
for insert
with check (auth.uid()=customer_id);

create policy orders_admin_update on public.orders
for update
using (public.has_admin_permission('orders','edit'))
with check (public.has_admin_permission('orders','edit'));

create policy messages_customer_select on public.messages
for select
using (auth.uid()=customer_id or public.has_admin_permission('messages','view'));

create policy messages_customer_insert on public.messages
for insert
with check (auth.uid()=customer_id);

create policy messages_admin_update on public.messages
for update
using (public.has_admin_permission('messages','edit'))
with check (public.has_admin_permission('messages','edit'));

create policy admins_owner_select on public.admins
for select
using (auth.uid()=user_id or public.has_admin_permission('admins','view'));

create policy admins_owner_edit on public.admins
for all
using (public.has_admin_permission('admins','edit') or auth.uid()=user_id)
with check (public.has_admin_permission('admins','edit') or auth.uid()=user_id);

create policy permissions_owner_select on public.admin_permissions
for select
using (public.has_admin_permission('admins','view'));

create policy permissions_owner_edit on public.admin_permissions
for all
using (public.has_admin_permission('admins','edit'))
with check (public.has_admin_permission('admins','edit'));

create policy notifications_owner_select on public.notifications
for select
using (auth.uid()=user_id);

create policy notifications_owner_update on public.notifications
for update
using (auth.uid()=user_id)
with check (auth.uid()=user_id);

create policy analytics_insert_public on public.analytics
for insert with check (true);

create policy analytics_owner_select on public.analytics
for select
using (auth.uid()=(select id from public.profiles p where p.id=analytics.profile_id) or public.has_admin_permission('analytics','view'));

create policy activity_admin_select on public.activity_logs
for select
using (public.has_admin_permission('data','view'));

create policy activity_admin_insert on public.activity_logs
for insert
with check (auth.uid() is not null);

-- ---------- atomic order -> card ----------
create or replace function public.confirm_order(target_order_id uuid)
returns public.cards
language plpgsql
security definer
set search_path=public
as $$
declare
  o public.orders;
  c public.cards;
  p public.profiles;
  uid text;
  slug text;
begin
  if not public.has_admin_permission('orders','edit') then
    raise exception 'Unauthorized';
  end if;

  select * into o
  from public.orders
  where id=target_order_id
  for update;

  if o.id is null then
    raise exception 'Order not found';
  end if;

  if o.status in ('rejected','cancelled') then
    raise exception 'Order cannot be confirmed';
  end if;

  if o.card_id is not null then
    select * into c from public.cards where id=o.card_id;
    return c;
  end if;

  select * into p
  from public.profiles
  where id=o.customer_id
  for update;

  if p.id is null then
    raise exception 'Customer profile not found';
  end if;

  uid:=public.generate_card_uid();
  slug:=lower(replace(uid,'-',''));

  insert into public.cards(
    card_uid,user_id,profile_id,order_id,card_name,public_slug,status
  )
  values(
    uid,o.customer_id,o.customer_id,o.id,coalesce(p.full_name,'ZOMA Card'),slug,'active'
  )
  returning * into c;

  update public.orders
  set status='confirmed', card_id=c.id
  where id=o.id;

  insert into public.notifications(user_id,title,body,type)
  values(
    o.customer_id,
    'تم تأكيد طلبك',
    'تم تأكيد طلب ZOMA وإنشاء الكارت الذكي الخاص بك.',
    'success'
  );

  insert into public.activity_logs(actor_user_id,action,module,target_id,metadata)
  values(
    auth.uid(),
    'confirm_order',
    'orders',
    o.id,
    jsonb_build_object('card_id',c.id,'card_uid',c.card_uid)
  );

  return c;
end $$;

-- ---------- replacement ----------
create or replace function public.replace_card(old_card_id uuid)
returns public.cards
language plpgsql
security definer
set search_path=public
as $$
declare
  oldc public.cards;
  newc public.cards;
  uid text;
begin
  if not public.has_admin_permission('cards','edit') then
    raise exception 'Unauthorized';
  end if;

  select * into oldc
  from public.cards
  where id=old_card_id
  for update;

  if oldc.id is null then
    raise exception 'Card not found';
  end if;

  if oldc.status='replaced' then
    raise exception 'Already replaced';
  end if;

  uid:=public.generate_card_uid();

  insert into public.cards(
    card_uid,user_id,profile_id,order_id,card_name,public_slug,status
  )
  values(
    uid,
    oldc.user_id,
    oldc.profile_id,
    oldc.order_id,
    oldc.card_name,
    lower(replace(uid,'-','')),
    'active'
  )
  returning * into newc;

  update public.cards
  set status='replaced', suspended_at=now(), replaced_by=newc.id
  where id=oldc.id;

  insert into public.notifications(user_id,title,body,type)
  values(
    oldc.user_id,
    'تم استبدال الكارت',
    'تم إنشاء Card ID جديد للكارت الخاص بك.',
    'info'
  );

  insert into public.activity_logs(actor_user_id,action,module,target_id,metadata)
  values(
    auth.uid(),'replace_card','cards',oldc.id,
    jsonb_build_object('new_card_id',newc.id,'new_card_uid',newc.card_uid)
  );

  return newc;
end $$;

create or replace function public.suspend_card(target_card_id uuid)
returns void
language plpgsql
security definer
set search_path=public
as $$
begin
  if not public.has_admin_permission('cards','edit') then
    raise exception 'Unauthorized';
  end if;

  update public.cards
  set status='suspended', suspended_at=now()
  where id=target_card_id;
end $$;

create or replace function public.reactivate_card(target_card_id uuid)
returns void
language plpgsql
security definer
set search_path=public
as $$
begin
  if not public.has_admin_permission('cards','edit') then
    raise exception 'Unauthorized';
  end if;

  update public.cards
  set status='active', suspended_at=null
  where id=target_card_id and status='suspended';
end $$;

-- ---------- login resolver ----------
create or replace function public.resolve_login_identifier(identifier text)
returns text
language plpgsql
security definer
set search_path=public
as $$
declare
  x text;
  p text;
begin
  x:=lower(trim(identifier));

  if position('@' in x)>0 then
    return x;
  end if;

  p:=public.normalize_phone(x);

  select u.email into x
  from auth.users u
  join public.profiles pr on pr.id=u.id
  where public.normalize_phone(pr.phone)=p
  limit 1;

  if x is null then
    select u.email into x
    from auth.users u
    join public.cards c on c.user_id=u.id
    where upper(c.card_uid)=upper(trim(identifier))
      and c.status <> 'replaced'
    limit 1;
  end if;

  return x;
end $$;

-- ---------- storage ----------
insert into storage.buckets(id,name,public)
values('zoma-assets','zoma-assets',true)
on conflict(id) do update set public=true;

do $$
begin
  begin execute 'drop policy if exists zoma_assets_public_read on storage.objects'; exception when others then null; end;
  begin execute 'drop policy if exists zoma_assets_auth_insert on storage.objects'; exception when others then null; end;
  begin execute 'drop policy if exists zoma_assets_owner_update on storage.objects'; exception when others then null; end;
  begin execute 'drop policy if exists zoma_assets_owner_delete on storage.objects'; exception when others then null; end;
end $$;

create policy zoma_assets_public_read on storage.objects
for select
using(bucket_id='zoma-assets');

create policy zoma_assets_auth_insert on storage.objects
for insert to authenticated
with check(bucket_id='zoma-assets');

create policy zoma_assets_owner_update on storage.objects
for update to authenticated
using(bucket_id='zoma-assets' and owner_id=auth.uid()::text)
with check(bucket_id='zoma-assets' and owner_id=auth.uid()::text);

create policy zoma_assets_owner_delete on storage.objects
for delete to authenticated
using(bucket_id='zoma-assets' and owner_id=auth.uid()::text);

-- ---------- seed templates ----------
insert into public.design_templates(code,name,description,config)
values
('BLACK-GOLD','Black Gold','أسود وذهبي فاخر',
 '{"background":"#0b0c0f","surface":"#141820","primary":"#d8b15a","text":"#f7f7f4","radius":24}'::jsonb),
('WHITE-PREMIUM','White Premium','أبيض نظيف وراقي',
 '{"background":"#f4f2ed","surface":"#ffffff","primary":"#161616","text":"#161616","radius":24}'::jsonb),
('EMERALD','Emerald','أخضر زمردي حديث',
 '{"background":"#071511","surface":"#0d211b","primary":"#50d39b","text":"#effff8","radius":24}'::jsonb),
('TECH-BLUE','Tech Blue','تقني أزرق',
 '{"background":"#07101e","surface":"#0d1b31","primary":"#5aa9ff","text":"#f3f8ff","radius":24}'::jsonb)
on conflict(code) do nothing;

insert into public.designs(code,name,description,design_type,template_id,config,price)
select 'ZOMA-BG','Black Gold','التصميم الأساسي','template',id,config,499
from public.design_templates where code='BLACK-GOLD'
on conflict(code) do nothing;

insert into public.designs(code,name,description,design_type,template_id,config,price)
select 'ZOMA-WP','White Premium','التصميم الأبيض','template',id,config,449
from public.design_templates where code='WHITE-PREMIUM'
on conflict(code) do nothing;

insert into public.designs(code,name,description,design_type,template_id,config,price)
select 'ZOMA-EM','Emerald','التصميم الزمردي','template',id,config,499
from public.design_templates where code='EMERALD'
on conflict(code) do nothing;

insert into public.designs(code,name,description,design_type,template_id,config,price)
select 'ZOMA-TB','Tech Blue','التصميم التقني','template',id,config,549
from public.design_templates where code='TECH-BLUE'
on conflict(code) do nothing;

-- =========================================================
-- END 00_ZOMA_COMPLETE_SAFE.sql
-- =========================================================
