import 'package:flutter/material.dart';
import '../../domain/models.dart';
import '../../domain/repositories.dart';

/// Giant buttons, a small "Mais", and the latest notes.
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

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Future<List<Note>> _future = widget.notes.recent(limit: 5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Family Note')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _BigButton(
              key: const Key('btn-write-all'),
              icon: Icons.edit,
              label: 'Escrever tudo aqui',
              onPressed: widget.onWriteAll),
          const SizedBox(height: 16),
          _BigButton(
              key: const Key('btn-shopping'),
              icon: Icons.shopping_cart,
              label: 'Lista de compras',
              onPressed: widget.onShoppingList),
          const SizedBox(height: 16),
          _BigButton(
              key: const Key('btn-family-notes'),
              icon: Icons.groups,
              label: 'O que a família escreveu',
              onPressed: widget.onFamilyNotes),
          if (widget.isAdmin && widget.onInvite != null) ...[
            const SizedBox(height: 16),
            _BigButton(
                key: const Key('btn-invite-home'),
                icon: Icons.person_add,
                label: 'Convidar a família',
                onPressed: widget.onInvite!),
          ],
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton(
              key: const Key('btn-more'),
              onPressed: widget.onMore,
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size(120, 56),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              child: const Text('Mais'),
            ),
          ),
          const SizedBox(height: 16),
          Text('Notas recentes', style: Theme.of(context).textTheme.titleLarge),
          FutureBuilder<List<Note>>(
            future: _future,
            builder: (c, snap) {
              final items = snap.data ?? const <Note>[];
              if (snap.connectionState == ConnectionState.done && items.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('Nenhuma nota ainda.'),
                );
              }
              return Column(children: [
                for (final n in items)
                  ListTile(
                    minVerticalPadding: 16,
                    title: Text(n.title.isEmpty ? '(sem título)' : n.title),
                    subtitle: Text([
                      if (n.category != null) n.category!,
                      n.isPrivate ? 'Só para mim' : 'Compartilhada com a família',
                    ].join(' · ')),
                    onTap: () => widget.onOpen?.call(n),
                  ),
              ]);
            },
          ),
        ],
      ),
    );
  }
}

class _BigButton extends StatelessWidget {
  const _BigButton({super.key, required this.icon, required this.label, required this.onPressed});
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 32),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(88),
          textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
