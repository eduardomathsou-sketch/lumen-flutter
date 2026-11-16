import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumen_store/account/account_controller.dart';
import 'package:lumen_store/checkout/commerce_api.dart';
import 'package:lumen_store/main.dart';
import 'package:lumen_store/store/store_pages.dart';

import 'checkout_test.dart' show MemoryStorage;

class VariantProducts implements ProductsRepository {
  VariantProducts(this.item);
  final StoreProduct item;
  @override
  Future<List<StoreProduct>> listProducts({
    String? search,
    int? categoryId,
    int skip = 0,
    int limit = 20,
  }) async => [item];
  @override
  Future<StoreProduct> product(int id) async => item;
  @override
  Future<List<StoreCategory>> categories() async => const [];
}

StoreProduct dressFromApi() => StoreProduct.fromJson({
  'id': 7,
  'name': 'Vestido Aura',
  'description': 'Cetim champagne.',
  'composition': 'Cetim acetinado.',
  'care': 'Lavar à mão.',
  'price': 289.9,
  'price_cents': 28990,
  'stock': 0,
  'rating_average': 4.5,
  'rating_count': 2,
  'variants': [
    {'id': 11, 'size': 'M', 'color': 'Champagne', 'label': 'M · Champagne', 'stock': 3},
    {'id': 12, 'size': 'G', 'color': 'Champagne', 'label': 'G · Champagne', 'stock': 0},
  ],
});

AccountController account() => AccountController(
  CommerceApi(storage: MemoryStorage(), accountStorage: MemoryStorage()),
  favoritesStorage: MemoryStorage(),
);

void main() {
  test('reads variants, sheet, rating and exact price from the API', () {
    final dress = dressFromApi();
    expect(dress.hasVariants, isTrue);
    expect(dress.availableStock, 3);
    expect(dress.formattedPrice, 'R\$ 289,90');
    expect(dress.formattedRating, '4,5 · 2 avaliações');
    expect(dress.composition, 'Cetim acetinado.');
    expect(
      StoreProduct.fromJson({
        'id': 1,
        'name': 'Bolsa',
        'price': 1234.5,
        'price_cents': 123450,
        'stock': 1,
      }).formattedPrice,
      'R\$ 1.234,50',
    );
  });

  testWidgets('a size/color must be chosen before adding to the bag', (
    tester,
  ) async {
    final added = <(int, int?)>[];
    await tester.pumpWidget(
      MaterialApp(
        home: ProductDetailPage(
          productId: 7,
          repository: VariantProducts(dressFromApi()),
          account: account(),
          onAdd: (product, quantity, variant) async =>
              added.add((quantity, variant?.id)),
          onBag: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Escolha o tamanho e a cor para continuar.'), findsOneWidget);
    expect(find.text('COMPOSIÇÃO'), findsOneWidget);
    expect(find.text('CUIDADOS'), findsOneWidget);
    expect(find.text('4,5 · 2 avaliações'), findsOneWidget);

    final add = find.text('ADICIONAR À SACOLA');
    await tester.ensureVisible(add);
    await tester.tap(add);
    await tester.pumpAndSettle();
    expect(added, isEmpty);

    // Variação esgotada não pode ser escolhida.
    await tester.ensureVisible(find.text('G · Champagne · esgotado'));
    await tester.tap(find.text('G · Champagne · esgotado'));
    await tester.pumpAndSettle();
    expect(find.text('Escolha o tamanho e a cor para continuar.'), findsOneWidget);

    await tester.tap(find.text('M · Champagne'));
    await tester.pumpAndSettle();
    expect(find.text('3 disponíveis'), findsOneWidget);

    await tester.ensureVisible(add);
    await tester.tap(add);
    await tester.pumpAndSettle();
    expect(added, [(1, 11)]);
  });
}
