enum Role { admin, adult, limited, guest }

class Note {
  final String id;
  final String title;
  final String body;
  final bool isPrivate;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  /// Topic name (e.g. "Saúde"), chosen by the organizer; null when unknown.
  final String? category;
  const Note({
    required this.id,
    required this.title,
    required this.body,
    this.isPrivate = true,
    required this.updatedAt,
    this.deletedAt,
    this.category,
  });

  Note copyWith({String? title, String? body, bool? isPrivate, DateTime? updatedAt, DateTime? deletedAt, String? category}) =>
      Note(
        id: id,
        title: title ?? this.title,
        body: body ?? this.body,
        isPrivate: isPrivate ?? this.isPrivate,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
        category: category ?? this.category,
      );
}

class ShoppingItem {
  final String id;
  final String text;
  final bool checked;
  const ShoppingItem({required this.id, required this.text, this.checked = false});
}

class ShoppingList {
  final String id;
  final String name;
  const ShoppingList({required this.id, required this.name});
}

class Member {
  final String userId;
  final String displayName;
  final Role role;
  const Member({required this.userId, required this.displayName, required this.role});
}

String roleLabel(Role r) => switch (r) {
      Role.admin => 'Administrador',
      Role.adult => 'Adulto',
      Role.limited => 'Acesso limitado',
      Role.guest => 'Convidado',
    };
