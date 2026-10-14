-- Hardening tests: list sharing + last-admin guard. Rolls back; leaves no data.
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


create function pg_temp.t_rows(q text) returns int language plpgsql as $$
declare n int;
begin execute q; get diagnostics n = row_count; return n; end $$;
-- a=admin, b=adult, c=limited, d=guest, f=adult (promoted later)
insert into auth.users (id,email) values
  ('00000000-0000-0000-0000-0000000000a1','ha@x.com'),
  ('00000000-0000-0000-0000-0000000000b1','hb@x.com'),
  ('00000000-0000-0000-0000-0000000000c1','hc@x.com'),
  ('00000000-0000-0000-0000-0000000000d1','hd@x.com'),
  ('00000000-0000-0000-0000-0000000000f1','hf@x.com');
insert into workspaces (id,name,created_by) values
  ('10000000-0000-0000-0000-000000000001','H1','00000000-0000-0000-0000-0000000000a1'),
  ('10000000-0000-0000-0000-000000000002','H2','00000000-0000-0000-0000-0000000000a1');
insert into memberships (workspace_id,user_id,role) values
  ('10000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-0000000000a1','admin'),
  ('10000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-0000000000b1','adult'),
  ('10000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-0000000000c1','limited'),
  ('10000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-0000000000d1','guest'),
  ('10000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-0000000000f1','adult'),
  ('10000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-0000000000a1','admin');
insert into shopping_lists (id,workspace_id,name,created_by) values
  ('20000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001','Private','00000000-0000-0000-0000-0000000000a1'),
  ('20000000-0000-0000-0000-000000000002','10000000-0000-0000-0000-000000000001','SharedRO','00000000-0000-0000-0000-0000000000a1'),
  ('20000000-0000-0000-0000-000000000003','10000000-0000-0000-0000-000000000001','SharedRW','00000000-0000-0000-0000-0000000000a1');
insert into shopping_items (id,list_id,text) values
  ('30000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000001','milk'),
  ('30000000-0000-0000-0000-000000000002','20000000-0000-0000-0000-000000000002','eggs'),
  ('30000000-0000-0000-0000-000000000003','20000000-0000-0000-0000-000000000003','rice');
insert into list_shares (list_id,user_id,can_edit) values
  ('20000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-0000000000d1',false),
  ('20000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-0000000000c1',false),
  ('20000000-0000-0000-0000-000000000003','00000000-0000-0000-0000-0000000000c1',true),
  ('20000000-0000-0000-0000-000000000003','00000000-0000-0000-0000-0000000000d1',true);

set local role authenticated;

-- guest
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-0000000000d1"}';
select pg_temp.t_ok((select count(*) from shopping_lists where id='20000000-0000-0000-0000-000000000001')=0,
  'guest cannot read unshared list');
select pg_temp.t_ok((select count(*) from shopping_items where list_id='20000000-0000-0000-0000-000000000001')=0,
  'guest cannot read items of unshared list');
select pg_temp.t_ok((select count(*) from shopping_lists where id='20000000-0000-0000-0000-000000000002')=1,
  'guest reads shared list');
select pg_temp.t_ok((select count(*) from shopping_items where list_id='20000000-0000-0000-0000-000000000002')=1,
  'guest reads items of shared list');
select pg_temp.t_throws($q$ insert into shopping_items(list_id,text) values ('20000000-0000-0000-0000-000000000003','x') $q$,
  'row-level security', 'guest cannot add items even with can_edit');

-- limited
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-0000000000c1"}';
select pg_temp.t_ok((select count(*) from shopping_lists)=2, 'limited sees only shared lists');
select pg_temp.t_throws($q$ insert into shopping_items(list_id,text) values ('20000000-0000-0000-0000-000000000002','x') $q$,
  'row-level security', 'limited without can_edit cannot add item');
select pg_temp.t_ok(pg_temp.t_rows($q$ update shopping_items set checked = true
    where id='30000000-0000-0000-0000-000000000002' $q$)=0,
  'limited without can_edit cannot check item');
select pg_temp.t_throws($q$ insert into shopping_items(list_id,text) values ('20000000-0000-0000-0000-000000000001','x') $q$,
  'row-level security', 'limited cannot add item to unshared list');
select pg_temp.t_ok(pg_temp.t_rows($q$ insert into shopping_items(list_id,text)
    values ('20000000-0000-0000-0000-000000000003','bread') $q$)=1,
  'limited with can_edit can add item');
select pg_temp.t_ok(pg_temp.t_rows($q$ update shopping_items set checked = true
    where id='30000000-0000-0000-0000-000000000003' $q$)=1,
  'limited with can_edit can check item');

-- adult
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-0000000000b1"}';
select pg_temp.t_ok((select count(*) from shopping_lists)=3, 'adult still reads all lists');
select pg_temp.t_ok((select count(*) from shopping_items)>=3, 'adult reads all items');

-- last-admin guard (workspace 1 has a single admin)
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-0000000000a1"}';
select pg_temp.t_throws($q$ update memberships set role='adult'
    where workspace_id='10000000-0000-0000-0000-000000000001' and user_id='00000000-0000-0000-0000-0000000000a1' $q$,
  'at least one administrator', 'sole admin cannot demote self');
select pg_temp.t_throws($q$ update memberships set status='removed'
    where workspace_id='10000000-0000-0000-0000-000000000001' and user_id='00000000-0000-0000-0000-0000000000a1' $q$,
  'at least one administrator', 'sole admin cannot remove self');

reset role;
select pg_temp.t_throws($q$ delete from memberships
    where workspace_id='10000000-0000-0000-0000-000000000001' and user_id='00000000-0000-0000-0000-0000000000a1' $q$,
  'at least one administrator', 'sole admin membership cannot be deleted');

-- promote f, then admin may demote
update memberships set role='admin'
  where workspace_id='10000000-0000-0000-0000-000000000001' and user_id='00000000-0000-0000-0000-0000000000f1';
set local role authenticated;
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-0000000000a1"}';
select pg_temp.t_ok(pg_temp.t_rows($q$ update memberships set role='adult'
    where workspace_id='10000000-0000-0000-0000-000000000001' and user_id='00000000-0000-0000-0000-0000000000a1' $q$)=1, 'admin can demote self when another admin exists');

-- whole-workspace delete still works
reset role;
select pg_temp.t_ok(pg_temp.t_rows($q$ delete from workspaces
    where id='10000000-0000-0000-0000-000000000002' $q$)=1,
  'deleting a workspace cascades past the guard');
select pg_temp.t_ok((select count(*) from memberships where workspace_id='10000000-0000-0000-0000-000000000002')=0,
  'cascaded memberships are gone');

rollback;

