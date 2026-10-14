import 'package:flutter/material.dart';
import '../../core/messages.dart';
import '../../data/auth_repository.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key, required this.auth});
  final AuthRepository auth;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  bool _codeSent = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action, String errorText) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) setState(() => _error = friendlyMessage(e, fallback: errorText));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _send() async {
    final email = _email.text.trim();
    if (!email.contains('@')) {
      setState(() => _error = 'Escreva o seu e-mail completo.');
      return;
    }
    await _run(() async {
      await widget.auth.sendCode(email);
      if (mounted) setState(() => _codeSent = true);
    }, 'Não foi possível enviar o código. Confira o e-mail e a internet.');
  }

  Future<void> _verify() async {
    final code = _code.text.trim();
    if (code.length < 6) {
      setState(() => _error = 'Escreva o código de 6 números que chegou no e-mail.');
      return;
    }
    await _run(() => widget.auth.verifyCode(_email.text.trim(), code),
        'Código incorreto ou vencido. Tente de novo.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Entrar')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Bem-vindo ao Family Note', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _email,
            enabled: !_codeSent,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(labelText: 'Seu e-mail'),
          ),
          const SizedBox(height: 16),
          if (!_codeSent)
            ElevatedButton(
              onPressed: _busy ? null : _send,
              child: const Text('Enviar código'),
            )
          else ...[
            const Text('Enviamos um código para o seu e-mail.'),
            const SizedBox(height: 16),
            TextField(
              controller: _code,
              keyboardType: TextInputType.number,
              maxLength: 8,
              decoration: const InputDecoration(labelText: 'Código de 6 números'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _busy ? null : _verify,
              child: const Text('Entrar'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _busy ? null : () => setState(() => _codeSent = false),
              style: TextButton.styleFrom(minimumSize: const Size.fromHeight(56)),
              child: const Text('Usar outro e-mail'),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!,
                key: const Key('error'),
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ],
      ),
    );
  }
}
