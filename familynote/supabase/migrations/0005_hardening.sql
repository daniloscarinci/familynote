-- 1. Per-list sharing for limited/guest members.
create table list_shares (
  list_id uuid not null references shopping_lists on delete cascade,
  user_id uuid not null references auth.users on delete cascade,
  can_edit boolean not null default false,
  primary key (list_id, user_id)
);
create index on list_shares(user_id);
alter table list_shares enable row level security;

-- SECURITY DEFINER helpers avoid policy recursion between lists and shares.
create or replace function can_read_list(p_list uuid) returns boolean
language sql stable security definer set search_path = public, extensions as $$
  select exists (
    select 1 from shopping_lists l
    where l.id = p_list and l.deleted_at is null and is_member(l.workspace_id)
      and (role_in(l.workspace_id) in ('admin','adult')
           or exists (select 1 from list_shares s where s.list_id = l.id and s.user_id = auth.uid())))
$$;

create or replace function can_edit_list_items(p_list uuid) returns boolean
language sql stable security definer set search_path = public, extensions as $$
  select exists (
    select 1 from shopping_lists l
    where l.id = p_list and l.deleted_at is null and is_member(l.workspace_id)
      and (role_in(l.workspace_id) in ('admin','adult')
           or (role_in(l.workspace_id) = 'limited' and exists (
                 select 1 from list_shares s
                 where s.list_id = l.id and s.user_id = auth.uid() and s.can_edit))))
$$;

create or replace function can_manage_list(p_list uuid) returns boolean
language sql stable security definer set search_path = public, extensions as $$
  select exists (
    select 1 from shopping_lists l
    where l.id = p_list and is_member(l.workspace_id)
      and (l.created_by = auth.uid() or role_in(l.workspace_id) = 'admin'))
$$;

drop policy lists_read on shopping_lists;
create policy lists_read on shopping_lists for select using (can_read_list(id));

drop policy items_read on shopping_items;
drop policy items_write on shopping_items;
create policy items_read on shopping_items for select using (can_read_list(list_id));
create policy items_write on shopping_items for all
  using (can_edit_list_items(list_id)) with check (can_edit_list_items(list_id));

create policy list_shares_read on list_shares for select
  using (user_id = auth.uid() or can_manage_list(list_id));
create policy list_shares_manage on list_shares for all
  using (can_manage_list(list_id)) with check (can_manage_list(list_id));

-- 2. A workspace must always keep an active administrator.
create or replace function memberships_last_admin_guard() returns trigger
language plpgsql security definer set search_path = public, extensions as $$
begin
  if old.role = 'admin' and old.status = 'active'
     and (tg_op = 'DELETE' or new.role <> 'admin' or new.status <> 'active') then
    -- Workspace row already gone means we are inside a cascade delete: allow.
    if exists (select 1 from workspaces w where w.id = old.workspace_id)
       and not exists (select 1 from memberships m
                       where m.workspace_id = old.workspace_id and m.user_id <> old.user_id
                         and m.role = 'admin' and m.status = 'active') then
      raise exception 'a workspace must keep at least one administrator';
    end if;
  end if;
  if tg_op = 'DELETE' then return old; end if;
  return new;
end $$;
create trigger memberships_last_admin_guard_trg before update or delete on memberships
  for each row execute function memberships_last_admin_guard();
