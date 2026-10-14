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
}
