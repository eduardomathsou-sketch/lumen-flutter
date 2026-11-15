import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumen_store/admin/admin_coupons.dart';
import 'package:lumen_store/checkout/commerce_api.dart';

class FakeCoupons implements AdminCouponsRepository {
  final items = <Json>[
    {
      'id': 1,
      'code': 'LUMEN10',
      'kind': 'percent',
      'value': 10,
      'min_subtotal_cents': 0,
      'max_uses': 100,
      'used_count': 3,
      'is_active': true,
      'version': 0,
      'expires_at': null,
    },
  ];
  Json? saved;

  @override
  Future<List<AdminCoupon>> coupons() async =>
      items.map(AdminCoupon.fromJson).toList();

  @override
  Future<AdminCoupon> save(Json data, {int? id}) async {
    saved = data;
    final coupon = {'id': id ?? items.length + 1, 'used_count': 0, 'version': 0, ...data};
    items.add(coupon);
    return AdminCoupon.fromJson(coupon);
  }
}

void main() {
  testWidgets('lists coupons and blocks a fixed coupon that could zero the total', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = FakeCoupons();
    await tester.pumpWidget(MaterialApp(home: AdminCouponsPage(repository: repo)));
    await tester.pumpAndSettle();
    expect(find.text('LUMEN10 · 10% de desconto'), findsOneWidget);
    expect(find.text('usado 3 de 100'), findsOneWidget);
    expect(find.text('Ativo'), findsOneWidget);

    await tester.tap(find.text('NOVO CUPOM'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('coupon-code')), 'bemvinda20');
    await tester.tap(find.byKey(const ValueKey('coupon-fixed')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('coupon-value')), '20');
    await tester.enterText(find.byKey(const ValueKey('coupon-minimum')), '20');
    await tester.tap(find.text('SALVAR CUPOM'));
    await tester.pumpAndSettle();
    expect(
      find.text('Para valor fixo, a compra mínima precisa ser maior que o desconto.'),
      findsOneWidget,
    );
    expect(repo.saved, isNull);

    await tester.enterText(find.byKey(const ValueKey('coupon-minimum')), '150,00');
    await tester.tap(find.text('SALVAR CUPOM'));
    await tester.pumpAndSettle();
    expect(repo.saved, {
      'code': 'BEMVINDA20',
      'kind': 'fixed',
      'value': 2000,
      'min_subtotal_cents': 15000,
      'expires_at': null,
      'max_uses': null,
      'is_active': true,
    });
    expect(find.text('BEMVINDA20 · R\$ 20,00 de desconto'), findsOneWidget);
  });
}
