-- ============================================================
-- CollabNote — skema Supabase
-- Jalankan di Supabase Dashboard > SQL Editor.
-- Aman dijalankan ulang (memakai IF NOT EXISTS / DROP IF EXISTS).
-- Jika tabelmu sudah ada, cocokkan dulu nama kolomnya dengan
-- lib/domain/models/*.dart sebelum menjalankan.
-- ============================================================

-- 1. TABEL ---------------------------------------------------
create table if not exists public.profiles (
  id            uuid primary key references auth.users(id) on delete cascade,
  full_name     text not null default '',
  study_program text not null default '',
  created_at    timestamptz not null default now()
);

create table if not exists public.projects (
  id           uuid primary key default gen_random_uuid(),
  owner_id     uuid not null default auth.uid()
               references auth.users(id) on delete cascade,
  title        text not null,
  description  text,
  category     text not null,
  project_type text not null default 'Individual',
  deadline     date,
  created_at   timestamptz not null default now()
);

create table if not exists public.tasks (
  id           uuid primary key default gen_random_uuid(),
  project_id   uuid not null references public.projects(id) on delete cascade,
  title        text not null,
  assignee     text,
  status       text not null default 'To Do'
               check (status in ('To Do', 'In Progress', 'Done')),
  is_completed boolean not null default false,
  created_at   timestamptz not null default now()
);

create table if not exists public.asset_links (
  id         uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  title      text not null,
  url        text not null,
  category   text not null default 'Lainnya',
  created_at timestamptz not null default now()
);

create index if not exists tasks_project_idx       on public.tasks(project_id);
create index if not exists asset_links_project_idx on public.asset_links(project_id);

-- 2. PROFIL OTOMATIS SAAT REGISTER ---------------------------
-- Nama & Prodi dikirim aplikasi lewat metadata signUp, lalu
-- trigger ini menyalinnya ke tabel profiles. Tetap bekerja
-- walaupun konfirmasi email diaktifkan.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, study_program)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', ''),
    coalesce(new.raw_user_meta_data->>'study_program', '')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- 3. ROW LEVEL SECURITY --------------------------------------
alter table public.profiles    enable row level security;
alter table public.projects    enable row level security;
alter table public.tasks       enable row level security;
alter table public.asset_links enable row level security;

drop policy if exists "profiles_own" on public.profiles;
create policy "profiles_own" on public.profiles
  for all using (id = auth.uid()) with check (id = auth.uid());

drop policy if exists "projects_owner" on public.projects;
create policy "projects_owner" on public.projects
  for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());

drop policy if exists "tasks_owner" on public.tasks;
create policy "tasks_owner" on public.tasks
  for all
  using (exists (
    select 1 from public.projects p
    where p.id = tasks.project_id and p.owner_id = auth.uid()))
  with check (exists (
    select 1 from public.projects p
    where p.id = tasks.project_id and p.owner_id = auth.uid()));

drop policy if exists "asset_links_owner" on public.asset_links;
create policy "asset_links_owner" on public.asset_links
  for all
  using (exists (
    select 1 from public.projects p
    where p.id = asset_links.project_id and p.owner_id = auth.uid()))
  with check (exists (
    select 1 from public.projects p
    where p.id = asset_links.project_id and p.owner_id = auth.uid()));

-- 4. REALTIME ------------------------------------------------
-- Wajib agar Task Board & Links Hub berubah otomatis.
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public' and tablename = 'tasks') then
    alter publication supabase_realtime add table public.tasks;
  end if;

  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public' and tablename = 'asset_links') then
    alter publication supabase_realtime add table public.asset_links;
  end if;
end $$;
