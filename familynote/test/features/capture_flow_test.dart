import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/surface.dart';
import 'package:familynote/core/theme.dart';
import 'package:familynote/data/fake_repos.dart';
import 'package:familynote/features/capture/capture_screen.dart';
import 'package:familynote/features/capture/save_organized.dart';

Future<void> open(WidgetTester t, FakeNoteRepository notes, FakeListRepository lists) async {
  await t.pumpWidget(MaterialApp(
    theme: buildTheme(),
    home: Builder(
      builder: (c) => Scaffold(
        body: TextButton(
          onPressed: () => Navigator.of(c).push(MaterialPageRoute<void>(
              builder: (_) => CaptureScreen(notes: notes, lists: lists))),
          child: const Text('HOME'),
        ),
      ),
    ),
  ));
  await t.tap(find.text('HOME'));
  await t.pumpAndSettle();
}

void main() {
  const input = 'Compras:\n- leite\n- 2 bananas\n- pão\nLigar para o médico amanhã';

  testWidgets('capture -> preview -> nothing saved until Guardar tudo -> saved', (t) async {
    tall(t);
    final notes = FakeNoteRepository();
    final lists = FakeListRepository();
    await open(t, notes, lists);

    final field = find.byKey(const Key('capture-field'));
    expect(t.widget<TextField>(field).autofocus, isTrue);
    expect(find.text('Escreva ou cole tudo: compras, lembretes, recados...'), findsOneWidget);
    expect(t.getSize(find.byKey(const Key('btn-organize'))).height, greaterThanOrEqualTo(72));

    await t.enterText(field, input);
    await t.tap(find.text('Organizar'));
    await t.pumpAndSettle();

    expect(find.text('Veja como organizei'), findsOneWidget);
    expect(find.text('Padaria'), findsOneWidget);
    expect(find.text('Hortifruti'), findsOneWidget);
    expect(find.text('Assunto: Saúde'), findsOneWidget);
    expect(await notes.recent(), isEmpty);
    expect(await lists.lists(), isEmpty);

    await t.tap(find.text('Guardar tudo'));
    await t.pumpAndSettle();
    expect(find.text('Pronto! 3 itens na lista de compras e 1 nota guardada.'), findsOneWidget);
    await t.tap(find.text('Ir para o início'));
    await t.pumpAndSettle();
    expect(find.text('HOME'), findsOneWidget);

    final list = (await lists.lists()).single;
    expect(list.name, 'Compras');
    expect((await lists.items(list.id)).map((i) => i.text), ['2 bananas', 'pão', 'leite']);
    final n = (await notes.recent()).single;
    expect(n.isPrivate, isTrue);
    expect(n.category, 'Saúde');
    expect(n.body, 'Ligar para o médico amanhã');
  });

  testWidgets('share switch makes the note shared', (t) async {
    tall(t);
    final notes = FakeNoteRepository();
    await open(t, notes, FakeListRepository());
    await t.enterText(find.byKey(const Key('capture-field')), 'Festa da vovó sábado');
    await t.tap(find.text('Organizar'));
    await t.pumpAndSettle();
    expect(t.widget<Switch>(find.descendant(of: find.byKey(const Key('share-switch')), matching: find.byType(Switch))).value, isFalse);
    await t.tap(find.text('Compartilhar com a família'));
    await t.pumpAndSettle();
    await t.tap(find.text('Guardar tudo'));
    await t.pumpAndSettle();
    expect((await notes.recent()).single.isPrivate, isFalse);
  });

  testWidgets('Voltar e editar keeps the text and saves nothing', (t) async {
    tall(t);
    final notes = FakeNoteRepository();
    await open(t, notes, FakeListRepository());
    await t.enterText(find.byKey(const Key('capture-field')), input);
    await t.tap(find.text('Organizar'));
    await t.pumpAndSettle();
    await t.tap(find.text('Voltar e editar'));
    await t.pumpAndSettle();
    expect(find.text(input), findsOneWidget);
    expect(await notes.recent(), isEmpty);
  });

  testWidgets('empty text asks to write something', (t) async {
    tall(t);
    await open(t, FakeNoteRepository(), FakeListRepository());
    await t.tap(find.text('Organizar'));
    await t.pumpAndSettle();
    expect(find.text('Escreva alguma coisa primeiro.'), findsOneWidget);
    expect(find.text('Veja como organizei'), findsNothing);
  });

  testWidgets('items already on the list are skipped', (t) async {
    tall(t);
    final lists = FakeListRepository();
    final l = await lists.createList('Compras');
    await lists.addItem(l.id, 'Leite');
    await open(t, FakeNoteRepository(), lists);
    await t.enterText(find.byKey(const Key('capture-field')), 'leite, pão');
    await t.tap(find.text('Organizar'));
    await t.pumpAndSettle();
    await t.tap(find.text('Guardar tudo'));
    await t.pumpAndSettle();
    expect(find.text('Pronto! 1 item na lista de compras.'), findsOneWidget);
    expect((await lists.items(l.id)).length, 2);
  });

  test('savedMessage wording', () {
    expect(savedMessage(items: 7, note: true),
        'Pronto! 7 itens na lista de compras e 1 nota guardada.');
    expect(savedMessage(items: 0, note: true), 'Pronto! 1 nota guardada.');
  });
}
