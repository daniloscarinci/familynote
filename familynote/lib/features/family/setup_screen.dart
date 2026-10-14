import 'package:flutter/material.dart';
import '../../data/workspace_repository.dart';
import 'join_code_field.dart';

/// First run: signed in but belongs to no family yet.
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key, required this.repo, required this.onReady});
  final WorkspaceRepository repo;
  final void Function(String workspaceId) onReady;

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _name = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final n = _name.text.trim();
    if (n.isEmpty) {
      setState(() => _error = 'Escreva um nome para a família.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final id = await widget.repo.createWorkspace(n);
      widget.onReady(id);
    } catch (_) {
      if (mounted) setState(() => _error = 'Não foi possível criar. Tente de novo.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar a sua família')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            key: const Key('family-name'),
            controller: _name,
            decoration: const InputDecoration(labelText: 'Nome da família'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _busy ? null : _create, child: const Text('Criar')),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),
          JoinCodeField(repo: widget.repo, onJoined: widget.onReady),
        ],
      ),
    );
  }
}
