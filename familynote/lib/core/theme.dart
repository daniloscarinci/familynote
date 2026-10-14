import 'package:flutter/material.dart';

const double kMinTarget = 56;

ThemeData buildTheme({double scale = 1.0, Brightness brightness = Brightness.light}) {
  final base = ThemeData(
    brightness: brightness,
    colorSchemeSeed: const Color(0xFF1B5E7A),
    useMaterial3: true,
  );
  double s(double v) => v * scale;
  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      bodyLarge: TextStyle(fontSize: s(18)),
      bodyMedium: TextStyle(fontSize: s(18)),
      titleLarge: TextStyle(fontSize: s(24), fontWeight: FontWeight.w600),
      labelLarge: TextStyle(fontSize: s(18), fontWeight: FontWeight.w600),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(kMinTarget, kMinTarget),
        textStyle: TextStyle(fontSize: s(18), fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
  );
}
