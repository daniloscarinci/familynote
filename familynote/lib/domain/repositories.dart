import 'models.dart';

abstract class NoteRepository {
  Future<Note> create({required String title, required String body, bool isPrivate = true});
  Future<Note> update(String id, {String? title, String? body, bool? isPrivate});
  Future<List<Note>> recent({int limit = 20});
  Future<List<Note>> search(String query);
  Future<void> softDelete(String id);
  Future<void> restore(String id);
  Future<List<Note>> trash();
}

abstract class ListRepository {
  Future<List<ShoppingList>> lists();
  Future<ShoppingList> createList(String name);
  Future<List<ShoppingItem>> items(String listId);
  Future<ShoppingItem> addItem(String listId, String text);
  Future<void> setChecked(String itemId, bool checked);
}
