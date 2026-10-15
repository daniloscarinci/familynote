import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
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
  String? _added;
  bool _loaded = false;

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
    if (mounted) {
      setState(() {
        _items = i;
        _loaded = true;
      });
    }
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
    final n = r.shopping.length;
    _message = n == 0 ? 'Isso já estava na lista.' : null;
    _added = n == 0 ? null : (n == 1 ? '1 item adicionado.' : '$n itens adicionados.');
    await _load();
  }

  Widget _row(ShoppingItem i) => BigCheckRow(
        label: i.text,
        checked: i.checked,
        onChanged: (v) async {
          await widget.repo.setChecked(i.id, v);
          await _load();
        },
      );

  Widget _header(String text, {Key? key}) => SectionTitle(text, key: key);

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
    return ScreenScaffold(
      title: widget.list.name,
      children: [
        LabeledField(
          label: 'Novo item',
          helper: 'Pode colar a lista inteira.',
          child: TextField(
            controller: _text,
            minLines: 1,
            maxLines: 4,
            keyboardType: TextInputType.multiline,
          ),
        ),
        const SizedBox(height: kButtonGap),
        BigButton(label: 'Adicionar', icon: Icons.add, onPressed: _add),
        const SizedBox(height: kButtonGap),
        if (_message != null)
          InlineMessage(_message!, textKey: const Key('list-message')),
        if (_added != null) InlineMessage(_added!, kind: MessageKind.success),
        if (_loaded && _items.isEmpty)
          Text("Ainda não há nada aqui. Escreva um item e toque em 'Adicionar'.",
              style: Theme.of(context).textTheme.bodyLarge),
        ..._groups(),
      ],
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
    return ScreenScaffold(
      title: 'Listas',
      children: [
        BigButton(label: 'Nova lista', icon: Icons.add, height: 72, onPressed: _newList),
        const SizedBox(height: kButtonGap),
        FutureBuilder<List<ShoppingList>>(
          future: _future,
          builder: (c, snap) {
            final lists = snap.data ?? const <ShoppingList>[];
            if (lists.isEmpty) {
              return Text('Nenhuma lista ainda. Toque em "Nova lista".',
                  style: Theme.of(context).textTheme.bodyLarge);
            }
            return Column(children: [
              for (final l in lists) ...[
                BigButton(
                  label: l.name,
                  icon: Icons.chevron_right,
                  outline: true,
                  height: 72,
                  alignStart: true,
                  onPressed: () => _open(l),
                ),
                const SizedBox(height: 12),
              ],
            ]);
          },
        ),
      ],
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
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LabeledField(
              label: 'Nome da lista',
              child: TextField(controller: _c, autofocus: true),
            ),
            const SizedBox(height: kSectionSpacing),
            BigButton(label: 'Criar', onPressed: () => Navigator.pop(context, _c.text)),
            const SizedBox(height: kButtonGap),
            BigButton(
                label: 'Cancelar', outline: true, onPressed: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }
}
