import 'package:flutter/material.dart';
import '../../domain/models.dart';
import '../../domain/organizer.dart';
import '../../domain/repositories.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key, required this.notes, required this.onNewNote, this.onOpen});
  final NoteRepository notes;
  final VoidCallback onNewNote;
  final void Function(Note)? onOpen;

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  late Future<List<Note>> _future = widget.notes.recent();
  final _search = TextEditingController();
  String? _filter;

  void _run(String q) => setState(() {
        _future = q.trim().isEmpty ? widget.notes.recent() : widget.notes.search(q);
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notas')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.onNewNote,
              icon: const Icon(Icons.add),
              label: const Text('Escrever tudo aqui'),
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(72)),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _search,
            onChanged: _run,
            decoration: const InputDecoration(
              labelText: 'Procurar',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<Note>>(
              future: _future,
              builder: (c, snap) {
                final all = snap.data ?? const <Note>[];
                if (all.isEmpty) {
                  return const Center(
                      child: Text('Nenhuma nota ainda. Toque em "Escrever tudo aqui".'));
                }
                final topics = <String>[
                  for (final c in NoteCategory.values)
                    if (all.any((n) => n.category == c.label)) c.label,
                ];
                final items =
                    _filter == null ? all : all.where((n) => n.category == _filter).toList();
                return Column(children: [
                  if (topics.isNotEmpty)
                    SizedBox(
                      height: 56,
                      child: ListView(scrollDirection: Axis.horizontal, children: [
                        for (final t in [null, ...topics])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: SizedBox(
                              height: 48,
                              child: ChoiceChip(
                                key: Key('chip-${t ?? 'todas'}'),
                                label: Text(t ?? 'Todas', style: const TextStyle(fontSize: 18)),
                                selected: _filter == t,
                                onSelected: (_) => setState(() => _filter = t),
                              ),
                            ),
                          ),
                      ]),
                    ),
                  Expanded(child: _noteList(items)),
                ]);
              },
            ),
          ),
        ]),
      ),
    );
  }

  Widget _noteList(List<Note> items) {
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (_, i) => ListTile(
                    minVerticalPadding: 16,
                    title: Text(items[i].title.isEmpty ? '(sem título)' : items[i].title),
                    subtitle: Text([
                      if (items[i].category != null) items[i].category!,
                      items[i].isPrivate ? 'Só para mim' : 'Compartilhada com a família',
                    ].join(' · ')),
                    onTap: () => widget.onOpen?.call(items[i]),
                  ),
                );
  }
}
