import 'package:flutter/material.dart';
import '../../core/messages.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../domain/models.dart';
import '../../domain/repositories.dart';

/// Notes shared with the family, newest first.
class SharedNotesScreen extends StatefulWidget {
  const SharedNotesScreen({super.key, required this.notes, this.onOpen});
  final NoteRepository notes;
  final void Function(Note)? onOpen;

  @override
  State<SharedNotesScreen> createState() => _SharedNotesScreenState();
}

String _snippet(String body) {
  final flat = body.replaceAll(RegExp(r'\s+'), ' ').trim();
  return flat.length <= 80 ? flat : '${flat.substring(0, 80)}...';
}

class _SharedNotesScreenState extends State<SharedNotesScreen> {
  late Future<List<Note>> _future = _load();

  Future<List<Note>> _load() async {
    final all = await widget.notes.recent(limit: 100);
    return all.where((n) => !n.isPrivate).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Widget build(BuildContext context) {
    final body = Theme.of(context).textTheme.bodyLarge;
    return ScreenScaffold(
      title: 'O que a família escreveu',
      children: [
        FutureBuilder<List<Note>>(
          future: _future,
          builder: (c, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                InlineMessage(friendlyMessage(snap.error!), kind: MessageKind.error),
                const SizedBox(height: kButtonGap),
                BigButton(
                  onPressed: () => setState(() => _future = _load()),
                  label: 'Tentar de novo',
                ),
              ]);
            }
            final items = snap.data!;
            if (items.isEmpty) {
              return Text('Ainda não há notas compartilhadas com a família.', style: body);
            }
            return Column(children: [
              for (final n in items) ...[
                BigButton(
                  label: n.title.isEmpty ? '(sem título)' : n.title,
                  caption: [
                    if (n.category != null) n.category!,
                    if (n.body.isNotEmpty) _snippet(n.body),
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
    );
  }
}
