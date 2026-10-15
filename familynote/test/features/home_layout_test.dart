import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:familynote/core/theme.dart';
import 'package:familynote/data/fake_repos.dart';
import 'package:familynote/domain/repositories.dart';
import 'package:familynote/features/home/home_screen.dart';
import '../support/surface.dart';

Widget _home(
  NoteRepository notes, {
  List<String>? log,
  bool isAdmin = false,
  String? name,
  int hour = 10,
  int? count,
}) =>
    MaterialApp(
      theme: buildTheme(),
      home: HomeScreen(
        key: ValueKey('$name$hour$count'),
        notes: notes,
        userName: name,
        clock: () => DateTime(2026, 10, 15, hour),
        shoppingCount: count == null ? null : () async => count,
        onWriteAll: () => log?.add('note'),
        isAdmin: isAdmin,
        onInvite: () => log?.add('invite'),
        onShoppingList: () => log?.add('shopping'),
        onFamilyNotes: () => log?.add('family'),
        onMore: () => log?.add('more'),
        onOpen: (n) => log?.add('open ${n.title}'),
      ),
    );

void main() {
  group('Home layout', () {
    testWidgets('primary is 96dp; the two outline buttons are 80dp; text >= 22', (t) async {
      tall(t);
      await t.pumpWidget(_home(FakeNoteRepository()));
      await t.pumpAndSettle();
      final primary = find.widgetWithText(ElevatedButton, 'Escrever tudo aqui');
      expect(primary, findsOneWidget);
      expect(t.getSize(primary).height, greaterThanOrEqualTo(96));
      for (final label in ['Lista de compras', 'O que a família escreveu']) {
        final btn = find.widgetWithText(OutlinedButton, label);
        expect(btn, findsOneWidget, reason: label);
        expect(t.getSize(btn).height, greaterThanOrEqualTo(80), reason: label);
      }
      for (final label in ['Escrever tudo aqui', 'Lista de compras', 'O que a família escreveu']) {
        final btn = label == 'Escrever tudo aqui'
            ? primary
            : find.widgetWithText(OutlinedButton, label);
        expect(t.getSize(btn).width, greaterThan(300), reason: label);
        final el = t.element(find.descendant(of: btn, matching: find.text(label)));
        expect(DefaultTextStyle.of(el).style.fontSize, greaterThanOrEqualTo(22), reason: label);
      }
    });

    testWidgets('buttons are stacked, never side by side', (t) async {
      tall(t);
      await t.pumpWidget(_home(FakeNoteRepository(), isAdmin: true));
      await t.pumpAndSettle();
      final tops = [
        for (final k in [
          'btn-write-all',
          'btn-shopping',
          'btn-family-notes',
          'btn-invite-home',
          'btn-more'
        ])
          t.getTopLeft(find.byKey(Key(k))).dy
      ];
      expect(tops, [...tops]..sort());
      expect(tops.toSet().length, tops.length);
    });

    testWidgets('"Outras opções" is a text button of at least 64dp, "Mais" is gone', (t) async {
      tall(t);
      await t.pumpWidget(_home(FakeNoteRepository()));
      final more = find.widgetWithText(TextButton, 'Outras opções');
      expect(more, findsOneWidget);
      expect(t.getSize(more).height, greaterThanOrEqualTo(64));
      expect(find.text('Mais'), findsNothing);
    });

    testWidgets('has no bottom navigation', (t) async {
      tall(t);
      await t.pumpWidget(_home(FakeNoteRepository()));
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('each button triggers its callback', (t) async {
      tall(t);
      final log = <String>[];
      await t.pumpWidget(_home(FakeNoteRepository(), log: log));
      await t.tap(find.text('Escrever tudo aqui'));
      await t.tap(find.text('Lista de compras'));
      await t.tap(find.text('O que a família escreveu'));
      await t.tap(find.text('Outras opções'));
      expect(log, ['note', 'shopping', 'family', 'more']);
    });

    testWidgets('admin sees a full-width Convidar a família outline button of >= 72dp',
        (t) async {
      tall(t);
      final log = <String>[];
      await t.pumpWidget(_home(FakeNoteRepository(), log: log, isAdmin: true));
      await t.pumpAndSettle();
      final btn = find.widgetWithText(OutlinedButton, 'Convidar a família');
      expect(btn, findsOneWidget);
      expect(t.getSize(btn).height, greaterThanOrEqualTo(72));
      expect(t.getSize(btn).width, greaterThan(300));
      await t.tap(btn);
      expect(log, ['invite']);
    });

    testWidgets('non-admin does not see the invite button', (t) async {
      tall(t);
      await t.pumpWidget(_home(FakeNoteRepository()));
      await t.pumpAndSettle();
      expect(find.text('Convidar a família'), findsNothing);
    });

    testWidgets('greets by first name, "Olá" without a name', (t) async {
      tall(t);
      await t.pumpWidget(_home(FakeNoteRepository(), name: 'Maria da Silva', hour: 9));
      await t.pumpAndSettle();
      expect(find.text('Bom dia, Maria'), findsOneWidget);
      await t.pumpWidget(_home(FakeNoteRepository(), hour: 9));
      await t.pumpAndSettle();
      expect(find.text('Olá'), findsOneWidget);
    });

    testWidgets('shopping button says the count in words', (t) async {
      tall(t);
      for (final (n, words) in [(5, '5 itens'), (1, '1 item'), (0, 'Nenhum item')]) {
        await t.pumpWidget(_home(FakeNoteRepository(), count: n));
        await t.pumpAndSettle();
        expect(find.text(words), findsOneWidget, reason: words);
      }
    });

    testWidgets('recent notes show their category', (t) async {
      tall(t);
      final repo = FakeNoteRepository();
      await repo.create(title: 'Consulta', body: '', categoryName: 'Saúde');
      await t.pumpWidget(_home(repo));
      await t.pumpAndSettle();
      expect(find.textContaining('Saúde'), findsOneWidget);
    });

    testWidgets('lists at most 3 recent notes as 72dp buttons that open them', (t) async {
      tall(t);
      final repo = FakeNoteRepository();
      for (final n in ['Um', 'Dois', 'Tres', 'Quatro']) {
        await repo.create(title: n, body: '');
      }
      final log = <String>[];
      await t.pumpWidget(_home(repo, log: log));
      await t.pumpAndSettle();
      expect(find.text('Últimas anotações'), findsOneWidget);
      final rows = find.byWidgetPredicate((w) =>
          w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('note-'));
      expect(rows, findsNWidgets(3));
      for (final r in rows.evaluate()) {
        expect(t.getSize(find.byWidget(r.widget)).height, greaterThanOrEqualTo(72));
      }
      await t.tap(rows.first);
      expect(log.single, startsWith('open '));
    });

    testWidgets('empty state says what to do', (t) async {
      tall(t);
      await t.pumpWidget(_home(FakeNoteRepository()));
      await t.pumpAndSettle();
      expect(find.text("Ainda não há nada aqui. Toque em 'Escrever tudo aqui'."), findsOneWidget);
    });
  });
}
