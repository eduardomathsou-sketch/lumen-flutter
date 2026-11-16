import 'dart:convert';

import 'package:http/http.dart' as http;

import '../api_config.dart';

/// Uma combinação de tamanho e cor com estoque próprio (ex.: "M · Champagne").
class ProductVariant {
  const ProductVariant({
    required this.id,
    required this.size,
    required this.color,
    required this.label,
    required this.stock,
  });

  final int id;
  final String size;
  final String color;
  final String label;
  final int stock;

  factory ProductVariant.fromJson(Map<String, dynamic> json) => ProductVariant(
    id: json['id'] as int,
    size: json['size'] as String,
    color: json['color'] as String,
    label: json['label'] as String,
    stock: json['stock'] as int,
  );

  bool get available => stock > 0;
}

class StoreProduct {
  const StoreProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    this.categoryName,
    this.imageUrl,
    this.priceCents,
    this.composition,
    this.care,
    this.variants = const [],
    this.ratingAverage,
    this.ratingCount = 0,
    this.compareAtCents,
    this.badge,
  });

  final int id;
  final String name;
  final String? description;
  final double price;
  final int stock;
  final String? categoryName;
  final String? imageUrl;
  // Valor exato em centavos, como a API guarda; `price` fica por compatibilidade.
  final int? priceCents;
  final String? composition;
  final String? care;
  // Vazia quando a peça não tem tamanho/cor; quando existe, a compra exige escolher uma.
  final List<ProductVariant> variants;
  final double? ratingAverage;
  final int ratingCount;
  // Preço "de" (promoção real); a API só manda quando é maior que o preço atual.
  final int? compareAtCents;
  // Selo da vitrine: novidade, pronta_entrega, edicao_limitada ou ultimas_pecas.
  final String? badge;

  factory StoreProduct.fromJson(Map<String, dynamic> json) => StoreProduct(
    id: json['id'] as int,
    name: json['name'] as String,
    description: json['description'] as String?,
    price: (json['price'] as num).toDouble(),
    stock: json['stock'] as int,
    categoryName: json['category_name'] as String?,
    imageUrl: json['image_url'] as String?,
    priceCents: json['price_cents'] as int?,
    composition: _text(json['composition']),
    care: _text(json['care']),
    variants: (json['variants'] as List? ?? const [])
        .map((v) => ProductVariant.fromJson(v as Map<String, dynamic>))
        .toList(),
    ratingAverage: (json['rating_average'] as num?)?.toDouble(),
    ratingCount: json['rating_count'] as int? ?? 0,
    compareAtCents: json['compare_at_cents'] as int?,
    badge: _text(json['badge']),
  );

  static String? _text(Object? value) {
    final text = (value as String?)?.trim();
    return text == null || text.isEmpty ? null : text;
  }

  bool get hasVariants => variants.isNotEmpty;

  /// Peças com tamanho/cor somam o estoque das variações.
  int get availableStock => hasVariants
      ? variants.fold(0, (total, v) => total + (v.stock > 0 ? v.stock : 0))
      : stock;

  String get shortDescription => categoryName ?? description ?? 'Seleção Lumen';

  int get cents => priceCents ?? (price * 100).round();

  String get formattedPrice => _money(cents);

  static String _money(int cents) {
    final reais = (cents ~/ 100).toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    return 'R\$ $reais,${(cents % 100).toString().padLeft(2, '0')}';
  }

  /// Promoção só aparece quando o preço "de" é maior que o atual.
  bool get hasDiscount => compareAtCents != null && compareAtCents! > cents;

  String? get formattedCompareAt => hasDiscount ? _money(compareAtCents!) : null;

  /// Desconto arredondado para baixo: nunca anuncia mais do que dá.
  int get discountPercent =>
      hasDiscount ? ((compareAtCents! - cents) * 100) ~/ compareAtCents! : 0;

  String? get badgeLabel => switch (badge) {
    'novidade' => 'NOVIDADE',
    'pronta_entrega' => 'PRONTA ENTREGA',
    'edicao_limitada' => 'EDIÇÃO LIMITADA',
    'ultimas_pecas' => 'ÚLTIMAS PEÇAS',
    _ => null,
  };

  /// Tamanhos à venda, na ordem cadastrada (sem repetir).
  List<String> get sizes => [
    for (final v in variants)
      if (v.stock > 0 && v.size.isNotEmpty) v.size,
  ].toSet().toList();

  String? get formattedRating => ratingAverage == null || ratingCount == 0
      ? null
      : '${ratingAverage!.toStringAsFixed(1).replaceAll('.', ',')} · '
            '$ratingCount ${ratingCount == 1 ? 'avaliação' : 'avaliações'}';
}

const lumenDemoProduct = StoreProduct(
  id: 0,
  name: 'Vestido Aura',
  description: 'Cetim champagne · edição limitada',
  price: 9.90,
  stock: 12,
  categoryName: 'Coleção Vista sua essência',
  imageUrl: 'https://lumen-store-omega.vercel.app/products/vestido-aura.png',
);

class StoreCategory {
  const StoreCategory(this.id, this.name);
  final int id;
  final String name;
}

abstract class ProductsRepository {
  Future<List<StoreProduct>> listProducts({
    String? search,
    int? categoryId,
    int skip = 0,
    int limit = 20,
  });
  Future<StoreProduct> product(int id);
  Future<List<StoreCategory>> categories();
}

class ProductApi implements ProductsRepository {
  ProductApi({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = baseUrl ?? apiBaseUrl;
  final http.Client _client;
  final String _baseUrl;
  Future<dynamic> _get(String path, [Map<String, String>? query]) async {
    try {
      final uri = Uri.parse('${_baseUrl.replaceFirst(RegExp(r'/+$'), '')}$path')
          .replace(queryParameters: query);
      final response = await _client
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        throw ProductApiException('Não foi possível carregar o catálogo.');
      }
      return jsonDecode(response.body);
    } catch (_) {
      throw ProductApiException(
        'Não foi possível conectar à loja. Confira a conexão e tente novamente.',
      );
    }
  }

  @override
  Future<List<StoreProduct>> listProducts({
    String? search,
    int? categoryId,
    int skip = 0,
    int limit = 20,
  }) async =>
      (await _get('/products', {
            'skip': '$skip',
            'limit': '$limit',
            if (search != null && search.isNotEmpty) 'search': search,
            if (categoryId != null) 'category_id': '$categoryId',
          }) as List)
          .map((x) => StoreProduct.fromJson(x as Map<String, dynamic>))
          .toList();
  @override
  Future<StoreProduct> product(int id) async => StoreProduct.fromJson(
    await _get('/products/$id') as Map<String, dynamic>,
  );
  @override
  Future<List<StoreCategory>> categories() async =>
      (await _get('/categories') as List)
          .map((x) => StoreCategory(x['id'] as int, x['name'] as String))
          .toList();
}

class ProductApiException implements Exception {
  ProductApiException(this.message);
  final String message;
  @override
  String toString() => message;
}
