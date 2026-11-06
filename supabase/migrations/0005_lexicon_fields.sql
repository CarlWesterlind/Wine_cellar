-- Fields filled with help from the lexicon, and the public bucket the app
-- downloads lexicon updates from.

alter table public.wines
  add column subregion        text,
  add column appellation      text,
  add column vineyard         text,
  add column sweetness        text,
  add column classifications  text[]  not null default '{}',
  add column grapes_blend     boolean not null default false,
  add column grapes_unknown   boolean not null default false,
  -- "Don't know" the grapes and a list of grapes contradict each other.
  add constraint grapes_unknown_has_no_grapes
    check (not grapes_unknown or cardinality(grapes) = 0);

-- The lexicon is the same for everyone and not secret. Only the project
-- owner uploads to it (from the dashboard or with the service key).
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('lexicon', 'lexicon', true, 5242880, array['application/json'])
on conflict (id) do nothing;

create policy "Anyone reads the lexicon" on storage.objects
  for select using (bucket_id = 'lexicon');
