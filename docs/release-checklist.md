# FamilyNote — Release Checklist (Foundation)

Tick every item before giving the app to the family.

## Automated
- [ ] `node --env-file=.env scripts/run.mjs test` → `failed 0` (dev project).
- [ ] `flutter analyze` → no issues.
- [ ] `flutter test` → all pass.
- [ ] `grep -r service_role familynote/lib familynote/test` returns nothing.
- [ ] `git status` clean; `.env` is not tracked (`git check-ignore familynote/supabase/.env`).

## Security
- [ ] Production Supabase project is separate from the dev project.
- [ ] Database password rotated after setup; it never appeared in chat, commits or screenshots.
- [ ] Email confirmation / OTP works and the template contains `{{ .Token }}`.
- [ ] Custom SMTP configured (built-in sender is for testing only).
- [ ] RLS enabled on every table (`select tablename from pg_tables where schemaname='public' and not rowsecurity` returns nothing).
- [ ] Manual check with two real accounts: user B cannot see user A's private note; guest sees only shared lists.
- [ ] Backups: daily backup plan or scheduled `pg_dump`, and a restore tested once.

## Usability (older users)
- [ ] Two older users, unaided: create a note, add an item to a shopping list, join the family with an invite code.
- [ ] Text size "Muito grande" does not hide or clip any button.
- [ ] Light and dark themes checked; contrast readable outdoors.
- [ ] Every action is reachable with text-labelled buttons (no icon-only, no swipe-only).

## Known gaps (not release blockers for a private pilot)
- Other members appear as "Membro da família" until a profile table policy and profile creation on signup are added.
- Invites always grant the Adult role (no role picker yet).
- Deleting an account that is the sole admin is blocked by design; a transfer or delete flow is needed.
- No offline queue, push notifications, attachments, export or recovery UI yet (Phase 2).
- Reminders exist in the schema only; no reminder screen yet.
