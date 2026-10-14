import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models.dart';
import '../domain/repositories.dart';
import 'auth_repository.dart';
import 'workspace_repository.dart';

Note _note(Map<String, dynamic> r) => Note(
      id: r['id'] as String,
      title: r['title'] as String,
      body: r['body'] as String,
      isPrivate: r['visibility'] == 'private',
      updatedAt: DateTime.parse(r['updated_at'] as String),
      deletedAt: r['deleted_at'] == null ? null : DateTime.parse(r['deleted_at'] as String),
    );

class SupabaseNoteRepository implements NoteRepository {
  SupabaseNoteRepository(this._db, this.workspaceId);
  final SupabaseClient _db;
  final String workspaceId;

  String get _me => _db.auth.currentUser!.id;

  @override
  Future<Note> create({required String title, required String body, bool isPrivate = true}) async {
    final r = await _db.from('notes').insert({
      'workspace_id': workspaceId,
      'owner_id': _me,
      'title': title,
      'body': body,
      'visibility': isPrivate ? 'private' : 'workspace',
    }).select().single();
    return _note(r);
  }

  @override
  Future<Note> update(String id, {String? title, String? body, bool? isPrivate}) async {
    final patch = <String, dynamic>{
      'updated_by': _me,
      'title': ?title,
      'body': ?body,
      if (isPrivate != null) 'visibility': isPrivate ? 'private' : 'workspace',
    };
    final r = await _db.from('notes').update(patch).eq('id', id).select().single();
    return _note(r);
  }

  @override
  Future<List<Note>> recent({int limit = 20}) async {
    final r = await _db
        .from('notes')
        .select()
        .eq('workspace_id', workspaceId)
        .isFilter('deleted_at', null)
        .order('updated_at', ascending: false)
        .limit(limit);
    return r.map<Note>(_note).toList();
  }

  @override
  Future<List<Note>> search(String query) async {
    final r = await _db
        .from('notes')
        .select()
        .eq('workspace_id', workspaceId)
        .isFilter('deleted_at', null)
        .textSearch('fts', query, config: 'portuguese')
        .limit(50);
    return r.map<Note>(_note).toList();
  }

  @override
  Future<void> softDelete(String id) => _db
      .from('notes')
      .update({'deleted_at': DateTime.now().toUtc().toIso8601String()}).eq('id', id);

  @override
  Future<void> restore(String id) => _db.from('notes').update({'deleted_at': null}).eq('id', id);

  /// Relies on the owner-only policy notes_read_own_trash (migration 0004).
  @override
  Future<List<Note>> trash() async {
    final r = await _db
        .from('notes')
        .select()
        .eq('workspace_id', workspaceId)
        .not('deleted_at', 'is', null)
        .eq('owner_id', _me);
    return r.map<Note>(_note).toList();
  }
}

class SupabaseListRepository implements ListRepository {
  SupabaseListRepository(this._db, this.workspaceId);
  final SupabaseClient _db;
  final String workspaceId;

  ShoppingList _list(Map<String, dynamic> r) =>
      ShoppingList(id: r['id'] as String, name: r['name'] as String);

  ShoppingItem _item(Map<String, dynamic> r) => ShoppingItem(
      id: r['id'] as String, text: r['text'] as String, checked: r['checked'] as bool);

  @override
  Future<List<ShoppingList>> lists() async {
    final r = await _db
        .from('shopping_lists')
        .select()
        .eq('workspace_id', workspaceId)
        .isFilter('deleted_at', null)
        .order('created_at');
    return r.map<ShoppingList>(_list).toList();
  }

  @override
  Future<ShoppingList> createList(String name) async {
    final r = await _db.from('shopping_lists').insert({
      'workspace_id': workspaceId,
      'name': name,
      'created_by': _db.auth.currentUser!.id,
    }).select().single();
    return _list(r);
  }

  @override
  Future<List<ShoppingItem>> items(String listId) async {
    final r = await _db
        .from('shopping_items')
        .select()
        .eq('list_id', listId)
        .order('sort_order')
        .order('created_at');
    return r.map<ShoppingItem>(_item).toList();
  }

  @override
  Future<ShoppingItem> addItem(String listId, String text) async {
    final r = await _db
        .from('shopping_items')
        .insert({'list_id': listId, 'text': text})
        .select()
        .single();
    return _item(r);
  }

  @override
  Future<void> setChecked(String itemId, bool checked) => _db.from('shopping_items').update({
        'checked': checked,
        'checked_by': checked ? _db.auth.currentUser!.id : null,
      }).eq('id', itemId);
}

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._db);
  final SupabaseClient _db;

  @override
  Stream<bool> get signedIn async* {
    yield _db.auth.currentSession != null;
    yield* _db.auth.onAuthStateChange.map((s) => s.session != null);
  }

  @override
  Future<void> sendCode(String email) =>
      _db.auth.signInWithOtp(email: email, shouldCreateUser: true);

  @override
  Future<void> verifyCode(String email, String code) =>
      _db.auth.verifyOTP(email: email, token: code, type: OtpType.email);

  @override
  Future<void> signOut() => _db.auth.signOut();
}

class SupabaseWorkspaceRepository implements WorkspaceRepository {
  SupabaseWorkspaceRepository(this._db);
  final SupabaseClient _db;

  @override
  String? get currentUserId => _db.auth.currentUser?.id;

  @override
  Future<String?> currentWorkspaceId() async {
    final r = await _db
        .from('memberships')
        .select('workspace_id')
        .eq('user_id', currentUserId!)
        .eq('status', 'active')
        .order('created_at')
        .limit(1)
        .maybeSingle();
    return r?['workspace_id'] as String?;
  }

  @override
  Future<String> createWorkspace(String name) async =>
      (await _db.rpc('create_workspace', params: {'p_name': name})) as String;

  @override
  Future<String> createInvitation(String workspaceId, String role) async =>
      (await _db.rpc('create_invitation', params: {'p_ws': workspaceId, 'p_role': role}))
          as String;

  @override
  Future<String> acceptInvitation(String token) async =>
      (await _db.rpc('accept_invitation', params: {'p_token': token.trim()})) as String;

  /// Profiles of other members are not readable under the current RLS
  /// (profiles_self), so only the caller's own display name is filled in; the
  /// UI falls back to a generic label for the rest.
  @override
  Future<List<Member>> members(String workspaceId) async {
    final rows = await _db
        .from('memberships')
        .select('user_id, role')
        .eq('workspace_id', workspaceId)
        .eq('status', 'active');
    final me = currentUserId!;
    final mine = await _db.from('profiles').select('display_name').eq('id', me).maybeSingle();
    final myName = (mine?['display_name'] as String?) ?? '';
    return rows
        .map<Member>((r) => Member(
              userId: r['user_id'] as String,
              displayName: r['user_id'] == me ? myName : '',
              role: Role.values.byName(r['role'] as String),
            ))
        .toList();
  }
}
