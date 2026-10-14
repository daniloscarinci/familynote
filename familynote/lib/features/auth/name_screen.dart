import 'package:flutter/material.dart';
import '../../core/messages.dart';
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
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 24),
            Text('Qual é o seu nome?', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 24),
            TextField(
              key: const Key('display-name'),
              controller: _name,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              style: const TextStyle(fontSize: 24),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
              decoration: const InputDecoration(hintText: 'Escreva aqui'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _busy ? null : _save,
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(72)),
              child: const Text('Continuar'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!,
                  key: const Key('error'),
                  style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.error)),
            ],
          ],
        ),
      ),
    );
  }
}
