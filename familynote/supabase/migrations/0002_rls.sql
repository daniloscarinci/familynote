-- Helpers are SECURITY DEFINER so policies never recurse into RLS.
create or replace function is_member(ws uuid) returns boolean
language sql stable security definer set search_path = public, extensions as $$
  select exists (select 1 from memberships
    where workspace_id = ws and user_id = auth.uid() and status = 'active')
$$;

create or replace function role_in(ws uuid) returns member_role
language sql stable security definer set search_path = public, extensions as $$
  select role from memberships
    where workspace_id = ws and user_id = auth.uid() and status = 'active'
$$;

-- Helpers take the note id and look the row up (avoids composite-row-in-policy risk).
create or replace function can_read_note(p_note uuid) returns boolean
language sql stable security definer set search_path = public, extensions as $$
  select exists (
    select 1 from notes n
    where n.id = p_note
      and n.deleted_at is null
      and is_member(n.workspace_id)
      and (
        n.owner_id = auth.uid()
        or (n.visibility = 'workspace' and role_in(n.workspace_id) in ('admin','adult'))
        or exists (select 1 from note_shares s where s.note_id = n.id and s.user_id = auth.uid())
      ))
$$;

create or replace function can_edit_note(p_note uuid) returns boolean
language sql stable security definer set search_path = public, extensions as $$
  select exists (
    select 1 from notes n
    where n.id = p_note
      and is_member(n.workspace_id)
      and (n.deleted_at is null or n.owner_id = auth.uid())
      and (
        n.owner_id = auth.uid()
        or (n.visibility = 'workspace' and role_in(n.workspace_id) in ('admin','adult'))
        or exists (select 1 from note_shares s
                   where s.note_id = n.id and s.user_id = auth.uid() and s.can_edit)
      ))
$$;

alter table profiles enable row level security;
alter table workspaces enable row level security;
alter table memberships enable row level security;
alter table invitations enable row level security;
alter table categories enable row level security;
alter table notes enable row level security;
alter table note_shares enable row level security;
alter table shopping_lists enable row level security;
alter table shopping_items enable row level security;
alter table reminders enable row level security;
alter table activity_log enable row level security;

create policy profiles_self on profiles for all using (id = auth.uid()) with check (id = auth.uid());

create policy ws_read on workspaces for select using (is_member(id));
-- Workspaces are created through create_workspace() (SECURITY DEFINER); no direct insert policy.

create policy mem_read on memberships for select using (user_id = auth.uid() or is_member(workspace_id));
create policy mem_admin on memberships for update
  using (role_in(workspace_id) = 'admin') with check (role_in(workspace_id) = 'admin');

create policy inv_admin on invitations for all
  using (role_in(workspace_id) = 'admin') with check (role_in(workspace_id) = 'admin');

create policy cat_read on categories for select using (is_member(workspace_id));
create policy cat_write on categories for all
  using (role_in(workspace_id) in ('admin','adult'))
  with check (role_in(workspace_id) in ('admin','adult'));

create policy notes_read on notes for select using (can_read_note(id));
create policy notes_insert on notes for insert
  with check (owner_id = auth.uid() and role_in(workspace_id) in ('admin','adult'));
create policy notes_update on notes for update
  using (can_edit_note(id))
  with check (is_member(workspace_id));
create policy notes_delete on notes for delete using (owner_id = auth.uid());

-- RLS WITH CHECK cannot see the old row, so immutability rules live in a trigger.
create or replace function notes_guard() returns trigger
language plpgsql security definer set search_path = public, extensions as $$
begin
  if new.category_id is not null and not exists (
       select 1 from categories c where c.id = new.category_id and c.workspace_id = new.workspace_id) then
    raise exception 'category does not belong to workspace';
  end if;
  if tg_op = 'UPDATE' and auth.uid() is not null then
    if new.workspace_id is distinct from old.workspace_id then
      raise exception 'note cannot move between workspaces';
    end if;
    if new.owner_id is distinct from old.owner_id then
      raise exception 'note owner cannot be changed';
    end if;
    if auth.uid() <> old.owner_id and
       (new.visibility is distinct from old.visibility
        or new.deleted_at is distinct from old.deleted_at) then
      raise exception 'only the owner can change visibility or delete a note';
    end if;
  end if;
  return new;
end $$;
create trigger notes_guard_trg before insert or update on notes
  for each row execute function notes_guard();

create policy shares_read on note_shares for select
  using (user_id = auth.uid() or exists (select 1 from notes n where n.id = note_id and n.owner_id = auth.uid()));
create policy shares_owner on note_shares for all
  using (exists (select 1 from notes n where n.id = note_id and n.owner_id = auth.uid()))
  with check (exists (select 1 from notes n where n.id = note_id and n.owner_id = auth.uid()));

create policy lists_read on shopping_lists for select
  using (is_member(workspace_id) and deleted_at is null);
create policy lists_write on shopping_lists for all
  using (role_in(workspace_id) in ('admin','adult'))
  with check (role_in(workspace_id) in ('admin','adult'));

create policy items_read on shopping_items for select
  using (exists (select 1 from shopping_lists l where l.id = list_id and is_member(l.workspace_id)));
create policy items_write on shopping_items for all
  using (exists (select 1 from shopping_lists l where l.id = list_id
                 and role_in(l.workspace_id) in ('admin','adult','limited')))
  with check (exists (select 1 from shopping_lists l where l.id = list_id
                 and role_in(l.workspace_id) in ('admin','adult','limited')));

create policy rem_self on reminders for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy log_read on activity_log for select using (role_in(workspace_id) = 'admin');
