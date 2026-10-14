# FamilyNote Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A working Flutter + Supabase app where family members sign in individually, share notes and shopping lists, keep private notes private, search, and set basic reminders, designed for older users.

**Architecture:** Postgres schema with row-level security is the single source of truth for permissions. Flutter client uses repository interfaces (Supabase implementations plus in-memory fakes) so UI and use cases are testable without a network. Senior-friendly rules (large text, 56dp targets, text labels) live in one theme module and are enforced by widget tests.

**Tech Stack:** Flutter 3.x, Dart, Riverpod, go_router, supabase_flutter, intl, flutter_secure_storage, Supabase CLI + Postgres (pgTAP), flutter_test.

**Spec:** `docs/superpowers/specs/2026-10-14-familynote-foundation-design.md`

**Prerequisites (verify first):** `flutter --version`, `supabase --version`, Docker running (for `supabase start`). Install missing tools before Task 1.

---

## File Structure

```
familynote/                      (Flutter app root, created by `flutter create`)
  lib/
    main.dart                    app bootstrap, Supabase init from --dart-define
    core/theme.dart              senior-friendly ThemeData, text scale, min target size
    core/status.dart             SaveStatus enum + label text (pt-BR)
    domain/models.dart           Note, ShoppingList, ShoppingItem, Member, Role
    domain/repositories.dart     abstract NoteRepository, ListRepository, WorkspaceRepository
    domain/autosave.dart         Autosaver (debounce + status stream)
    data/supabase_repos.dart     Supabase implementations
    data/fake_repos.dart         in-memory implementations for tests
    features/home/home_screen.dart
    features/notes/note_editor_screen.dart
    features/lists/lists_screen.dart
    features/family/family_screen.dart
    features/settings/settings_screen.dart
    features/shell/app_shell.dart  4 bottom tabs
  test/ ...                      mirrors lib/
  supabase/
    migrations/0001_schema.sql
    migrations/0002_rls.sql
    migrations/0003_invites.sql
    tests/rls_test.sql           pgTAP
```

---

### Task 1: Project scaffold and senior-friendly theme

**Files:**
- Create: `familynote/` (via flutter create), `familynote/lib/core/theme.dart`, `familynote/test/core/theme_test.dart`

- [ ] **Step 1: Scaffold**

Run (in project root): `flutter create --org com.familynote --project-name familynote familynote`
Then in `familynote/` run: `flutter pub add flutter_riverpod go_router supabase_flutter intl flutter_secure_storage`
Expected: `flutter pub get` succeeds.

- [ ] **Step 2: Write the failing test** — `familynote/test/core/theme_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:familynote/core/theme.dart';

void main() {
  test('body text is at least 18sp', () {
    final t = buildTheme(scale: 1.0);
    expect(t.textTheme.bodyLarge!.fontSize, greaterThanOrEqualTo(18));
  });

  test('buttons have at least 56dp height', () {
    final t = buildTheme(scale: 1.0);
    final size = t.elevatedButtonTheme.style!.minimumSize!.resolve({});
    expect(size!.height, greaterThanOrEqualTo(56));
  });

  test('scale multiplies body size', () {
    final big = buildTheme(scale: 1.3).textTheme.bodyLarge!.fontSize!;
    final normal = buildTheme(scale: 1.0).textTheme.bodyLarge!.fontSize!;
    expect(big, closeTo(normal * 1.3, 0.01));
  });
}
```

- [ ] **Step 3: Run to verify failure**

Run: `flutter test test/core/theme_test.dart` — Expected: FAIL (`theme.dart` missing).

- [ ] **Step 4: Implement** — `familynote/lib/core/theme.dart`

```dart
import 'package:flutter/material.dart';

const double kMinTarget = 56;

ThemeData buildTheme({double scale = 1.0, Brightness brightness = Brightness.light}) {
  final base = ThemeData(
    brightness: brightness,
    colorSchemeSeed: const Color(0xFF1B5E7A),
    useMaterial3: true,
  );
  double s(double v) => v * scale;
  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      bodyLarge: TextStyle(fontSize: s(18)),
      bodyMedium: TextStyle(fontSize: s(18)),
      titleLarge: TextStyle(fontSize: s(24), fontWeight: FontWeight.w600),
      labelLarge: TextStyle(fontSize: s(18), fontWeight: FontWeight.w600),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(kMinTarget, kMinTarget),
        textStyle: TextStyle(fontSize: s(18), fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
  );
}
```

- [ ] **Step 5: Run to verify pass** — `flutter test test/core/theme_test.dart` — Expected: 3 passed.

- [ ] **Step 6: Commit** — `git init` (project is not yet a repo), then `git add . && git commit -m "feat: scaffold app and senior-friendly theme"`

---

### Task 2: Database schema migration

**Files:**
- Create: `familynote/supabase/migrations/0001_schema.sql`

- [ ] **Step 1: Init Supabase** — in `familynote/`: `supabase init` then `supabase start`. Expected: local stack URLs printed.

- [ ] **Step 2: Write migration** — `0001_schema.sql`

```sql
create extension if not exists pgcrypto;

create type member_role as enum ('admin','adult','limited','guest');
create type member_status as enum ('active','removed');
create type note_visibility as enum ('private','workspace');
create type note_status as enum ('active','completed','archived');

create table profiles (
  id uuid primary key references auth.users on delete cascade,
  display_name text not null default '',
  locale text not null default 'pt-BR',
  text_scale numeric not null default 1.0,
  created_at timestamptz not null default now()
);

create table workspaces (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_by uuid not null references auth.users,
  created_at timestamptz not null default now()
);

create table memberships (
  workspace_id uuid not null references workspaces on delete cascade,
  user_id uuid not null references auth.users on delete cascade,
  role member_role not null,
  status member_status not null default 'active',
  created_at timestamptz not null default now(),
  primary key (workspace_id, user_id)
);
create index on memberships(user_id);

create table invitations (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references workspaces on delete cascade,
  role member_role not null,
  token_hash text not null unique,
  expires_at timestamptz not null,
  used_by uuid references auth.users,
  used_at timestamptz,
  created_by uuid not null references auth.users,
  created_at timestamptz not null default now()
);

create table categories (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references workspaces on delete cascade,
  name text not null,
  sort_order int not null default 0,
  created_at timestamptz not null default now()
);

create table notes (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references workspaces on delete cascade,
  owner_id uuid not null references auth.users,
  category_id uuid references categories on delete set null,
  title text not null default '',
  body text not null default '',
  visibility note_visibility not null default 'private',
  status note_status not null default 'active',
  updated_by uuid references auth.users,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);
create index on notes(workspace_id, updated_at desc);
create index notes_fts on notes using gin (to_tsvector('portuguese', title || ' ' || body));

create table note_shares (
  note_id uuid not null references notes on delete cascade,
  user_id uuid not null references auth.users on delete cascade,
  can_edit boolean not null default false,
  primary key (note_id, user_id)
);

create table shopping_lists (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references workspaces on delete cascade,
  name text not null,
  created_by uuid not null references auth.users,
  created_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table shopping_items (
  id uuid primary key default gen_random_uuid(),
  list_id uuid not null references shopping_lists on delete cascade,
  text text not null,
  checked boolean not null default false,
  checked_by uuid references auth.users,
  sort_order int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table reminders (
  id uuid primary key default gen_random_uuid(),
  note_id uuid not null references notes on delete cascade,
  user_id uuid not null references auth.users,
  remind_at timestamptz not null,
  timezone text not null,
  done boolean not null default false
);
create index on reminders(user_id, remind_at);

create table activity_log (
  id bigint generated always as identity primary key,
  workspace_id uuid not null references workspaces on delete cascade,
  actor_id uuid references auth.users,
  action text not null,
  entity text not null,
  entity_id uuid,
  at timestamptz not null default now()
);

create or replace function touch_updated_at() returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end $$;
create trigger notes_touch before update on notes
  for each row execute function touch_updated_at();
create trigger items_touch before update on shopping_items
  for each row execute function touch_updated_at();
```

- [ ] **Step 3: Apply** — `supabase db reset` — Expected: migration applies with no errors.

- [ ] **Step 4: Commit** — `git add . && git commit -m "feat(db): core schema"`

---

### Task 3: Row-level security policies and tests

**Files:**
- Create: `familynote/supabase/migrations/0002_rls.sql`, `familynote/supabase/tests/rls_test.sql`

- [ ] **Step 1: Write failing pgTAP test** — `supabase/tests/rls_test.sql`

```sql
begin;
select plan(5);

insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-00000000000a','a@x.com'),
  ('00000000-0000-0000-0000-00000000000b','b@x.com'),
  ('00000000-0000-0000-0000-00000000000c','c@x.com');
insert into workspaces (id,name,created_by) values
  ('10000000-0000-0000-0000-000000000001','Fam','00000000-0000-0000-0000-00000000000a');
insert into memberships (workspace_id,user_id,role) values
  ('10000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-00000000000a','admin'),
  ('10000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-00000000000b','adult');
insert into notes (id,workspace_id,owner_id,title,visibility) values
  ('20000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-00000000000a','secret','private'),
  ('20000000-0000-0000-0000-000000000002','10000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-00000000000a','shared','workspace');

set local role authenticated;

set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-00000000000b"}';
select is((select count(*)::int from notes where title='secret'), 0,
  'adult member cannot see another member private note');
select is((select count(*)::int from notes where title='shared'), 1,
  'adult member sees workspace note');

set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-00000000000c"}';
select is((select count(*)::int from notes), 0,
  'non-member sees no notes');

set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-00000000000a"}';
select is((select count(*)::int from notes), 2, 'owner sees own private and shared notes');

set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-00000000000b"}';
update notes set title='hacked' where title='secret';
select is((select count(*)::int from notes where title='hacked'), 0,
  'cannot update another member private note');

select * from finish();
rollback;
```

- [ ] **Step 2: Run and verify failure** — `supabase test db` — Expected: FAIL (no RLS yet, member sees secret).

- [ ] **Step 3: Implement** — `0002_rls.sql`

```sql
create or replace function is_member(ws uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from memberships
    where workspace_id = ws and user_id = auth.uid() and status = 'active')
$$;

create or replace function role_in(ws uuid) returns member_role
language sql stable security definer set search_path = public as $$
  select role from memberships
    where workspace_id = ws and user_id = auth.uid() and status = 'active'
$$;

create or replace function can_read_note(n notes) returns boolean
language sql stable security definer set search_path = public as $$
  select n.deleted_at is null and is_member(n.workspace_id) and (
    n.owner_id = auth.uid()
    or (n.visibility = 'workspace' and role_in(n.workspace_id) in ('admin','adult'))
    or exists (select 1 from note_shares s where s.note_id = n.id and s.user_id = auth.uid())
  )
$$;

create or replace function can_edit_note(n notes) returns boolean
language sql stable security definer set search_path = public as $$
  select is_member(n.workspace_id) and (
    n.owner_id = auth.uid()
    or (n.visibility = 'workspace' and role_in(n.workspace_id) in ('admin','adult'))
    or exists (select 1 from note_shares s
               where s.note_id = n.id and s.user_id = auth.uid() and s.can_edit)
  )
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
create policy ws_insert on workspaces for insert with check (created_by = auth.uid());

create policy mem_read on memberships for select using (user_id = auth.uid() or is_member(workspace_id));
create policy mem_admin on memberships for update
  using (role_in(workspace_id) = 'admin') with check (role_in(workspace_id) = 'admin');

create policy inv_admin on invitations for all
  using (role_in(workspace_id) = 'admin') with check (role_in(workspace_id) = 'admin');

create policy cat_read on categories for select using (is_member(workspace_id));
create policy cat_write on categories for all
  using (role_in(workspace_id) in ('admin','adult'))
  with check (role_in(workspace_id) in ('admin','adult'));

create policy notes_read on notes for select using (can_read_note(notes));
create policy notes_insert on notes for insert
  with check (owner_id = auth.uid() and role_in(workspace_id) in ('admin','adult'));
create policy notes_update on notes for update
  using (can_edit_note(notes)) with check (is_member(workspace_id));
create policy notes_delete on notes for delete using (owner_id = auth.uid());

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
```

- [ ] **Step 4: Run and verify pass** — `supabase db reset && supabase test db` — Expected: 5/5 pass.

- [ ] **Step 5: Commit** — `git add . && git commit -m "feat(db): row-level security with tests"`

---

### Task 4: Workspace bootstrap and invitations (RPC)

**Files:**
- Create: `familynote/supabase/migrations/0003_invites.sql`, append tests to `supabase/tests/rls_test.sql` as `supabase/tests/invite_test.sql`

- [ ] **Step 1: Failing test** — `supabase/tests/invite_test.sql`

```sql
begin;
select plan(4);

insert into auth.users (id,email) values
  ('00000000-0000-0000-0000-00000000000a','a@x.com'),
  ('00000000-0000-0000-0000-00000000000b','b@x.com');

set local role authenticated;
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-00000000000a"}';

select lives_ok($$ select create_workspace('Família Silva') $$, 'creates workspace');
select ok((select count(*) from memberships where role='admin') = 1, 'creator is admin');

create temp table t as
  select create_invitation((select id from workspaces limit 1), 'adult') as token;
grant all on t to authenticated;

set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-00000000000b"}';
select lives_ok($$ select accept_invitation((select token from t)) $$, 'accepts token');
select throws_ok($$ select accept_invitation((select token from t)) $$,
  'invalid or expired invitation', 'token is single use');

select * from finish();
rollback;
```

- [ ] **Step 2: Run, verify failure** — `supabase test db` — Expected: FAIL (functions missing).

- [ ] **Step 3: Implement** — `0003_invites.sql`

```sql
create or replace function create_workspace(p_name text) returns uuid
language plpgsql security definer set search_path = public as $$
declare ws uuid;
begin
  insert into workspaces(name, created_by) values (p_name, auth.uid()) returning id into ws;
  insert into memberships(workspace_id, user_id, role) values (ws, auth.uid(), 'admin');
  return ws;
end $$;

create or replace function create_invitation(p_ws uuid, p_role member_role) returns text
language plpgsql security definer set search_path = public as $$
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
language plpgsql security definer set search_path = public as $$
declare inv invitations;
begin
  select * into inv from invitations
   where token_hash = encode(digest(p_token, 'sha256'), 'hex')
     and used_at is null and expires_at > now() for update;
  if not found then raise exception 'invalid or expired invitation'; end if;
  insert into memberships(workspace_id, user_id, role)
  values (inv.workspace_id, auth.uid(), inv.role)
  on conflict (workspace_id, user_id)
    do update set role = excluded.role, status = 'active';
  update invitations set used_by = auth.uid(), used_at = now() where id = inv.id;
  return inv.workspace_id;
end $$;

grant execute on function create_workspace, create_invitation, accept_invitation to authenticated;
```

- [ ] **Step 4: Verify pass** — `supabase db reset && supabase test db` — Expected: all pass.

- [ ] **Step 5: Commit** — `git add . && git commit -m "feat(db): workspace creation and single-use invitations"`

---

### Task 5: Domain models, repository interfaces, fakes

**Files:**
- Create: `lib/domain/models.dart`, `lib/domain/repositories.dart`, `lib/data/fake_repos.dart`, `test/data/fake_repos_test.dart`

- [ ] **Step 1: Failing test** — `test/data/fake_repos_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:familynote/data/fake_repos.dart';

void main() {
  test('created note appears in recent list, newest first', () async {
    final repo = FakeNoteRepository();
    await repo.create(title: 'A', body: '');
    await repo.create(title: 'B', body: '');
    final recent = await repo.recent();
    expect(recent.map((n) => n.title), ['B', 'A']);
  });

  test('search matches title and body, ignoring case', () async {
    final repo = FakeNoteRepository();
    await repo.create(title: 'Mercado', body: 'leite e pão');
    expect((await repo.search('LEITE')).length, 1);
    expect((await repo.search('banana')).length, 0);
  });

  test('deleted notes leave recent and land in trash', () async {
    final repo = FakeNoteRepository();
    final n = await repo.create(title: 'X', body: '');
    await repo.softDelete(n.id);
    expect(await repo.recent(), isEmpty);
    expect((await repo.trash()).single.id, n.id);
  });
}
```

- [ ] **Step 2: Verify failure** — `flutter test test/data/fake_repos_test.dart` — Expected: FAIL.

- [ ] **Step 3: Implement** — `lib/domain/models.dart`

```dart
enum Role { admin, adult, limited, guest }

class Note {
  final String id;
  final String title;
  final String body;
  final bool isPrivate;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const Note({
    required this.id,
    required this.title,
    required this.body,
    this.isPrivate = true,
    required this.updatedAt,
    this.deletedAt,
  });

  Note copyWith({String? title, String? body, bool? isPrivate, DateTime? updatedAt, DateTime? deletedAt}) =>
      Note(
        id: id,
        title: title ?? this.title,
        body: body ?? this.body,
        isPrivate: isPrivate ?? this.isPrivate,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
      );
}

class ShoppingItem {
  final String id;
  final String text;
  final bool checked;
  const ShoppingItem({required this.id, required this.text, this.checked = false});
}

class ShoppingList {
  final String id;
  final String name;
  const ShoppingList({required this.id, required this.name});
}
```

`lib/domain/repositories.dart`

```dart
import 'models.dart';

abstract class NoteRepository {
  Future<Note> create({required String title, required String body, bool isPrivate = true});
  Future<Note> update(String id, {String? title, String? body, bool? isPrivate});
  Future<List<Note>> recent({int limit = 20});
  Future<List<Note>> search(String query);
  Future<void> softDelete(String id);
  Future<void> restore(String id);
  Future<List<Note>> trash();
}

abstract class ListRepository {
  Future<List<ShoppingList>> lists();
  Future<ShoppingList> createList(String name);
  Future<List<ShoppingItem>> items(String listId);
  Future<ShoppingItem> addItem(String listId, String text);
  Future<void> setChecked(String itemId, bool checked);
}
```

`lib/data/fake_repos.dart`

```dart
import '../domain/models.dart';
import '../domain/repositories.dart';

class FakeNoteRepository implements NoteRepository {
  final Map<String, Note> _notes = {};
  int _n = 0;
  int _tick = 0;

  DateTime _now() => DateTime(2026, 1, 1).add(Duration(seconds: _tick++));

  @override
  Future<Note> create({required String title, required String body, bool isPrivate = true}) async {
    final note = Note(id: 'n${_n++}', title: title, body: body, isPrivate: isPrivate, updatedAt: _now());
    _notes[note.id] = note;
    return note;
  }

  @override
  Future<Note> update(String id, {String? title, String? body, bool? isPrivate}) async {
    final next = _notes[id]!.copyWith(title: title, body: body, isPrivate: isPrivate, updatedAt: _now());
    _notes[id] = next;
    return next;
  }

  @override
  Future<List<Note>> recent({int limit = 20}) async {
    final l = _notes.values.where((n) => n.deletedAt == null).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return l.take(limit).toList();
  }

  @override
  Future<List<Note>> search(String query) async {
    final q = query.toLowerCase();
    return _notes.values
        .where((n) => n.deletedAt == null &&
            (n.title.toLowerCase().contains(q) || n.body.toLowerCase().contains(q)))
        .toList();
  }

  @override
  Future<void> softDelete(String id) async =>
      _notes[id] = _notes[id]!.copyWith(deletedAt: _now());

  @override
  Future<void> restore(String id) async {
    final n = _notes[id]!;
    _notes[id] = Note(
        id: n.id, title: n.title, body: n.body, isPrivate: n.isPrivate, updatedAt: _now());
  }

  @override
  Future<List<Note>> trash() async => _notes.values.where((n) => n.deletedAt != null).toList();
}
```

- [ ] **Step 4: Verify pass** — `flutter test test/data/fake_repos_test.dart` — Expected: 3 passed.

- [ ] **Step 5: Commit** — `git add . && git commit -m "feat: domain models, repository interfaces, fakes"`

---

### Task 6: Autosave with visible status

**Files:**
- Create: `lib/core/status.dart`, `lib/domain/autosave.dart`, `test/domain/autosave_test.dart`

- [ ] **Step 1: Failing test** — `test/domain/autosave_test.dart`

```dart
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:familynote/core/status.dart';
import 'package:familynote/domain/autosave.dart';

void main() {
  test('debounces rapid edits into one save and reports status', () {
    fakeAsync((async) {
      final saved = <String>[];
      final statuses = <SaveStatus>[];
      final a = Autosaver(
        save: (text) async => saved.add(text),
        delay: const Duration(milliseconds: 800),
      );
      a.status.listen(statuses.add);

      a.onChanged('o');
      a.onChanged('ol');
      a.onChanged('olá');
      async.elapse(const Duration(milliseconds: 900));
      async.flushMicrotasks();

      expect(saved, ['olá']);
      expect(statuses, [SaveStatus.saving, SaveStatus.saved]);
    });
  });

  test('failed save reports pending and keeps text for retry', () {
    fakeAsync((async) {
      final statuses = <SaveStatus>[];
      final a = Autosaver(
        save: (_) async => throw Exception('offline'),
        delay: const Duration(milliseconds: 100),
      );
      a.status.listen(statuses.add);
      a.onChanged('x');
      async.elapse(const Duration(milliseconds: 200));
      async.flushMicrotasks();
      expect(statuses.last, SaveStatus.pending);
      expect(a.unsaved, 'x');
    });
  });
}
```

Run `flutter pub add --dev fake_async` first.

- [ ] **Step 2: Verify failure** — `flutter test test/domain/autosave_test.dart` — Expected: FAIL.

- [ ] **Step 3: Implement** — `lib/core/status.dart`

```dart
enum SaveStatus { saved, saving, pending }

String statusLabel(SaveStatus s) => switch (s) {
      SaveStatus.saved => 'Salvo',
      SaveStatus.saving => 'Salvando...',
      SaveStatus.pending => 'Sem internet — será enviado depois',
    };
```

`lib/domain/autosave.dart`

```dart
import 'dart:async';
import '../core/status.dart';

class Autosaver {
  Autosaver({required this.save, this.delay = const Duration(milliseconds: 800)});

  final Future<void> Function(String text) save;
  final Duration delay;
  final _controller = StreamController<SaveStatus>.broadcast();
  Timer? _timer;
  String? unsaved;

  Stream<SaveStatus> get status => _controller.stream;

  void onChanged(String text) {
    unsaved = text;
    _timer?.cancel();
    _timer = Timer(delay, _flush);
  }

  Future<void> _flush() async {
    final text = unsaved;
    if (text == null) return;
    _controller.add(SaveStatus.saving);
    try {
      await save(text);
      if (unsaved == text) unsaved = null;
      _controller.add(SaveStatus.saved);
    } catch (_) {
      _controller.add(SaveStatus.pending);
    }
  }

  /// Call on app resume or connectivity change to retry kept text.
  Future<void> retry() => _flush();

  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}
```

- [ ] **Step 4: Verify pass** — `flutter test test/domain/autosave_test.dart` — Expected: 2 passed.

- [ ] **Step 5: Commit** — `git add . && git commit -m "feat: autosave with status reporting"`

---

### Task 7: Home screen, editor, and app shell (widget-tested)

**Files:**
- Create: `lib/features/shell/app_shell.dart`, `lib/features/home/home_screen.dart`, `lib/features/notes/note_editor_screen.dart`, `test/features/home_screen_test.dart`

- [ ] **Step 1: Failing test** — `test/features/home_screen_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:familynote/core/theme.dart';
import 'package:familynote/data/fake_repos.dart';
import 'package:familynote/features/home/home_screen.dart';

Widget _wrap(Widget w) => MaterialApp(theme: buildTheme(), home: w);

void main() {
  testWidgets('shows a large labelled New Note button', (t) async {
    await t.pumpWidget(_wrap(HomeScreen(notes: FakeNoteRepository(), onNewNote: () {})));
    final btn = find.widgetWithText(ElevatedButton, 'Nova nota');
    expect(btn, findsOneWidget);
    expect(t.getSize(btn).height, greaterThanOrEqualTo(56));
  });

  testWidgets('tapping New Note triggers callback (one action)', (t) async {
    var tapped = false;
    await t.pumpWidget(_wrap(HomeScreen(notes: FakeNoteRepository(), onNewNote: () => tapped = true)));
    await t.tap(find.text('Nova nota'));
    expect(tapped, isTrue);
  });

  testWidgets('lists recent notes', (t) async {
    final repo = FakeNoteRepository();
    await repo.create(title: 'Consulta dentista', body: '');
    await t.pumpWidget(_wrap(HomeScreen(notes: repo, onNewNote: () {})));
    await t.pumpAndSettle();
    expect(find.text('Consulta dentista'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Verify failure** — `flutter test test/features/home_screen_test.dart` — Expected: FAIL.

- [ ] **Step 3: Implement** — `lib/features/home/home_screen.dart`

```dart
import 'package:flutter/material.dart';
import '../../domain/models.dart';
import '../../domain/repositories.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.notes, required this.onNewNote, this.onOpen});
  final NoteRepository notes;
  final VoidCallback onNewNote;
  final void Function(Note)? onOpen;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Note>> _future = widget.notes.recent();
  final _search = TextEditingController();

  void _run(String q) => setState(() {
        _future = q.trim().isEmpty ? widget.notes.recent() : widget.notes.search(q);
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Início')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.onNewNote,
              icon: const Icon(Icons.add),
              label: const Text('Nova nota'),
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(72)),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _search,
            onChanged: _run,
            decoration: const InputDecoration(
              labelText: 'Procurar',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<Note>>(
              future: _future,
              builder: (c, snap) {
                final items = snap.data ?? const <Note>[];
                if (items.isEmpty) {
                  return const Center(child: Text('Nenhuma nota ainda. Toque em "Nova nota".'));
                }
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (_, i) => ListTile(
                    minVerticalPadding: 16,
                    title: Text(items[i].title.isEmpty ? '(sem título)' : items[i].title),
                    subtitle: Text(items[i].isPrivate ? 'Só para mim' : 'Compartilhada com a família'),
                    onTap: () => widget.onOpen?.call(items[i]),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}
```

`lib/features/notes/note_editor_screen.dart`

```dart
import 'package:flutter/material.dart';
import '../../core/status.dart';
import '../../domain/autosave.dart';
import '../../domain/models.dart';
import '../../domain/repositories.dart';

class NoteEditorScreen extends StatefulWidget {
  const NoteEditorScreen({super.key, required this.notes, this.existing});
  final NoteRepository notes;
  final Note? existing;

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late final _title = TextEditingController(text: widget.existing?.title ?? '');
  late final _body = TextEditingController(text: widget.existing?.body ?? '');
  String? _id;
  late final Autosaver _saver;
  SaveStatus _status = SaveStatus.saved;

  @override
  void initState() {
    super.initState();
    _id = widget.existing?.id;
    _saver = Autosaver(save: (_) => _persist());
    _saver.status.listen((s) {
      if (mounted) setState(() => _status = s);
    });
  }

  Future<void> _persist() async {
    if (_id == null) {
      final n = await widget.notes.create(title: _title.text, body: _body.text);
      _id = n.id;
    } else {
      await widget.notes.update(_id!, title: _title.text, body: _body.text);
    }
  }

  void _changed() => _saver.onChanged('${_title.text}\n${_body.text}');

  @override
  void dispose() {
    _saver.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nota')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(
            controller: _title,
            onChanged: (_) => _changed(),
            decoration: const InputDecoration(labelText: 'Título'),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TextField(
              controller: _body,
              onChanged: (_) => _changed(),
              maxLines: null,
              expands: true,
              autofocus: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(labelText: 'Escreva aqui'),
            ),
          ),
          const SizedBox(height: 8),
          Text(statusLabel(_status), key: const Key('save-status')),
        ]),
      ),
    );
  }
}
```

`lib/features/shell/app_shell.dart`

```dart
import 'package:flutter/material.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.tabs});
  /// Exactly four pages, in order: Início, Listas, Família, Ajustes.
  final List<Widget> tabs;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _i = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.tabs[_i],
      bottomNavigationBar: NavigationBar(
        height: 80,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        selectedIndex: _i,
        onDestinationSelected: (v) => setState(() => _i = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Início'),
          NavigationDestination(icon: Icon(Icons.shopping_cart), label: 'Listas'),
          NavigationDestination(icon: Icon(Icons.group), label: 'Família'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Ajustes'),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Verify pass** — `flutter test test/features/home_screen_test.dart` — Expected: 3 passed.

- [ ] **Step 5: Commit** — `git add . && git commit -m "feat: home, editor, and four-tab shell"`

---

### Task 8: Shopping lists screen

**Files:**
- Create: `lib/features/lists/lists_screen.dart`, extend `lib/data/fake_repos.dart` with `FakeListRepository`, `test/features/lists_screen_test.dart`

- [ ] **Step 1: Failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:familynote/core/theme.dart';
import 'package:familynote/data/fake_repos.dart';
import 'package:familynote/features/lists/lists_screen.dart';

void main() {
  testWidgets('add item and check it off', (t) async {
    final repo = FakeListRepository();
    final list = await repo.createList('Mercado');
    await t.pumpWidget(MaterialApp(
      theme: buildTheme(),
      home: ListDetailScreen(repo: repo, list: list),
    ));
    await t.enterText(find.byType(TextField), 'Leite');
    await t.tap(find.text('Adicionar'));
    await t.pumpAndSettle();
    expect(find.text('Leite'), findsOneWidget);

    await t.tap(find.byType(CheckboxListTile));
    await t.pumpAndSettle();
    final items = await repo.items(list.id);
    expect(items.single.checked, isTrue);
  });
}
```

- [ ] **Step 2: Verify failure** — `flutter test test/features/lists_screen_test.dart` — Expected: FAIL.

- [ ] **Step 3: Implement** — append to `fake_repos.dart`:

```dart
class FakeListRepository implements ListRepository {
  final _lists = <ShoppingList>[];
  final _items = <String, List<ShoppingItem>>{};
  int _n = 0;

  @override
  Future<List<ShoppingList>> lists() async => List.of(_lists);

  @override
  Future<ShoppingList> createList(String name) async {
    final l = ShoppingList(id: 'l${_n++}', name: name);
    _lists.add(l);
    _items[l.id] = [];
    return l;
  }

  @override
  Future<List<ShoppingItem>> items(String listId) async => List.of(_items[listId] ?? []);

  @override
  Future<ShoppingItem> addItem(String listId, String text) async {
    final i = ShoppingItem(id: 'i${_n++}', text: text);
    _items[listId]!.add(i);
    return i;
  }

  @override
  Future<void> setChecked(String itemId, bool checked) async {
    for (final l in _items.values) {
      final idx = l.indexWhere((i) => i.id == itemId);
      if (idx >= 0) l[idx] = ShoppingItem(id: itemId, text: l[idx].text, checked: checked);
    }
  }
}
```

`lib/features/lists/lists_screen.dart`

```dart
import 'package:flutter/material.dart';
import '../../domain/models.dart';
import '../../domain/repositories.dart';

class ListDetailScreen extends StatefulWidget {
  const ListDetailScreen({super.key, required this.repo, required this.list});
  final ListRepository repo;
  final ShoppingList list;

  @override
  State<ListDetailScreen> createState() => _ListDetailScreenState();
}

class _ListDetailScreenState extends State<ListDetailScreen> {
  final _text = TextEditingController();
  List<ShoppingItem> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final i = await widget.repo.items(widget.list.id);
    if (mounted) setState(() => _items = i);
  }

  Future<void> _add() async {
    final t = _text.text.trim();
    if (t.isEmpty) return;
    await widget.repo.addItem(widget.list.id, t);
    _text.clear();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.list.name)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Row(children: [
            Expanded(
              child: TextField(
                controller: _text,
                decoration: const InputDecoration(labelText: 'Novo item'),
                onSubmitted: (_) => _add(),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(onPressed: _add, child: const Text('Adicionar')),
          ]),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                for (final i in _items)
                  CheckboxListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    title: Text(i.text,
                        style: TextStyle(
                            fontSize: 20,
                            decoration: i.checked ? TextDecoration.lineThrough : null)),
                    value: i.checked,
                    onChanged: (v) async {
                      await widget.repo.setChecked(i.id, v ?? false);
                      await _load();
                    },
                  ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
```

- [ ] **Step 4: Verify pass** — `flutter test test/features/lists_screen_test.dart` — Expected: 1 passed.

- [ ] **Step 5: Commit** — `git add . && git commit -m "feat: shopping list screen"`

---

### Task 9: Supabase repositories, auth, and wiring

**Files:**
- Create: `lib/data/supabase_repos.dart`, modify `lib/main.dart`

- [ ] **Step 1: Implement `SupabaseNoteRepository`** — `lib/data/supabase_repos.dart`

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models.dart';
import '../domain/repositories.dart';

Note _note(Map<String, dynamic> r) => Note(
      id: r['id'] as String,
      title: r['title'] as String,
      body: r['body'] as String,
      isPrivate: r['visibility'] == 'private',
      updatedAt: DateTime.parse(r['updated_at'] as String),
      deletedAt: r['deleted_at'] == null ? null : DateTime.parse(r['deleted_at'] as String),
    );

class SupabaseNoteRepository implements NoteRepository {
  SupabaseNoteRepository(this._db, this.workspaceId);
  final SupabaseClient _db;
  final String workspaceId;

  @override
  Future<Note> create({required String title, required String body, bool isPrivate = true}) async {
    final r = await _db.from('notes').insert({
      'workspace_id': workspaceId,
      'owner_id': _db.auth.currentUser!.id,
      'title': title,
      'body': body,
      'visibility': isPrivate ? 'private' : 'workspace',
    }).select().single();
    return _note(r);
  }

  @override
  Future<Note> update(String id, {String? title, String? body, bool? isPrivate}) async {
    final patch = <String, dynamic>{
      'updated_by': _db.auth.currentUser!.id,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (isPrivate != null) 'visibility': isPrivate ? 'private' : 'workspace',
    };
    final r = await _db.from('notes').update(patch).eq('id', id).select().single();
    return _note(r);
  }

  @override
  Future<List<Note>> recent({int limit = 20}) async {
    final r = await _db
        .from('notes')
        .select()
        .eq('workspace_id', workspaceId)
        .is_('deleted_at', null)
        .order('updated_at', ascending: false)
        .limit(limit);
    return r.map<Note>(_note).toList();
  }

  @override
  Future<List<Note>> search(String query) async {
    final r = await _db
        .from('notes')
        .select()
        .eq('workspace_id', workspaceId)
        .is_('deleted_at', null)
        .textSearch('fts', query, config: 'portuguese')
        .limit(50);
    return r.map<Note>(_note).toList();
  }

  @override
  Future<void> softDelete(String id) =>
      _db.from('notes').update({'deleted_at': DateTime.now().toUtc().toIso8601String()}).eq('id', id);

  @override
  Future<void> restore(String id) => _db.from('notes').update({'deleted_at': null}).eq('id', id);

  @override
  Future<List<Note>> trash() async {
    final r = await _db
        .from('notes')
        .select()
        .eq('workspace_id', workspaceId)
        .not('deleted_at', 'is', null)
        .eq('owner_id', _db.auth.currentUser!.id);
    return r.map<Note>(_note).toList();
  }
}
```

Note: `notes_read` hides soft-deleted rows, so trash needs a separate owner-only policy. Add to `0004_trash.sql`:

```sql
create policy notes_read_own_trash on notes for select
  using (owner_id = auth.uid() and deleted_at is not null and is_member(workspace_id));
```

and add a generated column for search used above:

```sql
alter table notes add column fts tsvector
  generated always as (to_tsvector('portuguese', coalesce(title,'') || ' ' || coalesce(body,''))) stored;
create index notes_fts_col on notes using gin (fts);
```

- [ ] **Step 2: Bootstrap** — `lib/main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );
  runApp(const FamilyNoteApp());
}

class FamilyNoteApp extends StatelessWidget {
  const FamilyNoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FamilyNote',
      theme: buildTheme(),
      darkTheme: buildTheme(brightness: Brightness.dark),
      home: const Scaffold(body: Center(child: Text('FamilyNote'))),
    );
  }
}
```

The auth gate, workspace picker, and Family screen (invite link, member list) wire the repositories into `AppShell`; add them as a follow-up task once the sign-in flow is chosen (magic link requires a deep-link scheme configured per platform).

- [ ] **Step 3: Verify build** — `flutter analyze` — Expected: no issues. `flutter test` — Expected: all pass.

- [ ] **Step 4: Commit** — `git add . && git commit -m "feat: supabase repositories and bootstrap"`

---

### Task 10: Release checklist and docs

**Files:**
- Create: `docs/setup.md`, `docs/release-checklist.md`

- [ ] **Step 1: Write `docs/setup.md`** with: install Flutter and Supabase CLI, `supabase start`, `supabase db reset`, `flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`, how to run `supabase test db` and `flutter test`.

- [ ] **Step 2: Write `docs/release-checklist.md`** with items:
  - All SQL and Dart tests pass.
  - Service-role key absent from client code (`grep -r service_role lib/` returns nothing).
  - Two older users complete the three usability tasks unaided.
  - Text scale and dark theme visually checked.
  - Backup schedule enabled in the Supabase project.

- [ ] **Step 3: Commit** — `git add docs && git commit -m "docs: setup and release checklist"`

---

## Self-review notes

- **Spec coverage:** schema (T2), RLS and roles (T3), invitations (T4), models and repositories (T5), autosave and status (T6), home/editor/tabs and senior UX (T1, T7), shopping lists (T8), search and trash (T9), deployment docs (T10). Reminders (spec section 9) are only in the schema (`reminders` table, T2); there is no reminder UI or in-app banner yet, and the auth gate, workspace picker, and Family screen are stubbed in T9. Both are the first tasks of the next plan iteration, after sign-in deep links are chosen.
- **Known risk:** `can_read_note(notes)` is called with a row type in policies; if Postgres rejects the composite-argument form in a policy, switch the helpers to take `note_id uuid` and look the row up inside.
