import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:familynote/core/theme.dart';
import 'package:familynote/data/auth_repository.dart';
import 'package:familynote/data/fake_repos.dart';
import 'package:familynote/data/profile_repository.dart';
import 'package:familynote/data/workspace_repository.dart';
import 'package:familynote/domain/models.dart';
import 'package:familynote/domain/organizer.dart';
import 'package:familynote/features/auth/name_screen.dart';
import 'package:familynote/features/auth/sign_in_screen.dart';
import 'package:familynote/features/capture/capture_screen.dart';
import 'package:familynote/features/capture/preview_screen.dart';
import 'package:familynote/features/family/family_screen.dart';
import 'package:familynote/features/home/home_screen.dart';
import 'package:familynote/features/lists/lists_screen.dart';
import 'package:familynote/features/more/more_screen.dart';
import 'package:familynote/features/notes/note_editor_screen.dart';
import 'package:familynote/features/notes/notes_screen.dart';
import 'package:familynote/features/notes/shared_notes_screen.dart';
import 'package:familynote/features/settings/settings_screen.dart';

/// A phone-sized window (360x640) with the given text scale.
void phone(WidgetTester t, {double textScale = 1.0}) {
  t.view.physicalSize = const Size(360, 640);
  t.view.devicePixelRatio = 1;
  t.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(() {
    t.view.reset();
    t.platformDispatcher.clearAllTestValues();
  });
}

/// Set to Brightness.dark to build the screens with the dark theme.
Brightness screenBrightness = Brightness.light;

Widget _app(Widget home) => ProviderScope(
      child: MaterialApp(theme: buildTheme(brightness: screenBrightness), home: home),
    );

Future<FakeNoteRepository> _notes() async {
  final r = FakeNoteRepository();
  await r.create(
      title: 'Consulta com o dentista na próxima quinta-feira',
      body: 'Levar os exames e o cartão do convênio.',
      categoryName: 'Saúde',
      isPrivate: false);
  await r.create(title: 'Aniversário da vovó', body: 'Bolo e flores', isPrivate: false);
  await r.create(title: 'Conta de luz', body: 'Vence dia 10', categoryName: 'Contas');
  return r;
}

const longShopping = 'Compras:\n- leite integral\n- 2 bananas\n- pão francês\n- detergente\n'
    '- arroz\n- sabão em pó\n- maçã\nLigar para o médico amanhã de manhã e marcar retorno';

/// Every main screen, with realistic content, keyed by a readable name.
Map<String, Future<Widget> Function()> mainScreens() => {
      'Home': () async => _app(HomeScreen(
            notes: await _notes(),
            userName: 'Maria da Silva',
            isAdmin: true,
            onInvite: () {},
            shoppingCount: () async => 12,
            onWriteAll: () {},
            onShoppingList: () {},
            onFamilyNotes: () {},
            onMore: () {},
          )),
      'Capture': () async =>
          _app(CaptureScreen(notes: FakeNoteRepository(), lists: FakeListRepository())),
      'Preview': () async => _app(PreviewScreen(
            result: organize(longShopping),
            notes: FakeNoteRepository(),
            lists: FakeListRepository(),
          )),
      'Shopping list': () async {
        final repo = FakeListRepository();
        final list = await repo.createList('Compras');
        for (final x in ['leite integral', '2 bananas', 'pão francês', 'detergente', 'arroz']) {
          await repo.addItem(list.id, x);
        }
        return _app(ListDetailScreen(repo: repo, list: list));
      },
      'Family': () async => _app(FamilyScreen(
            repo: FakeWorkspaceRepository(workspaceId: 'ws1', members: [
              const Member(userId: 'me', displayName: 'Ana Maria', role: Role.admin),
              const Member(userId: 'u2', displayName: 'Maria Aparecida', role: Role.adult),
            ]),
            workspaceId: 'ws1',
            appUrl: 'https://familia.exemplo.com',
            openUrl: (_) async => true,
          )),
      'Settings': () async => _app(SettingsScreen(onSignOut: () {})),
      'Sign-in': () async => _app(SignInScreen(auth: FakeAuthRepository())),
      'Name': () async => _app(NameScreen(profiles: FakeProfileRepository(), onDone: () {})),
      'Note editor': () async => _app(NoteEditorScreen(notes: FakeNoteRepository())),
      'Outras opções': () async => _app(MoreScreen(
            onSearch: () {},
            onFamily: () {},
            onTextSize: () {},
            onSignOut: () {},
          )),
      'Procurar': () async => _app(NotesScreen(notes: await _notes(), onNewNote: () {})),
      'Família escreveu': () async => _app(SharedNotesScreen(notes: await _notes())),
    };
