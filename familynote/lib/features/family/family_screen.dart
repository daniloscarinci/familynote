import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/workspace_repository.dart';
import '../../domain/models.dart';
import 'join_code_field.dart';

class FamilyScreen extends StatefulWidget {
  const FamilyScreen({
    super.key,
    required this.repo,
    required this.workspaceId,
    this.onJoined,
  });
  final WorkspaceRepository repo;
  final String workspaceId;
  final void Function(String workspaceId)? onJoined;

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  late final Future<List<Member>> _members = widget.repo.members(widget.workspaceId);
  String? _invite;
  String? _error;

  Future<void> _invitePerson() async {
    setState(() => _error = null);
    try {
      final t = await widget.repo.createInvitation(widget.workspaceId, 'adult');
      if (mounted) setState(() => _invite = t);
    } catch (_) {
      if (mounted) setState(() => _error = 'Não foi possível criar o convite.');
    }
  }

  String _name(Member m) {
    if (m.userId == widget.repo.currentUserId) return 'Você';
    return m.displayName.isEmpty ? 'Membro da família' : m.displayName;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Família')),
      body: FutureBuilder<List<Member>>(
        future: _members,
        builder: (c, snap) {
          final members = snap.data ?? const <Member>[];
          final isAdmin = members.any(
              (m) => m.userId == widget.repo.currentUserId && m.role == Role.admin);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (snap.connectionState != ConnectionState.done)
                const Center(child: CircularProgressIndicator()),
              for (final m in members)
                ListTile(
                  minVerticalPadding: 12,
                  leading: const Icon(Icons.person),
                  title: Text(_name(m)),
                  subtitle: Text(roleLabel(m.role)),
                ),
              const SizedBox(height: 16),
              if (isAdmin) ...[
                ElevatedButton(
                  onPressed: _invitePerson,
                  child: const Text('Convidar alguém da família'),
                ),
                if (_invite != null) _InviteCard(code: _invite!),
                if (_error != null)
                  Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                const SizedBox(height: 24),
              ],
              const Divider(),
              const SizedBox(height: 16),
              JoinCodeField(
                repo: widget.repo,
                onJoined: (id) => widget.onJoined?.call(id),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InviteCard extends StatelessWidget {
  const _InviteCard({required this.code});
  final String code;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          const Text('Envie este código para a pessoa (vale por 7 dias):'),
          const SizedBox(height: 12),
          SelectableText(code,
              key: const Key('invite-code'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.copy),
            label: const Text('Copiar código'),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: code));
              if (context.mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Código copiado')));
              }
            },
          ),
        ]),
      ),
    );
  }
}
