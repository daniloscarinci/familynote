import '../../domain/models.dart';
import '../../domain/organizer.dart';
import '../../domain/repositories.dart';
import '../lists/default_list.dart';

/// Adds the entries to the family's "Compras" list, skipping items that are
/// already there. Returns how many were added.
Future<int> saveShopping(ListRepository lists, List<ShoppingEntry> entries) async {
  if (entries.isEmpty) return 0;
  final list = await defaultShoppingList(lists);
  final existing = (await lists.items(list.id)).map((i) => i.text).toList();
  final fresh = organize(entries.map((e) => e.text).join('\n'),
      forceShopping: true, existing: existing);
  for (final e in fresh.shopping) {
    await lists.addItem(list.id, e.text);
  }
  return fresh.shopping.length;
}

/// Saves the note once, private unless [share] is true. The category is
/// stored by name; the repository drops it quietly if it cannot be written.
Future<Note> saveNote(NoteRepository notes, NoteDraft draft, {required bool share}) =>
    notes.create(
      title: draft.title,
      body: draft.body,
      isPrivate: !share,
      categoryName: draft.category.label,
    );

String savedMessage({required int items, required bool note}) {
  final parts = <String>[
    if (items > 0) items == 1 ? '1 item na lista de compras' : '$items itens na lista de compras',
    if (note) '1 nota guardada',
  ];
  if (parts.isEmpty) return 'Pronto! Tudo isso já estava guardado.';
  return 'Pronto! ${parts.join(' e ')}.';
}
