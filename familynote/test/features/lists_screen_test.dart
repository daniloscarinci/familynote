import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:familynote/core/theme.dart';
import 'package:familynote/data/fake_repos.dart';
import 'package:familynote/features/lists/lists_screen.dart';

void main() {
  testWidgets('add item and check it off', (t) async {
    final repo = FakeListRepository();
    final list = await repo.createList('Mercado');
    await t.pumpWidget(MaterialApp(
      theme: buildTheme(),
      home: ListDetailScreen(repo: repo, list: list),
    ));
    await t.enterText(find.byType(TextField), 'Leite');
    await t.tap(find.text('Adicionar'));
    await t.pumpAndSettle();
    expect(find.text('Leite'), findsOneWidget);

    await t.tap(find.byType(CheckboxListTile));
    await t.pumpAndSettle();
    final items = await repo.items(list.id);
    expect(items.single.checked, isTrue);
  });

  testWidgets('checked item is struck through and Adicionar is >= 56dp', (t) async {
    final repo = FakeListRepository();
    final list = await repo.createList('Mercado');
    await t.pumpWidget(MaterialApp(
      theme: buildTheme(),
      home: ListDetailScreen(repo: repo, list: list),
    ));
    await t.enterText(find.byType(TextField), 'Pao');
    await t.tap(find.text('Adicionar'));
    await t.pumpAndSettle();
    await t.tap(find.byType(CheckboxListTile));
    await t.pumpAndSettle();

    final text = t.widget<Text>(find.text('Pao'));
    expect(text.style?.decoration, TextDecoration.lineThrough);
    expect(t.getSize(find.byType(ElevatedButton)).height, greaterThanOrEqualTo(56));
  });

  testWidgets('items are grouped by aisle in fixed order, sorted, checked ones at the bottom',
      (t) async {
    final repo = FakeListRepository();
    t.view.physicalSize = const Size(800, 2000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final list = await repo.createList('Compras');
    for (final x in ['detergente', 'pão', 'maçã', 'banana', 'arroz']) {
      await repo.addItem(list.id, x);
    }
    await t.pumpWidget(MaterialApp(
      theme: buildTheme(),
      home: ListDetailScreen(repo: repo, list: list),
    ));
    await t.pumpAndSettle();
    double y(Finder f) => t.getTopLeft(f).dy;
    final order = [
      'Hortifruti', 'banana', 'maçã', 'Padaria', 'pão', 'Mercearia', 'arroz', 'Limpeza',
      'detergente',
    ];
    final ys = [for (final o in order) y(find.text(o))];
    expect(ys, [...ys]..sort());
    expect(find.text('Já comprei'), findsNothing);

    await t.tap(find.widgetWithText(CheckboxListTile, 'banana'));
    await t.pumpAndSettle();
    expect(y(find.text('Já comprei')), greaterThan(y(find.text('detergente'))));
    expect(y(find.text('banana')), greaterThan(y(find.text('Já comprei'))));
    expect(t.getSize(find.byType(CheckboxListTile).first).height, greaterThanOrEqualTo(56));
  });

  testWidgets('pasting a whole list adds items and skips duplicates', (t) async {
    final repo = FakeListRepository();
    final list = await repo.createList('Compras');
    await repo.addItem(list.id, 'Leite');
    await t.pumpWidget(MaterialApp(
      theme: buildTheme(),
      home: ListDetailScreen(repo: repo, list: list),
    ));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField), 'leite, pão\n- 2 bananas;\n1) sabão em pó');
    await t.tap(find.text('Adicionar'));
    await t.pumpAndSettle();
    final texts = (await repo.items(list.id)).map((i) => i.text).toList();
    expect(texts, ['Leite', '2 bananas', 'pão', 'sabão em pó']);
    expect(find.text('Limpeza'), findsOneWidget);
  });
}
