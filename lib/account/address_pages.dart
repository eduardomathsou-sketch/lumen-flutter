import 'package:flutter/material.dart';

import '../checkout/checkout_pages.dart' show RetryNotice, errorText;
import '../checkout/commerce_api.dart';
import 'account_controller.dart';

/// Uma linha legível do endereço salvo (rua, número, bairro, cidade/UF).
String addressLine(Json a) {
  String part(String key) => (a[key] as String? ?? '').trim();
  final street = [part('street'), part('number'), part('complement')]
      .where((p) => p.isNotEmpty)
      .join(', ');
  return '$street · ${part('district')} · ${part('city')}/${part('state')}';
}

class AddressesPage extends StatefulWidget {
  const AddressesPage({super.key, required this.account});
  final AccountController account;
  @override
  State<AddressesPage> createState() => _AddressesPageState();
}

class _AddressesPageState extends State<AddressesPage> {
  List<Json> _items = [];
  bool _busy = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final items = await widget.account.addresses();
      if (mounted) setState(() => _items = items);
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit([Json? address]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddressFormPage(account: widget.account, address: address),
      ),
    );
    if (saved == true && mounted) await _load();
  }

  Future<void> _delete(Json address) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir endereço?'),
        content: Text('${address['label']} · ${addressLine(address)}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('EXCLUIR'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await widget.account.deleteAddress(address['id'] as int);
      if (mounted) await _load();
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Meus endereços')),
    floatingActionButton: _items.length < 10 && _error == null
        ? FloatingActionButton.extended(
            onPressed: _busy ? null : () => _edit(),
            icon: const Icon(Icons.add_location_alt_outlined),
            label: const Text('NOVO ENDEREÇO'),
          )
        : null,
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            children: [
              const Text('Até 10 endereços, para escolher no checkout.'),
              const SizedBox(height: 16),
              if (_busy) const LinearProgressIndicator(),
              if (_error != null) RetryNotice(_error!, () => _load()),
              if (!_busy && _error == null && _items.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Text('Nenhum endereço salvo ainda.'),
                ),
              for (final address in _items)
                Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: Icon(
                      address['is_default'] == true
                          ? Icons.home
                          : Icons.location_on_outlined,
                    ),
                    title: Text(
                      '${address['label']}${address['is_default'] == true ? ' · padrão' : ''}',
                    ),
                    subtitle: Text('${address['recipient']}\n${addressLine(address)}'),
                    isThreeLine: true,
                    onTap: () => _edit(address),
                    trailing: IconButton(
                      tooltip: 'Excluir endereço',
                      onPressed: () => _delete(address),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class AddressFormPage extends StatefulWidget {
  const AddressFormPage({super.key, required this.account, this.address});
  final AccountController account;
  final Json? address;
  @override
  State<AddressFormPage> createState() => _AddressFormPageState();
}

class _AddressFormPageState extends State<AddressFormPage> {
  static const _keys = [
    'label',
    'recipient',
    'postal_code',
    'street',
    'number',
    'complement',
    'district',
    'city',
    'state',
  ];
  final _form = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _fields = {
    for (final key in _keys)
      key: TextEditingController(
        text: widget.address?[key] as String? ?? (key == 'label' ? 'Casa' : ''),
      ),
  };
  late bool _default = widget.address?['is_default'] == true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _value(String key) => _fields[key]!.text.trim();

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.account.saveAddress({
        for (final key in _keys) key: _value(key),
        'postal_code': _value('postal_code').replaceAll(RegExp(r'\D'), ''),
        'state': _value('state').toUpperCase(),
        'is_default': _default,
      }, id: widget.address?['id'] as int?);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _field(
    String key,
    String label, {
    String? Function(String)? check,
    TextInputType? keyboard,
    int? maxLength,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      key: ValueKey('address-$key'),
      controller: _fields[key],
      enabled: !_busy,
      keyboardType: keyboard,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        counterText: '',
      ),
      validator: (value) => check?.call((value ?? '').trim()),
    ),
  );

  static String? Function(String) _min(int size, String message) =>
      (v) => v.length < size ? message : null;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.address == null ? 'Novo endereço' : 'Editar endereço'),
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _field('label', 'Nome do endereço (ex.: Casa, Trabalho)',
                    maxLength: 40, check: _min(1, 'Dê um nome ao endereço.')),
                _field('recipient', 'Quem recebe', maxLength: 120,
                    check: _min(3, 'Informe o nome de quem recebe.')),
                _field('postal_code', 'CEP', keyboard: TextInputType.number,
                    check: (v) => RegExp(r'^\d{5}-?\d{3}$').hasMatch(v)
                        ? null
                        : 'CEP com 8 números.'),
                _field('street', 'Rua', maxLength: 150,
                    check: _min(3, 'Informe a rua.')),
                _field('number', 'Número', maxLength: 20,
                    check: _min(1, 'Informe o número.')),
                _field('complement', 'Complemento (opcional)', maxLength: 100),
                _field('district', 'Bairro', maxLength: 100,
                    check: _min(2, 'Informe o bairro.')),
                _field('city', 'Cidade', maxLength: 100,
                    check: _min(2, 'Informe a cidade.')),
                _field('state', 'Estado (UF)', maxLength: 2,
                    check: (v) => RegExp(r'^[A-Za-z]{2}$').hasMatch(v)
                        ? null
                        : 'Use a sigla do estado, ex.: RN.'),
                SwitchListTile(
                  value: _default,
                  onChanged: _busy ? null : (v) => setState(() => _default = v),
                  title: const Text('Usar como endereço padrão'),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      _error!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _busy ? null : _save,
                  child: Text(_busy ? 'SALVANDO...' : 'SALVAR ENDEREÇO'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
