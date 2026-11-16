import 'package:flutter/material.dart';

import '../checkout/checkout_pages.dart';
import '../checkout/commerce_api.dart';
import 'account_controller.dart';

/// A API manda datas em UTC; o SQLite de desenvolvimento omite o "Z".
DateTime? parseServerDate(Object? value) {
  if (value is! String || value.isEmpty) return null;
  final text = RegExp(r'(Z|[+-]\d\d:\d\d)$').hasMatch(value)
      ? value
      : '${value}Z';
  return DateTime.tryParse(text)?.toLocal();
}

String shortDate(DateTime date) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(date.day)}/${two(date.month)} às ${two(date.hour)}:${two(date.minute)}';
}

/// Segurança da conta: trocar a senha e ver onde a conta está aberta.
/// Cada login cria um código de acesso próprio; encerrar um aparelho apaga o
/// código dele no servidor, e ele deixa de valer na hora.
class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key, required this.account});
  final AccountController account;
  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false, _closingOthers = false;
  String? _passwordError, _devicesError;
  List<Json>? _devices;
  final Set<String> _revoking = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _say(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  /// 401 aqui significa que este aparelho foi desconectado em outro lugar.
  Future<bool> _ended(Object error) async {
    if (error is! CommerceException || error.status != 401) return false;
    await widget.account.sessionEnded();
    if (mounted) Navigator.pop(context);
    return true;
  }

  Future<void> _load() async {
    setState(() => _devicesError = null);
    try {
      final devices = await widget.account.sessions();
      if (mounted) setState(() => _devices = devices);
    } catch (e) {
      if (await _ended(e)) return;
      if (mounted) setState(() => _devicesError = errorText(e));
    }
  }

  Future<void> _changePassword() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _passwordError = null;
    });
    try {
      await widget.account.changePassword(_current.text, _next.text);
      if (!mounted) return;
      _current.clear();
      _next.clear();
      _confirm.clear();
      _say('Senha alterada. Os outros aparelhos foram desconectados.');
      await _load();
    } catch (e) {
      // Senha atual errada também responde 401; aqui não é sessão encerrada.
      if (mounted) setState(() => _passwordError = errorText(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _revoke(Json device) async {
    final id = device['id'] as String?;
    if (id == null || _revoking.contains(id)) return;
    setState(() => _revoking.add(id));
    try {
      await widget.account.revokeSession(id);
      _say('Aparelho desconectado.');
      await _load();
    } catch (e) {
      if (await _ended(e)) return;
      _say(errorText(e));
    } finally {
      if (mounted) setState(() => _revoking.remove(id));
    }
  }

  Future<void> _closeOthers() async {
    if (_closingOthers) return;
    setState(() => _closingOthers = true);
    try {
      await widget.account.logoutOthers();
      _say('Pronto. Só este aparelho continua conectado.');
      await _load();
    } catch (e) {
      if (await _ended(e)) return;
      _say(errorText(e));
    } finally {
      if (mounted) setState(() => _closingOthers = false);
    }
  }

  String _deviceDetail(Json device) {
    if (device['current'] == true) return 'Este aparelho';
    final used = parseServerDate(device['last_used_at']);
    return used == null
        ? 'Conectado'
        : 'Usado por último em ${shortDate(used)}';
  }

  Widget _passwordField(
    String key,
    String label,
    TextEditingController controller,
    String? Function(String?) validator, {
    String? helper,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: TextFormField(
      key: ValueKey(key),
      controller: controller,
      enabled: !_saving,
      obscureText: true,
      enableSuggestions: false,
      autocorrect: false,
      decoration: InputDecoration(labelText: label, helperText: helper),
      validator: validator,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final devices = _devices;
    final others = devices?.where((d) => d['current'] != true).length ?? 0;
    return Scaffold(
      appBar: AppBar(title: const Text('Segurança')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'Alterar senha',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Form(
                  key: _form,
                  child: Column(
                    children: [
                      _passwordField(
                        'security-current',
                        'Senha atual',
                        _current,
                        (v) => v!.isEmpty ? 'Informe a senha atual.' : null,
                      ),
                      _passwordField(
                        'security-new',
                        'Nova senha',
                        _next,
                        (v) => v!.length < 12 || v.length > 128
                            ? 'Use de 12 a 128 caracteres.'
                            : null,
                        helper: 'De 12 a 128 caracteres. Pode usar uma frase.',
                      ),
                      _passwordField(
                        'security-confirm',
                        'Confirmar nova senha',
                        _confirm,
                        (v) =>
                            v != _next.text ? 'As senhas não conferem.' : null,
                      ),
                    ],
                  ),
                ),
                if (_passwordError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _passwordError!,
                      key: const ValueKey('security-error'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                FilledButton(
                  onPressed: _saving ? null : _changePassword,
                  child: Text(_saving ? 'AGUARDE...' : 'ALTERAR SENHA'),
                ),
                const SizedBox(height: 40),
                Text(
                  'Aparelhos conectados',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Onde sua conta está aberta agora. Não reconhece algum? Desconecte e troque a senha.',
                ),
                const SizedBox(height: 16),
                if (_devicesError != null)
                  RetryNotice(_devicesError!, _load)
                else if (devices == null)
                  const LinearProgressIndicator()
                else
                  for (final device in devices)
                    Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Icon(
                          device['current'] == true
                              ? Icons.check_circle
                              : Icons.lock_outline,
                        ),
                        title: Text(device['device'] as String? ?? 'Aparelho'),
                        subtitle: Text(_deviceDetail(device)),
                        trailing: device['current'] == true
                            ? null
                            : TextButton(
                                onPressed: _revoking.contains(device['id'])
                                    ? null
                                    : () => _revoke(device),
                                child: const Text('DESCONECTAR'),
                              ),
                      ),
                    ),
                if (others > 0) ...[
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _closingOthers ? null : _closeOthers,
                    child: const Text('DESCONECTAR OS OUTROS APARELHOS'),
                  ),
                ],
                const SizedBox(height: 24),
                const Text(
                  'Por segurança, cada conexão vale por até 7 dias. Depois disso é preciso entrar de novo.',
                  style: TextStyle(color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
