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
  List<Member> _members = const [];
  bool _loading = true;
  String? _loadError;
  String? _link;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool get _isAdmin => _members
      .any((m) => m.userId == widget.repo.currentUserId && m.role == Role.admin);

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final m = await widget.repo.members(widget.workspaceId);
      if (!mounted) return;
      setState(() {
        _members = m;
        _loading = false;
      });
      // The invite is ready as soon as the screen opens: no extra tap.
      if (_isAdmin && _link == null) await _invitePerson();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = friendlyMessage(e,
            fallback: 'Não foi possível ver a sua família agora. Tente de novo.');
      });
    }
  }

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

  Widget _inviteSection() {
    final big = ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(72));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (_link == null && _busy) const Center(child: CircularProgressIndicator()),
      if (_link != null) ...[
        Text('Mande este link. Quem abrir entra na sua família.',
            key: const Key('invite-hint'), style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          key: const Key('btn-whatsapp'),
          onPressed: _whatsapp,
          icon: const Icon(Icons.send),
          label: const Text('Enviar pelo WhatsApp'),
          style: big,
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          key: const Key('btn-copy'),
          onPressed: _copy,
          icon: const Icon(Icons.copy),
          label: const Text('Copiar link'),
          style: big,
        ),
        const SizedBox(height: 12),
        SelectableText(_link!, key: const Key('invite-link')),
        const SizedBox(height: 16),
      ],
      if (_error != null) ...[
        Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        const SizedBox(height: 12),
      ],
      OutlinedButton(
        key: const Key('btn-invite'),
        onPressed: _busy ? null : _invitePerson,
        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(64)),
        child: const Text('Convidar alguém'),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Família')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_loading) const Center(child: CircularProgressIndicator()),
          if (_loadError != null) ...[
            Text(_loadError!, key: const Key('load-error')),
            const SizedBox(height: 16),
            ElevatedButton(
              key: const Key('btn-retry'),
              onPressed: _load,
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(72)),
              child: const Text('Tentar de novo'),
            ),
          ],
          if (_isAdmin) ...[_inviteSection(), const SizedBox(height: 24)],
          for (final m in _members)
            ListTile(
              minVerticalPadding: 12,
              leading: const Icon(Icons.person),
              title: Text(_name(m)),
              subtitle: Text(roleLabel(m.role)),
            ),
        ],
      ),
    );
  }
}
