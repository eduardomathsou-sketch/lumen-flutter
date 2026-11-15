import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumen_store/admin/admin_orders.dart';
import 'package:lumen_store/checkout/commerce_api.dart';

Json orderJson({
  String status = 'awaiting_payment',
  String? fulfillment,
  String? tracking,
}) => {
  'id': 'abcd1234-0000-0000-0000-000000000000',
  'status': status,
  'fulfillment_status': fulfillment,
  'total_cents': 9480,
  'subtotal_cents': 7980,
  'shipping_cents': 1500,
  'discount_cents': 0,
  'shipping_label': 'Entrega padrão',
  'payer_email': 'cliente@example.com',
  'payer_document': '***.***.***-25',
  'items': [
    {'name': 'Vestido Aura', 'variant_label': 'M · Champagne', 'quantity': 2, 'unit_price_cents': 3990},
  ],
  'address': {
    'recipient': 'Cliente Lumen',
    'street': 'Rua das Flores',
    'number': '10',
    'district': 'Centro',
    'city': 'Natal',
    'state': 'RN',
    'postal_code': '59000000',
  },
  'payment': {'provider': 'sandbox', 'status': 'pending'},
  'tracking_code': tracking,
  'created_at': '2026-11-14T15:30:00Z',
};

class FakeOrdersAdmin implements AdminOrdersRepository {
  Json current = orderJson();
  final filters = <(String?, String?)>[];
  final actions = <String>[];

  @override
  Future<List<AdminOrder>> orders({
    String? status,
    String? fulfillment,
    int skip = 0,
  }) async {
    filters.add((status, fulfillment));
    return [AdminOrder.fromJson(current)];
  }

  @override
  Future<AdminOrder> order(String id) async => AdminOrder.fromJson(current);

  @override
  Future<AdminOrder> confirmTestPayment(String id) async {
    actions.add('confirm');
    current = orderJson(status: 'paid', fulfillment: 'preparing');
    return AdminOrder.fromJson(current);
  }

  @override
  Future<AdminOrder> advance(
    String id,
    String status, {
    String? trackingCode,
  }) async {
    actions.add('$status:${trackingCode ?? ''}');
    current = orderJson(status: 'paid', fulfillment: status, tracking: trackingCode);
    return AdminOrder.fromJson(current);
  }
}

/// Espera o aviso de confirmação sumir (ele fica sobre os botões do fim da tela).
Future<void> waitSnackBar(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lists orders by filter', (tester) async {
    final repo = FakeOrdersAdmin();
    await tester.pumpWidget(MaterialApp(home: AdminOrdersPage(repository: repo)));
    await tester.pumpAndSettle();
    expect(find.text('Pedido ABCD1234 · R\$ 94,80'), findsOneWidget);
    expect(repo.filters.last, ('paid', 'preparing'));

    await tester.tap(find.text('Aguardando pagamento'));
    await tester.pumpAndSettle();
    expect(repo.filters.last, ('awaiting_payment', null));
  });

  testWidgets('confirms a test PIX, ships with tracking and delivers', (
    tester,
  ) async {
    final repo = FakeOrdersAdmin();
    await tester.pumpWidget(
      MaterialApp(
        home: AdminOrderPage(repository: repo, orderId: repo.current['id'] as String),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Aguardando pagamento'), findsOneWidget);
    expect(find.text('2 × Vestido Aura · M · Champagne'), findsOneWidget);
    expect(find.text('CPF/CNPJ ***.***.***-25'), findsOneWidget);

    await tester.ensureVisible(find.text('CONFIRMAR PIX DE TESTE'));
    await tester.tap(find.text('CONFIRMAR PIX DE TESTE'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CONFIRMAR'));
    await tester.pumpAndSettle();
    expect(repo.actions, ['confirm']);
    expect(find.text('Pago · a preparar'), findsOneWidget);
    await waitSnackBar(tester);

    await tester.ensureVisible(find.byType(TextField));
    await tester.enterText(find.byType(TextField), ' BR123456789BR ');
    await tester.ensureVisible(find.text('MARCAR COMO ENVIADO'));
    await tester.tap(find.text('MARCAR COMO ENVIADO'));
    await tester.pumpAndSettle();
    expect(repo.actions.last, 'shipped:BR123456789BR');
    expect(find.text('Enviado'), findsOneWidget);
    expect(find.text('Rastreio: BR123456789BR'), findsOneWidget);
    await waitSnackBar(tester);

    await tester.ensureVisible(find.text('MARCAR COMO ENTREGUE'));
    await tester.tap(find.text('MARCAR COMO ENTREGUE'));
    await tester.pumpAndSettle();
    expect(repo.actions.last, 'delivered:');
    expect(find.text('Entregue'), findsOneWidget);
  });
}
