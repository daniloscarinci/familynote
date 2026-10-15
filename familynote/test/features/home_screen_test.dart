import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/surface.dart';
import 'package:familynote/core/theme.dart';
import 'package:familynote/data/fake_repos.dart';
import 'package:familynote/features/lists/default_list.dart';
import 'package:familynote/features/notes/notes_screen.dart';
import 'package:familynote/features/notes/shared_notes_screen.dart';

Widget _wrap(Widget w) => MaterialApp(theme: buildTheme(), home: w);

void main() {
  group('NotesScreen (Procurar)', () {
    testWidgets('shows a large labelled New Note button', (t) async {
    tall(t);
      await t.pumpWidget(_wrap(NotesScreen(notes: FakeNoteRepository(), onNewNote: () {})));
      final btn = find.widgetWithText(ElevatedButton, 'Escrever tudo aqui');
      expect(btn, findsOneWidget);
      expect(t.getSize(btn).height, greaterThanOrEqualTo(56));
    });

    testWidgets('lists and searches notes', (t) async {
    tall(t);
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

  group('NotesScreen filters', () {
    testWidgets('chips only for categories that exist, filter works', (t) async {
    tall(t);
      final repo = FakeNoteRepository();
      await repo.create(title: 'Dentista', body: '', categoryName: 'Saúde');
      await repo.create(title: 'Luz', body: '', categoryName: 'Contas');
      await t.pumpWidget(_wrap(NotesScreen(notes: repo, onNewNote: () {})));
      await t.pumpAndSettle();
      expect(find.widgetWithText(ChoiceChip, 'Saúde'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Contas'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Viagem'), findsNothing);
      expect(t.getSize(find.widgetWithText(ChoiceChip, 'Saúde')).height, greaterThanOrEqualTo(48));
      await t.tap(find.widgetWithText(ChoiceChip, 'Saúde'));
      await t.pumpAndSettle();
      expect(find.text('Dentista'), findsOneWidget);
      expect(find.text('Luz'), findsNothing);
      await t.tap(find.widgetWithText(ChoiceChip, 'Todas'));
      await t.pumpAndSettle();
      expect(find.text('Luz'), findsOneWidget);
    });
  });

  group('SharedNotesScreen', () {
    testWidgets('shows only shared notes, newest first', (t) async {
    tall(t);
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
