import 'package:flutter/material.dart' show Color;
import 'package:flutter_test/flutter_test.dart';
import 'package:familynote/core/theme.dart';

void main() {
  test('WCAG ratio sanity', () {
    expect(contrastRatio(const Color(0xFF000000), const Color(0xFFFFFFFF)), closeTo(21, 0.01));
    expect(contrastRatio(const Color(0xFF777777), const Color(0xFF777777)), closeTo(1, 0.001));
  });

  for (final entry in AppPalette.all.entries) {
    group('palette ${entry.key}', () {
      for (final pair in entry.value.pairs) {
        test('${pair.name} >= ${pair.minRatio}:1', () {
          expect(pair.ratio, greaterThanOrEqualTo(pair.minRatio),
              reason: '${pair.name} is ${pair.ratio.toStringAsFixed(2)}:1');
        });
      }
    });
  }

  test('spec colours are used exactly in the light palette', () {
    const p = AppPalette.light;
    expect(p.background, const Color(0xFFFFFDF8));
    expect(p.text, const Color(0xFF1B1B1B));
    expect(p.primary, const Color(0xFF0B5563));
    expect(p.textSecondary, const Color(0xFF4A4A4A));
    expect(contrastRatio(p.text, p.background), greaterThanOrEqualTo(15));
    expect(contrastRatio(p.textSecondary, p.background), greaterThanOrEqualTo(8));
  });
}
