import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import 'providers.dart';
import 'gates.dart';

class FamilyNoteApp extends ConsumerWidget {
  const FamilyNoteApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scale = ref.watch(textScaleProvider);
    return MaterialApp(
      title: 'Family Note',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      darkTheme: buildTheme(brightness: Brightness.dark),
      // Chosen automatically when the system "high contrast" flag is on.
      highContrastTheme: buildTheme(highContrast: true),
      highContrastDarkTheme: buildTheme(brightness: Brightness.dark, highContrast: true),
      themeMode: ThemeMode.system,
      // The person's size choice applies to every Text, including those with
      // their own size. "Normal" keeps whatever the device already uses.
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: scale == 1.0 ? mq : mq.copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        );
      },
      // Invite links look like /#/join/<token>; the token is read at startup,
      // so every address simply opens the app.
      initialRoute: '/',
      onGenerateRoute: (_) => MaterialPageRoute<void>(builder: (_) => const AuthGate()),
    );
  }
}
