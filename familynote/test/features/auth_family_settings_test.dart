import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/surface.dart';
import 'package:familynote/app/providers.dart';
import 'package:familynote/core/theme.dart';
import 'package:familynote/data/auth_repository.dart';
import 'package:familynote/data/workspace_repository.dart';
import 'package:familynote/domain/models.dart';
import 'package:familynote/features/auth/sign_in_screen.dart';
import 'package:familynote/features/family/family_screen.dart';
import 'package:familynote/features/settings/settings_screen.dart';

Widget _wrap(Widget child) => MaterialApp(theme: buildTheme(), home: child);

void main() {
  group('SignInScreen', () {
    testWidgets('email -> code -> signed in', (t) async {
    tall(t);
      final auth = FakeAuthRepository();
      await t.pumpWidget(_wrap(SignInScreen(auth: auth)));
      await t.tap(find.text('Prefiro receber um código por e-mail'));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField), 'ana@exemplo.com');
      await t.tap(find.text('Enviar código'));
      await t.pumpAndSettle();
      expect(auth.sentTo, ['ana@exemplo.com']);

      await t.enterText(find.byType(TextField).last, FakeAuthRepository.validCode);
      await t.tap(find.widgetWithText(ElevatedButton, 'Entrar'));
      await t.pumpAndSettle();
      expect(await auth.signedIn.first, isTrue);
    });

    testWidgets('wrong code shows an error', (t) async {
    tall(t);
      final auth = FakeAuthRepository();
      await t.pumpWidget(_wrap(SignInScreen(auth: auth)));
      await t.tap(find.text('Prefiro receber um código por e-mail'));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField), 'ana@exemplo.com');
      await t.tap(find.text('Enviar código'));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField).last, '000000');
      await t.tap(find.widgetWithText(ElevatedButton, 'Entrar'));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('error')), findsOneWidget);
      expect(await auth.signedIn.first, isFalse);
    });
  });

  group('SignInScreen password', () {
    Future<void> fill(WidgetTester t, String email, String pw) async {
      await t.enterText(find.byKey(const Key('email')), email);
      await t.enterText(find.byKey(const Key('password')), pw);
    }

    testWidgets('sign in success', (t) async {
    tall(t);
      final auth = FakeAuthRepository()..accounts['ana@exemplo.com'] = 'segredo1';
      await t.pumpWidget(_wrap(SignInScreen(auth: auth)));
      await fill(t, 'ana@exemplo.com', 'segredo1');
      await t.tap(find.byKey(const Key('primary')));
      await t.pumpAndSettle();
      expect(await auth.signedIn.first, isTrue);
    });

    testWidgets('wrong password shows plain message', (t) async {
    tall(t);
      final auth = FakeAuthRepository()..accounts['ana@exemplo.com'] = 'segredo1';
      await t.pumpWidget(_wrap(SignInScreen(auth: auth)));
      await fill(t, 'ana@exemplo.com', 'errada');
      await t.tap(find.byKey(const Key('primary')));
      await t.pumpAndSettle();
      expect(find.text('E-mail ou senha incorretos.'), findsOneWidget);
      expect(await auth.signedIn.first, isFalse);
    });

    testWidgets('create account success', (t) async {
    tall(t);
      final auth = FakeAuthRepository();
      await t.pumpWidget(_wrap(SignInScreen(auth: auth)));
      await t.tap(find.text('Criar minha conta'));
      await t.pumpAndSettle();
      expect(find.widgetWithText(ElevatedButton, 'Criar conta'), findsOneWidget);
      await fill(t, 'ana@exemplo.com', 'segredo1');
      await t.tap(find.byKey(const Key('primary')));
      await t.pumpAndSettle();
      expect(await auth.signedIn.first, isTrue);
    });

    testWidgets('create account needing confirmation', (t) async {
    tall(t);
      final auth = FakeAuthRepository()..requireConfirmation = true;
      await t.pumpWidget(_wrap(SignInScreen(auth: auth)));
      await t.tap(find.text('Criar minha conta'));
      await t.pumpAndSettle();
      await fill(t, 'ana@exemplo.com', 'segredo1');
      await t.tap(find.byKey(const Key('primary')));
      await t.pumpAndSettle();
      expect(find.text('Enviamos um e-mail para confirmar. Abra o link e depois entre aqui.'),
          findsOneWidget);
      expect(await auth.signedIn.first, isFalse);
    });

    testWidgets('short password is explained', (t) async {
    tall(t);
      final auth = FakeAuthRepository();
      await t.pumpWidget(_wrap(SignInScreen(auth: auth)));
      await t.tap(find.text('Criar minha conta'));
      await t.pumpAndSettle();
      await fill(t, 'ana@exemplo.com', '123');
      await t.tap(find.byKey(const Key('primary')));
      await t.pumpAndSettle();
      expect(find.text('A senha precisa ter pelo menos 6 caracteres.'), findsOneWidget);
    });

    testWidgets('show password toggle reveals the text', (t) async {
    tall(t);
      await t.pumpWidget(_wrap(SignInScreen(auth: FakeAuthRepository())));
      EditableText field() => t.widget<EditableText>(find.descendant(
          of: find.byKey(const Key('password')), matching: find.byType(EditableText)));
      expect(field().obscureText, isTrue);
      await t.tap(find.text('Mostrar senha'));
      await t.pumpAndSettle();
      expect(field().obscureText, isFalse);
    });

    testWidgets('switching to the code flow works', (t) async {
    tall(t);
      await t.pumpWidget(_wrap(SignInScreen(auth: FakeAuthRepository())));
      await t.tap(find.text('Prefiro receber um código por e-mail'));
      await t.pumpAndSettle();
      expect(find.text('Enviar código'), findsOneWidget);
      expect(find.byKey(const Key('password')), findsNothing);
    });

    testWidgets('targets are at least 56dp', (t) async {
    tall(t);
      await t.pumpWidget(_wrap(SignInScreen(auth: FakeAuthRepository())));
      for (final k in ['primary', 'toggle-create', 'use-code', 'show-password']) {
        expect(t.getSize(find.byKey(Key(k))).height, greaterThanOrEqualTo(56), reason: k);
      }
    });
  });

  group('FamilyScreen', () {
    FakeWorkspaceRepository repoWith(Role myRole) => FakeWorkspaceRepository(
          workspaceId: 'ws1',
          members: [
            Member(userId: 'me', displayName: '', role: myRole),
            const Member(userId: 'u2', displayName: 'Maria', role: Role.adult),
            const Member(userId: 'u3', displayName: '', role: Role.adult),
          ],
        );

    Widget screen(FakeWorkspaceRepository repo, List<Uri> opened, {bool ok = true}) =>
        _wrap(FamilyScreen(
          repo: repo,
          workspaceId: 'ws1',
          appUrl: 'https://familia.exemplo.com',
          openUrl: (u) async {
            opened.add(u);
            return ok;
          },
        ));

    testWidgets('shows real names, with a fallback for unnamed members', (t) async {
    tall(t);
      await t.pumpWidget(screen(repoWith(Role.admin), []));
      await t.pumpAndSettle();
      expect(find.text('Maria'), findsOneWidget);
      expect(find.text('Você'), findsOneWidget);
      expect(find.text('Membro da família'), findsOneWidget);
    });

    testWidgets('admin: invite is ready on open, no extra tap', (t) async {
    tall(t);
      final opened = <Uri>[];
      final repo = repoWith(Role.admin);
      await t.pumpWidget(screen(repo, opened));
      await t.pumpAndSettle();
      expect(repo.invitations, ['TOKEN0']);
      expect(find.text('Enviar pelo WhatsApp'), findsOneWidget);
      expect(find.text('Copiar link'), findsOneWidget);
      expect(find.text('Mande este link. Quem abrir entra na sua família.'), findsOneWidget);
      expect(t.getSize(find.byKey(const Key('btn-whatsapp'))).height, greaterThanOrEqualTo(56));
      expect(t.getSize(find.byKey(const Key('btn-copy'))).height, greaterThanOrEqualTo(56));
      expect(t.widget<SelectableText>(find.byKey(const Key('invite-link'), skipOffstage: false)).data,
          'https://familia.exemplo.com/#/join/TOKEN0');

      await t.tap(find.text('Enviar pelo WhatsApp'));
      await t.pumpAndSettle();
      expect(opened.single.host, 'wa.me');
      expect(opened.single.queryParameters['text'], contains('https://familia.exemplo.com/#/join/TOKEN0'));
    });

    testWidgets('Convidar alguem makes a new link', (t) async {
    tall(t);
      final repo = repoWith(Role.admin);
      await t.pumpWidget(screen(repo, []));
      await t.pumpAndSettle();
      await t.ensureVisible(find.text('Convidar alguém'));
      await t.tap(find.text('Convidar alguém'));
      await t.pumpAndSettle();
      expect(repo.invitations, ['TOKEN0', 'TOKEN1']);
      expect(t.widget<SelectableText>(find.byKey(const Key('invite-link'), skipOffstage: false)).data,
          'https://familia.exemplo.com/#/join/TOKEN1');
    });

    testWidgets('members load error shows plain message and retry works', (t) async {
    tall(t);
      final repo = repoWith(Role.admin)..membersError = Exception('boom');
      await t.pumpWidget(screen(repo, []));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('load-error')), findsOneWidget);
      expect(find.text('Tentar de novo'), findsOneWidget);
      expect(find.text('Enviar pelo WhatsApp'), findsNothing);
      repo.membersError = null;
      await t.tap(find.text('Tentar de novo'));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('load-error')), findsNothing);
      expect(find.text('Enviar pelo WhatsApp'), findsOneWidget);
    });

    testWidgets('copy puts the link on the clipboard', (t) async {
    tall(t);
      String? copied;
      t.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      });
      addTearDown(() => t.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));
      await t.pumpWidget(screen(repoWith(Role.admin), []));
      await t.pumpAndSettle();
      await t.tap(find.text('Copiar link'));
      await t.pumpAndSettle();
      expect(copied, 'https://familia.exemplo.com/#/join/TOKEN0');
      expect(find.text('Link copiado'), findsOneWidget);
    });

    testWidgets('non-admin has no invite button', (t) async {
    tall(t);
      await t.pumpWidget(screen(repoWith(Role.adult), []));
      await t.pumpAndSettle();
      expect(find.text('Convidar alguém'), findsNothing);
    });
  });

  testWidgets('SettingsScreen changes text size and signs out', (t) async {
    tall(t);
    var out = false;
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await t.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: _wrap(SettingsScreen(onSignOut: () => out = true)),
    ));
    expect(c.read(textScaleProvider), 1.0);
    await t.tap(find.text('Grande'));
    await t.pumpAndSettle();
    expect(c.read(textScaleProvider), 1.3);
    await t.tap(find.text('Muito grande'));
    await t.pumpAndSettle();
    expect(c.read(textScaleProvider), 1.6);
    await t.tap(find.text('Enorme'));
    await t.pumpAndSettle();
    expect(c.read(textScaleProvider), 2.0);
    // Signing out asks first; "Ficar" changes nothing.
    await t.tap(find.text('Sair'));
    await t.pumpAndSettle();
    await t.tap(find.text('Ficar'));
    await t.pumpAndSettle();
    expect(out, isFalse);
    await t.tap(find.text('Sair'));
    await t.pumpAndSettle();
    await t.tap(find.text('Sim, sair'));
    await t.pumpAndSettle();
    expect(out, isTrue);
  });
}
