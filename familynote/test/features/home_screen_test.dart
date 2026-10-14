import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:familynote/core/theme.dart';
import 'package:familynote/data/fake_repos.dart';
import 'package:familynote/domain/repositories.dart';
import 'package:familynote/features/home/home_screen.dart';
import 'package:familynote/features/lists/default_list.dart';
import 'package:familynote/features/notes/notes_screen.dart';
import 'package:familynote/features/notes/shared_notes_screen.dart';

Widget _wrap(Widget w) => MaterialApp(theme: buildTheme(), home: w);

Widget _home(NoteRepository notes, {List<String>? log}) => _wrap(HomeScreen(
      notes: notes,
      onNewNote: () => log?.add('note'),
      onShoppingList: () => log?.add('shopping'),
      onFamilyNotes: () => log?.add('family'),
      onMore: () => log?.add('more'),
    ));

void main() {
  group('HomeScreen', () {
    testWidgets('three giant labelled buttons, each >= 88dp, text >= 22', (t) async {
      await t.pumpWidget(_home(FakeNoteRepository()));
      await t.pumpAndSettle();
      for (final label in ['Escrever uma nota', 'Lista de compras', 'O que a família escreveu']) {
        final btn = find.widgetWithText(ElevatedButton, label);
        expect(btn, findsOneWidget, reason: label);
        final size = t.getSize(btn);
        expect(size.height, greaterThanOrEqualTo(88), reason: label);
        expect(size.width, greaterThan(300), reason: label);
        final text = t.widget<Text>(find.descendant(of: btn, matching: find.text(label)));
        final fontSize = text.style?.fontSize ??
            DefaultTextStyle.of(t.element(find.descendant(of: btn, matching: find.text(label)))).style.fontSize;
        expect(fontSize, greaterThanOrEqualTo(22), reason: label);
      }
    });

    testWidgets('"Mais" is a text button of at least 56dp', (t) async {
      await t.pumpWidget(_home(FakeNoteRepository()));
      final more = find.widgetWithText(OutlinedButton, 'Mais');
      expect(more, findsOneWidget);
      expect(t.getSize(more).height, greaterThanOrEqualTo(56));
    });

    testWidgets('has no bottom navigation', (t) async {
      await t.pumpWidget(_home(FakeNoteRepository()));
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('each button triggers its callback', (t) async {
      final log = <String>[];
      await t.pumpWidget(_home(FakeNoteRepository(), log: log));
      await t.tap(find.text('Escrever uma nota'));
      await t.tap(find.text('Lista de compras'));
      await t.tap(find.text('O que a família escreveu'));
      await t.tap(find.text('Mais'));
      expect(log, ['note', 'shopping', 'family', 'more']);
    });

    testWidgets('lists recent notes below the buttons', (t) async {
      final repo = FakeNoteRepository();
      await repo.create(title: 'Consulta dentista', body: '');
      await t.pumpWidget(_home(repo));
      await t.pumpAndSettle();
      expect(find.text('Notas recentes'), findsOneWidget);
      expect(find.text('Consulta dentista'), findsOneWidget);
    });
  });

  group('NotesScreen (inside Mais)', () {
    testWidgets('shows a large labelled New Note button', (t) async {
      await t.pumpWidget(_wrap(NotesScreen(notes: FakeNoteRepository(), onNewNote: () {})));
      final btn = find.widgetWithText(ElevatedButton, 'Nova nota');
      expect(btn, findsOneWidget);
      expect(t.getSize(btn).height, greaterThanOrEqualTo(56));
    });

    testWidgets('lists and searches notes', (t) async {
      final repo = FakeNoteRepository();
      await repo.create(title: 'Consulta dentista', body: '');
      await repo.create(title: 'Mercado', body: 'leite');
      await t.pumpWidget(_wrap(NotesScreen(notes: repo, onNewNote: () {})));
      await t.pumpAndSettle();
      expect(find.text('Consulta dentista'), findsOneWidget);
      await t.enterText(find.byType(TextField), 'leite');
      await t.pumpAndSettle();
      expect(find.text('Consulta dentista'), findsNothing);
      expect(find.text('Mercado'), findsOneWidget);
    });
  });

  group('SharedNotesScreen', () {
    testWidgets('shows only shared notes, newest first', (t) async {
      final repo = FakeNoteRepository();
      await repo.create(title: 'Antiga', body: '', isPrivate: false);
      await repo.create(title: 'Segredo', body: '', isPrivate: true);
      await repo.create(title: 'Nova', body: '', isPrivate: false);
      await t.pumpWidget(_wrap(SharedNotesScreen(notes: repo)));
      await t.pumpAndSettle();
      expect(find.text('Segredo'), findsNothing);
      final nova = t.getTopLeft(find.text('Nova')).dy;
      final antiga = t.getTopLeft(find.text('Antiga')).dy;
      expect(nova, lessThan(antiga));
    });
  });

  group('defaultShoppingList', () {
    test('creates "Compras" when there is none', () async {
      final repo = FakeListRepository();
      final l = await defaultShoppingList(repo);
      expect(l.name, 'Compras');
      expect((await repo.lists()).length, 1);
    });

    test('reuses the existing list instead of creating another', () async {
      final repo = FakeListRepository();
      await repo.createList('Mercado');
      final compras = await repo.createList('Compras');
      expect((await defaultShoppingList(repo)).id, compras.id);
      expect((await repo.lists()).length, 2);
    });

    test('falls back to the first list', () async {
      final repo = FakeListRepository();
      final first = await repo.createList('Mercado');
      expect((await defaultShoppingList(repo)).id, first.id);
    });
  });
}
