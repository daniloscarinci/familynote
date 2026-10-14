-- Owner-only read of own soft-deleted notes (notes_read hides deleted rows).
create policy notes_read_own_trash on notes for select
  using (owner_id = auth.uid() and deleted_at is not null and is_member(workspace_id));

-- Generated search column used by the client; replaces the expression index from 0001.
drop index if exists notes_fts;
alter table notes add column fts tsvector
  generated always as (to_tsvector('portuguese', coalesce(title,'') || ' ' || coalesce(body,''))) stored;
create index notes_fts_col on notes using gin (fts);
