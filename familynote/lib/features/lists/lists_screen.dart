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
