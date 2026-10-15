import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:familynote/app/providers.dart';

void main() {
  test('choices are 1.0, 1.3, 1.6, 2.0', () {
    expect(textScaleValues, [1.0, 1.3, 1.6, 2.0]);
  });

  test('old stored values map to the nearest new choice', () {
    expect(snapTextScale(1.0), 1.0);
    expect(snapTextScale(1.25), 1.3);
    expect(snapTextScale(1.5), 1.6);
    expect(snapTextScale(3.0), 2.0);
    expect(snapTextScale(0.5), 1.0);
  });

  test('provider starts from a snapped stored value', () {
    final c = ProviderContainer(overrides: [initialTextScaleProvider.overrideWithValue(1.25)]);
    addTearDown(c.dispose);
    expect(c.read(textScaleProvider), 1.3);
  });
}
