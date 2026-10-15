-- INSERT ... RETURNING re-evaluates SELECT policies on the new row. Helpers that
-- re-query the table by id use the statement snapshot and cannot see the row being
-- inserted, so the policy failed. These row-based helpers use only the row's own
-- columns (plus membership / share lookups). Semantics are identical to 0002/0005.
-- The uuid-based helpers are kept (still used by other policies and callers).

create or replace function can_read_note_row(
  p_id uuid, p_owner uuid, p_ws uuid, p_vis note_visibility, p_deleted timestamptz)
returns boolean
language sql stable security definer set search_path = public, extensions as $$
  select p_deleted is null
    and is_member(p_ws)
    and (
      p_owner = auth.uid()
      or (p_vis = 'workspace' and role_in(p_ws) in ('admin','adult'))
      or exists (select 1 from note_shares s where s.note_id = p_id and s.user_id = auth.uid())
    )
$$;

create or replace function can_edit_note_row(
  p_id uuid, p_owner uuid, p_ws uuid, p_vis note_visibility, p_deleted timestamptz)
returns boolean
language sql stable security definer set search_path = public, extensions as $$
  select is_member(p_ws)
    and (p_deleted is null or p_owner = auth.uid())
    and (
      p_owner = auth.uid()
      or (p_vis = 'workspace' and role_in(p_ws) in ('admin','adult'))
      or exists (select 1 from note_shares s
                 where s.note_id = p_id and s.user_id = auth.uid() and s.can_edit)
    )
$$;

drop policy notes_read on notes;
create policy notes_read on notes for select
  using (can_read_note_row(id, owner_id, workspace_id, visibility, deleted_at));

drop policy notes_update on notes;
create policy notes_update on notes for update
  using (can_edit_note_row(id, owner_id, workspace_id, visibility, deleted_at))
  with check (is_member(workspace_id));

create or replace function can_read_list_row(
  p_id uuid, p_ws uuid, p_deleted timestamptz)
returns boolean
language sql stable security definer set search_path = public, extensions as $$
  select p_deleted is null and is_member(p_ws)
    and (role_in(p_ws) in ('admin','adult')
         or exists (select 1 from list_shares s where s.list_id = p_id and s.user_id = auth.uid()))
$$;

drop policy lists_read on shopping_lists;
create policy lists_read on shopping_lists for select
  using (can_read_list_row(id, workspace_id, deleted_at));
