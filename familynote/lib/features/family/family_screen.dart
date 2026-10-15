import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/providers.dart';
import '../../core/join_link.dart';
import '../../core/messages.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
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
  String? _copied;
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
      _copied = null;
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
    // Stays on screen until the next action, so it is never missed.
    if (mounted) setState(() => _copied = 'Link copiado');
  }

  Widget _inviteSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (_link == null && _busy) const Center(child: CircularProgressIndicator()),
      if (_link != null) ...[
        Text('Mande este link. Quem abrir entra na sua família.',
            key: const Key('invite-hint'), style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: kButtonGap),
        BigButton(
          key: const Key('btn-whatsapp'),
          onPressed: _whatsapp,
          icon: Icons.send,
          label: 'Enviar pelo WhatsApp',
          height: 80,
        ),
        const SizedBox(height: kButtonGap),
        BigButton(
          key: const Key('btn-copy'),
          onPressed: _copy,
          icon: Icons.copy,
          label: 'Copiar link',
          outline: true,
          height: 72,
        ),
        const SizedBox(height: kButtonGap),
        if (_copied != null) ...[
          InlineMessage(_copied!, kind: MessageKind.success),
          const SizedBox(height: kButtonGap),
        ],
        SelectableText(_link!, key: const Key('invite-link')),
        const SizedBox(height: kButtonGap),
      ],
      if (_error != null) ...[
        InlineMessage(_error!, kind: MessageKind.error),
        const SizedBox(height: kButtonGap),
      ],
      BigButton(
        key: const Key('btn-invite'),
        onPressed: _busy ? null : _invitePerson,
        label: 'Convidar alguém',
        outline: true,
        height: 72,
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'Família',
      children: [
        if (_loading) const Center(child: CircularProgressIndicator()),
        if (_loadError != null) ...[
          InlineMessage(_loadError!, kind: MessageKind.error, textKey: const Key('load-error')),
          const SizedBox(height: kButtonGap),
          BigButton(
            key: const Key('btn-retry'),
            onPressed: _load,
            label: 'Tentar de novo',
            height: 72,
          ),
        ],
        if (_isAdmin) ...[_inviteSection(), const SizedBox(height: kSectionSpacing)],
        if (_members.isNotEmpty) const SectionTitle('Pessoas da família'),
        for (final m in _members)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.person, size: 32),
                title: Text(_name(m)),
                subtitle: Text(roleLabel(m.role)),
              ),
            ),
          ),
      ],
    );
  }
}
