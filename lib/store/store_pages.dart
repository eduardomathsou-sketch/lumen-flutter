import 'package:flutter/material.dart';

import '../account/account_controller.dart';
import '../lumen_theme.dart';
import '../checkout/checkout_pages.dart';
import '../checkout/commerce_api.dart' show maxUnitsPerItem;
import 'reviews.dart';
import 'catalog_api.dart';
import 'product_card.dart';
import 'store_layout.dart';

class ProductVisual extends StatelessWidget {
  const ProductVisual({super.key, required this.product, this.aspectRatio = 1});
  final StoreProduct product;

  /// 1 = quadrada (foto inteira); 3/4 = vitrine vertical (foto preenche o quadro).
  final double aspectRatio;
  @override
  Widget build(BuildContext context) {
    final image = product.imageUrl;
    if (image != null && image.isNotEmpty) {
      return AspectRatio(
        aspectRatio: aspectRatio,
        child: ColoredBox(
          color: const Color(0xFFF3F1EE),
          child: Image.network(
            image,
            width: double.infinity,
            height: double.infinity,
            fit: aspectRatio == 1 ? BoxFit.contain : BoxFit.cover,
            semanticLabel: product.name,
            errorBuilder: (_, _, _) => _placeholder(),
          ),
        ),
      );
    }
    return AspectRatio(aspectRatio: aspectRatio, child: _placeholder());
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
          colors: [Color(0xFFF7F5F2), Color(0xFFE7DFD3)],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 90, color: const Color(0xFFCBA96B)),
          const SizedBox(height: 12),
          const Text(
            'L U M E N',
            style: TextStyle(color: Color(0xFF8C6D3F), fontSize: 12),
          ),
          const Text(
            'Imagem ilustrativa',
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 10),
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
    this.onBuyNow,
  });
  final StoreProduct product;
  final AccountController account;
  final VoidCallback onOpen, onAdd;
  final VoidCallback? onBuyNow;
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
    onBuyNow: onBuyNow,
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
    this.onBuyNow,
    this.searchRequest = 0,
  });
  final ProductsRepository repository;
  final AccountController account;
  final ValueChanged<StoreProduct> onOpen, onAdd;
  final ValueChanged<StoreProduct>? onBuyNow;

  /// Muda quando a cliente toca em "Buscar": o campo de busca ganha o foco.
  final int searchRequest;
  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

enum _Sort { relevance, lowest, highest, name }

class _CatalogPageState extends State<CatalogPage> {
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  _Sort _sort = _Sort.relevance;
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
    if (widget.searchRequest > 0) _focusSearch();
  }

  @override
  void didUpdateWidget(CatalogPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchRequest != oldWidget.searchRequest) _focusSearch();
  }

  void _focusSearch() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) _searchFocus.requestFocus();
  });

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  List<StoreProduct> get _sorted {
    final items = [..._products];
    switch (_sort) {
      case _Sort.relevance:
        break;
      case _Sort.lowest:
        items.sort((a, b) => a.cents.compareTo(b.cents));
      case _Sort.highest:
        items.sort((a, b) => b.cents.compareTo(a.cents));
      case _Sort.name:
        items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }
    return items;
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
        ShowcaseHeader(
          label: 'Loja',
          title: 'Encontre sua próxima escolha',
          count: _busy && _products.isEmpty ? null : _products.length,
        ),
        const SizedBox(height: 20),
        TextField(
          key: const ValueKey('catalog-search'),
          controller: _search,
          focusNode: _searchFocus,
          onSubmitted: (_) => _load(),
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Buscar produtos',
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
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (sort, label) in const [
              (_Sort.relevance, 'Relevância'),
              (_Sort.lowest, 'Menor preço'),
              (_Sort.highest, 'Maior preço'),
              (_Sort.name, 'Nome A-Z'),
            ])
              ChoiceChip(
                key: ValueKey('sort-${sort.name}'),
                label: Text(label),
                selected: _sort == sort,
                onSelected: (_) => setState(() => _sort = sort),
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
            for (final product in _sorted)
              CatalogTile(
                key: ValueKey('catalog-product-${product.id}'),
                product: product,
                account: widget.account,
                onOpen: () => widget.onOpen(product),
                onAdd: () => widget.onAdd(product),
                onBuyNow: widget.onBuyNow == null
                    ? null
                    : () => widget.onBuyNow!(product),
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
    this.onBuyNow,
  });
  final AccountController account;
  final ValueChanged<StoreProduct> onOpen, onAdd;
  final ValueChanged<StoreProduct>? onBuyNow;
  final VoidCallback onExplore;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(22),
    children: [
      Text('FAVORITOS', style: Lumen.label),
      const SizedBox(height: 6),
      Text('Seus favoritos', style: Lumen.displayStyle(36)),
      const SizedBox(height: 8),
      Text(
        account.user == null
            ? 'Salvos neste aparelho. Entre para ter favoritos na conta.'
            : 'Suas escolhas, salvas na sua conta.',
        style: const TextStyle(color: Lumen.muted),
      ),
      const SizedBox(height: 24),
      if (account.loading)
        const LinearProgressIndicator()
      else if (account.error != null)
        RetryNotice(account.error!, account.initialize)
      else if (account.favorites.isEmpty) ...[
        const SizedBox(height: 40),
        const Icon(Icons.favorite_border, size: 64, color: Lumen.gold),
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
              onBuyNow: onBuyNow == null ? null : () => onBuyNow!(product),
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
                  image: DecoratedBox(
                    decoration: Lumen.card(),
                    child: ClipRRect(
                      borderRadius: Lumen.radius,
                      child: Stack(
                        children: [
                          ProductVisual(product: product),
                          Positioned(
                            top: 16,
                            left: 16,
                            child: ShopPill(
                              text: product.badgeLabel ?? 'LUMEN',
                              icon: Icons.auto_awesome,
                            ),
                          ),
                          const Positioned(
                            top: 16,
                            right: 16,
                            child: ShopPill(text: '1/1'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  details: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        product.categoryName ?? 'Seleção Lumen',
                        style: const TextStyle(
                          color: Lumen.muted,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(product.name, style: Lumen.displayStyle(40)),
                      const SizedBox(height: 16),
                      if (product.hasDiscount)
                        Text(
                          product.formattedCompareAt!,
                          style: const TextStyle(
                            color: Lumen.faint,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 14,
                        runSpacing: 6,
                        children: [
                          Text(
                            product.formattedPrice,
                            style: Lumen.displayStyle(40, weight: FontWeight.w600),
                          ),
                          if (product.hasDiscount)
                            ShopPill(
                              text: '-${product.discountPercent}%',
                              background: Lumen.sale,
                              foreground: Colors.white,
                              size: 13,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'à vista no PIX, aprovado na hora',
                        style: TextStyle(
                          color: Lumen.muted,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (product.formattedRating != null) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.star, size: 18, color: Lumen.gold),
                            const SizedBox(width: 6),
                            Text(product.formattedRating!),
                          ],
                        ),
                      ],
                      const SizedBox(height: 18),
                      Text(
                        product.description ?? 'Uma escolha da seleção Lumen.',
                        style: const TextStyle(
                          color: Lumen.text,
                          fontSize: 16,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const InfoCard(
                        icon: Icons.pix,
                        text: 'Pagamento por PIX',
                      ),
                      const SizedBox(height: 10),
                      const InfoCard(
                        icon: Icons.straighten,
                        text: 'Composição e cuidados na ficha',
                      ),
                      const SizedBox(height: 10),
                      const InfoCard(
                        icon: Icons.verified_user_outlined,
                        text: 'Compra protegida',
                      ),
                      if (product.hasVariants) ...[
                        const SizedBox(height: 22),
                        const Text(
                          'Tamanho e cor',
                          style: TextStyle(
                            color: Lumen.ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (final variant in product.variants)
                              ChoiceChip(
                                showCheckmark: false,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 10,
                                ),
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
                        style: const TextStyle(color: Lumen.muted),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: Lumen.card(),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Quantidade',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Diminuir',
                              onPressed: _busy || _quantity <= 1
                                  ? null
                                  : () => setState(() => _quantity--),
                              icon: const Icon(Icons.remove),
                            ),
                            Text(
                              '$_quantity',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
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
                      ),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.shopping_cart_outlined),
                        label: Text(
                          _busy ? 'ADICIONANDO...' : 'ADICIONAR À SACOLA',
                        ),
                        onPressed: _busy || stock == 0
                            ? null
                            : () => _add(product),
                      ),
                      const SizedBox(height: 10),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                        ),
                        onPressed: _busy || stock == 0
                            ? null
                            : () => _add(product, thenBag: true),
                        child: const Text('Comprar agora'),
                      ),
                      const SizedBox(height: 6),
                      TextButton.icon(
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
                      const InfoCard(
                        icon: Icons.verified_user_outlined,
                        text: 'Compra segura',
                      ),
                      const SizedBox(height: 10),
                      const InfoCard(
                        icon: Icons.local_shipping_outlined,
                        text: 'Entrega acompanhada, com código de rastreio',
                      ),
                      const SizedBox(height: 10),
                      const InfoCard(
                        icon: Icons.autorenew,
                        text: 'Devolução em até 7 dias',
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Frete e prazo aparecem na revisão da compra. Frete grátis a partir de 2 peças.',
                        style: TextStyle(color: Lumen.muted, fontSize: 13),
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

  /// Adiciona a peça; com [thenBag], já abre a sacola para finalizar.
  Future<void> _add(StoreProduct product, {bool thenBag = false}) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    var added = false;
    try {
      await widget.onAdd(product, _quantity, _variant);
      added = true;
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (added && thenBag && mounted) widget.onBag();
  }
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
        Text(title.toUpperCase(), style: Lumen.label),
        const SizedBox(height: 6),
        Text(text, style: const TextStyle(color: Lumen.text, height: 1.6)),
      ],
    ),
  );
}
