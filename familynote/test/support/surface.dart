import 'package:flutter/widgets.dart' show Size;
import 'package:flutter_test/flutter_test.dart';

/// Tall test window so whole screens are on screen without scrolling
/// (the app itself scrolls; layout at phone size is covered separately).
void tall(WidgetTester t) {
  t.view.physicalSize = const Size(800, 2400);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}
