import 'package:flutter/material.dart';

import '../checkout/checkout_pages.dart';
import 'account_controller.dart';

/// Esqueci minha senha, em dois passos na mesma tela:
/// 1) informar o e-mail (a resposta é igual com ou sem conta);
/// 2) colar o código recebido e escolher a nova senha.
class PasswordResetPage extends StatefulWidget {
  const PasswordResetPage({
    super.key,
    required this.account,
    this.initialEmail = '',
  });
  final AccountController account;
  final String initialEmail;
  @override
  State<PasswordResetPage> createState() => _PasswordResetPageState();
}

class _PasswordResetPageState extends State<PasswordResetPage> {
  final _requestForm = GlobalKey<FormState>();
  final _confirmForm = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false, _hasCode = false, _obscure = true;
  String? _error, _notice;

  @override
  void initState() {
    super.initState();
    _email.text = widget.initialEmail;
  }

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _request() async {
    if (_busy || !_requestForm.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final message = await widget.account.requestPasswordReset(_email.text);
      if (mounted) {
        setState(() {
          _notice = message;
          _hasCode = true;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (_busy || !_confirmForm.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.account.confirmPasswordReset(_code.text, _password.text);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _errorText(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16),
    child: Text(
      _error!,
      key: const ValueKey('reset-error'),
      style: TextStyle(color: Theme.of(context).colorScheme.error),
    ),
  );

  List<Widget> _requestStep(BuildContext context) => [
    Text(
      'Vamos criar uma nova senha.',
      style: Theme.of(context).textTheme.headlineMedium,
    ),
    const SizedBox(height: 12),
    const Text(
      'Informe o e-mail da sua conta. Enviaremos um código que vale por 30 minutos e funciona uma única vez.',
    ),
    const SizedBox(height: 28),
    Form(
      key: _requestForm,
      child: TextFormField(
        key: const ValueKey('reset-email'),
        controller: _email,
        enabled: !_busy,
        keyboardType: TextInputType.emailAddress,
        autofillHints: const [AutofillHints.email],
        autocorrect: false,
        decoration: const InputDecoration(
          labelText: 'E-mail',
          prefixIcon: Icon(Icons.mail_outline),
        ),
        validator: (v) =>
            RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v!.trim())
            ? null
            : 'Informe um e-mail válido.',
      ),
    ),
    if (_error != null) _errorText(context),
    const SizedBox(height: 24),
    FilledButton(
      onPressed: _busy ? null : _request,
      child: Text(_busy ? 'AGUARDE...' : 'ENVIAR CÓDIGO'),
    ),
    TextButton(
      onPressed: _busy
          ? null
          : () => setState(() {
              _hasCode = true;
              _error = null;
            }),
      child: const Text('Já tenho um código'),
    ),
  ];

  List<Widget> _confirmStep(BuildContext context) => [
    Text(
      'Confira seu e-mail.',
      style: Theme.of(context).textTheme.headlineMedium,
    ),
    const SizedBox(height: 12),
    Text(
      _notice ??
          'Cole o código que enviamos por e-mail e escolha a nova senha.',
      key: const ValueKey('reset-notice'),
    ),
    const SizedBox(height: 28),
    Form(
      key: _confirmForm,
      child: Column(
        children: [
          TextFormField(
            key: const ValueKey('reset-code'),
            controller: _code,
            enabled: !_busy,
            autocorrect: false,
            enableSuggestions: false,
            decoration: const InputDecoration(
              labelText: 'Código recebido por e-mail',
              prefixIcon: Icon(Icons.key),
            ),
            validator: (v) => v!.trim().length < 20
                ? 'Cole o código completo do e-mail.'
                : null,
          ),
          const SizedBox(height: 18),
          TextFormField(
            key: const ValueKey('reset-password'),
            controller: _password,
            enabled: !_busy,
            obscureText: _obscure,
            enableSuggestions: false,
            autocorrect: false,
            autofillHints: const [AutofillHints.newPassword],
            decoration: InputDecoration(
              labelText: 'Nova senha',
              helperText: 'De 12 a 128 caracteres. Pode usar uma frase.',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                tooltip: _obscure ? 'Mostrar senha' : 'Ocultar senha',
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: (v) => v!.length < 12 || v.length > 128
                ? 'Use de 12 a 128 caracteres.'
                : null,
          ),
          const SizedBox(height: 18),
          TextFormField(
            key: const ValueKey('reset-confirm'),
            controller: _confirm,
            enabled: !_busy,
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            decoration: const InputDecoration(labelText: 'Confirmar senha'),
            validator: (v) =>
                v != _password.text ? 'As senhas não conferem.' : null,
          ),
        ],
      ),
    ),
    const SizedBox(height: 16),
    const Text(
      'Ao salvar, sua conta é desconectada de todos os aparelhos e você entra de novo com a nova senha.',
    ),
    if (_error != null) _errorText(context),
    const SizedBox(height: 24),
    FilledButton(
      onPressed: _busy ? null : _save,
      child: Text(_busy ? 'AGUARDE...' : 'SALVAR NOVA SENHA'),
    ),
    TextButton(
      onPressed: _busy
          ? null
          : () => setState(() {
              _hasCode = false;
              _error = null;
            }),
      child: const Text('Pedir outro código'),
    ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Esqueci minha senha')),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Icon(
                Icons.lock_reset,
                size: 44,
                color: Color(0xFFD9B66A),
              ),
              const SizedBox(height: 24),
              ...(_hasCode ? _confirmStep(context) : _requestStep(context)),
            ],
          ),
        ),
      ),
    ),
  );
}
