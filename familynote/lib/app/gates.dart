import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/messages.dart';
import '../features/auth/name_screen.dart';
import '../features/auth/sign_in_screen.dart';
import 'main_flow.dart';
import 'providers.dart';

const defaultFamilyName = 'Minha família';

/// Signed out: invite link -> anonymous account; otherwise e-mail code.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authRepositoryProvider);
    return StreamBuilder<bool>(
      stream: auth.signedIn,
      builder: (c, snap) {
        if (!snap.hasData) return const _Loading();
        if (snap.data == true) return const _ReadyGate();
        if (ref.watch(joinTokenProvider) != null) return const _AnonymousJoin();
        return SignInScreen(auth: auth);
      },
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class _Problem extends StatelessWidget {
  const _Problem({required this.message, required this.onRetry, this.onSkip});
  final String message;
  final VoidCallback onRetry;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(24),
            children: [
              Text(message, key: const Key('problem'), style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(72)),
                child: const Text('Tentar de novo'),
              ),
              if (onSkip != null) ...[
                const SizedBox(height: 16),
                TextButton(
                  onPressed: onSkip,
                  style: TextButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                  child: const Text('Continuar sem o convite'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Opened from an invite link while signed out: create the anonymous account.
class _AnonymousJoin extends ConsumerStatefulWidget {
  const _AnonymousJoin();

  @override
  ConsumerState<_AnonymousJoin> createState() => _AnonymousJoinState();
}

class _AnonymousJoinState extends ConsumerState<_AnonymousJoin> {
  String? _error;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    setState(() => _error = null);
    try {
      await ref.read(authRepositoryProvider).signInAnonymously();
    } catch (e) {
      if (mounted) {
        setState(() => _error = friendlyMessage(e,
            fallback: 'Não foi possível entrar com este link. Tente de novo.'));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error == null) return const _Loading();
    return _Problem(
      message: _error!,
      onRetry: _start,
      onSkip: () => ref.read(joinTokenProvider.notifier).clear(),
    );
  }
}

class _Ready {
  const _Ready(this.workspaceId, this.needsName);
  final String workspaceId;
  final bool needsName;
}

/// Signed in: accept a pending invite, find or create the family, ask the name once.
class _ReadyGate extends ConsumerStatefulWidget {
  const _ReadyGate();

  @override
  ConsumerState<_ReadyGate> createState() => _ReadyGateState();
}

class _ReadyGateState extends ConsumerState<_ReadyGate> {
  late Future<_Ready> _future = _load();
  bool _nameDone = false;

  Future<_Ready> _load() async {
    final ws = ref.read(workspaceRepositoryProvider);
    final token = ref.read(joinTokenProvider);
    String? id;
    if (token != null) {
      try {
        id = await ws.acceptInvitation(token);
        ref.read(joinTokenProvider.notifier).clear();
      } catch (_) {
        // A used link (for example after a page reload) is harmless for people who
        // already have a family.
        id = await ws.currentWorkspaceId();
        if (id == null) rethrow;
        ref.read(joinTokenProvider.notifier).clear();
      }
    }
    id ??= await ws.currentWorkspaceId();
    id ??= await ws.createWorkspace(defaultFamilyName);
    var needsName = false;
    try {
      needsName = (await ref.read(profileRepositoryProvider).displayName()).trim().isEmpty;
    } catch (_) {
      // Not being able to read the name must not block the person.
    }
    return _Ready(id, needsName);
  }

  void _retry() => setState(() {
        _future = _load();
      });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_Ready>(
      future: _future,
      builder: (c, snap) {
        if (snap.connectionState != ConnectionState.done) return const _Loading();
        if (snap.hasError) {
          final hasToken = ref.read(joinTokenProvider) != null;
          return _Problem(
            message: friendlyMessage(snap.error!,
                fallback: 'Não foi possível preparar a sua família. Tente de novo.'),
            onRetry: _retry,
            onSkip: hasToken
                ? () {
                    ref.read(joinTokenProvider.notifier).clear();
                    _retry();
                  }
                : null,
          );
        }
        final r = snap.data!;
        if (r.needsName && !_nameDone) {
          return NameScreen(
            profiles: ref.read(profileRepositoryProvider),
            onDone: () => setState(() => _nameDone = true),
          );
        }
        return MainFlow(key: ValueKey(r.workspaceId), workspaceId: r.workspaceId);
      },
    );
  }
}
