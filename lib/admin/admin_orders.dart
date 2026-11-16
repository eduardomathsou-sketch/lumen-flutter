import 'package:flutter/material.dart';

import '../checkout/checkout_pages.dart' show RetryNotice, errorText;
import '../checkout/commerce_api.dart';

/// Pedido como a administração vê: CPF mascarado, endereço completo e entrega.
class AdminOrder {
  AdminOrder.fromJson(Json json)
    : id = json['id'] as String,
      status = json['status'] as String,
      fulfillment = json['fulfillment_status'] as String?,
      totalCents = json['total_cents'] as int,
      subtotalCents = json['subtotal_cents'] as int? ?? json['total_cents'] as int,
      shippingCents = json['shipping_cents'] as int? ?? 0,
      discountCents = json['discount_cents'] as int? ?? 0,
      couponCode = json['coupon_code'] as String?,
      shippingLabel = json['shipping_label'] as String?,
      payerEmail = json['payer_email'] as String?,
      payerDocument = json['payer_document'] as String?,
      recipient = json['recipient'] as String? ??
          (json['address'] as Json?)?['recipient'] as String?,
      units = json['units'] as int?,
      items = (json['items'] as List? ?? const []).cast<Json>(),
      address = json['address'] as Json? ?? const {},
      payment = json['payment'] as Json?,
      trackingCode = json['tracking_code'] as String?,
      createdAt = DateTime.parse(_utc(json['created_at'] as String)).toLocal();

  static String _utc(String value) =>
      RegExp(r'(Z|[+-]\d\d:\d\d)$').hasMatch(value) ? value : '${value}Z';

  final String id, status;
  final String? fulfillment, couponCode, shippingLabel, payerEmail;
  final String? payerDocument, recipient, trackingCode;
  final int totalCents, subtotalCents, shippingCents, discountCents;
  final int? units;
  final List<Json> items;
  final Json address;
  final Json? payment;
  final DateTime createdAt;

  String get reference => id.split('-').first.toUpperCase();
  bool get awaitingPayment => status == 'awaiting_payment';
  bool get paid => status == 'paid';
  bool get testPix => awaitingPayment && payment?['provider'] == 'sandbox';

  String get when {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(createdAt.day)}/${two(createdAt.month)} '
        '${two(createdAt.hour)}:${two(createdAt.minute)}';
  }

  String get statusLabel => switch (status) {
    'awaiting_payment' => 'Aguardando pagamento',
    'paid' => switch (fulfillment) {
      'shipped' => 'Enviado',
      'delivered' => 'Entregue',
      _ => 'Pago · a preparar',
    },
    'cancelled' => 'Cancelado',
    'failed' => 'Pagamento recusado',
    'refunded' => 'Reembolsado',
    'review_required' => 'Pagamento em análise',
    _ => status,
  };
}

abstract class AdminOrdersRepository {
  Future<List<AdminOrder>> orders({String? status, String? fulfillment, int skip = 0});
  Future<AdminOrder> order(String id);
  Future<AdminOrder> confirmTestPayment(String id);
  Future<AdminOrder> advance(String id, String status, {String? trackingCode});
}

class AdminOrdersApi implements AdminOrdersRepository {
  AdminOrdersApi(this.api);
  final CommerceApi api;

  @override
  Future<List<AdminOrder>> orders({
    String? status,
    String? fulfillment,
    int skip = 0,
  }) async {
    final query = Uri(
      queryParameters: {
        'skip': '$skip',
        'limit': '20',
        'status': ?status,
        'fulfillment': ?fulfillment,
      },
    ).query;
    return (await api.adminRequest('GET', '/orders?$query') as List)
        .map((o) => AdminOrder.fromJson(o as Json))
        .toList();
  }

  @override
  Future<AdminOrder> order(String id) async => AdminOrder.fromJson(
    await api.adminRequest('GET', '/orders/${Uri.encodeComponent(id)}') as Json,
  );

  @override
  Future<AdminOrder> confirmTestPayment(String id) async => AdminOrder.fromJson(
    await api.adminRequest(
      'POST',
      '/orders/${Uri.encodeComponent(id)}/confirm-test-payment',
    ) as Json,
  );

  @override
  Future<AdminOrder> advance(
    String id,
    String status, {
    String? trackingCode,
  }) async {
    await api.adminRequest(
      'POST',
      '/orders/${Uri.encodeComponent(id)}/fulfillment',
      body: {'status': status, 'tracking_code': ?trackingCode},
    );
    return order(id);
  }
}

/// Filtros da lista: rótulo → (status, entrega).
const _filters = <String, (String?, String?)>{
  'A preparar': ('paid', 'preparing'),
  'Aguardando pagamento': ('awaiting_payment', null),
  'Enviados': ('paid', 'shipped'),
  'Entregues': ('paid', 'delivered'),
  'Todos': (null, null),
};

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key, required this.repository});
  final AdminOrdersRepository repository;
  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  String _filter = _filters.keys.first;
  List<AdminOrder> _orders = [];
  bool _busy = true, _more = false;
  String? _error;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool append = false}) async {
    final generation = ++_generation;
    setState(() {
      _busy = true;
      _error = null;
    });
    final (status, fulfillment) = _filters[_filter]!;
    try {
      final result = await widget.repository.orders(
        status: status,
        fulfillment: fulfillment,
        skip: append ? _orders.length : 0,
      );
      if (!mounted || generation != _generation) return;
      setState(() {
        _orders = append ? [..._orders, ...result] : result;
        _more = result.length == 20;
      });
    } catch (e) {
      if (mounted && generation == _generation) {
        setState(() => _error = errorText(e));
      }
    } finally {
      if (mounted && generation == _generation) setState(() => _busy = false);
    }
  }

  Future<void> _open(AdminOrder order) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AdminOrderPage(
          repository: widget.repository,
          orderId: order.id,
        ),
      ),
    );
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Administração · Pedidos'),
      actions: [
        IconButton(
          tooltip: 'Atualizar pedidos',
          onPressed: _busy ? null : () => _load(),
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              children: [
                Text(
                  'Pedidos da loja',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Confira o que foi pago, envie com o código de rastreio e marque a entrega.',
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final label in _filters.keys)
                      ChoiceChip(
                        label: Text(label),
                        selected: _filter == label,
                        onSelected: _busy
                            ? null
                            : (_) {
                                setState(() => _filter = label);
                                _load();
                              },
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                if (_busy) const LinearProgressIndicator(),
                if (_error != null) RetryNotice(_error!, () => _load()),
                if (!_busy && _error == null && _orders.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Text('Nenhum pedido aqui.'),
                  ),
                for (final order in _orders)
                  Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      title: Text('Pedido ${order.reference} · ${money(order.totalCents)}'),
                      subtitle: Text(
                        '${order.when} · ${order.recipient ?? order.payerEmail ?? ''}\n${order.statusLabel}',
                      ),
                      isThreeLine: true,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _open(order),
                    ),
                  ),
                if (_more && _error == null)
                  OutlinedButton(
                    onPressed: _busy ? null : () => _load(append: true),
                    child: const Text('CARREGAR MAIS'),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class AdminOrderPage extends StatefulWidget {
  const AdminOrderPage({
    super.key,
    required this.repository,
    required this.orderId,
  });
  final AdminOrdersRepository repository;
  final String orderId;
  @override
  State<AdminOrderPage> createState() => _AdminOrderPageState();
}

class _AdminOrderPageState extends State<AdminOrderPage> {
  final _tracking = TextEditingController();
  AdminOrder? _order;
  bool _busy = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tracking.dispose();
    super.dispose();
  }

  Future<void> _run(Future<AdminOrder> Function() action, [String? done]) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final order = await action();
      if (!mounted) return;
      setState(() => _order = order);
      if (done != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(done)));
      }
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _load() => _run(() => widget.repository.order(widget.orderId));

  Future<void> _confirmTestPayment() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar PIX de teste?'),
        content: const Text(
          'Use só para testar a loja. O pedido passa a pago e segue para preparação.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('CONFIRMAR'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await _run(
        () => widget.repository.confirmTestPayment(widget.orderId),
        'Pagamento de teste confirmado.',
      );
    }
  }

  Future<void> _ship() {
    final code = _tracking.text.trim();
    return _run(
      () => widget.repository.advance(
        widget.orderId,
        'shipped',
        trackingCode: code.isEmpty ? null : code,
      ),
      'Pedido marcado como enviado. A cliente recebe um e-mail.',
    );
  }

  Future<void> _deliver() => _run(
    () => widget.repository.advance(widget.orderId, 'delivered'),
    'Pedido marcado como entregue.',
  );

  Widget _row(String label, String value, {bool strong = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(
          value,
          style: strong ? const TextStyle(fontWeight: FontWeight.w700) : null,
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final order = _order;
    final address = order?.address ?? const {};
    String part(String key) => (address[key] as String? ?? '').trim();
    final street = [part('street'), part('number'), part('complement')]
        .where((p) => p.isNotEmpty)
        .join(', ');
    final city = [part('district'), '${part('city')}/${part('state')}', part('postal_code')]
        .where((p) => p.isNotEmpty && p != '/')
        .join(' · ');
    return Scaffold(
      appBar: AppBar(title: Text(order == null ? 'Pedido' : 'Pedido ${order.reference}')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (_busy) const LinearProgressIndicator(),
                if (_error != null)
                  RetryNotice(
                    _error!,
                    () {
                      if (order == null) {
                        _load();
                      } else {
                        setState(() => _error = null);
                      }
                    },
                  ),
                if (order != null) ...[
                  Text(order.statusLabel, style: Theme.of(context).textTheme.headlineSmall),
                  Text(order.when),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('ITENS', style: TextStyle(letterSpacing: 2, fontSize: 12)),
                          const SizedBox(height: 8),
                          for (final item in order.items)
                            _row(
                              '${item['quantity']} × ${item['name']}'
                              '${item['variant_label'] == null ? '' : ' · ${item['variant_label']}'}',
                              money((item['unit_price_cents'] as int) * (item['quantity'] as int)),
                            ),
                          const Divider(),
                          _row('Subtotal', money(order.subtotalCents)),
                          if (order.discountCents > 0)
                            _row('Cupom ${order.couponCode ?? ''}', '− ${money(order.discountCents)}'),
                          _row(order.shippingLabel ?? 'Frete', money(order.shippingCents)),
                          _row('Total', money(order.totalCents), strong: true),
                        ],
                      ),
                    ),
                  ),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('ENTREGA', style: TextStyle(letterSpacing: 2, fontSize: 12)),
                          const SizedBox(height: 8),
                          Text(order.recipient ?? ''),
                          if (street.isNotEmpty) Text(street),
                          if (city.isNotEmpty) Text(city),
                          if (order.payerEmail != null) Text(order.payerEmail!),
                          if (order.payerDocument != null) Text('CPF/CNPJ ${order.payerDocument}'),
                          if (order.trackingCode != null) ...[
                            const SizedBox(height: 8),
                            SelectableText('Rastreio: ${order.trackingCode}'),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (order.testPix)
                    FilledButton.icon(
                      onPressed: _busy ? null : _confirmTestPayment,
                      icon: const Icon(Icons.verified_outlined),
                      label: const Text('CONFIRMAR PIX DE TESTE'),
                    ),
                  if (order.paid && order.fulfillment == 'preparing') ...[
                    TextField(
                      controller: _tracking,
                      maxLength: 40,
                      decoration: const InputDecoration(
                        labelText: 'Código de rastreio (opcional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: _busy ? null : _ship,
                      icon: const Icon(Icons.local_shipping_outlined),
                      label: const Text('MARCAR COMO ENVIADO'),
                    ),
                  ],
                  if (order.paid && order.fulfillment == 'shipped')
                    FilledButton.icon(
                      onPressed: _busy ? null : _deliver,
                      icon: const Icon(Icons.inventory_outlined),
                      label: const Text('MARCAR COMO ENTREGUE'),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
