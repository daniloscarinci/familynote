import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/messages.dart';
import '../domain/models.dart';
import '../features/capture/capture_screen.dart';
import '../features/family/family_screen.dart';
import '../features/home/home_screen.dart';
import '../features/lists/default_list.dart';
import '../features/lists/lists_screen.dart';
import '../features/notes/note_editor_screen.dart';
import '../features/notes/notes_screen.dart';
import '../features/notes/shared_notes_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/shell/app_shell.dart';
import 'providers.dart';

/// Home with three big buttons; "Mais" opens the four-tab area.
class MainFlow extends ConsumerStatefulWidget {
  const MainFlow({super.key, required this.workspaceId});
  final String workspaceId;

  @override
  ConsumerState<MainFlow> createState() => _MainFlowState();
}

class _MainFlowState extends ConsumerState<MainFlow> {
  late final notes = ref.read(noteRepositoryFactoryProvider)(widget.workspaceId);
  late final lists = ref.read(listRepositoryFactoryProvider)(widget.workspaceId);
  int _rev = 0;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdmin();
  }

  /// The invite button shows only once we know the person is the admin.
  Future<void> _checkAdmin() async {
    try {
      final repo = ref.read(workspaceRepositoryProvider);
      final members = await repo.members(widget.workspaceId);
      final admin = members.any((m) => m.userId == repo.currentUserId && m.role == Role.admin);
      if (mounted) setState(() => _isAdmin = admin);
    } catch (_) {
      // Stay hidden; the Família screen under "Mais" explains and can retry.
    }
  }

  Widget _familyScreen() => FamilyScreen(
        repo: ref.read(workspaceRepositoryProvider),
        workspaceId: widget.workspaceId,
        appUrl: ref.read(appUrlProvider),
        openUrl: ref.read(urlOpenerProvider),
      );

  Future<void> _push(Widget page) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
    if (mounted) setState(() => _rev++);
  }

  Future<void> _openEditor([Note? existing]) =>
      _push(NoteEditorScreen(notes: notes, existing: existing));

  Future<void> _openShopping() async {
    try {
      final list = await defaultShoppingList(lists);
      if (mounted) await _push(ListDetailScreen(repo: lists, list: list));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(friendlyMessage(e,
              fallback: 'Não foi possível abrir a lista de compras. Tente de novo.'))));
    }
  }

  Future<void> _openMore() => _push(Builder(
        builder: (ctx) => AppShell(
          onBack: () => Navigator.of(ctx).pop(),
          tabs: [
            NotesScreen(
                notes: notes,
                onNewNote: () => _push(CaptureScreen(notes: notes, lists: lists)),
                onOpen: _openEditor),
            ListsScreen(repo: lists),
            _familyScreen(),
            SettingsScreen(onSignOut: () {
              Navigator.of(ctx).pop();
              ref.read(authRepositoryProvider).signOut();
            }),
          ],
        ),
      ));

  @override
  Widget build(BuildContext context) {
    return HomeScreen(
      key: ValueKey(_rev),
      notes: notes,
      onWriteAll: () => _push(CaptureScreen(notes: notes, lists: lists)),
      isAdmin: _isAdmin,
      onInvite: () => _push(_familyScreen()),
      onOpen: _openEditor,
      onShoppingList: _openShopping,
      onFamilyNotes: () => _push(SharedNotesScreen(notes: notes, onOpen: _openEditor)),
      onMore: _openMore,
    );
  }
}
