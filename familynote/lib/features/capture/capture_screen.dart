import 'package:flutter/material.dart';
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
    return Scaffold(
      appBar: AppBar(title: const Text('Escrever tudo aqui')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Expanded(
            child: TextField(
              key: const Key('capture-field'),
              controller: _text,
              autofocus: true,
              maxLines: null,
              expands: true,
              keyboardType: TextInputType.multiline,
              textAlignVertical: TextAlignVertical.top,
              style: const TextStyle(fontSize: 20),
              decoration: const InputDecoration(
                hintText: 'Escreva ou cole tudo: compras, lembretes, recados...',
                alignLabelWithHint: true,
              ),
            ),
          ),
          if (_hint != null) ...[
            const SizedBox(height: 8),
            Text(_hint!, key: const Key('capture-hint')),
          ],
          const SizedBox(height: 12),
          ElevatedButton(
            key: const Key('btn-organize'),
            onPressed: _organize,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(72),
              textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            child: const Text('Organizar'),
          ),
        ]),
      ),
    );
  }
}
