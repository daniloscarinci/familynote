import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../domain/models.dart';
import '../../domain/repositories.dart';
import 'greeting.dart';

/// "1 item", "5 itens" or "Nenhum item".
String itemCountWords(int n) => n <= 0 ? 'Nenhum item' : (n == 1 ? '1 item' : '$n itens');

/// Hub: big labelled buttons only, then the latest three notes.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.notes,
    required this.onWriteAll,
    required this.onShoppingList,
    required this.onFamilyNotes,
    required this.onMore,
    this.onOpen,
    this.isAdmin = false,
    this.onInvite,
    this.userName,
    this.shoppingCount,
    this.message,
    this.clock = DateTime.now,
  });
  final NoteRepository notes;
  final VoidCallback onWriteAll;
  final VoidCallback onShoppingList;
  final VoidCallback onFamilyNotes;
  final VoidCallback onMore;
  final void Function(Note)? onOpen;

  /// Only the family admin sees "Convidar a família".
  final bool isAdmin;
  final VoidCallback? onInvite;

  /// Shown in the greeting (first name only); "Olá" when null or empty.
  final String? userName;

  /// Number of open items on the shopping list, shown in words on its button.
  final Future<int> Function()? shoppingCount;

  /// Plain-words problem shown above the buttons (for example a failed open).
  final String? message;
  final DateTime Function() clock;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Future<List<Note>> _future = widget.notes.recent(limit: 3);
  late final Future<int?> _count = _loadCount();

  Future<int?> _loadCount() async {
    try {
      return await widget.shoppingCount?.call();
    } catch (_) {
      return null; // The button simply shows no count.
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(kScreenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Family Note', style: t.bodySmall),
              Semantics(
                header: true,
                child: Text(greeting(widget.clock(), widget.userName),
                    key: const Key('greeting'), style: t.titleLarge),
              ),
              const SizedBox(height: kSectionSpacing),
              if (widget.message != null) ...[
                InlineMessage(widget.message!, kind: MessageKind.error),
                const SizedBox(height: kButtonGap),
              ],
              BigButton(
                key: const Key('btn-write-all'),
                icon: Icons.edit,
                label: 'Escrever tudo aqui',
                height: 96,
                onPressed: widget.onWriteAll,
              ),
              const SizedBox(height: kButtonGap),
              FutureBuilder<int?>(
                future: _count,
                builder: (c, snap) => BigButton(
                  key: const Key('btn-shopping'),
                  icon: Icons.shopping_cart,
                  label: 'Lista de compras',
                  caption: snap.data == null ? null : itemCountWords(snap.data!),
                  outline: true,
                  height: 80,
                  onPressed: widget.onShoppingList,
                ),
              ),
              const SizedBox(height: kButtonGap),
              BigButton(
                key: const Key('btn-family-notes'),
                icon: Icons.groups,
                label: 'O que a família escreveu',
                outline: true,
                height: 80,
                onPressed: widget.onFamilyNotes,
              ),
              if (widget.isAdmin && widget.onInvite != null) ...[
                const SizedBox(height: kButtonGap),
                BigButton(
                  key: const Key('btn-invite-home'),
                  icon: Icons.person_add,
                  label: 'Convidar a família',
                  outline: true,
                  height: 72,
                  onPressed: widget.onInvite!,
                ),
              ],
              const SizedBox(height: kButtonGap),
              TextButton(
                key: const Key('btn-more'),
                onPressed: widget.onMore,
                child: const Text('Outras opções'),
              ),
              const SizedBox(height: kSectionSpacing),
              const SectionTitle('Últimas anotações'),
              FutureBuilder<List<Note>>(
                future: _future,
                builder: (c, snap) {
                  final items = snap.data ?? const <Note>[];
                  if (snap.connectionState == ConnectionState.done && items.isEmpty) {
                    return Text(
                        "Ainda não há nada aqui. Toque em 'Escrever tudo aqui'.",
                        style: t.bodyLarge);
                  }
                  return Column(children: [
                    for (final n in items) ...[
                      BigButton(
                        key: Key('note-${n.id}'),
                        label: n.title.isEmpty ? '(sem título)' : n.title,
                        caption: [
                          if (n.category != null) n.category!,
                          n.isPrivate ? 'Só para mim' : 'Compartilhada com a família',
                        ].join(' · '),
                        outline: true,
                        height: 72,
                        alignStart: true,
                        onPressed: () => widget.onOpen?.call(n),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ]);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
