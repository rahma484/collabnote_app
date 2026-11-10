-- ============================================================
-- CollabNote — data contoh (opsional)
-- Tugas meminta minimal 5 data untuk tiap jenis. Jalankan SETELAH
-- kamu mendaftar di aplikasi. Ganti email di bawah dengan emailmu.
-- ============================================================
do $$
declare
  uid uuid;
  p1  uuid;
  p2  uuid;
begin
  select id into uid from auth.users where email = 'GANTI_DENGAN_EMAILMU';
  if uid is null then
    raise exception 'Email tidak ditemukan di auth.users';
  end if;

  -- 5 proyek (data utama), satu per template
  insert into public.projects (owner_id, title, description, category, project_type)
  values (uid, 'Aplikasi CollabNote', 'Tugas UTS Flutter + Supabase',
          'Software / App Development', 'Group')
  returning id into p1;

  insert into public.projects (owner_id, title, description, category, project_type)
  values (uid, 'Proposal Skripsi', 'Draft proposal bab 1-3',
          'Makalah, Proposal, & Riset Ilmiah', 'Individual')
  returning id into p2;

  insert into public.projects (owner_id, title, category, project_type) values
    (uid, 'Rencana Usaha Kedai Kopi', 'Business Plan & Startup', 'Group'),
    (uid, 'Poster Event Himpunan',    'Creative, Media / Desain', 'Individual'),
    (uid, 'Catatan Ide Mingguan',     'Catatan Bebas / General',  'Individual');

  -- 6 tugas (data aksi)
  insert into public.tasks (project_id, title, assignee, status, is_completed) values
    (p1, 'Rancang database Supabase',   'Rahma', 'Done',        true),
    (p1, 'Implementasi login',          'Rahma', 'In Progress', false),
    (p1, 'Bangun Task Board',           'Dina',  'To Do',       false),
    (p1, 'Tulis README',                'Dina',  'To Do',       false),
    (p2, 'Cari 10 jurnal rujukan',      'Rahma', 'In Progress', false),
    (p2, 'Susun kerangka bab 1',        'Rahma', 'To Do',       false);

  -- 6 tautan (data informasi)
  insert into public.asset_links (project_id, title, url, category) values
    (p1, 'Repo GitHub CollabNote', 'https://github.com',         'Kode'),
    (p1, 'Desain UI di Figma',     'https://www.figma.com',      'Desain'),
    (p1, 'Folder Drive Tugas',     'https://drive.google.com',   'Dokumen'),
    (p1, 'Slide Presentasi UTS',   'https://docs.google.com',    'Presentasi'),
    (p2, 'Draft Proposal Bab 1-3', 'https://docs.google.com',    'Dokumen'),
    (p2, 'Daftar Pustaka',         'https://scholar.google.com', 'Lainnya');
end $$;
