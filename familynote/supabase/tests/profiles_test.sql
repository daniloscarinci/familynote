-- Profiles trigger, RLS visibility, anonymous join.
begin;

create function pg_temp.t_ok(c boolean, d text) returns text language sql as
$$ select case when coalesce(c, false) then 'ok - ' else 'not ok - ' end || d $$;

insert into auth.users (id,email) values
  ('00000000-0000-0000-0000-0000000000a1','a@x.com'),
  ('00000000-0000-0000-0000-0000000000b1','b@x.com'),
  ('00000000-0000-0000-0000-0000000000c1','c@x.com');
insert into auth.users (id,email,is_anonymous) values
  ('00000000-0000-0000-0000-0000000000d1',null,true);

select pg_temp.t_ok(
  (select count(*) from profiles where id in (
    '00000000-0000-0000-0000-0000000000a1','00000000-0000-0000-0000-0000000000b1',
    '00000000-0000-0000-0000-0000000000c1','00000000-0000-0000-0000-0000000000d1')) = 4,
  'trigger creates a profile for every new user');
select pg_temp.t_ok(
  (select display_name from profiles where id = '00000000-0000-0000-0000-0000000000a1') = '',
  'new profile has an empty display name');
-- idempotent: re-running the insert logic must not fail or duplicate
create function pg_temp.dup_insert() returns int language plpgsql as $$
declare n int;
begin
  insert into profiles (id) values ('00000000-0000-0000-0000-0000000000a1') on conflict (id) do nothing;
  get diagnostics n = row_count;
  return n;
end $$;
select pg_temp.t_ok(pg_temp.dup_insert() = 0, 'profile creation is idempotent');

set local role authenticated;
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-0000000000a1"}';
select set_config('test.ws', create_workspace('Familia')::text, true);
select set_config('test.tok', create_invitation(current_setting('test.ws')::uuid,'adult'), true);

set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-0000000000b1"}';
select accept_invitation(current_setting('test.tok'));

-- a (admin) and b (member) see each other; c (stranger) is invisible
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-0000000000a1"}';
select pg_temp.t_ok(
  (select count(*) from profiles where id = '00000000-0000-0000-0000-0000000000b1') = 1,
  'member sees profile of a family member');
select pg_temp.t_ok(
  (select count(*) from profiles where id = '00000000-0000-0000-0000-0000000000c1') = 0,
  'user cannot read a stranger profile');
select pg_temp.t_ok(
  (select count(*) from profiles where id = '00000000-0000-0000-0000-0000000000a1') = 1,
  'user reads own profile');

-- update own only
update profiles set display_name = 'Ana' where id = '00000000-0000-0000-0000-0000000000a1';
select pg_temp.t_ok(
  (select display_name from profiles where id = '00000000-0000-0000-0000-0000000000a1') = 'Ana',
  'user updates own profile');
with u as (
  update profiles set display_name = 'Hack' where id = '00000000-0000-0000-0000-0000000000b1'
  returning 1)
select pg_temp.t_ok((select count(*) from u) = 0, 'user cannot update another profile');

set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-0000000000b1"}';
select pg_temp.t_ok(
  (select display_name from profiles where id = '00000000-0000-0000-0000-0000000000a1') = 'Ana',
  'member sees the name the admin saved');

-- removed members are no longer visible
reset role;
update memberships set status = 'removed'
 where user_id = '00000000-0000-0000-0000-0000000000b1';
set local role authenticated;
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-0000000000a1"}';
select pg_temp.t_ok(
  (select count(*) from profiles where id = '00000000-0000-0000-0000-0000000000b1') = 0,
  'removed member profile is hidden');
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-0000000000b1"}';
select pg_temp.t_ok(
  (select count(*) from profiles where id = '00000000-0000-0000-0000-0000000000a1') = 0,
  'removed member cannot see the family profiles');

-- anonymous user accepts an invitation and sees the workspace
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-0000000000a1"}';
select set_config('test.tok2', create_invitation(current_setting('test.ws')::uuid,'adult'), true);
set local request.jwt.claims =
  '{"sub":"00000000-0000-0000-0000-0000000000d1","is_anonymous":true}';
select pg_temp.t_ok(
  accept_invitation(current_setting('test.tok2')) = current_setting('test.ws')::uuid,
  'anonymous user accepts invitation');
select pg_temp.t_ok(
  (select count(*) from workspaces where id = current_setting('test.ws')::uuid) = 1,
  'anonymous member sees the workspace');
select pg_temp.t_ok(
  (select count(*) from profiles where id = '00000000-0000-0000-0000-0000000000a1') = 1,
  'anonymous member sees the organizer name');
update profiles set display_name = 'Vovó' where id = '00000000-0000-0000-0000-0000000000d1';
select pg_temp.t_ok(
  (select display_name from profiles where id = '00000000-0000-0000-0000-0000000000d1') = 'Vovó',
  'anonymous user saves own name');

rollback;
