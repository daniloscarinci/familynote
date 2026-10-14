import '../domain/models.dart';
import '../domain/repositories.dart';

class FakeNoteRepository implements NoteRepository {
  final Map<String, Note> _notes = {};
  int _n = 0;
  int _tick = 0;

  DateTime _now() => DateTime(2026, 1, 1).add(Duration(seconds: _tick++));

  @override
  Future<Note> create({required String title, required String body, bool isPrivate = true}) async {
    final note = Note(id: 'n${_n++}', title: title, body: body, isPrivate: isPrivate, updatedAt: _now());
    _notes[note.id] = note;
    return note;
  }

  @override
  Future<Note> update(String id, {String? title, String? body, bool? isPrivate}) async {
    final next = _notes[id]!.copyWith(title: title, body: body, isPrivate: isPrivate, updatedAt: _now());
    _notes[id] = next;
    return next;
  }

  @override
  Future<List<Note>> recent({int limit = 20}) async {
    final l = _notes.values.where((n) => n.deletedAt == null).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return l.take(limit).toList();
  }

  @override
  Future<List<Note>> search(String query) async {
    final q = query.toLowerCase();
    return _notes.values
        .where((n) => n.deletedAt == null &&
            (n.title.toLowerCase().contains(q) || n.body.toLowerCase().contains(q)))
        .toList();
  }

  @override
  Future<void> softDelete(String id) async =>
      _notes[id] = _notes[id]!.copyWith(deletedAt: _now());

  @override
  Future<void> restore(String id) async {
    final n = _notes[id]!;
    _notes[id] = Note(
        id: n.id, title: n.title, body: n.body, isPrivate: n.isPrivate, updatedAt: _now());
  }

  @override
  Future<List<Note>> trash() async => _notes.values.where((n) => n.deletedAt != null).toList();
}

class FakeListRepository implements ListRepository {
  final _lists = <ShoppingList>[];
  final _items = <String, List<ShoppingItem>>{};
  int _n = 0;

  @override
  Future<List<ShoppingList>> lists() async => List.of(_lists);

  @override
  Future<ShoppingList> createList(String name) async {
    final l = ShoppingList(id: 'l${_n++}', name: name);
    _lists.add(l);
    _items[l.id] = [];
    return l;
  }

  @override
  Future<List<ShoppingItem>> items(String listId) async => List.of(_items[listId] ?? []);

  @override
  Future<ShoppingItem> addItem(String listId, String text) async {
    final i = ShoppingItem(id: 'i${_n++}', text: text);
    _items[listId]!.add(i);
    return i;
  }

  @override
  Future<void> setChecked(String itemId, bool checked) async {
    for (final l in _items.values) {
      final idx = l.indexWhere((i) => i.id == itemId);
      if (idx >= 0) l[idx] = ShoppingItem(id: itemId, text: l[idx].text, checked: checked);
    }
  }
}
