import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../checkout/checkout_pages.dart' show errorText;
import 'account_controller.dart';
import 'legal_pages.dart';

/// Nome e telefone (o e-mail é o login e não muda por aqui).
class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key, required this.account});
  final AccountController account;
  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(
    text: widget.account.user?['full_name'] as String? ?? '',
  );
  late final _phone = TextEditingController(
    text: widget.account.user?['phone'] as String? ?? '',
  );
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final name = _name.text.trim();
    final phone = _phone.text.replaceAll(RegExp(r'\D'), '');
    try {
      await widget.account.updateProfile(
        fullName: name.isEmpty ? null : name,
        phone: phone.isEmpty ? null : phone,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dados atualizados.')),
      );
      await Navigator.of(context).maybePop();
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Meus dados')),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  widget.account.user?['email'] as String? ?? '',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                const Text('Seu e-mail é o seu acesso e não muda por aqui.'),
                const SizedBox(height: 24),
                TextFormField(
                  key: const ValueKey('profile-name'),
                  controller: _name,
                  enabled: !_busy,
                  maxLength: 120,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nome completo',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey('profile-phone'),
                  controller: _phone,
                  enabled: !_busy,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Celular com DDD (opcional)',
                    helperText: 'Usado só para falar sobre a entrega.',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
                    if (digits.isEmpty || RegExp(r'^\d{10,11}$').hasMatch(digits)) {
                      return null;
                    }
                    return 'Informe DDD e número (10 ou 11 dígitos).';
                  },
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _error!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _busy ? null : _save,
                  child: Text(_busy ? 'SALVANDO...' : 'SALVAR'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Direitos da titular (LGPD, art. 18): comunicações, cópia dos dados e exclusão.
class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key, required this.account});
  final AccountController account;
  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  bool _busy = false;

  void _say(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _marketing(bool enabled) async {
    setState(() => _busy = true);
    try {
      await widget.account.setMarketing(enabled);
      if (mounted) {
        _say(enabled ? 'Você vai receber nossas novidades.' : 'Comunicações desligadas.');
      }
    } catch (e) {
      if (mounted) _say(errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Pede a senha; devolve null se a pessoa desistir.
  Future<String?> _askPassword(String title, String message, String action) =>
      showDialog<String>(
        context: context,
        builder: (context) => _PasswordDialog(
          title: title,
          message: message,
          action: action,
        ),
      );

  Future<void> _export() async {
    final password = await _askPassword(
      'Baixar meus dados',
      'Por segurança, confirme sua senha. A cópia vem em formato JSON e é copiada para a área de transferência.',
      'COPIAR MEUS DADOS',
    );
    if (password == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final data = await widget.account.exportData(password);
      await Clipboard.setData(
        ClipboardData(text: const JsonEncoder.withIndent('  ').convert(data)),
      );
      if (mounted) _say('Seus dados foram copiados. Cole num arquivo para guardar.');
    } catch (e) {
      if (mounted) _say(errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final password = await _askPassword(
      'Excluir minha conta',
      'Apagamos endereços, favoritos, avaliações e o cadastro. Os pedidos já feitos ficam '
          'guardados só pelo prazo legal, sem o seu nome ou e-mail. Isso não pode ser desfeito.',
      'EXCLUIR DEFINITIVAMENTE',
    );
    if (password == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.account.deleteAccount(password);
      if (!mounted) return;
      _say('Sua conta foi excluída.');
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (mounted) {
        _say(errorText(e));
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Privacidade')),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: AnimatedBuilder(
            animation: widget.account,
            builder: (context, _) => ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (_busy) const LinearProgressIndicator(),
                Card(
                  child: SwitchListTile(
                    key: const ValueKey('marketing-switch'),
                    value: widget.account.user?['marketing_opt_in'] == true,
                    onChanged: _busy ? null : _marketing,
                    title: const Text('Novidades e lembretes'),
                    subtitle: const Text(
                      'Lançamentos e um lembrete discreto da sua sacola. Os e-mails sobre seus pedidos chegam sempre.',
                    ),
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.download_outlined),
                    title: const Text('Baixar meus dados'),
                    subtitle: const Text('Conta, endereços, favoritos, avaliações e pedidos'),
                    onTap: _busy ? null : _export,
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.policy_outlined),
                    title: const Text('Política de Privacidade'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            LegalPage(account: widget.account, slug: 'privacy'),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  key: const ValueKey('delete-account'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: _busy ? null : _delete,
                  icon: const Icon(Icons.delete_forever_outlined),
                  label: const Text('EXCLUIR MINHA CONTA'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog({
    required this.title,
    required this.message,
    required this.action,
  });
  final String title, message, action;
  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _password = TextEditingController();
  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  void _confirm() {
    if (_password.text.isEmpty) return;
    Navigator.of(context).pop(_password.text);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.message),
        const SizedBox(height: 16),
        TextField(
          key: const ValueKey('confirm-password'),
          controller: _password,
          obscureText: true,
          autofocus: true,
          onSubmitted: (_) => _confirm(),
          decoration: const InputDecoration(labelText: 'Sua senha'),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('CANCELAR'),
      ),
      FilledButton(onPressed: _confirm, child: Text(widget.action)),
    ],
  );
}
