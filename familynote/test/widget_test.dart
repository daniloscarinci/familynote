import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:familynote/app/app.dart';
import 'package:familynote/app/providers.dart';
import 'package:familynote/data/auth_repository.dart';
import 'package:familynote/data/fake_repos.dart';
import 'package:familynote/data/workspace_repository.dart';
import 'package:familynote/domain/models.dart';
import 'package:familynote/main.dart' show MissingConfigApp;

Widget _app(FakeAuthRepository auth, FakeWorkspaceRepository ws) {
  final notes = FakeNoteRepository();
  final lists = FakeListRepository();
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(auth),
      workspaceRepositoryProvider.overrideWithValue(ws),
      noteRepositoryFactoryProvider.overrideWithValue((_) => notes),
      listRepositoryFactoryProvider.overrideWithValue((_) => lists),
    ],
    child: const FamilyNoteApp(),
  );
}

void main() {
  testWidgets('signed out shows the sign-in screen', (t) async {
    await t.pumpWidget(_app(FakeAuthRepository(), FakeWorkspaceRepository()));
    await t.pumpAndSettle();
    expect(find.text('Enviar código'), findsOneWidget);
  });

  testWidgets('sign in, then shows the four tabs', (t) async {
    final ws = FakeWorkspaceRepository(
      workspaceId: 'ws1',
      members: [const Member(userId: 'me', displayName: '', role: Role.admin)],
    );
    await t.pumpWidget(_app(FakeAuthRepository(), ws));
    await t.pumpAndSettle();

    await t.enterText(find.byType(TextField).first, 'a@b.com');
    await t.tap(find.text('Enviar código'));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField).last, FakeAuthRepository.validCode);
    await t.tap(find.widgetWithText(ElevatedButton, 'Entrar'));
    await t.pumpAndSettle();

    for (final label in ['Início', 'Listas', 'Família', 'Ajustes']) {
      expect(find.text(label), findsWidgets);
    }
    expect(find.text('Nova nota'), findsOneWidget);
  });

  testWidgets('signed in without a family shows the setup screen', (t) async {
    await t.pumpWidget(_app(FakeAuthRepository(signedIn: true), FakeWorkspaceRepository()));
    await t.pumpAndSettle();
    expect(find.text('Criar a sua família'), findsOneWidget);

    await t.enterText(find.byKey(const Key('family-name')), 'Silva');
    await t.tap(find.text('Criar'));
    await t.pumpAndSettle();
    expect(find.text('Nova nota'), findsOneWidget);
  });
}

  testWidgets('missing config shows a Portuguese message', (t) async {
    await t.pumpWidget(const MissingConfigApp());
    expect(find.textContaining('não está configurado'), findsOneWidget);
  });
}
