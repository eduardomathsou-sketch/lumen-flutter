import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumen_store/store/catalog_api.dart';
import 'package:lumen_store/store/product_card.dart';

StoreProduct product({int? compareAt, String? badge, int stock = 3}) =>
    StoreProduct.fromJson({
      'id': 1,
      'name': 'Bolsa Aurora',
      'description': 'Bolsa estruturada.',
      'price': 129.9,
      'price_cents': 12990,
      'stock': stock,
      'category_name': 'Moda feminina',
      'compare_at_cents': compareAt,
      'badge': badge,
    });

Future<void> pumpCard(WidgetTester tester, StoreProduct item, {VoidCallback? onAdd}) =>
    tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              width: 320,
              child: ShopProductCard(
                product: item,
                favorite: false,
                onFavorite: () {},
                onAdd: onAdd ?? () {},
                onOpen: () {},
              ),
            ),
          ),
        ),
      ),
    );

void main() {
  test('discount is real, rounded down and only when the old price is higher', () {
    final sale = product(compareAt: 16990);
    expect(sale.hasDiscount, isTrue);
    expect(sale.discountPercent, 23); // 4000/16990 = 23,5% → anuncia 23%
    expect(sale.formattedCompareAt, 'R\$ 169,90');
    expect(product(compareAt: 12990).hasDiscount, isFalse);
    expect(product(compareAt: 9990).hasDiscount, isFalse);
    expect(product(badge: 'pronta_entrega').badgeLabel, 'PRONTA ENTREGA');
    expect(product(badge: 'qualquer-coisa').badgeLabel, isNull);
  });

  testWidgets('card shows badge, discount, old price and buys', (tester) async {
    var added = 0;
    await pumpCard(
      tester,
      product(compareAt: 16990, badge: 'novidade'),
      onAdd: () => added++,
    );
    expect(find.text('NOVIDADE'), findsOneWidget);
    expect(find.text('-23%'), findsOneWidget);
    expect(find.text('R\$ 169,90'), findsOneWidget);
    expect(find.text('R\$ 129,90'), findsOneWidget);
    expect(find.text('Moda feminina'), findsOneWidget);
    expect(find.text('NOVIDADE'), findsOneWidget);
    await tester.tap(find.byTooltip('Adicionar à sacola'));
    expect(added, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sold out card cannot be bought and shows no fake promotion', (
    tester,
  ) async {
    var added = 0;
    await pumpCard(tester, product(stock: 0), onAdd: () => added++);
    expect(find.text('Esgotado'), findsWidgets);
    expect(find.textContaining('%'), findsNothing);
    await tester.tap(find.byTooltip('Adicionar à sacola'));
    expect(added, 0);
  });
}
