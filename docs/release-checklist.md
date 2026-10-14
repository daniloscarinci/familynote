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
- [ ] **Allow anonymous sign-ins** is on, and CAPTCHA / rate limits are enabled for it.
- [ ] Email confirmation / OTP works and the template contains `{{ .Token }}`.
- [ ] Custom SMTP configured (built-in sender is for testing only).
- [ ] RLS enabled on every table (`select tablename from pg_tables where schemaname='public' and not rowsecurity` returns nothing).
- [ ] Manual check with two real accounts: user B cannot see user A's private note; guest sees only shared lists.
- [ ] Backups: daily backup plan or scheduled `pg_dump`, and a restore tested once.

## Usability (older users)
- [ ] Web build hosted at a stable HTTPS address and built with `APP_URL` set to it.
- [ ] Organizer: sign in with the emailed code, land on Home with no setup question, tap "Convidar alguém", send the link by WhatsApp.
- [ ] Two older users, unaided: open the link, type their name, write a note, open the shopping list, read what the family wrote.
- [ ] Home shows three big buttons; "Mais" opens search, lists, family and settings.
- [ ] Text size "Muito grande" does not hide or clip any button.
- [ ] Light and dark themes checked; contrast readable outdoors.
- [ ] Every action is reachable with text-labelled buttons (no icon-only, no swipe-only).

## Known gaps (not release blockers for a private pilot)
- An anonymous account is lost if the relative clears browser data (re-invite); upgrade to an e-mail account is a later release.
- Native deep links, Google sign-in and a "change my name" screen are not included yet.
- Invites always grant the Adult role (no role picker yet).
- Deleting an account that is the sole admin is blocked by design; a transfer or delete flow is needed.
- No offline queue, push notifications, attachments, export or recovery UI yet (Phase 2).
- Reminders exist in the schema only; no reminder screen yet.
