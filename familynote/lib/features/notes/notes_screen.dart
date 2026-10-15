import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../domain/models.dart';
import '../../domain/organizer.dart';
import '../../domain/repositories.dart';

/// "Procurar": search the notes and filter them by topic.
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

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _run(String q) => setState(() {
        _future = q.trim().isEmpty ? widget.notes.recent() : widget.notes.search(q);
      });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ScreenScaffold(
      title: 'Procurar',
      children: [
        LabeledField(
          label: 'Procurar nas suas notas',
          child: TextField(
            controller: _search,
            onChanged: _run,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search)),
          ),
        ),
        const SizedBox(height: kButtonGap),
        FutureBuilder<List<Note>>(
          future: _future,
          builder: (c, snap) {
            final all = snap.data ?? const <Note>[];
            if (all.isEmpty) {
              return Text("Ainda não há nada aqui. Toque em 'Escrever tudo aqui'.",
                  style: Theme.of(context).textTheme.bodyLarge);
            }
            final topics = <String>[
              for (final c in NoteCategory.values)
                if (all.any((n) => n.category == c.label)) c.label,
            ];
            final items = _filter == null ? all : all.where((n) => n.category == _filter).toList();
            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (topics.isNotEmpty)
                Wrap(spacing: 12, runSpacing: 12, children: [
                  for (final t in [null, ...topics])
                    ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 56),
                      child: ChoiceChip(
                        key: Key('chip-${t ?? 'todas'}'),
                        label: Text(t ?? 'Todas',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: _filter == t ? p.onPrimary : p.primary)),
                        selected: _filter == t,
                        onSelected: (_) => setState(() => _filter = t),
                      ),
                    ),
                ]),
              const SizedBox(height: kButtonGap),
              for (final n in items) ...[
                BigButton(
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
        const SizedBox(height: kSectionSpacing),
        BigButton(
          label: 'Escrever tudo aqui',
          icon: Icons.edit,
          height: 72,
          onPressed: widget.onNewNote,
        ),
      ],
    );
  }
}
