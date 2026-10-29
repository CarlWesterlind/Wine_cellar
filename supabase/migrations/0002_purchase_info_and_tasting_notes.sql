-- Purchase date and shop on each wine, and a log of dated tasting notes
-- that replaces the single `notes` field.

alter table public.wines
  add column purchase_date  date,
  add column purchased_from text;

create table public.tasting_notes (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null default auth.uid()
              references auth.users (id) on delete cascade,
  wine_id     uuid not null references public.wines (id) on delete cascade,
  tasted_on   date not null default current_date,
  rating      smallint check (rating between 1 and 5),
  text        text not null check (length(trim(text)) > 0),
  created_at  timestamptz not null default now()
);

create index tasting_notes_wine_id_idx on public.tasting_notes (wine_id);

-- Keep existing notes: each becomes a tasting note dated the day the wine
-- was added.
insert into public.tasting_notes (user_id, wine_id, tasted_on, text)
select user_id, id, created_at::date, notes
from public.wines
where notes is not null and length(trim(notes)) > 0;

alter table public.wines drop column notes;

-- Each user can only see and change their own notes, and only add notes to
-- their own wines.
alter table public.tasting_notes enable row level security;

create policy "Users read own notes" on public.tasting_notes
  for select using (auth.uid() = user_id);

create policy "Users add notes to own wines" on public.tasting_notes
  for insert with check (
    auth.uid() = user_id
    and exists (
      select 1 from public.wines w
      where w.id = wine_id and w.user_id = auth.uid()
    )
  );

create policy "Users update own notes" on public.tasting_notes
  for update using (auth.uid() = user_id)
  with check (
    auth.uid() = user_id
    and exists (
      select 1 from public.wines w
      where w.id = wine_id and w.user_id = auth.uid()
    )
  );

create policy "Users delete own notes" on public.tasting_notes
  for delete using (auth.uid() = user_id);
