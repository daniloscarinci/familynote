import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:familynote/core/theme.dart';
import 'package:familynote/data/fake_repos.dart';
import 'package:familynote/features/home/home_screen.dart';

Widget _wrap(Widget w) => MaterialApp(theme: buildTheme(), home: w);

void main() {
  testWidgets('shows a large labelled New Note button', (t) async {
    await t.pumpWidget(_wrap(HomeScreen(notes: FakeNoteRepository(), onNewNote: () {})));
    final btn = find.widgetWithText(ElevatedButton, 'Nova nota');
    expect(btn, findsOneWidget);
    expect(t.getSize(btn).height, greaterThanOrEqualTo(56));
  });

  testWidgets('tapping New Note triggers callback (one action)', (t) async {
    var tapped = false;
    await t.pumpWidget(_wrap(HomeScreen(notes: FakeNoteRepository(), onNewNote: () => tapped = true)));
    await t.tap(find.text('Nova nota'));
    expect(tapped, isTrue);
  });

  testWidgets('lists recent notes', (t) async {
    final repo = FakeNoteRepository();
    await repo.create(title: 'Consulta dentista', body: '');
    await t.pumpWidget(_wrap(HomeScreen(notes: repo, onNewNote: () {})));
    await t.pumpAndSettle();
    expect(find.text('Consulta dentista'), findsOneWidget);
  });
}
