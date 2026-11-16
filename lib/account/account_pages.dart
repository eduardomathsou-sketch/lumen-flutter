import 'package:flutter/material.dart';

import '../form_list_view.dart';
import '../checkout/checkout_pages.dart';
import '../admin/admin_api.dart';
import '../admin/admin_coupons.dart';
import '../admin/admin_orders.dart';
import '../admin/admin_pages.dart';
import 'account_controller.dart';
import 'address_pages.dart';
import 'legal_pages.dart';
import 'password_pages.dart';
import 'privacy_pages.dart';
import 'security_pages.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    super.key,
    required this.account,
    required this.onOrders,
    this.onCatalogChanged,
  });
  final AccountController account;
  final VoidCallback onOrders;
  final VoidCallback? onCatalogChanged;
  Future<void> _legal(BuildContext context, String slug) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => LegalPage(account: account, slug: slug),
        ),
      );

  Future<void> _auth(BuildContext context, bool register) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AuthPage(account: account, register: register),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: account,
    builder: (context, _) => ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'MINHA CONTA',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.4,
            color: Color(0xFF444444),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Seu espaço Lumen',
          style: TextStyle(fontFamily: 'Bodoni', fontSize: 34, height: 1.1),
        ),
        const SizedBox(height: 8),
        const Text(
          'Sua conta, seus favoritos, suas escolhas.',
          style: TextStyle(color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 32),
        if (account.loading)
          const LinearProgressIndicator()
        else if (account.error != null)
          RetryNotice(account.error!, account.initialize),
        const CircleAvatar(
          radius: 38,
          child: Icon(Icons.person_outline, size: 40),
        ),
        const SizedBox(height: 18),
        Text(
          account.user?['email'] as String? ?? 'Bem-vinda à Lumen',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 24),
        if (account.user == null) ...[
          const Text(
            'Entre para acessar sua sacola, seus pedidos e favoritos em outros aparelhos.',
            textAlign: TextAlign.center,
            style: TextStyle(height: 1.5),
          ),
          const SizedBox(height: 24),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: account.loading ? null : () => _auth(context, false),
            child: const Text('ENTRAR'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: account.loading ? null : () => _auth(context, true),
            child: const Text('CRIAR CONTA'),
          ),
        ],
        const SizedBox(height: 32),
        Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 8,
            ),
            leading: const Icon(Icons.receipt_long_outlined),
            title: const Text('Meus pedidos'),
            subtitle: Text(
              account.user == null
                  ? 'Compras desta sessão'
                  : 'Acompanhe suas compras',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: onOrders,
          ),
        ),
        if (account.user != null) ...[
          if (!account.termsCurrent) ...[
            const SizedBox(height: 12),
            Card(
              key: const ValueKey('terms-renewal'),
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Atualizamos os Termos de Uso e a Política de Privacidade. Leia e aceite para continuar.',
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        TextButton(
                          onPressed: () => _legal(context, 'terms'),
                          child: const Text('Ler os Termos'),
                        ),
                        TextButton(
                          onPressed: () => _legal(context, 'privacy'),
                          child: const Text('Ler a Política'),
                        ),
                        FilledButton(
                          onPressed: () async {
                            try {
                              await account.acceptTerms();
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(errorText(e))),
                                );
                              }
                            }
                          },
                          child: const Text('LI E ACEITO'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (account.isAdmin) ...[
            const SizedBox(height: 12),
            Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                leading: const Icon(Icons.storefront_outlined),
                title: const Text('Administrar loja'),
                subtitle: const Text('Produtos, categorias e estoque'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          AdminCatalogPage(repository: AdminApi(account.api)),
                    ),
                  );
                  onCatalogChanged?.call();
                },
              ),
            ),
            const SizedBox(height: 12),
            Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                leading: const Icon(Icons.receipt_long_outlined),
                title: const Text('Pedidos da loja'),
                subtitle: const Text('Pagamento, envio e entrega'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => AdminOrdersPage(
                      repository: AdminOrdersApi(account.api),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                leading: const Icon(Icons.local_offer_outlined),
                title: const Text('Cupons'),
                subtitle: const Text('Criar, pausar e acompanhar o uso'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => AdminCouponsPage(
                      repository: AdminCouponsApi(account.api),
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
              leading: const Icon(Icons.lock_outline),
              title: const Text('Segurança'),
              subtitle: const Text('Senha e aparelhos conectados'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => SecurityPage(account: account),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
              leading: const Icon(Icons.location_on_outlined),
              title: const Text('Meus endereços'),
              subtitle: const Text('Para escolher no checkout'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => AddressesPage(account: account),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
              leading: const Icon(Icons.person_outline),
              title: const Text('Meus dados'),
              subtitle: const Text('Nome e celular'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ProfileEditPage(account: account),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Privacidade'),
              subtitle: const Text('Comunicações, cópia dos dados e exclusão da conta'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PrivacyPage(account: account),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Sua sessão dura até 7 dias. Ao sair, seus pedidos e favoritos continuam salvos na conta.',
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            icon: const Icon(Icons.logout),
            label: const Text('SAIR DA CONTA'),
            onPressed: () async {
              final yes = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Sair da conta?'),
                  content: const Text(
                    'Você pode entrar novamente a qualquer momento.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('VOLTAR'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('SAIR'),
                    ),
                  ],
                ),
              );
              if (yes != true) return;
              try {
                await account.logout();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(errorText(e))));
                }
              }
            },
          ),
        ],
        const SizedBox(height: 32),
        const Divider(),
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            for (final entry in legalTitles.entries)
              TextButton(
                onPressed: () => _legal(context, entry.key),
                child: Text(entry.value),
              ),
          ],
        ),
      ],
    ),
  );
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, required this.account, this.register = false});
  final AccountController account;
  final bool register;
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  late bool _register;
  bool _busy = false, _obscure = true;
  bool _acceptTerms = false, _marketing = false, _termsError = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _register = widget.register;
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _openLegal(String slug) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => LegalPage(account: widget.account, slug: slug),
    ),
  );

  Future<void> _forgotPassword() async {
    final changed = await Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (_) => PasswordResetPage(
          account: widget.account,
          initialEmail: _email.text.trim(),
        ),
      ),
    );
    if (changed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Senha alterada. Entre com a nova senha.'),
        ),
      );
    }
  }

  Future<void> _submit() async {
    if (_busy) return;
    final valid = _form.currentState!.validate();
    // O aceite é explícito: sem marcar a caixa, o cadastro não é enviado.
    final missingTerms = _register && !_acceptTerms;
    if (missingTerms != _termsError) setState(() => _termsError = missingTerms);
    if (!valid || missingTerms) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.account.signIn(
        _email.text,
        _password.text,
        _register,
        acceptTerms: _acceptTerms,
        marketing: _marketing,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(_register ? 'Criar conta' : 'Entrar na Lumen')),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Form(
            key: _form,
            child: AutofillGroup(
              child: FormListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const Icon(
                    Icons.auto_awesome_outlined,
                    size: 44,
                    color: Color(0xFFCBA96B),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _register
                        ? 'Sua essência tem lugar aqui.'
                        : 'Que bom ter você de volta.',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _register
                        ? 'Cadastre seu e-mail e uma senha para guardar suas escolhas.'
                        : 'Entre com seu e-mail e senha para continuar.',
                  ),
                  const SizedBox(height: 28),
                  TextFormField(
                    key: const ValueKey('auth-email'),
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
                        RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                            .hasMatch(v!.trim())
                        ? null
                        : 'Informe um e-mail válido.',
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    key: const ValueKey('auth-password'),
                    controller: _password,
                    enabled: !_busy,
                    obscureText: _obscure,
                    enableSuggestions: false,
                    autocorrect: false,
                    autofillHints: [
                      _register
                          ? AutofillHints.newPassword
                          : AutofillHints.password,
                    ],
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      helperText:
                          'De 12 a 128 caracteres. Pode usar uma frase.',
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
                  if (_register) ...[
                    const SizedBox(height: 18),
                    TextFormField(
                      key: const ValueKey('auth-confirm'),
                      controller: _confirm,
                      enabled: !_busy,
                      obscureText: true,
                      enableSuggestions: false,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'Confirmar senha',
                      ),
                      validator: (v) => v != _password.text
                          ? 'As senhas não conferem.'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      key: const ValueKey('auth-terms'),
                      value: _acceptTerms,
                      onChanged: _busy
                          ? null
                          : (v) => setState(() {
                              _acceptTerms = v ?? false;
                              if (_acceptTerms) _termsError = false;
                            }),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Li e aceito os Termos de Uso e a Política de Privacidade.',
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        TextButton(
                          onPressed: () => _openLegal('terms'),
                          child: const Text('Ler os Termos'),
                        ),
                        TextButton(
                          onPressed: () => _openLegal('privacy'),
                          child: const Text('Ler a Política'),
                        ),
                      ],
                    ),
                    if (_termsError)
                      Text(
                        'Para criar a conta, aceite os Termos de Uso e a Política de Privacidade.',
                        key: const ValueKey('auth-terms-error'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    CheckboxListTile(
                      key: const ValueKey('auth-marketing'),
                      value: _marketing,
                      onChanged: _busy
                          ? null
                          : (v) => setState(() => _marketing = v ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Quero receber novidades e lembretes da Lumen por e-mail.',
                      ),
                      subtitle: const Text(
                        'Opcional. Você pode desligar quando quiser.',
                      ),
                    ),
                  ] else
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        key: const ValueKey('auth-forgot'),
                        onPressed: _busy ? null : _forgotPassword,
                        child: const Text('Esqueci minha senha'),
                      ),
                    ),
                  const SizedBox(height: 20),
                  const Text(
                    'No primeiro acesso, a sacola atual fica vinculada à conta. Se você já tem uma sacola na conta, ela será retomada.',
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        _error!,
                        key: const ValueKey('auth-error'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: Text(
                      _busy
                          ? 'AGUARDE...'
                          : _register
                          ? 'CADASTRAR'
                          : 'ENTRAR',
                    ),
                  ),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                            _register = !_register;
                            _error = null;
                            _acceptTerms = false;
                            _marketing = false;
                            _termsError = false;
                            _form.currentState!.reset();
                          }),
                    child: Text(
                      _register
                          ? 'Já tenho uma conta'
                          : 'Ainda não tenho conta',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
