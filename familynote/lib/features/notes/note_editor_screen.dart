import 'package:flutter/material.dart';
import '../../core/status.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../domain/autosave.dart';
import '../../domain/models.dart';
import '../../domain/organizer.dart';
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
      final n = await widget.notes
          .create(title: _title.text, body: _body.text, categoryName: _topic());
      _id = n.id;
    } else {
      await widget.notes
          .update(_id!, title: _title.text, body: _body.text, categoryName: _topic());
    }
  }

  /// The topic is always picked by the organizer, never by hand.
  String _topic() => categoryOfNote('${_title.text} ${_body.text}').label;

  void _changed() => _saver.onChanged('${_title.text}\n${_body.text}');

  @override
  void dispose() {
    _saver.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (statusColor, statusIcon) = switch (_status) {
      SaveStatus.saved => (p.success, Icons.check_circle_outline),
      SaveStatus.saving => (p.primary, Icons.sync),
      SaveStatus.pending => (p.warning, Icons.cloud_off),
    };
    return ScreenScaffold(
      title: 'Nota',
      children: [
        LabeledField(
          label: 'Título',
          child: TextField(
            key: const Key('note-title'),
            controller: _title,
            onChanged: (_) => _changed(),
          ),
        ),
        const SizedBox(height: kButtonGap),
        LabeledField(
          label: 'Escreva aqui',
          child: TextField(
            key: const Key('note-body'),
            controller: _body,
            onChanged: (_) => _changed(),
            minLines: 10,
            maxLines: null,
            autofocus: true,
            keyboardType: TextInputType.multiline,
            textAlignVertical: TextAlignVertical.top,
          ),
        ),
        const SizedBox(height: kButtonGap),
        if (widget.existing?.category != null) ...[
          Text('Assunto: ${widget.existing!.category}', key: const Key('note-category')),
          const SizedBox(height: 8),
        ],
        // Always visible: where the note stands, in icon and words.
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(statusIcon, color: statusColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              statusLabel(_status),
              key: const Key('save-status'),
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w600, color: statusColor, height: 1.4),
            ),
          ),
        ]),
      ],
    );
  }
}
