-- INSERT/UPDATE ... RETURNING tests: RETURNING re-checks the SELECT policy on the new row.
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

-- Runs q (a statement with RETURNING); returns rows returned, or -1 on error.
create function pg_temp.t_ret(q text) returns int language plpgsql as $$
declare n int;
begin execute q; get diagnostics n = row_count; return n;
exception when others then return -1; end $$;

-- a=admin, b=adult, c=limited, d=guest
insert into auth.users (id,email) values
  ('00000000-0000-0000-0000-0000000000a7','ra@x.com'),
  ('00000000-0000-0000-0000-0000000000b7','rb@x.com'),
  ('00000000-0000-0000-0000-0000000000c7','rc@x.com'),
  ('00000000-0000-0000-0000-0000000000d7','rd@x.com');
insert into workspaces (id,name,created_by) values
  ('10000000-0000-0000-0000-000000000071','R1','00000000-0000-0000-0000-0000000000a7'),
  ('10000000-0000-0000-0000-000000000072','R2','00000000-0000-0000-0000-0000000000a7');
insert into memberships (workspace_id,user_id,role) values
  ('10000000-0000-0000-0000-000000000071','00000000-0000-0000-0000-0000000000a7','admin'),
  ('10000000-0000-0000-0000-000000000071','00000000-0000-0000-0000-0000000000b7','adult'),
  ('10000000-0000-0000-0000-000000000071','00000000-0000-0000-0000-0000000000c7','limited'),
  ('10000000-0000-0000-0000-000000000071','00000000-0000-0000-0000-0000000000d7','guest'),
  ('10000000-0000-0000-0000-000000000072','00000000-0000-0000-0000-0000000000a7','admin');
insert into shopping_lists (id,workspace_id,name,created_by) values
  ('20000000-0000-0000-0000-000000000071','10000000-0000-0000-0000-000000000071','Unshared','00000000-0000-0000-0000-0000000000a7');

set local role authenticated;

-- admin
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-0000000000a7"}';
select pg_temp.t_ok(pg_temp.t_ret($q$ insert into notes(id,workspace_id,owner_id,title,visibility)
    values ('40000000-0000-0000-0000-000000000071','10000000-0000-0000-0000-000000000071',
            '00000000-0000-0000-0000-0000000000a7','priv','private') returning id $q$)=1,
  'admin inserts own private note RETURNING');
select pg_temp.t_ok(pg_temp.t_ret($q$ update notes set title='priv2'
    where id='40000000-0000-0000-0000-000000000071' returning id,title $q$)=1,
  'owner updates own note RETURNING');
select pg_temp.t_ok(pg_temp.t_ret($q$ insert into shopping_lists(id,workspace_id,name,created_by)
    values ('20000000-0000-0000-0000-000000000072','10000000-0000-0000-0000-000000000071','L1',
            '00000000-0000-0000-0000-0000000000a7') returning id $q$)=1,
  'admin inserts shopping list RETURNING');
select pg_temp.t_ok(pg_temp.t_ret($q$ insert into shopping_items(list_id,text)
    values ('20000000-0000-0000-0000-000000000072','milk') returning id $q$)=1,
  'admin inserts item RETURNING');
select pg_temp.t_ok(pg_temp.t_ret($q$ insert into list_shares(list_id,user_id,can_edit)
    values ('20000000-0000-0000-0000-000000000072','00000000-0000-0000-0000-0000000000c7',true)
    returning list_id $q$)=1,
  'admin inserts list share RETURNING');
select pg_temp.t_ok(pg_temp.t_ret($q$ insert into note_shares(note_id,user_id,can_edit)
    values ('40000000-0000-0000-0000-000000000071','00000000-0000-0000-0000-0000000000d7',false)
    returning note_id $q$)=1,
  'owner inserts note share RETURNING');
select pg_temp.t_ok(pg_temp.t_ret($q$ update shopping_lists set name='L1b'
    where id='20000000-0000-0000-0000-000000000072' returning id $q$)=1,
  'admin updates list RETURNING');
select pg_temp.t_throws($q$ insert into notes(workspace_id,owner_id,title)
    values ('10000000-0000-0000-0000-000000000072','00000000-0000-0000-0000-0000000000b7','x') returning id $q$,
  'row-level security', 'cannot insert note owned by someone else RETURNING');

-- adult
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-0000000000b7"}';
select pg_temp.t_ok(pg_temp.t_ret($q$ insert into notes(id,workspace_id,owner_id,title,visibility)
    values ('40000000-0000-0000-0000-000000000072','10000000-0000-0000-0000-000000000071',
            '00000000-0000-0000-0000-0000000000b7','ws','workspace') returning id $q$)=1,
  'adult inserts workspace note RETURNING');
select pg_temp.t_ok(pg_temp.t_ret($q$ insert into shopping_lists(workspace_id,name,created_by)
    values ('10000000-0000-0000-0000-000000000071','Groceries',
            '00000000-0000-0000-0000-0000000000b7') returning id $q$)=1,
  'adult inserts shopping list RETURNING');
select pg_temp.t_ok((select count(*) from notes where id='40000000-0000-0000-0000-000000000071')=0,
  'adult cannot read admin private note');
select pg_temp.t_throws($q$ insert into notes(workspace_id,owner_id,title)
    values ('10000000-0000-0000-0000-000000000072','00000000-0000-0000-0000-0000000000b7','x') returning id $q$,
  'row-level security', 'cross-workspace note insert rejected');
select pg_temp.t_throws($q$ insert into shopping_lists(workspace_id,name,created_by)
    values ('10000000-0000-0000-0000-000000000072','x','00000000-0000-0000-0000-0000000000b7') returning id $q$,
  'row-level security', 'cross-workspace list insert rejected');

-- limited
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-0000000000c7"}';
select pg_temp.t_throws($q$ insert into notes(workspace_id,owner_id,title)
    values ('10000000-0000-0000-0000-000000000071','00000000-0000-0000-0000-0000000000c7','x') returning id $q$,
  'row-level security', 'limited cannot insert notes');
select pg_temp.t_ok((select count(*) from shopping_lists where id='20000000-0000-0000-0000-000000000071')=0,
  'limited cannot read unshared list');
select pg_temp.t_ok((select count(*) from shopping_lists where id='20000000-0000-0000-0000-000000000072')=1,
  'limited reads shared list');
select pg_temp.t_ok(pg_temp.t_ret($q$ insert into shopping_items(list_id,text)
    values ('20000000-0000-0000-0000-000000000072','bread') returning id $q$)=1,
  'limited with can_edit adds item RETURNING');

-- guest
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-0000000000d7"}';
select pg_temp.t_ok((select count(*) from shopping_lists where id='20000000-0000-0000-0000-000000000071')=0,
  'guest cannot read unshared list');
select pg_temp.t_ok((select count(*) from notes where id='40000000-0000-0000-0000-000000000071')=1,
  'guest reads note shared with them');
select pg_temp.t_throws($q$ insert into notes(workspace_id,owner_id,title)
    values ('10000000-0000-0000-0000-000000000071','00000000-0000-0000-0000-0000000000d7','x') returning id $q$,
  'row-level security', 'guest cannot insert notes');

rollback;
