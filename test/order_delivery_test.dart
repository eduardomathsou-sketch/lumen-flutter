import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumen_store/checkout/checkout_pages.dart';
import 'package:lumen_store/checkout/commerce_api.dart';

import 'checkout_test.dart' show FakeCommerce, orderJson;

class DeliveryCommerce extends FakeCommerce implements OrderReturns {
  String fulfillment = 'delivered';
  Json? requested;

  @override
  Future<StoreOrder> order(String id) async => StoreOrder.fromJson({
    ...orderJson(status: 'paid'),
    'fulfillment_status': fulfillment,
    'tracking_code': 'BR123456789BR',
    'shipped_at': '2026-11-10T12:00:00Z',
    'delivered_at': fulfillment == 'delivered' ? '2026-11-12T12:00:00Z' : null,
  });

  @override
  Future<ReturnInfo> returnInfo(String orderId) async => ReturnInfo.fromJson({
    'eligible': true,
    'reasons': {
      'arrependimento': '2026-11-19T12:00:00Z',
      'defeito': '2027-02-10T12:00:00Z',
    },
    'request': requested == null ? null : {'status': 'requested', ...requested!},
  });

  @override
  Future<ReturnInfo> requestReturn(
    String orderId,
    String reason,
    String details,
  ) async {
    requested = {'reason': reason, 'details': details};
    return returnInfo(orderId);
  }
}

void tall(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('shipped order shows tracking and no return yet', (tester) async {
    tall(tester);
    final repo = DeliveryCommerce()..fulfillment = 'shipped';
    await tester.pumpWidget(
      MaterialApp(home: OrderPage(orderId: '12345678-order', repository: repo)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Enviado'), findsOneWidget);
    expect(find.textContaining('BR123456789BR'), findsOneWidget);
    expect(find.text('SOLICITAR DEVOLUÇÃO'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('delivered order requests a return with a chosen reason', (
    tester,
  ) async {
    tall(tester);
    final repo = DeliveryCommerce();
    await tester.pumpWidget(
      MaterialApp(home: OrderPage(orderId: '12345678-order', repository: repo)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('SOLICITAR DEVOLUÇÃO'));
    await tester.pumpAndSettle();

    final send = find.widgetWithText(FilledButton, 'ENVIAR');
    expect(tester.widget<FilledButton>(send).onPressed, isNull);
    await tester.tap(find.byKey(const ValueKey('return-defeito')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('return-details')),
      ' Costura soltando ',
    );
    await tester.tap(send);
    await tester.pumpAndSettle();

    expect(repo.requested, {'reason': 'defeito', 'details': 'Costura soltando'});
    expect(
      find.text('Solicitação enviada · aguardando a loja'),
      findsOneWidget,
    );
    expect(find.text('SOLICITAR DEVOLUÇÃO'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('orders list shows the delivery stage', (tester) async {
    final repo = DeliveryCommerce();
    await tester.pumpWidget(MaterialApp(home: OrdersPage(repository: repo)));
    await tester.pumpAndSettle();
    expect(find.textContaining('Entregue ·'), findsOneWidget);
  });
}
