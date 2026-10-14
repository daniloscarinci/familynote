-- Plain-SQL TAP-style tests (no pgTAP needed). Each result row is 'ok - ...' or 'not ok - ...'.
begin;

create function pg_temp.t_ok(c boolean, d text) returns text language sql as
$$ select case when coalesce(c, false) then 'ok - ' else 'not ok - ' end || d $$;

create function pg_temp.t_throws(q text, pat text, d text) returns text language plpgsql as $$
begin
  execute q;
  return 'not ok - ' || d || ' (no error raised)';
exception when others then
  if sqlerrm ilike '%' || pat || '%' then return 'ok - ' || d; end if;
  return 'not ok - ' || d || ' (got: ' || sqlerrm || ')';
end $$;

insert into auth.users (id,email) values
  ('00000000-0000-0000-0000-00000000000a','a@x.com'),
  ('00000000-0000-0000-0000-00000000000b','b@x.com'),
  ('00000000-0000-0000-0000-00000000000e','e@x.com');

set local role authenticated;
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-00000000000a"}';

-- workspace id and token are carried between roles in transaction-local settings
select set_config('test.ws', create_workspace('Familia Silva')::text, true);
select pg_temp.t_ok(current_setting('test.ws') <> '', 'creates workspace');
select pg_temp.t_ok(
  (select count(*) from memberships
    where role = 'admin' and workspace_id = current_setting('test.ws')::uuid) = 1,
  'creator is admin');

select set_config('test.token', create_invitation(current_setting('test.ws')::uuid, 'adult'), true);
select pg_temp.t_ok(length(current_setting('test.token')) = 64, 'admin gets a 64-char token');
select pg_temp.t_ok(
  (select count(*) from invitations where token_hash = current_setting('test.token')) = 0,
  'raw token is not stored');

-- non-admin cannot invite
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-00000000000e"}';
select pg_temp.t_throws(
  $q$ select create_invitation(current_setting('test.ws')::uuid, 'adult') $q$,
  'only administrators', 'non-admin cannot create invitation');

-- b accepts
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-00000000000b"}';
select pg_temp.t_ok(
  accept_invitation(current_setting('test.token')) = current_setting('test.ws')::uuid,
  'accepts token');
select pg_temp.t_ok(
  (select role::text from memberships where user_id = '00000000-0000-0000-0000-00000000000b') = 'adult',
  'accepted member has invited role');
select pg_temp.t_throws(
  $q$ select accept_invitation(current_setting('test.token')) $q$,
  'invalid or expired invitation', 'token is single use');
select pg_temp.t_throws(
  $q$ select accept_invitation('not-a-real-token') $q$,
  'invalid or expired invitation', 'unknown token is rejected');

rollback;
