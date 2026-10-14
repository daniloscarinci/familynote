create or replace function create_workspace(p_name text) returns uuid
language plpgsql security definer set search_path = public, extensions as $$
declare ws uuid;
begin
  if auth.uid() is null then raise exception 'not authenticated'; end if;
  insert into workspaces(name, created_by) values (p_name, auth.uid()) returning id into ws;
  insert into memberships(workspace_id, user_id, role) values (ws, auth.uid(), 'admin');
  return ws;
end $$;

create or replace function create_invitation(p_ws uuid, p_role member_role) returns text
language plpgsql security definer set search_path = public, extensions as $$
declare tok text := encode(gen_random_bytes(32), 'hex');
begin
  if role_in(p_ws) is distinct from 'admin' then
    raise exception 'only administrators can invite';
  end if;
  insert into invitations(workspace_id, role, token_hash, expires_at, created_by)
  values (p_ws, p_role, encode(digest(tok, 'sha256'), 'hex'),
          now() + interval '7 days', auth.uid());
  return tok;
end $$;

create or replace function accept_invitation(p_token text) returns uuid
language plpgsql security definer set search_path = public, extensions as $$
declare inv invitations;
begin
  if auth.uid() is null then raise exception 'not authenticated'; end if;
  select * into inv from invitations
   where token_hash = encode(digest(p_token, 'sha256'), 'hex')
     and used_at is null and expires_at > now() for update;
  if not found then raise exception 'invalid or expired invitation'; end if;
  -- An already-active member keeps their current role; only removed members are re-activated.
  insert into memberships(workspace_id, user_id, role)
  values (inv.workspace_id, auth.uid(), inv.role)
  on conflict (workspace_id, user_id)
    do update set role = excluded.role, status = 'active'
    where memberships.status = 'removed';
  update invitations set used_by = auth.uid(), used_at = now() where id = inv.id;
  return inv.workspace_id;
end $$;

revoke execute on function create_workspace(text), create_invitation(uuid, member_role),
  accept_invitation(text) from public, anon;
grant execute on function create_workspace(text), create_invitation(uuid, member_role),
  accept_invitation(text) to authenticated;
