import 'package:flutter/material.dart';
import '../../core/messages.dart';
import '../../data/auth_repository.dart';

enum _Mode { signIn, create, code }

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key, required this.auth});
  final AuthRepository auth;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _code = TextEditingController();
  _Mode _mode = _Mode.signIn;
  bool _codeSent = false;
  bool _busy = false;
  bool _showPassword = false;
  String? _error;

  static const _bigText = TextStyle(fontSize: 18);
  static final _bigButton = ElevatedButton.styleFrom(
    minimumSize: const Size.fromHeight(56),
    textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
  );
  static final _bigTextButton = TextButton.styleFrom(
    minimumSize: const Size.fromHeight(56),
    textStyle: const TextStyle(fontSize: 18),
  );

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _code.dispose();
    super.dispose();
  }

  void _setMode(_Mode m) => setState(() {
        _mode = m;
        _error = null;
        _codeSent = false;
      });

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

  bool _emailOk() {
    if (_email.text.trim().contains('@')) return true;
    setState(() => _error = 'Escreva o seu e-mail completo.');
    return false;
  }

  Future<void> _submitPassword() async {
    if (!_emailOk()) return;
    final email = _email.text.trim();
    final pw = _password.text;
    if (pw.length < 6) {
      setState(() => _error = 'A senha precisa ter pelo menos 6 caracteres.');
      return;
    }
    final creating = _mode == _Mode.create;
    await _run(
      () => creating
          ? widget.auth.signUpWithPassword(email, pw)
          : widget.auth.signInWithPassword(email, pw),
      'Não foi possível entrar. Confira o e-mail, a senha e a internet.',
    );
  }

  Future<void> _send() async {
    if (!_emailOk()) return;
    await _run(() async {
      await widget.auth.sendCode(_email.text.trim());
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

  Widget _passwordBody() {
    final creating = _mode == _Mode.create;
    return AutofillGroup(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextField(
          key: const Key('email'),
          controller: _email,
          style: _bigText,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: const InputDecoration(labelText: 'E-mail'),
        ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('password'),
          controller: _password,
          style: _bigText,
          obscureText: !_showPassword,
          autofillHints: [creating ? AutofillHints.newPassword : AutofillHints.password],
          decoration: const InputDecoration(labelText: 'Senha'),
          onSubmitted: (_) => _busy ? null : _submitPassword(),
        ),
        const SizedBox(height: 8),
        TextButton(
          key: const Key('show-password'),
          onPressed: () => setState(() => _showPassword = !_showPassword),
          style: _bigTextButton,
          child: Text(_showPassword ? 'Esconder senha' : 'Mostrar senha'),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          key: const Key('primary'),
          onPressed: _busy ? null : _submitPassword,
          style: _bigButton,
          child: Text(_busy ? 'Aguarde...' : (creating ? 'Criar conta' : 'Entrar')),
        ),
        const SizedBox(height: 8),
        TextButton(
          key: const Key('toggle-create'),
          onPressed: _busy ? null : () => _setMode(creating ? _Mode.signIn : _Mode.create),
          style: _bigTextButton,
          child: Text(creating ? 'Já tenho conta' : 'Criar minha conta'),
        ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 8),
        OutlinedButton(
          key: const Key('use-code'),
          onPressed: _busy ? null : () => _setMode(_Mode.code),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            textStyle: const TextStyle(fontSize: 18),
          ),
          child: const Text('Prefiro receber um código por e-mail'),
        ),
      ]),
    );
  }

  Widget _codeBody() {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      TextField(
        controller: _email,
        enabled: !_codeSent,
        style: _bigText,
        keyboardType: TextInputType.emailAddress,
        autofillHints: const [AutofillHints.email],
        decoration: const InputDecoration(labelText: 'Seu e-mail'),
      ),
      const SizedBox(height: 16),
      if (!_codeSent)
        ElevatedButton(
          onPressed: _busy ? null : _send,
          style: _bigButton,
          child: Text(_busy ? 'Aguarde...' : 'Enviar código'),
        )
      else ...[
        const Text('Enviamos um código para o seu e-mail.', style: _bigText),
        const SizedBox(height: 16),
        TextField(
          controller: _code,
          style: _bigText,
          keyboardType: TextInputType.number,
          maxLength: 8,
          decoration: const InputDecoration(labelText: 'Código de 6 números'),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _busy ? null : _verify,
          style: _bigButton,
          child: Text(_busy ? 'Aguarde...' : 'Entrar'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _busy ? null : () => setState(() => _codeSent = false),
          style: _bigTextButton,
          child: const Text('Usar outro e-mail'),
        ),
      ],
      const SizedBox(height: 16),
      TextButton(
        key: const Key('use-password'),
        onPressed: _busy ? null : () => _setMode(_Mode.signIn),
        style: _bigTextButton,
        child: const Text('Voltar para entrar com senha'),
      ),
    ]);
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
          if (_mode == _Mode.code) _codeBody() else _passwordBody(),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!,
                key: const Key('error'),
                style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.error)),
          ],
        ],
      ),
    );
  }
}
