-- Bottle photos, AI sommelier info, and a log of label scans for the daily
-- limit in the scan-label function.

alter table public.wines
  add column photo_path text,
  add column sommelier  jsonb;

-- One row per label scan. The scan-label function counts the rows of the
-- last 24 hours. Users can read and add their own rows but never change or
-- delete them, so the count can't be reset from the app.
create table public.label_scans (
  id         bigint generated always as identity primary key,
  user_id    uuid not null default auth.uid()
             references auth.users (id) on delete cascade,
  created_at timestamptz not null default now()
);

create index label_scans_user_time_idx
  on public.label_scans (user_id, created_at);

alter table public.label_scans enable row level security;

create policy "Users read own scans" on public.label_scans
  for select using (auth.uid() = user_id);

create policy "Users add own scans" on public.label_scans
  for insert with check (auth.uid() = user_id);

-- Private photo storage. Each user's photos live in a folder named after
-- their user id, and only they can read or change it.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'wine-photos',
  'wine-photos',
  false,
  5242880, -- 5 MB
  array['image/jpeg', 'image/png', 'image/webp']
);

create policy "Users read own photos" on storage.objects
  for select to authenticated
  using (
    bucket_id = 'wine-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "Users add own photos" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'wine-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "Users delete own photos" on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'wine-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
