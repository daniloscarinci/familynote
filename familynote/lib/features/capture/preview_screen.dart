import 'package:flutter/material.dart';
import '../../core/messages.dart';
import '../../domain/organizer.dart';
import '../../domain/repositories.dart';
import 'save_organized.dart';

/// Shows what the organizer understood. Nothing is saved until "Guardar tudo".
class PreviewScreen extends StatefulWidget {
  const PreviewScreen({super.key, required this.result, required this.notes, required this.lists});
  final OrganizedResult result;
  final NoteRepository notes;
  final ListRepository lists;

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  bool _share = false;
  bool _saving = false;
  String? _error;
  // Kept between attempts so a retry never saves the same thing twice.
  int? _itemsSaved;
  bool _noteSaved = false;

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      _itemsSaved ??= await saveShopping(widget.lists, widget.result.shopping);
      final note = widget.result.note;
      if (note != null && !_noteSaved) {
        await saveNote(widget.notes, note, share: _share);
        _noteSaved = true;
      }
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          content: Text(savedMessage(items: _itemsSaved!, note: widget.result.note != null),
              style: const TextStyle(fontSize: 20)),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: ElevatedButton.styleFrom(minimumSize: const Size(160, 56)),
              child: const Text('Ir para o início'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (mounted) {
        setState(() => _error =
            friendlyMessage(e, fallback: 'Não foi possível guardar agora. Tente de novo.'));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  List<Widget> _shoppingSection(BuildContext context) {
    final r = widget.result;
    if (r.shopping.isEmpty) return const [];
    final theme = Theme.of(context).textTheme;
    final n = r.shopping.length;
    return [
      Text(n == 1 ? 'Lista de compras (1 item)' : 'Lista de compras ($n itens)',
          style: theme.titleLarge),
      for (final c in ShoppingCategory.values)
        if (r.shopping.any((e) => e.category == c)) ...[
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Text(c.label, style: theme.titleMedium),
          ),
          for (final e in r.shopping.where((e) => e.category == c))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(e.text, style: const TextStyle(fontSize: 20)),
            ),
        ],
      const SizedBox(height: 24),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final note = widget.result.note;
    return Scaffold(
      appBar: AppBar(title: const Text('Veja como organizei')),
      body: Column(children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ..._shoppingSection(context),
              if (note != null) ...[
                Text('Nota', style: theme.titleLarge),
                const SizedBox(height: 8),
                Text(note.title, style: theme.titleMedium),
                Text('Assunto: ${note.category.label}', key: const Key('preview-category')),
                const SizedBox(height: 8),
                Text(note.body, style: const TextStyle(fontSize: 20)),
                const SizedBox(height: 16),
                SwitchListTile(
                  key: const Key('share-switch'),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Compartilhar com a família',
                      style: TextStyle(fontSize: 20)),
                  subtitle: Text(_share ? 'Todos da família vão ver.' : 'Só você vai ver.'),
                  value: _share,
                  onChanged: (v) => setState(() => _share = v),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (_error != null) ...[
              Text(_error!,
                  key: const Key('save-error'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
              const SizedBox(height: 8),
            ],
            ElevatedButton(
              key: const Key('btn-save-all'),
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(72),
                textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              child: const Text('Guardar tudo'),
            ),
            const SizedBox(height: 8),
            TextButton(
              key: const Key('btn-back-edit'),
              onPressed: _saving ? null : () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(minimumSize: const Size.fromHeight(56)),
              child: const Text('Voltar e editar', style: TextStyle(fontSize: 20)),
            ),
          ]),
        ),
      ]),
    );
  }
}
