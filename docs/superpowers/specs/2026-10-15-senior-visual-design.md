# Senior-Friendly Visual Design — Brief

Date: 2026-10-15
Applies to: every screen of the Flutter app. Extends section 3 of the foundation design.

## Goals
An 70+ user with reduced vision, reduced fine motor control and little tech experience should be able to: see everything without squinting, hit every control the first time, never wonder "what happens if I tap this", and never get lost.

## Principles
1. **One thing per screen.** One primary action, visually dominant. Secondary actions are plainly smaller and clearly secondary.
2. **Words, not symbols.** Every button has a text label; icons only accompany text, never replace it.
3. **Always say where you are and how to go back.** Every non-Home screen has a large title and a labelled "Voltar" button (not just an arrow).
4. **Always confirm.** After saving/sending, show a large, readable confirmation that stays for at least 4 seconds, in words ("Guardado. Pode voltar.").
5. **Forgiving.** Destructive actions always ask in plain words and are undoable ("Apagar" goes to the Lixeira).
6. **Calm.** No animation that moves content, no auto-dismissing toasts under 4s, no hidden gestures, no long lists of choices.

## Visual system
**Color (light theme default).**
- Background: warm off-white `#FFFDF8`. Surface cards: white with a 2dp border `#C9C4B8`.
- Text: near-black `#1B1B1B` on background (contrast >= 15:1). Secondary text never lighter than `#4A4A4A` (>= 8:1).
- Primary action: deep teal `#0B5563` with white text (>= 8:1). Secondary action: white surface, 2dp teal border, teal text.
- Success `#1B6B2F`, warning `#8A5A00`, error `#A4161A` — each always paired with an icon AND words, never colour alone.
- Dark theme: background `#121212`, text `#F2F2F2`, primary `#7FD1DE` with `#00262C` text; same contrast targets.
- Respect the system "high contrast" flag by switching to the maximum-contrast variant.

**Typography.**
- Base text 20sp (was 18), titles 28sp bold, buttons 22sp bold, never below 18sp anywhere (no captions, no hints below 18sp).
- Weight 500+ for body (no light weights). Line height 1.4. Left-aligned, max line length ~60 characters.
- Text size choices in Ajustes: Normal (1.0), Grande (1.3), Muito grande (1.6), Enorme (2.0). Layouts must not clip or overlap at 2.0 (use scrolling, wrap, and stack buttons vertically).
- Font: system default sans-serif; do not add web fonts.

**Shape and spacing.**
- Buttons: min height 64dp (primary 80dp), full width on phones, 16dp corner radius, 2dp border, 16dp vertical gap between buttons (never two buttons side by side on phones).
- Tap targets >= 56dp with >= 12dp spacing; checkboxes/switches enlarged (scale >= 1.4) with the whole row tappable.
- Screen padding 20dp; section spacing 24dp.
- A visible focus ring (3dp) for keyboard/switch users.

**Navigation.**
- Home is the hub: big buttons only. No bottom bar on Home.
- Sub-screens: top bar with title (28sp) and a labelled "Voltar" at left. At most one level deep from Home for the 4 daily tasks (write, shopping, family writing, invite).
- "Mais" is renamed "Outras opções" and lists plain-language rows (Procurar, Família, Lixeira, Letras maiores e menores, Sair), each 72dp.

**Feedback.**
- Saving state is a persistent line under the editor, 20sp, with an icon: "Salvo" / "Salvando..." / "Sem internet. Sua nota está guardada e será enviada depois."
- Errors appear inline above the button that caused them, with the fix in one sentence, never as a toast.
- Empty states say what to do: "Ainda não há nada aqui. Toque em 'Escrever tudo aqui'."

**Home layout (phone).**
1. App name + greeting with the person's first name ("Bom dia, Maria").
2. **Escrever tudo aqui** (primary, 96dp, teal, large pencil icon + text).
3. **Lista de compras** (primary-outline, 80dp) with a count badge in words ("5 itens").
4. **O que a família escreveu** (primary-outline, 80dp).
5. **Convidar a família** (outline, 72dp, admin only).
6. **Outras opções** (text button, 64dp).
A short "Últimas anotações" list below (max 3 rows, 72dp each, each row a button).

## Acceptance checks (automated where possible)
- Widget tests assert: min font size >= 18sp for every Text in each main screen at scale 1.0; every Button/ListTile/Checkbox row height >= 56dp; Home primary >= 96dp.
- Contrast unit test computes WCAG ratio for each theme colour pair; body/primary pairs >= 7:1, others >= 4.5:1.
- Golden-style layout tests at text scale 2.0 on a 360x640 viewport produce no overflow errors for: Home, Capture, Preview, Shopping list, Family, Settings, Sign-in.
- Manual: two older users complete write-everything, check an item, and invite a relative unaided.

## Out of scope
Voice dictation, custom fonts, illustrations/animations, localization changes.
