import '../../domain/models.dart';
import '../../domain/repositories.dart';

const defaultListName = 'Compras';

/// The family's shopping list: the one named "Compras", else the oldest one.
/// Creates "Compras" when the family has no list yet.
Future<ShoppingList> defaultShoppingList(ListRepository repo) async {
  final all = await repo.lists();
  if (all.isEmpty) return repo.createList(defaultListName);
  return all.firstWhere((l) => l.name == defaultListName, orElse: () => all.first);
}
