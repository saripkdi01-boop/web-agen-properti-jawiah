-- ============================================================
-- Klien 02 — Website Personal Jawiah (Agen Properti SDP + Salwa Tours)
-- Migrasi 001: skema awal (12 tabel)
-- Cara pakai: tempel seluruh isi file ini ke Supabase Dashboard
-- > SQL Editor > New query > Run
-- ============================================================

-- 1. Agen
create table if not exists agents (
  id uuid primary key default gen_random_uuid(),
  nama text not null,
  foto_url text,
  tagline text,
  bio text,
  wa_numbers text[] not null default '{}',
  tiktok_url text,
  instagram_url text,
  facebook_url text,
  jam_operasional text,
  statistik jsonb not null default '{}',
  created_at timestamptz not null default now()
);

-- 2. Produk perumahan (SDP)
create table if not exists products (
  id uuid primary key default gen_random_uuid(),
  agent_id uuid references agents(id) on delete cascade,
  nama text not null,
  slug text not null unique,
  lokasi text,
  alamat text,
  maps_url text,
  harga_mulai numeric,
  angsuran_mulai numeric,
  tipe text not null default 'subsidi' check (tipe in ('subsidi','komersil')),
  status text not null default 'ready' check (status in ('ready','indent','coming_soon','sold_out')),
  badge_promo text,
  deskripsi text,
  featured boolean not null default false,
  created_at timestamptz not null default now()
);
create index if not exists products_agent_idx on products(agent_id);
create index if not exists products_featured_idx on products(featured) where featured;

-- 3. Galeri produk
create table if not exists product_images (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references products(id) on delete cascade,
  url text not null,
  caption text,
  urutan int not null default 0,
  created_at timestamptz not null default now()
);
create index if not exists product_images_product_idx on product_images(product_id, urutan);

-- 4. Spesifikasi produk (fleksibel per produk)
create table if not exists product_specs (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references products(id) on delete cascade,
  kategori text,
  nama text not null,
  nilai text not null,
  urutan int not null default 0
);
create index if not exists product_specs_product_idx on product_specs(product_id, urutan);

-- 5. Fasilitas (kawasan & sekitar)
create table if not exists product_facilities (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references products(id) on delete cascade,
  nama text not null,
  kategori text not null default 'kawasan' check (kategori in ('kawasan','sekitar')),
  jarak_menit int,
  urutan int not null default 0
);
create index if not exists product_facilities_product_idx on product_facilities(product_id, urutan);

-- 6. Promo per produk
create table if not exists product_promos (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references products(id) on delete cascade,
  judul text not null,
  deskripsi text,
  syarat_ketentuan text,
  berlaku_sampai date,
  aktif boolean not null default true,
  created_at timestamptz not null default now()
);

-- 7. Paket travel umroh & haji (Salwa Tours)
create table if not exists travel_packages (
  id uuid primary key default gen_random_uuid(),
  agent_id uuid references agents(id) on delete cascade,
  nama text not null,
  slug text not null unique,
  jenis text not null default 'umroh' check (jenis in ('umroh','haji','wisata')),
  durasi_hari int,
  harga_mulai numeric,
  maskapai text,
  hotel_makkah text,
  hotel_madinah text,
  jadwal_keberangkatan text,
  deskripsi text,
  termasuk text,
  tidak_termasuk text,
  badge_promo text,
  featured boolean not null default false,
  aktif boolean not null default true,
  created_at timestamptz not null default now()
);
create index if not exists travel_packages_agent_idx on travel_packages(agent_id);

-- 8. Testimoni
create table if not exists testimonials (
  id uuid primary key default gen_random_uuid(),
  agent_id uuid references agents(id) on delete cascade,
  product_id uuid references products(id) on delete set null,
  nama text not null,
  foto_url text,
  kutipan text not null,
  rating int check (rating between 1 and 5),
  tampil boolean not null default false,
  created_at timestamptz not null default now()
);

-- 9. Artikel
create table if not exists articles (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  judul text not null,
  cover_url text,
  isi text,
  published boolean not null default false,
  published_at timestamptz,
  created_at timestamptz not null default now()
);

-- 10. FAQ (umum, produk, atau travel)
create table if not exists faqs (
  id uuid primary key default gen_random_uuid(),
  product_id uuid references products(id) on delete cascade,
  travel_package_id uuid references travel_packages(id) on delete cascade,
  pertanyaan text not null,
  jawaban text not null,
  urutan int not null default 0
);
create index if not exists faqs_product_idx on faqs(product_id, urutan);

-- 11. Leads (dari form kontak)
create table if not exists leads (
  id uuid primary key default gen_random_uuid(),
  nama text not null,
  no_wa text not null,
  kebutuhan text not null default 'konsultasi' check (kebutuhan in ('beli','konsultasi','survei','umroh','haji')),
  product_id uuid references products(id) on delete set null,
  travel_package_id uuid references travel_packages(id) on delete set null,
  pesan text,
  status text not null default 'baru' check (status in ('baru','dihubungi','deal','batal')),
  created_at timestamptz not null default now()
);
create index if not exists leads_status_idx on leads(status, created_at desc);

-- 12. Pengaturan situs
create table if not exists site_settings (
  key text primary key,
  value text not null,
  updated_at timestamptz not null default now()
);

-- ============================================================
-- RLS: baca publik untuk konten, tulis hanya service role
-- ============================================================
alter table agents enable row level security;
alter table products enable row level security;
alter table product_images enable row level security;
alter table product_specs enable row level security;
alter table product_facilities enable row level security;
alter table product_promos enable row level security;
alter table travel_packages enable row level security;
alter table testimonials enable row level security;
alter table articles enable row level security;
alter table faqs enable row level security;
alter table leads enable row level security;
alter table site_settings enable row level security;

create policy "baca publik" on agents for select using (true);
create policy "baca publik" on products for select using (true);
create policy "baca publik" on product_images for select using (true);
create policy "baca publik" on product_specs for select using (true);
create policy "baca publik" on product_facilities for select using (true);
create policy "baca publik" on product_promos for select using (true);
create policy "baca publik" on travel_packages for select using (aktif = true);
create policy "baca publik" on testimonials for select using (tampil = true);
create policy "baca publik" on articles for select using (published = true);
create policy "baca publik" on faqs for select using (true);
create policy "baca publik" on site_settings for select using (true);

create policy "insert leads publik" on leads for insert with check (true);

-- ============================================================
-- DATA AWAL: agen + 7 proyek SDP
-- (nomor WA & harga = placeholder, diganti data asli Bu Jawiah)
-- ============================================================
insert into agents (nama, tagline, bio, wa_numbers, jam_operasional, statistik)
values (
  'Jawiah',
  'Rumah impian & perjalanan ibadah, satu pintu',
  'Agen PT. Swarna Dwipa Property di Kendari sekaligus konsultan Salwa Tours untuk perjalanan ibadah umroh dan haji. Siap membantu dari konsultasi, survei lokasi, sampai akad — dan mendampingi rencana ibadah Anda.',
  array['6281234567890'],
  'Senin–Sabtu, 08.00–20.00 WITA',
  '{"proyek_tersedia": 7, "layanan": 2}'::jsonb
) on conflict do nothing;

insert into products (agent_id, nama, slug, lokasi, tipe, deskripsi, featured)
select id, x.nama, x.slug, x.lokasi, 'subsidi', x.deskripsi, x.featured
from agents, (values
  ('Madinah City Square Type 70','madinah-city-square-type-70','Hombis, Baruga','Rumah Type 70 di kawasan Madinah City Square, Baruga.', true),
  ('Madinah City Square 3 Type 36','madinah-city-square-3-type-36','Hombis, Baruga','Rumah Type 36 di kawasan Madinah City Square 3, Baruga.', true),
  ('Grand Mangkubumi Residence','grand-mangkubumi-residence','Jl. Konggoasa, Puuwatu','Hunian di Jl. Konggoasa, Puuwatu.', false),
  ('Prima Kampus Square','prima-kampus-square','Jl. H. Lamuse, Kampus UHO','Hunian dekat Kampus UHO, cocok untuk investasi kos/kontrakan.', false),
  ('Madinah 5','madinah-5','Jl. Chairil Anwar, THR','Hunian di Jl. Chairil Anwar, kawasan THR.', false),
  ('Baruga Regency','baruga-regency','Jl. Ade Irma Nasution, Baruga','Hunian di Jl. Ade Irma Nasution, Baruga.', false),
  ('Shafa Marwa 2','shafa-marwa-2','Jl. Lalombako, THR','Hunian di Jl. Lalombako, kawasan THR.', false)
) as x(nama, slug, lokasi, deskripsi, featured)
where agents.nama = 'Jawiah'
on conflict (slug) do nothing;
