import 'package:flutter/material.dart';
import '../../core/status.dart';
import '../../domain/autosave.dart';
import '../../domain/models.dart';
import '../../domain/repositories.dart';

class NoteEditorScreen extends StatefulWidget {
  const NoteEditorScreen({super.key, required this.notes, this.existing});
  final NoteRepository notes;
  final Note? existing;

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late final _title = TextEditingController(text: widget.existing?.title ?? '');
  late final _body = TextEditingController(text: widget.existing?.body ?? '');
  String? _id;
  late final Autosaver _saver;
  SaveStatus _status = SaveStatus.saved;

  @override
  void initState() {
    super.initState();
    _id = widget.existing?.id;
    _saver = Autosaver(save: (_) => _persist());
    _saver.status.listen((s) {
      if (mounted) setState(() => _status = s);
    });
  }

  Future<void> _persist() async {
    if (_id == null) {
      final n = await widget.notes.create(title: _title.text, body: _body.text);
      _id = n.id;
    } else {
      await widget.notes.update(_id!, title: _title.text, body: _body.text);
    }
  }

  void _changed() => _saver.onChanged('${_title.text}\n${_body.text}');

  @override
  void dispose() {
    _saver.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nota')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(
            controller: _title,
            onChanged: (_) => _changed(),
            decoration: const InputDecoration(labelText: 'Título'),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TextField(
              controller: _body,
              onChanged: (_) => _changed(),
              maxLines: null,
              expands: true,
              autofocus: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(labelText: 'Escreva aqui'),
            ),
          ),
          const SizedBox(height: 8),
          Text(statusLabel(_status), key: const Key('save-status')),
        ]),
      ),
    );
  }
}
