import 'package:flutter_test/flutter_test.dart';
import 'package:familynote/core/theme.dart';

void main() {
  test('body text is at least 18sp', () {
    final t = buildTheme(scale: 1.0);
    expect(t.textTheme.bodyLarge!.fontSize, greaterThanOrEqualTo(18));
  });

  test('buttons have at least 56dp height', () {
    final t = buildTheme(scale: 1.0);
    final size = t.elevatedButtonTheme.style!.minimumSize!.resolve({});
    expect(size!.height, greaterThanOrEqualTo(56));
  });

  test('scale multiplies body size', () {
    final big = buildTheme(scale: 1.3).textTheme.bodyLarge!.fontSize!;
    final normal = buildTheme(scale: 1.0).textTheme.bodyLarge!.fontSize!;
    expect(big, closeTo(normal * 1.3, 0.01));
  });
}
