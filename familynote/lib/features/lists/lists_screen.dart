import 'package:flutter/material.dart';
import '../../domain/models.dart';
import '../../domain/organizer.dart';
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
  String? _message;

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

  /// Accepts one item or a whole pasted list; the organizer sorts it out.
  Future<void> _add() async {
    final t = _text.text.trim();
    if (t.isEmpty) return;
    final r = organize(t, forceShopping: true, existing: _items.map((i) => i.text));
    for (final e in r.shopping) {
      await widget.repo.addItem(widget.list.id, e.text);
    }
    _text.clear();
    _message = r.shopping.isEmpty ? 'Isso já estava na lista.' : null;
    await _load();
  }

  Widget _row(ShoppingItem i) => CheckboxListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        controlAffinity: ListTileControlAffinity.leading,
        title: Text(i.text,
            style: TextStyle(
                fontSize: 20, decoration: i.checked ? TextDecoration.lineThrough : null)),
        value: i.checked,
        onChanged: (v) async {
          await widget.repo.setChecked(i.id, v ?? false);
          await _load();
        },
      );

  Widget _header(String text, {Key? key}) => Padding(
        key: key,
        padding: const EdgeInsets.only(top: 16, bottom: 4),
        child: Text(text, style: Theme.of(context).textTheme.titleLarge),
      );

  List<Widget> _groups() {
    final open = _items.where((i) => !i.checked).toList();
    final done = _items.where((i) => i.checked).toList();
    final byCategory = <ShoppingCategory, List<ShoppingItem>>{};
    for (final i in open) {
      (byCategory[categoryOfItem(i.text)] ??= []).add(i);
    }
    int cmp(ShoppingItem a, ShoppingItem b) =>
        shoppingKey(a.text).compareTo(shoppingKey(b.text));
    return [
      for (final c in ShoppingCategory.values)
        if (byCategory[c] != null) ...[
          _header(c.label, key: Key('group-${c.label}')),
          for (final i in byCategory[c]!..sort(cmp)) _row(i),
        ],
      if (done.isNotEmpty) ...[
        _header('Já comprei', key: const Key('group-done')),
        for (final i in done..sort(cmp)) _row(i),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.list.name)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: TextField(
                controller: _text,
                minLines: 1,
                maxLines: 4,
                keyboardType: TextInputType.multiline,
                decoration: const InputDecoration(
                  labelText: 'Novo item',
                  helperText: 'Pode colar a lista inteira.',
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _add,
              style: ElevatedButton.styleFrom(minimumSize: const Size(120, 56)),
              child: const Text('Adicionar'),
            ),
          ]),
          if (_message != null) ...[
            const SizedBox(height: 8),
            Text(_message!, key: const Key('list-message')),
          ],
          const SizedBox(height: 8),
          Expanded(child: ListView(children: _groups())),
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
