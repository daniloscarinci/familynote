import 'package:flutter/material.dart';
import '../../core/messages.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
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

  static const _gap = SizedBox(height: kButtonGap);

  Widget _passwordBody() {
    final creating = _mode == _Mode.create;
    return AutofillGroup(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        LabeledField(
          label: 'E-mail',
          child: TextField(
            key: const Key('email'),
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
          ),
        ),
        _gap,
        LabeledField(
          label: 'Senha',
          child: TextField(
            key: const Key('password'),
            controller: _password,
            obscureText: !_showPassword,
            autofillHints: [creating ? AutofillHints.newPassword : AutofillHints.password],
            onSubmitted: (_) => _busy ? null : _submitPassword(),
          ),
        ),
        _gap,
        TextButton(
          key: const Key('show-password'),
          onPressed: () => setState(() => _showPassword = !_showPassword),
          child: Text(_showPassword ? 'Esconder senha' : 'Mostrar senha'),
        ),
        _gap,
        ..._errorBlock(),
        BigButton(
          key: const Key('primary'),
          onPressed: _busy ? null : _submitPassword,
          label: _busy ? 'Aguarde...' : (creating ? 'Criar conta' : 'Entrar'),
        ),
        _gap,
        TextButton(
          key: const Key('toggle-create'),
          onPressed: _busy ? null : () => _setMode(creating ? _Mode.signIn : _Mode.create),
          child: Text(creating ? 'Já tenho conta' : 'Criar minha conta'),
        ),
        const SizedBox(height: kSectionSpacing),
        BigButton(
          key: const Key('use-code'),
          outline: true,
          onPressed: _busy ? null : () => _setMode(_Mode.code),
          label: 'Prefiro receber um código por e-mail',
        ),
      ]),
    );
  }

  List<Widget> _errorBlock() => [
        if (_error != null) ...[
          InlineMessage(_error!, kind: MessageKind.error, textKey: const Key('error')),
          _gap,
        ],
      ];

  Widget _codeBody() {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      LabeledField(
        label: 'Seu e-mail',
        child: TextField(
          controller: _email,
          enabled: !_codeSent,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
        ),
      ),
      _gap,
      if (!_codeSent) ...[
        ..._errorBlock(),
        BigButton(
          onPressed: _busy ? null : _send,
          label: _busy ? 'Aguarde...' : 'Enviar código',
        ),
      ] else ...[
        const InlineMessage('Enviamos um código para o seu e-mail.'),
        _gap,
        LabeledField(
          label: 'Código de 6 números',
          child: TextField(
            controller: _code,
            keyboardType: TextInputType.number,
            maxLength: 8,
          ),
        ),
        _gap,
        ..._errorBlock(),
        BigButton(
          onPressed: _busy ? null : _verify,
          label: _busy ? 'Aguarde...' : 'Entrar',
        ),
        _gap,
        TextButton(
          onPressed: _busy ? null : () => setState(() => _codeSent = false),
          child: const Text('Usar outro e-mail'),
        ),
      ],
      _gap,
      TextButton(
        key: const Key('use-password'),
        onPressed: _busy ? null : () => _setMode(_Mode.signIn),
        child: const Text('Voltar para entrar com senha'),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'Entrar',
      showBack: false,
      children: [
        Text('Bem-vindo ao Family Note', style: Theme.of(context).textTheme.titleMedium),
        _gap,
        if (_mode == _Mode.code) _codeBody() else _passwordBody(),
      ],
    );
  }
}
