# FamilyNote — Setup

## 1. Requirements
- Flutter 3.47+ (installed at `C:\Users\danil\dev\flutter`; add `...\flutter\bin` to PATH).
- Node 20+ (for the database runner).
- A Supabase project (hosted). Docker is not required.
- Windows: enable **Developer Mode** (Settings → For developers) to build plugins.

### Windows path with an apostrophe
This folder name contains `'` ("Dad's games"), which breaks `flutter test`. Map a drive letter first:

```
subst T: "C:\Users\danil\Desktop\Dad's games\The Family Note"
cd T:\familynote
```

The mapping resets on reboot. Moving the project to a path without an apostrophe removes the need.

## 2. Database (Supabase)
1. Create a project at supabase.com (free plan is enough for development).
2. Save the connection string in `familynote/supabase/.env` (git-ignored):

   ```
   DATABASE_URL=postgresql://postgres:<PASSWORD>@db.<REF>.supabase.co:5432/postgres
   ```

   Use the direct connection or the session pooler, not the transaction pooler (port 6543).
3. Apply migrations and run tests:

   ```
   cd familynote/supabase
   npm install
   node --env-file=.env scripts/run.mjs migrate
   node --env-file=.env scripts/run.mjs test
   ```

   Expect `# passed 55, failed 0`. Tests roll back and leave no data.

Never run the tests against a database holding real family data.

## 3. Sign-in (one-time Supabase settings)
The organizer signs in with **e-mail and password** by default. The emailed-code option stays available on the same screen.

**Password sign-in (default).** Works once the Email provider is on (Authentication -> Providers -> Email).
- For a family pilot you can switch **Confirm email** off (Authentication -> Providers -> Email). New accounts then sign in immediately and no e-mail is sent. With it on, a new account must open the link in the confirmation e-mail before signing in; the app tells the user so.
- Passwords need at least 6 characters.

**Emailed code (optional secondary path).**
1. Supabase dashboard -> Authentication -> Email Templates -> **Magic Link** (and **Confirm signup**).
2. Make sure each body contains `{{ .Token }}` (for example: `Seu código: {{ .Token }}`).
3. Authentication -> URL Configuration -> set **Site URL** to the hosted app address (`APP_URL`).
4. The built-in mail sender is rate limited. For real use, configure custom SMTP (Authentication -> SMTP Settings).

## 3b. Anonymous sign-in (one-time Supabase setting, required for invite links)
Relatives join by tapping a link; the app creates an individual account for them with Supabase anonymous sign-in.
1. Supabase dashboard → Authentication → Sign In / Providers → turn on **Allow anonymous sign-ins**.
2. Before public use, protect it from bulk account creation: Authentication → Attack Protection → enable **CAPTCHA**, and review Authentication → Rate Limits (anonymous sign-ins per hour per IP).
3. Anonymous accounts are tied to the browser storage of that device. If a relative clears browser data, the account is lost; create a new invite for them.

## 4. Run the app
Get the **Project URL** and **anon (public) key** from Project Settings → API. Never use the `service_role` key in the app.

```
cd familynote
flutter run -d chrome ^
  --dart-define=SUPABASE_URL=https://<REF>.supabase.co ^
  --dart-define=SUPABASE_ANON_KEY=<ANON_KEY>
```

(Use `\` instead of `^` outside Windows cmd.) Without the two values the app shows a Portuguese configuration message.

### Invite links and `APP_URL`
Invite links look like `<APP_URL>/#/join/<token>`. Set the address where the web app is hosted:

```
--dart-define=APP_URL=https://familia.exemplo.com
```

If `APP_URL` is not set, the web app uses the address it was opened from (fine for local testing, but links made on `localhost` only work on that computer).

### Hosting requirement
The link must open the app for the relative, so the web build (`flutter build web ...`, folder `build/web`) must be hosted at a stable HTTPS address (any static host). Pass the same `SUPABASE_*` and `APP_URL` defines when building. Relatives can then use "Add to home screen" on their phone. Native deep links are a later step.

## 5. Tests
```
cd familynote
flutter analyze
flutter test
```

## 6. Backups and recovery
- Supabase free plan has no point-in-time recovery. Before real use, either upgrade to a plan with daily backups or schedule a `pg_dump` of the database.
- Recovery: restore the dump into a new project, re-run `scripts/run.mjs migrate` (it skips applied migrations), update `.env` and the app's `--dart-define` values.
- Soft-deleted notes are kept until removed; the trash screen restores them.

## 7. Updating
1. Add a new numbered file in `familynote/supabase/migrations/` (never edit applied ones).
2. Add or extend a test in `familynote/supabase/tests/`.
3. Run `migrate`, then `test`.
4. Build and release the app.
