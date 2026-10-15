import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:familynote/app/app.dart';
import 'package:familynote/app/providers.dart';
import 'package:familynote/core/messages.dart';
import 'package:familynote/data/auth_repository.dart';
import 'package:familynote/data/fake_repos.dart';
import 'package:familynote/data/profile_repository.dart';
import 'package:familynote/data/workspace_repository.dart';
import 'package:familynote/domain/models.dart';
import 'package:familynote/main.dart' show MissingConfigApp;

Widget _app(
  FakeAuthRepository auth,
  FakeWorkspaceRepository ws, {
  FakeProfileRepository? profiles,
  FakeListRepository? lists,
  String? joinToken,
}) {
  final notes = FakeNoteRepository();
  final l = lists ?? FakeListRepository();
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(auth),
      workspaceRepositoryProvider.overrideWithValue(ws),
      profileRepositoryProvider.overrideWithValue(profiles ?? FakeProfileRepository(name: 'Ana')),
      noteRepositoryFactoryProvider.overrideWithValue((_) => notes),
      listRepositoryFactoryProvider.overrideWithValue((_) => l),
      initialJoinTokenProvider.overrideWithValue(joinToken),
      appUrlProvider.overrideWithValue('https://familia.exemplo.com'),
    ],
    child: const FamilyNoteApp(),
  );
}

void main() {
  testWidgets('signed out shows the sign-in screen', (t) async {
    await t.pumpWidget(_app(FakeAuthRepository(), FakeWorkspaceRepository()));
    await t.pumpAndSettle();
    expect(find.text('Criar minha conta'), findsOneWidget);
    expect(find.text('Prefiro receber um código por e-mail'), findsOneWidget);
  });

  testWidgets('sign in, then Home with three big buttons and no bottom bar', (t) async {
    final ws = FakeWorkspaceRepository(
      workspaceId: 'ws1',
      members: [const Member(userId: 'me', displayName: '', role: Role.admin)],
    );
    await t.pumpWidget(_app(FakeAuthRepository(), ws));
    await t.pumpAndSettle();

    await t.tap(find.text('Prefiro receber um código por e-mail'));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField).first, 'a@b.com');
    await t.tap(find.text('Enviar código'));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField).last, FakeAuthRepository.validCode);
    await t.tap(find.widgetWithText(ElevatedButton, 'Entrar'));
    await t.pumpAndSettle();

    expect(find.text('Escrever tudo aqui'), findsOneWidget);
    expect(find.text('Lista de compras'), findsOneWidget);
    expect(find.text('O que a família escreveu'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  group('invite on Home', () {
    testWidgets('admin sees the button and it opens Familia with the invite ready', (t) async {
      final ws = FakeWorkspaceRepository(
        workspaceId: 'ws1',
        members: [const Member(userId: 'me', displayName: '', role: Role.admin)],
      );
      await t.pumpWidget(_app(FakeAuthRepository(signedIn: true), ws));
      await t.pumpAndSettle();
      await t.tap(find.text('Convidar a família'));
      await t.pumpAndSettle();
      expect(find.text('Enviar pelo WhatsApp'), findsOneWidget);
      expect(find.text('Copiar link'), findsOneWidget);
    });

    testWidgets('non-admin does not see it', (t) async {
      final ws = FakeWorkspaceRepository(
        workspaceId: 'ws1',
        members: [const Member(userId: 'me', displayName: '', role: Role.adult)],
      );
      await t.pumpWidget(_app(FakeAuthRepository(signedIn: true), ws));
      await t.pumpAndSettle();
      expect(find.text('Escrever tudo aqui'), findsOneWidget);
      expect(find.text('Convidar a família'), findsNothing);
    });
  });

  group('automatic family', () {
    testWidgets('signed in without a family creates one silently', (t) async {
      final ws = FakeWorkspaceRepository();
      await t.pumpWidget(_app(FakeAuthRepository(signedIn: true), ws));
      await t.pumpAndSettle();
      expect(ws.createdNames, ['Minha família']);
      expect(find.text('Escrever tudo aqui'), findsOneWidget);
      expect(find.text('Criar a sua família'), findsNothing);
    });

    testWidgets('failure shows a plain retry screen, retry succeeds', (t) async {
      final ws = FakeWorkspaceRepository()..createError = Exception('SocketException: Failed host lookup');
      await t.pumpWidget(_app(FakeAuthRepository(signedIn: true), ws));
      await t.pumpAndSettle();
      expect(find.text(offlineMessage), findsOneWidget);
      expect(find.text('Tentar de novo'), findsOneWidget);

      ws.createError = null;
      await t.tap(find.text('Tentar de novo'));
      await t.pumpAndSettle();
      expect(find.text('Escrever tudo aqui'), findsOneWidget);
    });
  });

  group('join by link', () {
    testWidgets('signed out with a token: anonymous sign-in, accept, name, Home', (t) async {
      final auth = FakeAuthRepository();
      final ws = FakeWorkspaceRepository(userId: 'me')..invitations.add('TOK');
      final profiles = FakeProfileRepository();
      await t.pumpWidget(_app(auth, ws, profiles: profiles, joinToken: 'TOK'));
      await t.pumpAndSettle();

      expect(auth.anonymousSignIns, 1);
      expect(ws.createdNames, isEmpty, reason: 'must join, not create a family');
      expect(ws.workspaceId, 'ws1');
      expect(find.text('Qual é o seu nome?'), findsOneWidget);
      expect(find.text('Criar minha conta'), findsNothing);

      await t.enterText(find.byKey(const Key('display-name')), 'Vovó Rosa');
      await t.tap(find.text('Continuar'));
      await t.pumpAndSettle();
      expect(profiles.name, 'Vovó Rosa');
      expect(find.text('Escrever tudo aqui'), findsOneWidget);
    });

    testWidgets('already signed in with a token just accepts it', (t) async {
      final auth = FakeAuthRepository(signedIn: true);
      final ws = FakeWorkspaceRepository()..invitations.add('TOK');
      await t.pumpWidget(_app(auth, ws, joinToken: 'TOK'));
      await t.pumpAndSettle();
      expect(auth.anonymousSignIns, 0);
      expect(ws.workspaceId, 'ws1');
      expect(ws.createdNames, isEmpty);
      expect(find.text('Escrever tudo aqui'), findsOneWidget);
    });

    testWidgets('bad link shows a friendly message and a way to continue', (t) async {
      final auth = FakeAuthRepository(signedIn: true);
      final ws = FakeWorkspaceRepository();
      await t.pumpWidget(_app(auth, ws, joinToken: 'WRONG'));
      await t.pumpAndSettle();
      expect(find.textContaining('convite não vale mais'), findsOneWidget);
      await t.tap(find.text('Continuar sem o convite'));
      await t.pumpAndSettle();
      expect(ws.createdNames, ['Minha família']);
      expect(find.text('Escrever tudo aqui'), findsOneWidget);
    });

    testWidgets('anonymous sign-in failure is explained in plain words', (t) async {
      final auth = FakeAuthRepository()..anonymousError = Exception('Anonymous sign-ins are disabled');
      await t.pumpWidget(_app(auth, FakeWorkspaceRepository(), joinToken: 'TOK'));
      await t.pumpAndSettle();
      expect(find.textContaining('Peça ajuda'), findsOneWidget);
      expect(find.text('Anonymous sign-ins are disabled'), findsNothing);
    });
  });

  group('name screen', () {
    testWidgets('organizer without a name is asked once, then sees Home', (t) async {
      final ws = FakeWorkspaceRepository(workspaceId: 'ws1');
      await t.pumpWidget(
          _app(FakeAuthRepository(signedIn: true), ws, profiles: FakeProfileRepository()));
      await t.pumpAndSettle();
      expect(find.text('Qual é o seu nome?'), findsOneWidget);
      expect(find.text('Continuar'), findsOneWidget);
      // empty name is refused with a plain sentence
      await t.tap(find.text('Continuar'));
      await t.pumpAndSettle();
      expect(find.text('Escreva o seu nome para continuar.'), findsOneWidget);
    });
  });

  group('Mais', () {
    testWidgets('opens the four-tab area and goes back', (t) async {
      final ws = FakeWorkspaceRepository(
        workspaceId: 'ws1',
        members: [const Member(userId: 'me', displayName: 'Ana', role: Role.admin)],
      );
      await t.pumpWidget(_app(FakeAuthRepository(signedIn: true), ws));
      await t.pumpAndSettle();
      await t.tap(find.text('Mais'));
      await t.pumpAndSettle();
      for (final label in ['Notas', 'Listas', 'Família', 'Ajustes']) {
        expect(find.text(label), findsWidgets);
      }
      await t.tap(find.text('Voltar ao início'));
      await t.pumpAndSettle();
      expect(find.text('Escrever tudo aqui'), findsOneWidget);
    });

    testWidgets('Lista de compras creates "Compras" and opens it', (t) async {
      final ws = FakeWorkspaceRepository(workspaceId: 'ws1');
      final lists = FakeListRepository();
      await t.pumpWidget(_app(FakeAuthRepository(signedIn: true), ws, lists: lists));
      await t.pumpAndSettle();
      await t.tap(find.text('Lista de compras'));
      await t.pumpAndSettle();
      expect((await lists.lists()).single.name, 'Compras');
      expect(find.text('Novo item'), findsOneWidget);
    });
  });

  testWidgets('missing config shows a Portuguese message', (t) async {
    await t.pumpWidget(const MissingConfigApp());
    expect(find.textContaining('não está configurado'), findsOneWidget);
  });
}
