-- Profiles are created automatically for every new account (including
-- anonymous accounts used by invite links) and are readable by people who
-- share an active family with the user.

create or replace function handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into profiles (id) values (new.id) on conflict (id) do nothing;
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();

-- Back-fill accounts that existed before this migration.
insert into profiles (id) select id from auth.users on conflict (id) do nothing;

-- True when the signed-in user and [other] are both active members of one family.
create or replace function shares_workspace(other uuid) returns boolean
language sql stable security definer set search_path = public, extensions as $$
  select exists (
    select 1
      from memberships mine
      join memberships theirs on theirs.workspace_id = mine.workspace_id
     where mine.user_id = auth.uid() and mine.status = 'active'
       and theirs.user_id = other and theirs.status = 'active')
$$;

-- profiles_self (0002) stays for own read/write; add read of family members.
create policy profiles_family_read on profiles for select
  using (shares_workspace(id));

revoke execute on function shares_workspace(uuid) from public, anon;
grant execute on function shares_workspace(uuid) to authenticated;
