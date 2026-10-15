import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:familynote/app/app.dart';
import 'package:familynote/app/providers.dart';
import 'package:familynote/core/theme.dart';
import 'package:familynote/data/auth_repository.dart';

AppPalette _palette(WidgetTester t) =>
    Theme.of(t.element(find.byType(Scaffold).first)).extension<AppPalette>()!;

Widget _app({double scale = 1.0}) => ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        initialTextScaleProvider.overrideWithValue(scale),
      ],
      child: const FamilyNoteApp(),
    );

void main() {
  testWidgets('normal settings use the default light palette', (t) async {
    await t.pumpWidget(_app());
    await t.pumpAndSettle();
    expect(_palette(t).background, AppPalette.light.background);
  });

  testWidgets('system high contrast switches to the maximum-contrast palette', (t) async {
    t.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(highContrast: true);
    addTearDown(t.platformDispatcher.clearAllTestValues);
    await t.pumpWidget(_app());
    await t.pumpAndSettle();
    expect(_palette(t).text, AppPalette.lightHighContrast.text);
    expect(_palette(t).primary, AppPalette.lightHighContrast.primary);
  });

  testWidgets('dark system theme uses the dark palette', (t) async {
    t.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(t.platformDispatcher.clearAllTestValues);
    await t.pumpWidget(_app());
    await t.pumpAndSettle();
    expect(_palette(t).background, AppPalette.dark.background);
  });

  testWidgets('the chosen text size scales every Text in the app', (t) async {
    await t.pumpWidget(_app());
    await t.pumpAndSettle();
    final normal = t.getSize(find.text('Entrar').first).height;
    await t.pumpWidget(_app(scale: 2.0));
    await t.pumpAndSettle();
    expect(t.getSize(find.text('Entrar').first).height, greaterThan(normal * 1.8));
  });
}
