-- Wines in each user's cellar. Run this in the Supabase SQL editor
-- (or with `supabase db push`) before starting the app.

create type wine_type as enum (
  'red', 'white', 'rose', 'sparkling', 'dessert', 'fortified'
);

create table public.wines (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null default auth.uid()
              references auth.users (id) on delete cascade,
  name        text not null check (length(trim(name)) > 0),
  producer    text,
  vintage     int check (vintage between 1800 and 2200),
  type        wine_type not null default 'red',
  country     text,
  region      text,
  grapes      text[] not null default '{}',
  quantity    int not null default 1 check (quantity >= 0),
  price       numeric(10, 2) check (price >= 0),
  rack        text,
  shelf       text,
  position    text,
  drink_from  int,
  drink_until int,
  notes       text,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  check (drink_from is null or drink_until is null or drink_from <= drink_until)
);

create index wines_user_id_idx on public.wines (user_id);

create function public.set_updated_at() returns trigger
language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger wines_set_updated_at
  before update on public.wines
  for each row execute function public.set_updated_at();

-- Each user can only see and change their own wines.
alter table public.wines enable row level security;

create policy "Users read own wines" on public.wines
  for select using (auth.uid() = user_id);

create policy "Users add own wines" on public.wines
  for insert with check (auth.uid() = user_id);

create policy "Users update own wines" on public.wines
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "Users delete own wines" on public.wines
  for delete using (auth.uid() = user_id);
