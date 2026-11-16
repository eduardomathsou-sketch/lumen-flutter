import 'package:flutter/material.dart';

import '../form_list_view.dart';
import '../checkout/checkout_pages.dart' show RetryNotice, errorText;
import '../checkout/commerce_api.dart';

/// "39,90" ou "39.90" → 3990. Null quando não é um valor válido.
int? parseCents(String value) {
  final text = value.trim().replaceAll(',', '.');
  if (!RegExp(r'^\d{1,7}(\.\d{1,2})?$').hasMatch(text)) return null;
  final parts = text.split('.');
  return int.parse(parts[0]) * 100 +
      (parts.length == 1 ? 0 : int.parse(parts[1].padRight(2, '0')));
}

String _plainMoney(int cents) =>
    '${cents ~/ 100},${(cents % 100).toString().padLeft(2, '0')}';

class AdminCoupon {
  AdminCoupon.fromJson(Json json)
    : id = json['id'] as int,
      code = json['code'] as String,
      kind = json['kind'] as String,
      value = json['value'] as int,
      minSubtotalCents = json['min_subtotal_cents'] as int? ?? 0,
      maxUses = json['max_uses'] as int?,
      usedCount = json['used_count'] as int? ?? 0,
      isActive = json['is_active'] == true,
      version = json['version'] as int? ?? 0,
      expiresAt = json['expires_at'] is String
          ? DateTime.parse(
              RegExp(r'(Z|[+-]\d\d:\d\d)$').hasMatch(json['expires_at'] as String)
                  ? json['expires_at'] as String
                  : '${json['expires_at']}Z',
            )
          : null;
  final int id, value, minSubtotalCents, usedCount, version;
  final String code, kind;
  final int? maxUses;
  final bool isActive;
  final DateTime? expiresAt;

  bool get expired => expiresAt != null && expiresAt!.isBefore(DateTime.now());
  String get discountLabel => kind == 'percent' ? '$value% de desconto' : '${money(value)} de desconto';
  String get summary => [
    if (minSubtotalCents > 0) 'compra mínima ${money(minSubtotalCents)}',
    maxUses == null ? 'usado $usedCount vezes' : 'usado $usedCount de $maxUses',
    if (expiresAt != null) 'até ${_date(expiresAt!)}',
  ].join(' · ');
  String get stateLabel => !isActive
      ? 'Pausado'
      : expired
      ? 'Vencido'
      : maxUses != null && usedCount >= maxUses!
      ? 'Esgotado'
      : 'Ativo';
}

String _date(DateTime value) {
  final d = value.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year}';
}

abstract class AdminCouponsRepository {
  Future<List<AdminCoupon>> coupons();
  Future<AdminCoupon> save(Json data, {int? id});
}

class AdminCouponsApi implements AdminCouponsRepository {
  AdminCouponsApi(this.api);
  final CommerceApi api;

  @override
  Future<List<AdminCoupon>> coupons() async =>
      (await api.adminRequest('GET', '/coupons') as List)
          .map((c) => AdminCoupon.fromJson(c as Json))
          .toList();

  @override
  Future<AdminCoupon> save(Json data, {int? id}) async => AdminCoupon.fromJson(
    await api.adminRequest(
      id == null ? 'POST' : 'PUT',
      id == null ? '/coupons' : '/coupons/$id',
      body: data,
    ) as Json,
  );
}

class AdminCouponsPage extends StatefulWidget {
  const AdminCouponsPage({super.key, required this.repository});
  final AdminCouponsRepository repository;
  @override
  State<AdminCouponsPage> createState() => _AdminCouponsPageState();
}

class _AdminCouponsPageState extends State<AdminCouponsPage> {
  List<AdminCoupon> _items = [];
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
      final items = await widget.repository.coupons();
      if (mounted) setState(() => _items = items);
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit([AdminCoupon? coupon]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            CouponFormPage(repository: widget.repository, coupon: coupon),
      ),
    );
    if (saved == true && mounted) await _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Cupons')),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _busy ? null : () => _edit(),
      icon: const Icon(Icons.add),
      label: const Text('NOVO CUPOM'),
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              if (_busy) const LinearProgressIndicator(),
              if (_error != null) RetryNotice(_error!, () => _load()),
              if (!_busy && _error == null && _items.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Nenhum cupom criado ainda.'),
                ),
              for (final coupon in _items)
                Card(
                  child: ListTile(
                    title: Text('${coupon.code} · ${coupon.discountLabel}'),
                    subtitle: Text(coupon.summary),
                    trailing: Chip(label: Text(coupon.stateLabel)),
                    onTap: () => _edit(coupon),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class CouponFormPage extends StatefulWidget {
  const CouponFormPage({super.key, required this.repository, this.coupon});
  final AdminCouponsRepository repository;
  final AdminCoupon? coupon;
  @override
  State<CouponFormPage> createState() => _CouponFormPageState();
}

class _CouponFormPageState extends State<CouponFormPage> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _code, _value, _minimum, _maxUses;
  late String _kind;
  late bool _active;
  DateTime? _expires;

  @override
  void initState() {
    super.initState();
    final c = widget.coupon;
    _code = TextEditingController(text: c?.code ?? '');
    _kind = c?.kind ?? 'percent';
    _value = TextEditingController(
      text: c == null
          ? ''
          : c.kind == 'percent'
          ? '${c.value}'
          : _plainMoney(c.value),
    );
    _minimum = TextEditingController(
      text: c == null || c.minSubtotalCents == 0
          ? ''
          : _plainMoney(c.minSubtotalCents),
    );
    _maxUses = TextEditingController(text: c?.maxUses?.toString() ?? '');
    _expires = c?.expiresAt?.toLocal();
    _active = c?.isActive ?? true;
  }

  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_code, _value, _minimum, _maxUses]) {
      c.dispose();
    }
    super.dispose();
  }

  int? get _valueNumber => _kind == 'percent'
      ? int.tryParse(_value.text.trim())
      : parseCents(_value.text);
  int get _minimumCents =>
      _minimum.text.trim().isEmpty ? 0 : (parseCents(_minimum.text) ?? -1);

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
      initialDate: _expires != null && _expires!.isAfter(now) ? _expires! : now,
    );
    if (picked != null) setState(() => _expires = picked);
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final expires = _expires;
    final current = widget.coupon;
    try {
      await widget.repository.save({
        'code': _code.text.trim().toUpperCase(),
        'kind': _kind,
        'value': _valueNumber,
        'min_subtotal_cents': _minimumCents,
        'expires_at': expires == null
            ? null
            : DateTime(expires.year, expires.month, expires.day, 23, 59, 59)
                  .toUtc()
                  .toIso8601String(),
        'max_uses': int.tryParse(_maxUses.text.trim()),
        'is_active': _active,
        if (current != null) 'version': current.version,
      }, id: current?.id);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  InputDecoration _decoration(String label, {String? helper, String? prefix}) =>
      InputDecoration(
        labelText: label,
        helperText: helper,
        prefixText: prefix,
        border: const OutlineInputBorder(),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.coupon == null ? 'Novo cupom' : 'Editar ${widget.coupon!.code}',
      ),
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Form(
            key: _form,
            child: FormListView(
              padding: const EdgeInsets.all(20),
              children: [
                TextFormField(
                  key: const ValueKey('coupon-code'),
                  controller: _code,
                  enabled: !_busy,
                  textCapitalization: TextCapitalization.characters,
                  decoration: _decoration(
                    'Código',
                    helper: 'Letras, números, - ou _ (3 a 30). Ex.: BEMVINDA10',
                  ),
                  validator: (v) =>
                      RegExp(r'^[A-Za-z0-9_-]{3,30}$').hasMatch(v!.trim())
                      ? null
                      : 'Use de 3 a 30 letras, números, - ou _.',
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Porcentagem'),
                      selected: _kind == 'percent',
                      onSelected: _busy ? null : (_) => setState(() => _kind = 'percent'),
                    ),
                    ChoiceChip(
                      key: const ValueKey('coupon-fixed'),
                      label: const Text('Valor fixo'),
                      selected: _kind == 'fixed',
                      onSelected: _busy ? null : (_) => setState(() => _kind = 'fixed'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const ValueKey('coupon-value'),
                  controller: _value,
                  enabled: !_busy,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: _kind == 'percent'
                      ? _decoration('Desconto (%)', helper: 'De 1 a 90')
                      : _decoration('Desconto', prefix: 'R\$ '),
                  validator: (_) {
                    final value = _valueNumber;
                    if (_kind == 'percent') {
                      return value != null && value >= 1 && value <= 90
                          ? null
                          : 'Porcentagem de 1 a 90.';
                    }
                    return value != null && value > 0 ? null : 'Informe o valor, ex.: 20,00.';
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey('coupon-minimum'),
                  controller: _minimum,
                  enabled: !_busy,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: _decoration(
                    'Compra mínima (opcional)',
                    prefix: 'R\$ ',
                  ),
                  validator: (_) {
                    final minimum = _minimumCents;
                    if (minimum < 0) return 'Valor inválido, ex.: 150,00.';
                    // O total nunca pode chegar a R$ 0,00 (o PIX não aceita).
                    if (_kind == 'fixed' && minimum <= (_valueNumber ?? 0)) {
                      return 'Para valor fixo, a compra mínima precisa ser maior que o desconto.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _maxUses,
                  enabled: !_busy,
                  keyboardType: TextInputType.number,
                  decoration: _decoration(
                    'Limite de usos (opcional)',
                    helper: 'Em branco = sem limite',
                  ),
                  validator: (v) {
                    if (v!.trim().isEmpty) return null;
                    final n = int.tryParse(v.trim());
                    return n != null && n >= 1 && n <= 1000000 ? null : 'Número inteiro a partir de 1.';
                  },
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_outlined),
                  title: Text(
                    _expires == null
                        ? 'Sem data de validade'
                        : 'Válido até ${_date(_expires!)}',
                  ),
                  trailing: _expires == null
                      ? TextButton(onPressed: _busy ? null : _pickDate, child: const Text('DEFINIR'))
                      : TextButton(
                          onPressed: _busy ? null : () => setState(() => _expires = null),
                          child: const Text('REMOVER'),
                        ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _active,
                  onChanged: _busy ? null : (v) => setState(() => _active = v),
                  title: const Text('Cupom ativo'),
                  subtitle: const Text('Desligue para pausar sem apagar.'),
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
                  child: Text(_busy ? 'SALVANDO...' : 'SALVAR CUPOM'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
