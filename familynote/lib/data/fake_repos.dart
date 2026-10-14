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
