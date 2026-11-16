import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumen_store/checkout/checkout_pages.dart';
import 'package:lumen_store/checkout/commerce_api.dart';

import 'checkout_test.dart' show FakeCommerce, fillCheckout;

/// Só LUMEN10 existe (10% de R$ 79,80); qualquer outro código é recusado como na API.
class CouponCommerce extends FakeCommerce {
  final asked = <String?>[];
  @override
  Future<CheckoutQuote> quote({String? postalCode, String? coupon}) async {
    asked.add(coupon);
    if (coupon != null && coupon != 'LUMEN10') {
      throw const CommerceException('Cupom inválido.', 422);
    }
    return CheckoutQuote.fromJson({
      ...data,
      'shipping_cents': 1500,
      'total_cents': coupon == null ? 9480 : 8682,
      'discount_cents': coupon == null ? 0 : 798,
      'coupon_code': coupon,
      'shipping_label': 'Entrega padrão',
      'shipping_days': 7,
    });
  }
}

Future<void> reveal(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    150,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('invalid coupon is refused; valid coupon goes into the order', (
    tester,
  ) async {
    final repo = CouponCommerce();
    await tester.pumpWidget(MaterialApp(home: CheckoutPage(repository: repo)));
    await tester.pumpAndSettle();
    await fillCheckout(tester);

    await reveal(tester, find.text('Tem um cupom?'));
    await tester.tap(find.text('Tem um cupom?'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('coupon')), 'chute1');
    await reveal(tester, find.text('APLICAR'));
    await tester.tap(find.text('APLICAR'));
    await tester.pumpAndSettle();
    expect(repo.asked.last, 'CHUTE1');
    expect(find.text('Cupom inválido.'), findsOneWidget);
    expect(find.byKey(const ValueKey('coupon-applied')), findsNothing);

    await tester.enterText(find.byKey(const ValueKey('coupon')), 'lumen10');
    await reveal(tester, find.text('APLICAR'));
    await tester.tap(find.text('APLICAR'));
    await tester.pumpAndSettle();
    expect(find.text('Cupom LUMEN10: − R\$ 7,98'), findsOneWidget);
    expect(find.text('Total: R\$ 86,82'), findsOneWidget);

    await reveal(tester, find.text('CONFIRMAR E GERAR PIX'));
    await tester.tap(find.text('CONFIRMAR E GERAR PIX'));
    await tester.pumpAndSettle();
    expect(repo.requests.single['coupon_code'], 'LUMEN10');
    expect(repo.requests.single['expected_total_cents'], 8682);
  });
}
