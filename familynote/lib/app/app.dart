import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../domain/models.dart';
import '../features/auth/sign_in_screen.dart';
import '../features/family/family_screen.dart';
import '../features/family/setup_screen.dart';
import '../features/home/home_screen.dart';
import '../features/lists/lists_screen.dart';
import '../features/notes/note_editor_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/shell/app_shell.dart';
import 'providers.dart';

class FamilyNoteApp extends ConsumerWidget {
  const FamilyNoteApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scale = ref.watch(textScaleProvider);
    return MaterialApp(
      title: 'Family Note',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(scale: scale),
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authRepositoryProvider);
    return StreamBuilder<bool>(
      stream: auth.signedIn,
      builder: (c, snap) {
        if (!snap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snap.data != true) return SignInScreen(auth: auth);
        return const _WorkspaceGate();
      },
    );
  }
}

class _WorkspaceGate extends ConsumerStatefulWidget {
  const _WorkspaceGate();

  @override
  ConsumerState<_WorkspaceGate> createState() => _WorkspaceGateState();
}

class _WorkspaceGateState extends ConsumerState<_WorkspaceGate> {
  late Future<String?> _future = ref.read(workspaceRepositoryProvider).currentWorkspaceId();
  String? _id;

  void _set(String id) => setState(() => _id = id);

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(workspaceRepositoryProvider);
    if (_id != null) return _MainTabs(key: ValueKey(_id), workspaceId: _id!, onJoined: _set);
    return FutureBuilder<String?>(
      future: _future,
      builder: (c, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snap.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('Não foi possível carregar. Confira a internet.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() => _future = repo.currentWorkspaceId()),
                    child: const Text('Tentar de novo'),
                  ),
                ]),
              ),
            ),
          );
        }
        final id = snap.data;
        if (id != null) return _MainTabs(key: ValueKey(id), workspaceId: id, onJoined: _set);
        return SetupScreen(repo: repo, onReady: _set);
      },
    );
  }
}

class _MainTabs extends ConsumerStatefulWidget {
  const _MainTabs({super.key, required this.workspaceId, required this.onJoined});
  final String workspaceId;
  final void Function(String) onJoined;

  @override
  ConsumerState<_MainTabs> createState() => _MainTabsState();
}

class _MainTabsState extends ConsumerState<_MainTabs> {
  late final notes = ref.read(noteRepositoryFactoryProvider)(widget.workspaceId);
  late final lists = ref.read(listRepositoryFactoryProvider)(widget.workspaceId);
  int _rev = 0;

  Future<void> _openEditor([Note? existing]) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => NoteEditorScreen(notes: notes, existing: existing),
    ));
    if (mounted) setState(() => _rev++);
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(tabs: [
      HomeScreen(
        key: ValueKey(_rev),
        notes: notes,
        onNewNote: _openEditor,
        onOpen: _openEditor,
      ),
      ListsScreen(repo: lists),
      FamilyScreen(
        repo: ref.read(workspaceRepositoryProvider),
        workspaceId: widget.workspaceId,
        onJoined: widget.onJoined,
      ),
      SettingsScreen(onSignOut: () => ref.read(authRepositoryProvider).signOut()),
    ]);
  }
}
