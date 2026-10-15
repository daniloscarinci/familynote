import 'package:flutter/material.dart';

/// Smallest comfortable tap height in dp.
const double kMinTarget = 56;

/// Never show text smaller than this (sp, before the person's text-size choice).
const double kMinFontSize = 18;

const double kScreenPadding = 20;
const double kSectionSpacing = 24;
const double kButtonGap = 16;
const double kButtonRadius = 16;

/// WCAG 2.x contrast ratio between two opaque colours (1 to 21).
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

/// A pair of colours that are shown together, with the ratio they must reach.
class ContrastPair {
  const ContrastPair(this.name, this.foreground, this.background, this.minRatio);
  final String name;
  final Color foreground;
  final Color background;
  final double minRatio;
  double get ratio => contrastRatio(foreground, background);
}

/// Every colour the app uses. Four sets: light, dark and a maximum-contrast
/// variant of each (chosen when the system "high contrast" flag is on).
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.brightness,
    required this.background,
    required this.surface,
    required this.border,
    required this.text,
    required this.textSecondary,
    required this.primary,
    required this.onPrimary,
    required this.success,
    required this.warning,
    required this.error,
    required this.onError,
    required this.disabled,
  });

  final Brightness brightness;
  final Color background;
  final Color surface;
  final Color border;
  final Color text;
  final Color textSecondary;
  final Color primary;
  final Color onPrimary;
  final Color success;
  final Color warning;
  final Color error;
  final Color onError;
  final Color disabled;

  static const light = AppPalette(
    brightness: Brightness.light,
    background: Color(0xFFFFFDF8),
    surface: Color(0xFFFFFFFF),
    border: Color(0xFFC9C4B8),
    text: Color(0xFF1B1B1B),
    textSecondary: Color(0xFF4A4A4A),
    primary: Color(0xFF0B5563),
    onPrimary: Color(0xFFFFFFFF),
    success: Color(0xFF1B6B2F),
    warning: Color(0xFF8A5A00),
    error: Color(0xFFA4161A),
    onError: Color(0xFFFFFFFF),
    disabled: Color(0xFFE6E2D8),
  );

  static const dark = AppPalette(
    brightness: Brightness.dark,
    background: Color(0xFF121212),
    surface: Color(0xFF1E1E1E),
    border: Color(0xFF8A8A8A),
    text: Color(0xFFF2F2F2),
    textSecondary: Color(0xFFCFCFCF),
    primary: Color(0xFF7FD1DE),
    onPrimary: Color(0xFF00262C),
    success: Color(0xFF7FD99A),
    warning: Color(0xFFF2C14E),
    error: Color(0xFFFF9B9B),
    onError: Color(0xFF3A0000),
    disabled: Color(0xFF2E2E2E),
  );

  static const lightHighContrast = AppPalette(
    brightness: Brightness.light,
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    border: Color(0xFF000000),
    text: Color(0xFF000000),
    textSecondary: Color(0xFF1B1B1B),
    primary: Color(0xFF00363F),
    onPrimary: Color(0xFFFFFFFF),
    success: Color(0xFF0B4A1C),
    warning: Color(0xFF5C3C00),
    error: Color(0xFF8A0000),
    onError: Color(0xFFFFFFFF),
    disabled: Color(0xFFE0E0E0),
  );

  static const darkHighContrast = AppPalette(
    brightness: Brightness.dark,
    background: Color(0xFF000000),
    surface: Color(0xFF000000),
    border: Color(0xFFFFFFFF),
    text: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFF2F2F2),
    primary: Color(0xFF9FE6F2),
    onPrimary: Color(0xFF000000),
    success: Color(0xFF9BE8B0),
    warning: Color(0xFFFFD66B),
    error: Color(0xFFFFB3B3),
    onError: Color(0xFF000000),
    disabled: Color(0xFF2E2E2E),
  );

  static const all = {
    'light': light,
    'dark': dark,
    'light high contrast': lightHighContrast,
    'dark high contrast': darkHighContrast,
  };

  /// Body and primary pairs must reach 7:1, the others 4.5:1.
  List<ContrastPair> get pairs => [
        ContrastPair('text on background', text, background, 7),
        ContrastPair('text on surface', text, surface, 7),
        ContrastPair('secondary text on background', textSecondary, background, 7),
        ContrastPair('secondary text on surface', textSecondary, surface, 7),
        ContrastPair('on-primary on primary', onPrimary, primary, 7),
        ContrastPair('primary on background', primary, background, 7),
        ContrastPair('primary on surface', primary, surface, 7),
        ContrastPair('secondary text on disabled', textSecondary, disabled, 4.5),
        ContrastPair('success on background', success, background, 4.5),
        ContrastPair('success on surface', success, surface, 4.5),
        ContrastPair('warning on background', warning, background, 4.5),
        ContrastPair('warning on surface', warning, surface, 4.5),
        ContrastPair('error on background', error, background, 4.5),
        ContrastPair('error on surface', error, surface, 4.5),
        ContrastPair('on-error on error', onError, error, 4.5),
      ];

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) => this;
}

extension PaletteContext on BuildContext {
  /// The palette of the current theme (light when none is set).
  AppPalette get palette => Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}

/// Page changes that do not move anything: the new page simply appears.
class _NoMotionTransitions extends PageTransitionsBuilder {
  const _NoMotionTransitions();

  @override
  Widget buildTransitions<T>(PageRoute<T> route, BuildContext context,
          Animation<double> animation, Animation<double> secondaryAnimation, Widget child) =>
      child;
}

TextTheme _textTheme(double scale, AppPalette p) {
  TextStyle s(double size, {FontWeight weight = FontWeight.w500, Color? color}) => TextStyle(
        fontSize: size * scale,
        fontWeight: weight,
        height: 1.4,
        color: color ?? p.text,
      );
  return TextTheme(
    displayLarge: s(32, weight: FontWeight.w700),
    displayMedium: s(32, weight: FontWeight.w700),
    displaySmall: s(30, weight: FontWeight.w700),
    headlineLarge: s(28, weight: FontWeight.w700),
    headlineMedium: s(28, weight: FontWeight.w700),
    headlineSmall: s(28, weight: FontWeight.w700),
    titleLarge: s(28, weight: FontWeight.w700),
    titleMedium: s(22, weight: FontWeight.w700),
    titleSmall: s(20, weight: FontWeight.w700),
    bodyLarge: s(20),
    bodyMedium: s(20),
    bodySmall: s(18, color: p.textSecondary),
    labelLarge: s(22, weight: FontWeight.w700),
    labelMedium: s(18, weight: FontWeight.w600),
    labelSmall: s(18, weight: FontWeight.w600),
  );
}

/// The whole design system. [scale] multiplies the theme's own text sizes;
/// the app applies the person's text-size choice through MediaQuery instead,
/// so that every Text (even ones with their own size) follows it.
ThemeData buildTheme({
  double scale = 1.0,
  Brightness brightness = Brightness.light,
  bool highContrast = false,
}) {
  final p = switch ((brightness, highContrast)) {
    (Brightness.light, false) => AppPalette.light,
    (Brightness.dark, false) => AppPalette.dark,
    (Brightness.light, true) => AppPalette.lightHighContrast,
    (Brightness.dark, true) => AppPalette.darkHighContrast,
  };
  final text = _textTheme(scale, p);
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(kButtonRadius));
  final buttonText = TextStyle(fontSize: 22 * scale, fontWeight: FontWeight.w700, height: 1.3);
  const padding = EdgeInsets.symmetric(horizontal: 20, vertical: 12);

  // Visible keyboard / switch-access focus ring: 3dp.
  WidgetStateProperty<BorderSide?> side(Color rest, {double restWidth = 0, Color? ring}) =>
      WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.focused)) {
          return BorderSide(color: ring ?? p.text, width: 3);
        }
        return restWidth == 0 ? BorderSide.none : BorderSide(color: rest, width: restWidth);
      });

  final colorScheme = ColorScheme(
    brightness: brightness,
    primary: p.primary,
    onPrimary: p.onPrimary,
    secondary: p.primary,
    onSecondary: p.onPrimary,
    error: p.error,
    onError: p.onError,
    surface: p.surface,
    onSurface: p.text,
    onSurfaceVariant: p.textSecondary,
    outline: p.textSecondary,
    outlineVariant: p.border,
    surfaceContainerHighest: p.disabled,
    inverseSurface: p.text,
    onInverseSurface: p.background,
  );

  WidgetStateProperty<Color?> fill(Color enabled) => WidgetStateProperty.resolveWith(
      (s) => s.contains(WidgetState.disabled) ? p.disabled : enabled);
  WidgetStateProperty<Color?> ink(Color enabled) => WidgetStateProperty.resolveWith(
      (s) => s.contains(WidgetState.disabled) ? p.textSecondary : enabled);

  OutlineInputBorder inputBorder(Color c, double w) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: c, width: w));

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: p.background,
    canvasColor: p.background,
    extensions: [p],
    textTheme: text,
    primaryTextTheme: text,
    focusColor: p.text.withValues(alpha: 0.16),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: _NoMotionTransitions(),
      TargetPlatform.iOS: _NoMotionTransitions(),
      TargetPlatform.linux: _NoMotionTransitions(),
      TargetPlatform.macOS: _NoMotionTransitions(),
      TargetPlatform.windows: _NoMotionTransitions(),
      TargetPlatform.fuchsia: _NoMotionTransitions(),
    }),
    appBarTheme: AppBarTheme(
      backgroundColor: p.background,
      foregroundColor: p.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 72,
      titleTextStyle: text.titleLarge,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(88, 64)),
        padding: const WidgetStatePropertyAll(padding),
        shape: WidgetStatePropertyAll(shape),
        elevation: const WidgetStatePropertyAll(0),
        textStyle: WidgetStatePropertyAll(buttonText),
        backgroundColor: fill(p.primary),
        foregroundColor: ink(p.onPrimary),
        side: side(p.primary, ring: p.onPrimary),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(88, 64)),
        padding: const WidgetStatePropertyAll(padding),
        shape: WidgetStatePropertyAll(shape),
        textStyle: WidgetStatePropertyAll(buttonText),
        backgroundColor: fill(p.surface),
        foregroundColor: ink(p.primary),
        side: side(p.primary, restWidth: 2),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(64, 64)),
        padding: const WidgetStatePropertyAll(padding),
        shape: WidgetStatePropertyAll(shape),
        textStyle: WidgetStatePropertyAll(buttonText),
        foregroundColor: ink(p.primary),
        side: side(p.primary),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.surface,
      contentPadding: const EdgeInsets.all(16),
      border: inputBorder(p.textSecondary, 2),
      enabledBorder: inputBorder(p.textSecondary, 2),
      focusedBorder: inputBorder(p.primary, 3),
      errorBorder: inputBorder(p.error, 2),
      focusedErrorBorder: inputBorder(p.error, 3),
      disabledBorder: inputBorder(p.border, 2),
      hintStyle: text.bodyLarge!.copyWith(color: p.textSecondary),
      helperStyle: text.bodySmall,
      errorStyle: text.bodySmall!.copyWith(color: p.error),
      labelStyle: text.bodyLarge,
      floatingLabelBehavior: FloatingLabelBehavior.never,
    ),
    checkboxTheme: CheckboxThemeData(
      side: BorderSide(color: p.textSecondary, width: 2),
      fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.primary : p.surface),
      checkColor: WidgetStatePropertyAll(p.onPrimary),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStatePropertyAll(p.primary),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.onPrimary : p.textSecondary),
      trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.primary : p.surface),
      trackOutlineColor: WidgetStatePropertyAll(p.textSecondary),
      trackOutlineWidth: const WidgetStatePropertyAll(2),
    ),
    cardTheme: CardThemeData(
      color: p.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kButtonRadius),
        side: BorderSide(color: p.border, width: 2),
      ),
    ),
    dividerTheme: DividerThemeData(color: p.border, thickness: 2),
    listTileTheme: ListTileThemeData(
      minVerticalPadding: 12,
      minTileHeight: 72,
      titleTextStyle: text.bodyLarge,
      subtitleTextStyle: text.bodySmall,
      iconColor: p.primary,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: p.surface,
      selectedColor: p.primary,
      checkmarkColor: p.onPrimary,
      side: BorderSide(color: p.primary, width: 2),
      labelStyle: text.labelMedium!.copyWith(fontSize: 20 * scale),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.surface,
      titleTextStyle: text.titleLarge,
      contentTextStyle: text.bodyLarge,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kButtonRadius),
        side: BorderSide(color: p.border, width: 2),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: p.text,
      contentTextStyle: text.bodyLarge!.copyWith(color: p.background),
      actionTextColor: p.background,
    ),
  );
}
