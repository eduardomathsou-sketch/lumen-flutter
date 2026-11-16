import 'package:flutter/material.dart';

import '../account/account_controller.dart';
import '../checkout/checkout_pages.dart';
import '../checkout/commerce_api.dart' show maxUnitsPerItem;
import 'reviews.dart';
import 'catalog_api.dart';
import 'product_card.dart';
import 'store_layout.dart';

class ProductVisual extends StatelessWidget {
  const ProductVisual({super.key, required this.product});
  final StoreProduct product;
  @override
  Widget build(BuildContext context) {
    final image = product.imageUrl;
    if (image != null && image.isNotEmpty) {
      return AspectRatio(
        aspectRatio: 1,
        child: ColoredBox(
          color: const Color(0xFFF1E8D8),
          child: Image.network(
            image,
            width: double.infinity,
            fit: BoxFit.contain,
            semanticLabel: product.name,
            errorBuilder: (_, _, _) => _placeholder(),
          ),
        ),
      );
    }
    return AspectRatio(aspectRatio: 1, child: _placeholder());
  }

  Widget _placeholder() {
    final beauty = '${product.categoryName} ${product.name}'.toLowerCase();
    final icon = beauty.contains('bolsa')
        ? Icons.shopping_bag_outlined
        : beauty.contains('beleza') ||
              beauty.contains('bruma') ||
              beauty.contains('oleo')
        ? Icons.spa_outlined
        : Icons.checkroom;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF1E8D8), Color(0xFFCDB38C)],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 90, color: const Color(0xFF866B48)),
          const SizedBox(height: 12),
          const Text(
            'L U M E N',
            style: TextStyle(color: Color(0xFF866B48), fontSize: 12),
          ),
          const Text(
            'Imagem ilustrativa',
            style: TextStyle(color: Color(0xFF756C62), fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class CatalogTile extends StatelessWidget {
  const CatalogTile({
    super.key,
    required this.product,
    required this.account,
    required this.onOpen,
    required this.onAdd,
  });
  final StoreProduct product;
  final AccountController account;
  final VoidCallback onOpen, onAdd;
  @override
  Widget build(BuildContext context) => ShopProductCard(
    product: product,
    favorite: account.isFavorite(product.id),
    favoriteBusy: account.loading || account.updating.contains(product.id),
    onFavorite: () async {
      try {
        await account.toggle(product);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorText(e))),
          );
        }
      }
    },
    onAdd: onAdd,
    onOpen: onOpen,
  );
}

class CatalogPage extends StatefulWidget {
  const CatalogPage({
    super.key,
    required this.repository,
    required this.account,
    required this.onOpen,
    required this.onAdd,
  });
  final ProductsRepository repository;
  final AccountController account;
  final ValueChanged<StoreProduct> onOpen, onAdd;
  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  final _search = TextEditingController();
  List<StoreCategory> _categories = [];
  List<StoreProduct> _products = [];
  int? _category;
  bool _busy = false, _more = false;
  String? _error;
  int _generation = 0;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load({bool append = false}) async {
    final generation = ++_generation;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final categories = await widget.repository.categories();
      final products = await widget.repository.listProducts(
        search: _search.text.trim(),
        categoryId: _category,
        skip: append ? _products.length : 0,
      );
      if (!mounted || generation != _generation) return;
      setState(() {
        _categories = categories;
        _products = append ? [..._products, ...products] : products;
        _more = products.length == 20;
      });
    } catch (e) {
      if (mounted && generation == _generation) {
        setState(() => _error = errorText(e));
      }
    } finally {
      if (mounted && generation == _generation) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: _load,
    child: ListView(
      key: const PageStorageKey('catalog'),
      padding: const EdgeInsets.all(22),
      children: [
        const Text(
          'Encontre sua próxima escolha',
          style: TextStyle(fontSize: 29),
        ),
        const SizedBox(height: 8),
        const Text(
          'Explore nossas categorias e descubra seus favoritos.',
          style: TextStyle(color: Color(0xFFA7A097)),
        ),
        const SizedBox(height: 22),
        TextField(
          key: const ValueKey('catalog-search'),
          controller: _search,
          onSubmitted: (_) => _load(),
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Buscar produtos',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              tooltip: 'Buscar',
              onPressed: () => _load(),
              icon: const Icon(Icons.arrow_forward),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Tudo'),
              selected: _category == null,
              onSelected: (_) {
                setState(() => _category = null);
                _load();
              },
            ),
            for (final category in _categories)
              ChoiceChip(
                label: Text(category.name),
                selected: _category == category.id,
                onSelected: (_) {
                  setState(() => _category = category.id);
                  _load();
                },
              ),
          ],
        ),
        const SizedBox(height: 20),
        if (_busy) const LinearProgressIndicator(),
        if (_error != null) RetryNotice(_error!, () => _load()),
        if (!_busy && _error == null && _products.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 60),
            child: Text(
              'Nenhum produto encontrado. Experimente outra busca.',
              textAlign: TextAlign.center,
            ),
          ),
        const SizedBox(height: 12),
        ProductCollection(
          children: [
            for (final product in _products)
              CatalogTile(
                key: ValueKey('catalog-product-${product.id}'),
                product: product,
                account: widget.account,
                onOpen: () => widget.onOpen(product),
                onAdd: () => widget.onAdd(product),
              ),
          ],
        ),
        const SizedBox(height: 20),
        if (_more && _error == null)
          OutlinedButton(
            onPressed: _busy ? null : () => _load(append: true),
            child: const Text('CARREGAR MAIS'),
          ),
      ],
    ),
  );
}

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({
    super.key,
    required this.account,
    required this.onOpen,
    required this.onAdd,
    required this.onExplore,
  });
  final AccountController account;
  final ValueChanged<StoreProduct> onOpen, onAdd;
  final VoidCallback onExplore;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(22),
    children: [
      const Text('Seus favoritos', style: TextStyle(fontSize: 30)),
      const SizedBox(height: 8),
      Text(
        account.user == null
            ? 'Salvos neste aparelho. Entre para ter favoritos na conta.'
            : 'Suas escolhas, salvas na sua conta.',
        style: const TextStyle(color: Color(0xFFA7A097)),
      ),
      const SizedBox(height: 24),
      if (account.loading)
        const LinearProgressIndicator()
      else if (account.error != null)
        RetryNotice(account.error!, account.initialize)
      else if (account.favorites.isEmpty) ...[
        const SizedBox(height: 40),
        const Icon(Icons.favorite_border, size: 64, color: Color(0xFFD9B66A)),
        const SizedBox(height: 20),
        const Text(
          'Ainda não tem favoritos por aqui.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: onExplore,
          child: const Text('EXPLORAR CATÁLOGO'),
        ),
      ],
      ProductCollection(
        children: [
          for (final product in account.favorites)
            CatalogTile(
              key: ValueKey('favorite-product-${product.id}'),
              product: product,
              account: account,
              onOpen: () => onOpen(product),
              onAdd: () => onAdd(product),
            ),
        ],
      ),
    ],
  );
}

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({
    super.key,
    required this.productId,
    required this.repository,
    required this.account,
    required this.onAdd,
    required this.onBag,
  });
  final int productId;
  final ProductsRepository repository;
  final AccountController account;
  final Future<void> Function(StoreProduct, int, ProductVariant?) onAdd;
  final VoidCallback onBag;
  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late Future<StoreProduct> _future;
  int _quantity = 1;
  bool _busy = false;
  String? _error;
  ProductVariant? _variant;

  void _choose(ProductVariant variant) => setState(() {
    _variant = variant;
    _error = null;
    // Só variações com estoque podem ser escolhidas, então stock >= 1 aqui.
    if (_quantity > variant.stock) _quantity = variant.stock;
  });
  @override
  void initState() {
    super.initState();
    _future = widget.repository.product(widget.productId);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Detalhes do produto'),
      actions: [
        IconButton(
          tooltip: 'Abrir sacola',
          onPressed: widget.onBag,
          icon: const Icon(Icons.shopping_bag_outlined),
        ),
      ],
    ),
    body: StoreViewport(
      maxWidth: 1100,
      child: AnimatedBuilder(
        animation: widget.account,
        builder: (context, _) => FutureBuilder<StoreProduct>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return RetryNotice(
                errorText(snapshot.error!),
                () => setState(() {
                  _future = widget.repository.product(widget.productId);
                }),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final product = snapshot.data!;
            final needsChoice = product.hasVariants && _variant == null;
            final stock = product.hasVariants
                ? (_variant?.stock ?? 0)
                : product.stock;
            final soldOut = product.availableStock == 0;
            return ListView(
              padding: const EdgeInsets.all(22),
              children: [
                ProductDetailLayout(
                  image: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: ProductVisual(product: product),
                  ),
                  details: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (product.badgeLabel != null || product.hasDiscount) ...[
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            if (product.badgeLabel != null)
                              ShopPill(
                                text: product.badgeLabel!,
                                icon: Icons.auto_awesome,
                              ),
                            if (product.hasDiscount)
                              ShopPill(
                                text: '-${product.discountPercent}%',
                                background: const Color(0xFFB23A3A),
                                foreground: Colors.white,
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                      Text(
                        (product.categoryName ?? 'Seleção Lumen').toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFFD9B66A),
                          fontSize: 12,
                          letterSpacing: 1.6,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        product.name,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 12),
                      if (product.hasDiscount)
                        Text(
                          product.formattedCompareAt!,
                          style: const TextStyle(
                            color: Color(0xFFA7A097),
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      Text(
                        product.formattedPrice,
                        style: const TextStyle(
                          fontFamily: 'serif',
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                          height: 1.15,
                        ),
                      ),
                      const Text(
                        'à vista no PIX',
                        style: TextStyle(color: Color(0xFFA7A097), fontSize: 13),
                      ),
                      if (product.formattedRating != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 18,
                              color: Color(0xFFD9B66A),
                            ),
                            const SizedBox(width: 6),
                            Text(product.formattedRating!),
                          ],
                        ),
                      ],
                      const SizedBox(height: 20),
                      Text(
                        product.description ?? 'Uma escolha da seleção Lumen.',
                      ),
                      if (product.hasVariants) ...[
                        const SizedBox(height: 20),
                        Text(
                          'Tamanho e cor',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final variant in product.variants)
                              ChoiceChip(
                                label: Text(
                                  variant.available
                                      ? variant.label
                                      : '${variant.label} · esgotado',
                                ),
                                selected: _variant?.id == variant.id,
                                onSelected: _busy || !variant.available
                                    ? null
                                    : (_) => _choose(variant),
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 18),
                      Text(
                        soldOut
                            ? 'Produto esgotado'
                            : needsChoice
                            ? 'Escolha o tamanho e a cor para continuar.'
                            : '$stock disponíveis',
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Expanded(child: Text('Quantidade')),
                          IconButton(
                            tooltip: 'Diminuir',
                            onPressed: _busy || _quantity <= 1
                                ? null
                                : () => setState(() => _quantity--),
                            icon: const Icon(Icons.remove),
                          ),
                          Text('$_quantity'),
                          IconButton(
                            tooltip: 'Aumentar',
                            onPressed:
                                _busy ||
                                    needsChoice ||
                                    _quantity >= stock ||
                                    _quantity >= maxUnitsPerItem
                                ? null
                                : () => setState(() => _quantity++),
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      ),
                      if (_error != null)
                        Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        icon: const Icon(Icons.shopping_bag_outlined),
                        label: Text(
                          _busy ? 'ADICIONANDO...' : 'ADICIONAR À SACOLA',
                        ),
                        onPressed: _busy || stock == 0
                            ? null
                            : () async {
                                setState(() {
                                  _busy = true;
                                  _error = null;
                                });
                                try {
                                  await widget.onAdd(
                                    product,
                                    _quantity,
                                    _variant,
                                  );
                                } catch (e) {
                                  if (mounted) {
                                    setState(() => _error = errorText(e));
                                  }
                                } finally {
                                  if (mounted) setState(() => _busy = false);
                                }
                              },
                      ),
                      OutlinedButton.icon(
                        onPressed:
                            widget.account.loading ||
                                widget.account.updating.contains(product.id)
                            ? null
                            : () async {
                                try {
                                  await widget.account.toggle(product);
                                } catch (e) {
                                  if (mounted) {
                                    setState(() => _error = errorText(e));
                                  }
                                }
                              },
                        icon: Icon(
                          widget.account.isFavorite(product.id)
                              ? Icons.favorite
                              : Icons.favorite_border,
                        ),
                        label: Text(
                          widget.account.isFavorite(product.id)
                              ? 'REMOVER DOS FAVORITOS'
                              : 'SALVAR NOS FAVORITOS',
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Frete e prazo são apresentados na revisão da compra. Pagamento por PIX.',
                      ),
                      if (product.composition != null)
                        ProductInfoSection(
                          title: 'Composição',
                          text: product.composition!,
                        ),
                      if (product.care != null)
                        ProductInfoSection(
                          title: 'Cuidados',
                          text: product.care!,
                        ),
                      if (product.ratingCount > 0)
                        ProductReviews(
                          productId: product.id,
                          load: widget.account.api.reviews,
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}

/// Ficha da peça (composição, cuidados): título discreto e texto corrido.
class ProductInfoSection extends StatelessWidget {
  const ProductInfoSection({super.key, required this.title, required this.text});
  final String title;
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFFD9B66A),
            letterSpacing: 2,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        Text(text),
      ],
    ),
  );
}
