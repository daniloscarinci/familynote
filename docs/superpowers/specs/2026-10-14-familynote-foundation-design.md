# FamilyNote — Foundation (Sub-project 1) Design

Date: 2026-10-14
Status: Draft for review

## 1. Goal
A family note app that older, non-technical people can use without help. Users can capture a note in two taps, share lists with family, and trust that private notes stay private.

Out of scope here (later sub-projects): planning horizons, tasks and assignment, recurrence, offline queue, attachments, notification preferences, export UI, AI, voice, calendar, expenses.

## 2. Stack
- Client: Flutter (Android, iOS, web), Riverpod for state, `go_router` for navigation, `intl` for pt-BR and en.
- Backend: Supabase (Postgres, Auth, Realtime, Storage). One project, two environments (dev, prod).
- Authorization lives in Postgres row-level security (RLS). The client holds only the anon key; no service-role key ships in the app.

## 3. Senior-friendly UX rules (acceptance criteria)
1. Body text at least 18sp, user-adjustable (Normal, Grande, Muito grande). Contrast at least WCAG AA.
2. Touch targets at least 56dp; spacing at least 12dp.
3. Every button has a text label. No icon-only actions, no swipe-only or long-press-only actions.
4. Four bottom tabs with text: Início, Listas, Família, Ajustes.
5. Início shows only: large "Nova nota" button, search field, recent notes.
6. New note: tap "Nova nota", type. Autosaves with debounce; no Save button, no required fields.
7. Plain Portuguese, no jargon. Errors say what happened and what to do next.
8. Destructive actions ask in plain words and are recoverable from "Lixeira" (30 days).
9. Status line on every editor: "Salvo", "Salvando...", "Sem internet — será enviado depois".
10. Sign-in by email link (magic link) or invite link; no password rules to remember.
11. Light and dark themes; respects system font scale.

## 4. Roles
| Role | Can |
|---|---|
| Administrator | Everything; invite, remove, change roles, manage categories |
| Adult | Create/edit/share notes and lists; edit shared items |
| Limited | View and edit items explicitly shared; cannot create shared items |
| Guest | View items explicitly shared only |

Private notes (`visibility = 'private'`) are readable and writable only by the owner. This holds even for the Administrator.

## 5. Data model (Postgres)
All tables have `id uuid pk`, `created_at`, `updated_at`; soft-deletable tables have `deleted_at`.

- `profiles(id → auth.users, display_name, locale, text_scale)`
- `workspaces(id, name, created_by)`
- `memberships(workspace_id, user_id, role, status)` unique (workspace_id, user_id)
- `invitations(id, workspace_id, role, token_hash, expires_at, used_by, used_at)`
- `categories(id, workspace_id, name, sort_order)`
- `notes(id, workspace_id, owner_id, category_id, title, body, visibility, status, updated_by, deleted_at)`
- `note_shares(note_id, user_id, can_edit)` for sharing with specific members (Limited, Guest)
- `tags(id, workspace_id, name)`, `note_tags(note_id, tag_id)`
- `shopping_lists(id, workspace_id, name, created_by, deleted_at)`
- `shopping_items(id, list_id, text, checked, checked_by, sort_order)`
- `reminders(id, note_id, user_id, remind_at, timezone, done)`
- `activity_log(id, workspace_id, actor_id, action, entity, entity_id, at)`

Indexes: `notes(workspace_id, updated_at desc)`, GIN full-text on `notes(title, body)` (Portuguese config), `memberships(user_id)`, `reminders(user_id, remind_at)`.

## 6. Security model
- RLS enabled on every table; default deny.
- Helper SQL functions `is_member(ws)`, `role_in(ws)`, `can_read_note(note)`, `can_edit_note(note)` used in policies.
- Note read: owner, or (visibility = 'workspace' and role in Admin/Adult), or row in `note_shares`.
- Invitation tokens: random 32 bytes, stored hashed, single use, 7-day expiry; accepted through an RPC function that validates the token and inserts the membership.
- Search runs through the same RLS, so results never leak inaccessible notes.
- Removing a member sets `status = 'removed'`; policies stop matching immediately, and the client wipes its local cache on next auth check.
- Storage of session token via platform secure storage (Keychain/Keystore).

## 7. Client architecture
Layers, each with one purpose and independent tests:
- `data/` — Supabase repositories (notes, lists, workspace, auth). Interfaces first so UI tests use fakes.
- `domain/` — models and use cases (autosave debouncer, invite acceptance, role checks for UI hints).
- `features/` — screens: home, note editor, lists, family, settings, trash, search.
- `core/` — theme (scalable text, 56dp targets), l10n, status indicator, error mapping.

The UI hides actions a role cannot perform as a convenience only; RLS is the enforcement.

## 8. Sync (this sub-project)
Online-first with Supabase Realtime for shared lists and notes. Last-write-wins per field for list items; for note body, a save that detects a newer `updated_at` creates a "Cópia em conflito" note instead of overwriting. Full offline queue arrives in sub-project 2; here the editor keeps unsaved text locally and retries.

## 9. Reminders
A reminder is a `remind_at` instant plus the user's IANA timezone. In-app: a banner on Início for due items. Push comes with sub-project 2.

## 10. Testing
- SQL tests (pgTAP or scripted): user B cannot select/update user A's private note; guest cannot read unshared notes; removed member loses access; invitation token reuse and expiry fail.
- Dart unit tests for use cases and repositories (fakes).
- Widget tests: Início has a "Nova nota" button at least 56dp; editor autosaves; text scale applies.
- One integration test: two clients, shared list item appears on the second within a few seconds.
- Manual: 2 older users complete "create note", "add item to shopping list", "invite a relative" unaided.

## 11. Deployment
Supabase migrations in `supabase/migrations`, applied with the Supabase CLI. Environment config via `--dart-define`. Setup and release checklist in `docs/`.

## 12. Open decisions
- Supabase hosted free tier is assumed; revisit if the family exceeds its limits.
- Soft-delete retention fixed at 30 days now; configurable later.
