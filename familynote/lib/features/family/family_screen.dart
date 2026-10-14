import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/providers.dart';
import '../../core/join_link.dart';
import '../../core/messages.dart';
import '../../data/workspace_repository.dart';
import '../../domain/models.dart';

class FamilyScreen extends StatefulWidget {
  const FamilyScreen({
    super.key,
    required this.repo,
    required this.workspaceId,
    required this.appUrl,
    required this.openUrl,
  });
  final WorkspaceRepository repo;
  final String workspaceId;

  /// Where the app is hosted; invite links point here.
  final String appUrl;
  final UrlOpener openUrl;

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  late final Future<List<Member>> _members = widget.repo.members(widget.workspaceId);
  String? _link;
  String? _error;
  bool _busy = false;

  Future<void> _invitePerson() async {
    setState(() {
      _error = null;
      _busy = true;
    });
    try {
      final t = await widget.repo.createInvitation(widget.workspaceId, 'adult');
      if (mounted) setState(() => _link = buildInviteLink(widget.appUrl, t));
    } catch (e) {
      if (mounted) {
        setState(() => _error =
            friendlyMessage(e, fallback: 'Não foi possível criar o convite. Tente de novo.'));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _name(Member m) {
    final n = m.displayName.trim();
    if (m.userId == widget.repo.currentUserId) return n.isEmpty ? 'Você' : '$n (você)';
    return n.isEmpty ? 'Membro da família' : n;
  }

  Future<void> _whatsapp() async {
    final text = 'Oi! Entre na nossa família no Family Note. É só tocar neste link: $_link';
    final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
    try {
      final ok = await widget.openUrl(uri);
      if (!ok) throw Exception('could not open');
    } catch (_) {
      if (mounted) {
        setState(() => _error =
            'Não foi possível abrir o WhatsApp. Toque em "Copiar link" e envie por onde preferir.');
      }
    }
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _link!));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link copiado')));
    }
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
                  key: const Key('btn-invite'),
                  onPressed: _busy ? null : _invitePerson,
                  style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(72)),
                  child: const Text('Convidar alguém'),
                ),
                if (_link != null) ...[
                  const SizedBox(height: 16),
                  const Text('Escolha como enviar o convite. Ele vale por 7 dias.'),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    key: const Key('btn-whatsapp'),
                    onPressed: _whatsapp,
                    icon: const Icon(Icons.send),
                    label: const Text('Enviar pelo WhatsApp'),
                    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(72)),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    key: const Key('btn-copy'),
                    onPressed: _copy,
                    icon: const Icon(Icons.copy),
                    label: const Text('Copiar link'),
                    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(72)),
                  ),
                  const SizedBox(height: 12),
                  SelectableText(_link!, key: const Key('invite-link')),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
              ],
            ],
          );
        },
      ),
    );
  }
}
