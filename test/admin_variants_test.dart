import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumen_store/admin/admin_api.dart';
import 'package:lumen_store/admin/admin_variants.dart';
import 'package:lumen_store/checkout/commerce_api.dart';

class FakeVariants implements AdminVariantsRepository {
  final items = <Json>[
    {'id': 1, 'size': 'P', 'color': 'Champagne', 'label': 'P / Champagne', 'stock': 4, 'is_active': true, 'version': 2},
  ];
  final saves = <(int?, Json)>[];

  @override
  Future<List<AdminVariant>> variants(int productId) async =>
      items.map(AdminVariant.fromJson).toList();

  @override
  Future<AdminVariant> saveVariant(int productId, Json data, {int? id}) async {
    saves.add((id, data));
    final label = [data['size'], data['color']].where((p) => (p as String).isNotEmpty).join(' / ');
    final saved = {'id': id ?? items.length + 1, 'label': label, 'version': 0, ...data};
    items
      ..removeWhere((v) => v['id'] == saved['id'])
      ..add(saved);
    return AdminVariant.fromJson(saved);
  }
}

void main() {
  testWidgets('adds a size, requires size or color and edits with the version', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = FakeVariants();
    await tester.pumpWidget(
      MaterialApp(
        home: AdminVariantsPage(repository: repo, productId: 7, productName: 'Vestido Aura'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('P / Champagne'), findsOneWidget);
    expect(find.text('Estoque total à venda: 4 unidades'), findsOneWidget);

    await tester.tap(find.text('NOVO TAMANHO/COR'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('variant-stock')), '5');
    await tester.tap(find.text('SALVAR'));
    await tester.pumpAndSettle();
    expect(find.text('Informe o tamanho, a cor ou os dois.'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('variant-size')), 'm');
    await tester.enterText(find.byKey(const ValueKey('variant-color')), 'Champagne');
    await tester.tap(find.text('SALVAR'));
    await tester.pumpAndSettle();
    expect(repo.saves.last.$1, isNull);
    expect(
      repo.saves.last.$2,
      {'size': 'M', 'color': 'Champagne', 'stock': 5, 'is_active': true},
    );
    expect(find.text('Estoque total à venda: 9 unidades'), findsOneWidget);

    await tester.tap(find.text('P / Champagne'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('variant-stock')), '0');
    await tester.tap(find.text('SALVAR'));
    await tester.pumpAndSettle();
    expect(repo.saves.last.$1, 1);
    expect(repo.saves.last.$2['version'], 2);
    expect(repo.saves.last.$2['stock'], 0);
  });
}
