import 'package:flutter/material.dart';
import '../../core/messages.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
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
          icon: Icon(Icons.check_circle, size: 48, color: ctx.palette.success),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(savedMessage(items: _itemsSaved!, note: widget.result.note != null),
                  style: Theme.of(ctx).textTheme.bodyLarge),
              const SizedBox(height: kSectionSpacing),
              BigButton(
                label: 'Ir para o início',
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ]),
          ),
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
      SectionTitle(n == 1 ? 'Lista de compras (1 item)' : 'Lista de compras ($n itens)'),
      for (final c in ShoppingCategory.values)
        if (r.shopping.any((e) => e.category == c)) ...[
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Text(c.label, style: theme.titleSmall),
          ),
          for (final e in r.shopping.where((e) => e.category == c))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(e.text, style: theme.bodyLarge),
            ),
        ],
      const SizedBox(height: kSectionSpacing),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final note = widget.result.note;
    return ScreenScaffold(
      title: 'Veja como organizei',
      onBack: _saving ? () {} : null,
      children: [
        ..._shoppingSection(context),
        if (note != null) ...[
          const SectionTitle('Nota'),
          Text(note.title, style: theme.titleSmall),
          Text('Assunto: ${note.category.label}', key: const Key('preview-category')),
          const SizedBox(height: 8),
          Text(note.body, style: theme.bodyLarge),
          const SizedBox(height: kButtonGap),
          BigSwitchRow(
            key: const Key('share-switch'),
            title: 'Compartilhar com a família',
            subtitle: _share ? 'Todos da família vão ver.' : 'Só você vai ver.',
            value: _share,
            onChanged: (v) => setState(() => _share = v),
          ),
        ],
        const SizedBox(height: kSectionSpacing),
        if (_error != null) ...[
          InlineMessage(_error!, kind: MessageKind.error, textKey: const Key('save-error')),
          const SizedBox(height: kButtonGap),
        ],
        BigButton(
          key: const Key('btn-save-all'),
          label: 'Guardar tudo',
          icon: Icons.check,
          height: 80,
          onPressed: _saving ? null : _save,
        ),
        const SizedBox(height: kButtonGap),
        BigButton(
          key: const Key('btn-back-edit'),
          label: 'Voltar e editar',
          outline: true,
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
