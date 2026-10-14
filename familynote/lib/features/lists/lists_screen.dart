import 'package:flutter/material.dart';
import '../../domain/models.dart';
import '../../domain/repositories.dart';

class ListDetailScreen extends StatefulWidget {
  const ListDetailScreen({super.key, required this.repo, required this.list});
  final ListRepository repo;
  final ShoppingList list;

  @override
  State<ListDetailScreen> createState() => _ListDetailScreenState();
}

class _ListDetailScreenState extends State<ListDetailScreen> {
  final _text = TextEditingController();
  List<ShoppingItem> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final i = await widget.repo.items(widget.list.id);
    if (mounted) setState(() => _items = i);
  }

  Future<void> _add() async {
    final t = _text.text.trim();
    if (t.isEmpty) return;
    await widget.repo.addItem(widget.list.id, t);
    _text.clear();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.list.name)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Row(children: [
            Expanded(
              child: TextField(
                controller: _text,
                decoration: const InputDecoration(labelText: 'Novo item'),
                onSubmitted: (_) => _add(),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(onPressed: _add, child: const Text('Adicionar')),
          ]),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                for (final i in _items)
                  CheckboxListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    title: Text(i.text,
                        style: TextStyle(
                            fontSize: 20,
                            decoration: i.checked ? TextDecoration.lineThrough : null)),
                    value: i.checked,
                    onChanged: (v) async {
                      await widget.repo.setChecked(i.id, v ?? false);
                      await _load();
                    },
                  ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class ListsScreen extends StatefulWidget {
  const ListsScreen({super.key, required this.repo});
  final ListRepository repo;

  @override
  State<ListsScreen> createState() => _ListsScreenState();
}

class _ListsScreenState extends State<ListsScreen> {
  late Future<List<ShoppingList>> _future = widget.repo.lists();

  void _reload() => setState(() => _future = widget.repo.lists());

  Future<void> _newList() async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const _NameDialog(),
    );
    if (name == null || name.trim().isEmpty) return;
    final list = await widget.repo.createList(name.trim());
    if (!mounted) return;
    await _open(list);
  }

  Future<void> _open(ShoppingList list) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => ListDetailScreen(repo: widget.repo, list: list),
    ));
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Listas')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _newList,
              icon: const Icon(Icons.add),
              label: const Text('Nova lista'),
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(72)),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<ShoppingList>>(
              future: _future,
              builder: (c, snap) {
                final lists = snap.data ?? const <ShoppingList>[];
                if (lists.isEmpty) {
                  return const Center(child: Text('Nenhuma lista ainda. Toque em "Nova lista".'));
                }
                return ListView.separated(
                  itemCount: lists.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (_, i) => ListTile(
                    minVerticalPadding: 16,
                    title: Text(lists[i].name),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _open(lists[i]),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}

class _NameDialog extends StatefulWidget {
  const _NameDialog();

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nova lista'),
      content: TextField(
        controller: _c,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Nome da lista'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(minimumSize: const Size(56, 56)),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _c.text),
          child: const Text('Criar'),
        ),
      ],
    );
  }
}
