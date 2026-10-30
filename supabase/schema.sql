-- DUYUSCRIPT ROBLOX HUB — NEW, SEPARATE SUPABASE PROJECT
-- Run the complete file in the SQL Editor of a newly created Supabase project.
create extension if not exists pgcrypto;

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);
create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  name text not null unique check (char_length(name) between 1 and 48),
  created_at timestamptz not null default now()
);
create table if not exists public.scripts (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(title) between 2 and 100),
  slug text not null unique check (slug ~ '^[a-z0-9]+([a-z0-9-]*[a-z0-9])?$'),
  game text not null default 'Roblox',
  category text not null,
  description text not null default '' check (char_length(description) <= 3000),
  code text not null default '' check (char_length(code) <= 500000),
  thumbnail text not null default '',
  discord_url text not null default '',
  featured boolean not null default false,
  views bigint not null default 0 check (views >= 0),
  downloads bigint not null default 0 check (downloads >= 0),
  avg_rating numeric(3,2) not null default 0,
  rating_count integer not null default 0,
  status text not null default 'draft' check (status in ('draft','published','hidden')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table if not exists public.reviews (
  id uuid primary key default gen_random_uuid(),
  script_id uuid not null references public.scripts(id) on delete cascade,
  display_name text not null check (char_length(display_name) between 1 and 32),
  rating integer not null check (rating between 1 and 5),
  comment text not null check (char_length(comment) between 1 and 1000),
  is_visible boolean not null default false,
  created_at timestamptz not null default now()
);
create index if not exists scripts_public_order on public.scripts(status, created_at desc);
create index if not exists scripts_category on public.scripts(category);
create index if not exists reviews_script_visible on public.reviews(script_id,is_visible,created_at desc);

create or replace function public.is_current_user_admin() returns boolean
language sql stable security definer set search_path=public
as $$ select exists(select 1 from public.admin_users where user_id=auth.uid()); $$;
revoke all on function public.is_current_user_admin() from public;
grant execute on function public.is_current_user_admin() to anon, authenticated;

create or replace function public.increment_script_metric(p_script_id uuid,p_metric text) returns void
language plpgsql security definer set search_path=public
as $$ begin
  if p_metric not in ('views','downloads') then raise exception 'Invalid metric'; end if;
  update public.scripts set
    views = case when p_metric='views' then views+1 else views end,
    downloads = case when p_metric='downloads' then downloads+1 else downloads end
  where id=p_script_id and status='published';
end; $$;
revoke all on function public.increment_script_metric(uuid,text) from public;
grant execute on function public.increment_script_metric(uuid,text) to anon,authenticated;

create or replace function public.refresh_script_rating() returns trigger
language plpgsql security definer set search_path=public
as $$ declare target uuid; begin
  target := coalesce(new.script_id,old.script_id);
  update public.scripts s set
    rating_count = coalesce(x.cnt,0), avg_rating = coalesce(x.avg,0)
  from (select count(*)::int cnt,round(avg(rating),2) avg from public.reviews where script_id=target and is_visible=true) x
  where s.id=target;
  if tg_op = 'DELETE' then return old; else return new; end if;
end; $$;
drop trigger if exists reviews_rating_refresh on public.reviews;
create trigger reviews_rating_refresh after insert or update or delete on public.reviews for each row execute function public.refresh_script_rating();

alter table public.admin_users enable row level security;
alter table public.categories enable row level security;
alter table public.scripts enable row level security;
alter table public.reviews enable row level security;

-- Admin role list is not readable/writable from browser clients.
drop policy if exists "admin users deny client access" on public.admin_users;
create policy "admin users deny client access" on public.admin_users for all using (false) with check (false);
-- Public may read category names. Admins manage them.
drop policy if exists "categories public read" on public.categories;
create policy "categories public read" on public.categories for select using (true);
drop policy if exists "categories admin manage" on public.categories;
create policy "categories admin manage" on public.categories for all to authenticated using (public.is_current_user_admin()) with check (public.is_current_user_admin());
-- Public reads only published scripts; Admins have full management access.
drop policy if exists "published scripts public read" on public.scripts;
create policy "published scripts public read" on public.scripts for select using (status='published' or public.is_current_user_admin());
drop policy if exists "scripts admin insert" on public.scripts;
create policy "scripts admin insert" on public.scripts for insert to authenticated with check (public.is_current_user_admin());
drop policy if exists "scripts admin update" on public.scripts;
create policy "scripts admin update" on public.scripts for update to authenticated using (public.is_current_user_admin()) with check (public.is_current_user_admin());
drop policy if exists "scripts admin delete" on public.scripts;
create policy "scripts admin delete" on public.scripts for delete to authenticated using (public.is_current_user_admin());
-- Visitors can submit a review, but it remains hidden until an Admin approves it.
drop policy if exists "public submit review" on public.reviews;
create policy "public submit review" on public.reviews for insert to anon,authenticated with check (
  is_visible=false and exists(select 1 from public.scripts s where s.id=script_id and s.status='published')
);
drop policy if exists "public read approved reviews" on public.reviews;
create policy "public read approved reviews" on public.reviews for select using (is_visible=true or public.is_current_user_admin());
drop policy if exists "admin moderate reviews" on public.reviews;
create policy "admin moderate reviews" on public.reviews for update to authenticated using (public.is_current_user_admin()) with check (public.is_current_user_admin());
drop policy if exists "admin delete reviews" on public.reviews;
create policy "admin delete reviews" on public.reviews for delete to authenticated using (public.is_current_user_admin());

insert into public.categories(name) values ('Utility'),('UI'),('Building'),('Guide'),('Other') on conflict(name) do nothing;

-- ADMIN BOOTSTRAP (manual, once):
-- 1) Create your own Admin user in Supabase Dashboard > Authentication > Users.
-- 2) Copy that user's UUID, then run this separately in SQL Editor:
-- insert into public.admin_users(user_id) values ('PASTE-AUTH-USER-UUID-HERE');
-- Never create a public Admin registration form. Never expose service_role keys.
