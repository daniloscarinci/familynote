import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/screens.dart';

/// Effective font size of a Text, after the theme's default style.
double _size(WidgetTester t, Element e) {
  final w = e.widget as Text;
  final style = DefaultTextStyle.of(e).style.merge(w.style);
  return style.fontSize ?? 14;
}

void main() {
  final screens = mainScreens();
  for (final entry in screens.entries) {
    testWidgets('${entry.key}: every Text is at least 18sp at scale 1.0', (t) async {
      phone(t);
      await t.pumpWidget(await entry.value());
      await t.pumpAndSettle();
      final small = <String>[];
      for (final e in find.byType(Text).evaluate()) {
        final s = _size(t, e);
        if (s < 18) small.add('"${(e.widget as Text).data}" is ${s}sp');
      }
      for (final e in find.byType(EditableText).evaluate()) {
        final s = (e.widget as EditableText).style.fontSize ?? 14;
        if (s < 18) small.add('a text field is ${s}sp');
      }
      expect(small, isEmpty);
    });

    testWidgets('${entry.key}: every button and row is at least 56dp tall', (t) async {
      phone(t);
      await t.pumpWidget(await entry.value());
      await t.pumpAndSettle();
      final targets = find.byWidgetPredicate((w) =>
          w is ButtonStyleButton ||
          w is CheckboxListTile ||
          w is RadioListTile ||
          w is ChoiceChip ||
          w is ListTile);
      final short = <String>[];
      for (final e in targets.evaluate()) {
        final h = t.getSize(find.byWidget(e.widget)).height;
        if (h < 56) short.add('${e.widget.runtimeType} is ${h}dp');
      }
      expect(short, isEmpty);
    });
  }

  testWidgets('Home: primary button is at least 96dp, others at least 72dp', (t) async {
    phone(t);
    await t.pumpWidget(await screens['Home']!());
    await t.pumpAndSettle();
    expect(t.getSize(find.byKey(const Key('btn-write-all'))).height, greaterThanOrEqualTo(96));
    expect(t.getSize(find.byKey(const Key('btn-shopping'))).height, greaterThanOrEqualTo(80));
    expect(t.getSize(find.byKey(const Key('btn-family-notes'))).height, greaterThanOrEqualTo(80));
    expect(t.getSize(find.byKey(const Key('btn-invite-home'))).height, greaterThanOrEqualTo(72));
    expect(t.getSize(find.byKey(const Key('btn-more'))).height, greaterThanOrEqualTo(64));
  });

  testWidgets('every non-Home sub-screen has a labelled Voltar and a 28sp title', (t) async {
    for (final name in ['Capture', 'Preview', 'Shopping list', 'Family', 'Settings']) {
      phone(t);
      await t.pumpWidget(await screens[name]!());
      await t.pumpAndSettle();
      expect(find.widgetWithText(TextButton, 'Voltar'), findsOneWidget, reason: name);
      final title = t.firstWidget<Semantics>(find.descendant(
          of: find.byType(SingleChildScrollView), matching: find.byWidgetPredicate(
              (w) => w is Semantics && w.properties.header == true)));
      final text = find.descendant(of: find.byWidget(title), matching: find.byType(Text));
      expect(_size(t, t.element(text)), greaterThanOrEqualTo(28), reason: name);
    }
  });

  testWidgets('theme: focus ring is 3dp, page changes do not move content', (t) async {
    phone(t);
    await t.pumpWidget(await screens['Home']!());
    final theme = Theme.of(t.element(find.byType(Scaffold).first));
    final style = theme.elevatedButtonTheme.style!;
    final side = style.side!.resolve({WidgetState.focused})!;
    expect(side.width, 3);
    for (final p in TargetPlatform.values) {
      final b = theme.pageTransitionsTheme.builders[p]!;
      expect(b.runtimeType.toString(), contains('NoMotion'));
    }
    expect(theme.elevatedButtonTheme.style!.minimumSize!.resolve({})!.height, 64);
  });
}
