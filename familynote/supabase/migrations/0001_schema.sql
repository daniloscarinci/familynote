create schema if not exists extensions;
create extension if not exists pgcrypto with schema extensions;

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

create or replace function touch_updated_at() returns trigger
language plpgsql set search_path = public as $$
begin new.updated_at = now(); return new; end $$;
create trigger notes_touch before update on notes
  for each row execute function touch_updated_at();
create trigger items_touch before update on shopping_items
  for each row execute function touch_updated_at();
