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

insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-00000000000a','a@x.com'),
  ('00000000-0000-0000-0000-00000000000b','b@x.com'),
  ('00000000-0000-0000-0000-00000000000c','c@x.com'),
  ('00000000-0000-0000-0000-00000000000d','d@x.com');
insert into workspaces (id,name,created_by) values
  ('10000000-0000-0000-0000-000000000001','Fam','00000000-0000-0000-0000-00000000000a'),
  ('10000000-0000-0000-0000-000000000002','Other','00000000-0000-0000-0000-00000000000c');
insert into memberships (workspace_id,user_id,role) values
  ('10000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-00000000000a','admin'),
  ('10000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-00000000000b','adult'),
  ('10000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-00000000000d','guest'),
  ('10000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-00000000000c','admin');
insert into notes (id,workspace_id,owner_id,title,visibility) values
  ('20000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-00000000000a','secret','private'),
  ('20000000-0000-0000-0000-000000000002','10000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-00000000000a','shared','workspace');

set local role authenticated;

-- member b (adult)
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-00000000000b"}';
select pg_temp.t_ok((select count(*)::int from notes where title='secret') = 0,
  'adult member cannot see another member private note');
select pg_temp.t_ok((select count(*)::int from notes where title='shared') = 1,
  'adult member sees workspace note');

update notes set title='hacked' where title='secret';
select pg_temp.t_ok((select count(*)::int from notes where title='hacked') = 0,
  'cannot update another member private note');

select pg_temp.t_throws($q$ update notes set workspace_id='10000000-0000-0000-0000-000000000002'
    where id='20000000-0000-0000-0000-000000000002' $q$, 'cannot move between',
  'member cannot move a note into a workspace they do not belong to');
select pg_temp.t_throws($q$ update notes set owner_id='00000000-0000-0000-0000-00000000000b'
    where id='20000000-0000-0000-0000-000000000002' $q$, 'owner cannot be changed',
  'member cannot take ownership of a workspace note');
select pg_temp.t_throws($q$ update notes set visibility='private'
    where id='20000000-0000-0000-0000-000000000002' $q$, 'only the owner',
  'non-owner cannot change visibility');
select pg_temp.t_throws($q$ insert into notes (workspace_id,owner_id,title)
    values ('10000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-00000000000b','x') $q$,
  'row-level security', 'cannot insert a note into a foreign workspace');
select pg_temp.t_throws($q$ insert into notes (workspace_id,owner_id,title)
    values ('10000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-00000000000a','x') $q$,
  'row-level security', 'cannot insert a note owned by someone else');

-- non-member c sees nothing of workspace 1
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-00000000000c"}';
select pg_temp.t_ok((select count(*)::int from notes) = 0, 'non-member sees no notes');

-- guest d: no workspace notes without a share
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-00000000000d"}';
select pg_temp.t_ok((select count(*)::int from notes) = 0, 'guest sees no unshared notes');

-- owner a
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-00000000000a"}';
select pg_temp.t_ok((select count(*)::int from notes) = 2, 'owner sees own private and shared notes');
select pg_temp.t_ok((select title from notes where id='20000000-0000-0000-0000-000000000001') = 'secret',
  'private note title intact after other member update attempt');

rollback;
