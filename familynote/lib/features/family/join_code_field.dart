import 'package:flutter/material.dart';
import '../../data/workspace_repository.dart';

/// "Tenho um código de convite" field + button. Calls [onJoined] with the workspace id.
class JoinCodeField extends StatefulWidget {
  const JoinCodeField({super.key, required this.repo, required this.onJoined});
  final WorkspaceRepository repo;
  final void Function(String workspaceId) onJoined;

  @override
  State<JoinCodeField> createState() => _JoinCodeFieldState();
}

class _JoinCodeFieldState extends State<JoinCodeField> {
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _accept() async {
    final t = _code.text.trim();
    if (t.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final id = await widget.repo.acceptInvitation(t);
      widget.onJoined(id);
    } catch (_) {
      if (mounted) setState(() => _error = 'Código inválido ou vencido. Peça um novo.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      TextField(
        key: const Key('join-code'),
        controller: _code,
        decoration: const InputDecoration(labelText: 'Tenho um código de convite'),
      ),
      const SizedBox(height: 8),
      ElevatedButton(
        onPressed: _busy ? null : _accept,
        child: const Text('Entrar na família'),
      ),
      if (_error != null) ...[
        const SizedBox(height: 8),
        Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
      ],
    ]);
  }
}
