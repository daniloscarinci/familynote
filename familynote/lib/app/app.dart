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
      theme: buildTheme(scale: scale),
      // Invite links look like /#/join/<token>; the token is read at startup,
      // so every address simply opens the app.
      initialRoute: '/',
      onGenerateRoute: (_) => MaterialPageRoute<void>(builder: (_) => const AuthGate()),
    );
  }
}
