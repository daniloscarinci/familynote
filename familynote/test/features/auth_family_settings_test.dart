import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      await t.pumpWidget(screen(repoWith(Role.admin), []));
      await t.pumpAndSettle();
      expect(find.text('Maria'), findsOneWidget);
      expect(find.text('Você'), findsOneWidget);
      expect(find.text('Membro da família'), findsOneWidget);
    });

    testWidgets('admin invites: WhatsApp and copy buttons with the join link', (t) async {
      final opened = <Uri>[];
      await t.pumpWidget(screen(repoWith(Role.admin), opened));
      await t.pumpAndSettle();
      expect(find.text('Enviar pelo WhatsApp'), findsNothing);
      await t.tap(find.text('Convidar alguém'));
      await t.pumpAndSettle();
      expect(find.text('Enviar pelo WhatsApp'), findsOneWidget);
      expect(find.text('Copiar link'), findsOneWidget);
      expect(t.getSize(find.byKey(const Key('btn-whatsapp'))).height, greaterThanOrEqualTo(56));
      expect(t.getSize(find.byKey(const Key('btn-copy'))).height, greaterThanOrEqualTo(56));
      expect(t.widget<SelectableText>(find.byKey(const Key('invite-link'), skipOffstage: false)).data,
          'https://familia.exemplo.com/#/join/TOKEN0');

      await t.tap(find.text('Enviar pelo WhatsApp'));
      await t.pumpAndSettle();
      expect(opened.single.host, 'wa.me');
      expect(opened.single.queryParameters['text'], contains('https://familia.exemplo.com/#/join/TOKEN0'));
    });

    testWidgets('copy puts the link on the clipboard', (t) async {
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
      await t.tap(find.text('Convidar alguém'));
      await t.pumpAndSettle();
      await t.tap(find.text('Copiar link'));
      await t.pumpAndSettle();
      expect(copied, 'https://familia.exemplo.com/#/join/TOKEN0');
      expect(find.text('Link copiado'), findsOneWidget);
    });

    testWidgets('non-admin has no invite button', (t) async {
      await t.pumpWidget(screen(repoWith(Role.adult), []));
      await t.pumpAndSettle();
      expect(find.text('Convidar alguém'), findsNothing);
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
