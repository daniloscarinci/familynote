import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../domain/organizer.dart';
import '../../domain/repositories.dart';
import 'preview_screen.dart';

/// One big box: write or paste everything, then "Organizar".
class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key, required this.notes, required this.lists});
  final NoteRepository notes;
  final ListRepository lists;

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  final _text = TextEditingController();
  String? _hint;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _organize() {
    final result = organize(_text.text);
    if (result.isEmpty) {
      setState(() => _hint = 'Escreva alguma coisa primeiro.');
      return;
    }
    setState(() => _hint = null);
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => PreviewScreen(result: result, notes: widget.notes, lists: widget.lists),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'Escrever tudo aqui',
      children: [
        LabeledField(
          label: 'Escreva ou cole tudo',
          child: TextField(
            key: const Key('capture-field'),
            controller: _text,
            autofocus: true,
            minLines: 8,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            textAlignVertical: TextAlignVertical.top,
            decoration: const InputDecoration(
              hintText: 'Escreva ou cole tudo: compras, lembretes, recados...',
              alignLabelWithHint: true,
            ),
          ),
        ),
        const SizedBox(height: kButtonGap),
        if (_hint != null) ...[
          InlineMessage(_hint!, kind: MessageKind.error, textKey: const Key('capture-hint')),
          const SizedBox(height: kButtonGap),
        ],
        BigButton(
          key: const Key('btn-organize'),
          label: 'Organizar',
          icon: Icons.auto_fix_high,
          height: 80,
          onPressed: _organize,
        ),
      ],
    );
  }
}
