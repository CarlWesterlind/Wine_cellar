-- A history of bottles drunk, and the racks drawn on the cellar map.

create table public.consumed_bottles (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null default auth.uid()
              references auth.users (id) on delete cascade,
  wine_id     uuid not null references public.wines (id) on delete cascade,
  drunk_on    date not null default current_date,
  occasion    text check (occasion is null or length(trim(occasion)) > 0),
  created_at  timestamptz not null default now()
);

create index consumed_bottles_user_id_idx on public.consumed_bottles (user_id);

alter table public.consumed_bottles enable row level security;

create policy "Users read own history" on public.consumed_bottles
  for select using (auth.uid() = user_id);

create policy "Users add history to own wines" on public.consumed_bottles
  for insert with check (
    auth.uid() = user_id
    and exists (
      select 1 from public.wines w
      where w.id = wine_id and w.user_id = auth.uid()
    )
  );

create policy "Users delete own history" on public.consumed_bottles
  for delete using (auth.uid() = user_id);

create table public.racks (
  id               uuid primary key default gen_random_uuid(),
  user_id          uuid not null default auth.uid()
                   references auth.users (id) on delete cascade,
  name             text not null check (length(trim(name)) > 0),
  shelves          smallint not null check (shelves between 1 and 30),
  slots_per_shelf  smallint not null check (slots_per_shelf between 1 and 30),
  created_at       timestamptz not null default now()
);

alter table public.racks enable row level security;

create policy "Users manage own racks" on public.racks
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
