import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/app.dart';
import 'app/providers.dart';
import 'core/join_link.dart';
import 'core/theme.dart';
import 'data/supabase_repos.dart';

const _url = String.fromEnvironment('SUPABASE_URL');
const _anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
const _appUrl = String.fromEnvironment('APP_URL');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (_url.isEmpty || _anonKey.isEmpty) {
    runApp(const MissingConfigApp());
    return;
  }
  await Supabase.initialize(url: _url, publishableKey: _anonKey);
  final db = Supabase.instance.client;

  var scale = 1.0;
  try {
    final prefs = await SharedPreferences.getInstance();
    scale = prefs.getDouble(textScaleKey) ?? 1.0;
  } catch (_) {}

  runApp(ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(SupabaseAuthRepository(db)),
      profileRepositoryProvider.overrideWithValue(SupabaseProfileRepository(db)),
      appUrlProvider.overrideWithValue(
          resolveAppUrl(define: _appUrl, base: kIsWeb ? Uri.base : Uri())),
      initialJoinTokenProvider
          .overrideWithValue(kIsWeb ? JoinLinkParser.fromUri(Uri.base) : null),
      workspaceRepositoryProvider.overrideWithValue(SupabaseWorkspaceRepository(db)),
      noteRepositoryFactoryProvider
          .overrideWithValue((ws) => SupabaseNoteRepository(db, ws)),
      listRepositoryFactoryProvider
          .overrideWithValue((ws) => SupabaseListRepository(db, ws)),
      initialTextScaleProvider.overrideWithValue(scale),
    ],
    child: const FamilyNoteApp(),
  ));
}

class MissingConfigApp extends StatelessWidget {
  const MissingConfigApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: buildTheme(),
      home: const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'O aplicativo ainda não está configurado.\n\n'
              'Faltam os dados de conexão (SUPABASE_URL e SUPABASE_ANON_KEY). '
              'Peça a quem instalou o aplicativo para configurá-los.',
              style: TextStyle(fontSize: 20),
            ),
          ),
        ),
      ),
    );
  }
}
