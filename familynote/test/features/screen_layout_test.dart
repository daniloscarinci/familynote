import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/screens.dart';

/// Pumps every main screen at the biggest text size on a small phone and
/// fails on any layout exception (overflow, unbounded constraints...).
void main() {
  final screens = mainScreens();
  for (final entry in screens.entries) {
    testWidgets('${entry.key}: no overflow at text scale 2.0 on 360x640', (t) async {
      phone(t, textScale: 2.0);
      await t.pumpWidget(await entry.value());
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      // Content must be reachable by scrolling, not cut off.
      expect(find.byType(Scrollable), findsWidgets);
    });

    testWidgets('${entry.key}: no overflow at text scale 1.0 on 360x640', (t) async {
      phone(t);
      await t.pumpWidget(await entry.value());
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('Preview: biggest text size also fits after scrolling to the buttons', (t) async {
    phone(t, textScale: 2.0);
    await t.pumpWidget(await screens['Preview']!());
    await t.pumpAndSettle();
    await t.ensureVisible(find.byKey(const Key('btn-save-all')));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    expect(t.getRect(find.byKey(const Key('btn-save-all'))).right, lessThanOrEqualTo(360));
  });

  testWidgets('Dark theme renders every main screen without errors', (t) async {
    phone(t);
    screenBrightness = Brightness.dark;
    addTearDown(() => screenBrightness = Brightness.light);
    for (final entry in screens.entries) {
      await t.pumpWidget(await entry.value());
      await t.pumpAndSettle();
      expect(t.takeException(), isNull, reason: entry.key);
    }
  });
}
