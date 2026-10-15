import 'package:flutter/material.dart';
import '../../core/messages.dart';
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

class _SharedNotesScreenState extends State<SharedNotesScreen> {
  late Future<List<Note>> _future = _load();

  Future<List<Note>> _load() async {
    final all = await widget.notes.recent(limit: 100);
    return all.where((n) => !n.isPrivate).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('O que a família escreveu')),
      body: FutureBuilder<List<Note>>(
        future: _future,
        builder: (c, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(friendlyMessage(snap.error!)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() => _future = _load()),
                    child: const Text('Tentar de novo'),
                  ),
                ]),
              ),
            );
          }
          final items = snap.data!;
          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Ainda não há notas compartilhadas com a família.'),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(),
            itemBuilder: (_, i) => ListTile(
              minVerticalPadding: 16,
              title: Text(items[i].title.isEmpty ? '(sem título)' : items[i].title),
              subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (items[i].category != null)
                  Text(items[i].category!, key: const Key('note-category')),
                if (items[i].body.isNotEmpty)
                  Text(items[i].body, maxLines: 2, overflow: TextOverflow.ellipsis),
              ]),
              onTap: () => widget.onOpen?.call(items[i]),
            ),
          );
        },
      ),
    );
  }
}
