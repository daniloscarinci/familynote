# Simple, Automatic Onboarding — Addendum

Date: 2026-10-14
Amends: `2026-10-14-familynote-foundation-design.md` sections 3 and 7. Drives from the requirement that an older relative must be able to use the app with no help.

## Roles of people
- **Organizer:** a comfortable family member. Signs in once with an emailed code, which creates the family automatically. Invites others.
- **Relative:** gets a link by WhatsApp, taps it, types their name, and is in. Never types an email, password, or code.

## Join by link (no typing)
1. Organizer taps **"Convidar alguém"**. The app creates a single-use invitation (existing `create_invitation`, 7-day expiry) and builds `<APP_URL>/#/join/<token>`.
2. Buttons: **"Enviar pelo WhatsApp"** (opens `https://wa.me/?text=<message with link>`) and **"Copiar link"**.
3. The relative opens the link. The app reads the token from the URL fragment, signs in with Supabase **anonymous sign-in** (a real, individual account bound to that device), then calls `accept_invitation(token)`.
4. One screen asks **"Qual é o seu nome?"** (one big field, one button "Continuar"). The name is saved to `profiles.display_name`.
5. The relative lands on Home, signed in permanently on that device.

Identity: each person is an individual authenticated user, so private notes stay private and access can be revoked. Nothing is shared between family members.

Risk and mitigation: an anonymous account is tied to the browser/device storage. If the relative clears browser data, the account is lost. Mitigation: the organizer can re-invite (new link, new account), and a later release can offer "guardar com meu email" to upgrade the anonymous account.

## Automatic family
After the organizer signs in, if they have no workspace the app silently calls `create_workspace('Minha família')` and goes to Home. No setup screen. The family name can be changed later in Ajustes.

## Home screen
Three giant labelled buttons, each at least 88dp tall:
1. **Escrever uma nota**
2. **Lista de compras** (opens the family's default list, created automatically on first use)
3. **O que a família escreveu** (shared notes, newest first)

A small **"Mais"** button opens the former four tabs (search, lists, family, settings). Recent notes remain visible below the buttons.

## Plain language
All user-visible errors and statuses use full sentences in pt-BR, no technical words (e.g. "Sem internet. Sua nota está guardada e será enviada depois.").

## Database changes (migration 0006)
- Trigger on `auth.users` insert creates a `profiles` row (display name empty).
- Policy: a user can read profiles of people who share an active workspace with them; update only their own.
- `accept_invitation` already works for anonymous users (they hold the `authenticated` role); add a test.

## Hosting requirement
The invite link must open the app, so the web build is hosted at a stable HTTPS URL (`APP_URL`). The relative can then use "Add to home screen". Native deep links are a later step.

## Supabase dashboard settings (manual, one time)
- Authentication → Sign In / Providers → enable **Allow anonymous sign-ins**.
- Enable CAPTCHA or rate limits for anonymous sign-ins before public use (anonymous accounts can otherwise be created in bulk).

## Out of scope
Google sign-in, native deep links, account upgrade from anonymous to email.
