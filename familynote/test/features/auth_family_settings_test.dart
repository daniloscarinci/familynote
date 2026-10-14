import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
      final auth = FakeAuthRepository();
      await t.pumpWidget(_wrap(SignInScreen(auth: auth)));
      expect(find.text('Entrar'), findsOneWidget); // app bar title only
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
      final auth = FakeAuthRepository();
      await t.pumpWidget(_wrap(SignInScreen(auth: auth)));
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

  group('FamilyScreen', () {
    FakeWorkspaceRepository repoWith(Role myRole) => FakeWorkspaceRepository(
          workspaceId: 'ws1',
          members: [
            Member(userId: 'me', displayName: '', role: myRole),
            const Member(userId: 'u2', displayName: 'Maria', role: Role.adult),
          ],
        );

    testWidgets('admin sees invite button and the code', (t) async {
      final repo = repoWith(Role.admin);
      await t.pumpWidget(_wrap(FamilyScreen(repo: repo, workspaceId: 'ws1')));
      await t.pumpAndSettle();
      expect(find.text('Maria'), findsOneWidget);
      expect(find.text('Você'), findsOneWidget);
      await t.tap(find.text('Convidar alguém da família'));
      await t.pumpAndSettle();
      expect(find.text('TOKEN0'), findsOneWidget);
      expect(find.text('Copiar código'), findsOneWidget);
    });

    testWidgets('non-admin has no invite button but can enter a code', (t) async {
      final repo = repoWith(Role.adult);
      await t.pumpWidget(_wrap(FamilyScreen(repo: repo, workspaceId: 'ws1')));
      await t.pumpAndSettle();
      expect(find.text('Convidar alguém da família'), findsNothing);
      expect(find.byKey(const Key('join-code')), findsOneWidget);
    });
  });

  testWidgets('SettingsScreen changes text size and signs out', (t) async {
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
    expect(c.read(textScaleProvider), 1.25);
    await t.tap(find.text('Muito grande'));
    await t.pumpAndSettle();
    expect(c.read(textScaleProvider), 1.5);
    await t.tap(find.text('Sair'));
    expect(out, isTrue);
  });
}
