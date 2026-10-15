import 'package:flutter/material.dart';
import '../../core/messages.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/profile_repository.dart';

/// One question: "Qual é o seu nome?". Saved to the profile other members see.
class NameScreen extends StatefulWidget {
  const NameScreen({super.key, required this.profiles, required this.onDone});
  final ProfileRepository profiles;
  final VoidCallback onDone;

  @override
  State<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends State<NameScreen> {
  final _name = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final n = _name.text.trim();
    if (n.isEmpty) {
      setState(() => _error = 'Escreva o seu nome para continuar.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.profiles.setDisplayName(n);
      widget.onDone();
    } catch (e) {
      if (mounted) {
        setState(() => _error =
            friendlyMessage(e, fallback: 'Não foi possível guardar o nome. Tente de novo.'));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'Qual é o seu nome?',
      showBack: false,
      children: [
        LabeledField(
          label: 'O seu nome',
          child: TextField(
            key: const Key('display-name'),
            controller: _name,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
            decoration: const InputDecoration(hintText: 'Escreva aqui'),
          ),
        ),
        const SizedBox(height: kButtonGap),
        if (_error != null) ...[
          InlineMessage(_error!, kind: MessageKind.error, textKey: const Key('error')),
          const SizedBox(height: kButtonGap),
        ],
        BigButton(
          label: 'Continuar',
          onPressed: _busy ? null : _save,
        ),
      ],
    );
  }
}
