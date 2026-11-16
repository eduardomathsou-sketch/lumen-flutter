import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'checkout/commerce_api.dart';
import 'checkout/checkout_pages.dart';

import 'store/product_card.dart';
import 'store/catalog_api.dart';
import 'store/store_pages.dart';
import 'store/store_layout.dart';
import 'store/collection_banner.dart';
import 'store/store_chrome.dart';
import 'account/account_controller.dart';
import 'account/account_pages.dart';
import 'account/legal_pages.dart';
import 'lumen_theme.dart';
export 'store/catalog_api.dart';

void main() => runApp(const LumenApp());

/// Atalhos da paleta (ver lumen_theme.dart).
class LumenColors {
  static const ink = Lumen.ink;
  static const paper = Lumen.background;
  static const gold = Lumen.gold;
  static const goldLight = Lumen.gold;
  static const muted = Lumen.muted;
}

class LumenApp extends StatelessWidget {
  const LumenApp({
    super.key,
    this.productsRepository,
    this.commerceRepository,
    this.accountController,
  });

  final ProductsRepository? productsRepository;
  final CommerceRepository? commerceRepository;
  final AccountController? accountController;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Lumen',
    debugShowCheckedModeBanner: false,
    theme: lumenTheme(),
    home: LumenExperience(
      productsRepository: productsRepository ?? ProductApi(),
      commerceRepository: commerceRepository ?? CommerceApi(),
      accountController: accountController,
    ),
  );
}

class LumenExperience extends StatefulWidget {
  const LumenExperience({
    super.key,
    required this.productsRepository,
    required this.commerceRepository,
    this.accountController,
  });

  final ProductsRepository productsRepository;
  final CommerceRepository commerceRepository;
  final AccountController? accountController;

  @override
  State<LumenExperience> createState() => _LumenExperienceState();
}

class _LumenExperienceState extends State<LumenExperience> {
  bool _showSplash = true;
  Timer? _splashTimer;

  @override
  void initState() {
    super.initState();
    _splashTimer = Timer(const Duration(milliseconds: 2400), () {
      if (mounted) setState(() => _showSplash = false);
    });
  }

  void _finishSplash() {
    _splashTimer?.cancel();
    setState(() => _showSplash = false);
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: const Duration(milliseconds: 650),
    switchInCurve: Curves.easeOutCubic,
    switchOutCurve: Curves.easeInCubic,
    transitionBuilder: (child, animation) => FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, .03),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    ),
    child: _showSplash
        ? SplashScreen(key: const ValueKey('splash'), onFinish: _finishSplash)
        : LumenHome(
            key: const ValueKey('home'),
            productsRepository: widget.productsRepository,
            commerceRepository: widget.commerceRepository,
            accountController: widget.accountController,
          ),
  );
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onFinish});

  final VoidCallback onFinish;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    return Scaffold(
      body: InkWell(
        onTap: widget.onFinish,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(-.1, -.35),
              radius: 1.15,
              colors: [Colors.white, Lumen.background],
            ),
          ),
          child: Center(
            child: FadeTransition(
              opacity: curve,
              child: ScaleTransition(
                scale: Tween<double>(begin: .88, end: 1).animate(curve),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LumenMark(size: 140),
                    SizedBox(height: 18),
                    Text(
                      'L U M E N',
                      style: TextStyle(
                        fontFamily: Lumen.display,
                        color: Lumen.ink,
                        fontSize: 32,
                        letterSpacing: 9,
                      ),
                    ),
                    SizedBox(height: 42),
                    _Tagline(),
                    SizedBox(height: 32),
                    Text(
                      'toque para entrar',
                      style: TextStyle(
                        color: LumenColors.muted,
                        fontSize: 11,
                        letterSpacing: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Tagline extends StatelessWidget {
  const _Tagline();

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: const [
      SizedBox(
        width: 66,
        child: Divider(color: LumenColors.gold, thickness: .6),
      ),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: Icon(Icons.star_rounded, color: LumenColors.gold, size: 17),
      ),
      SizedBox(
        width: 66,
        child: Divider(color: LumenColors.gold, thickness: .6),
      ),
    ],
  );
}

class LumenHome extends StatefulWidget {
  const LumenHome({
    super.key,
    required this.productsRepository,
    required this.commerceRepository,
    this.accountController,
  });

  final ProductsRepository productsRepository;
  final CommerceRepository commerceRepository;
  final AccountController? accountController;

  @override
  State<LumenHome> createState() => _LumenHomeState();
}

class _LumenHomeState extends State<LumenHome> {
  late final AccountController _account;
  int? _lastUserId;
  CartSnapshot? _cart;
  bool _cartBusy = false;
  // 0 início, 1 loja, 2 favoritos, 3 conta.
  int _selectedNav = 0;
  int _searchRequest = 0;
  final _scaffold = GlobalKey<ScaffoldState>();
  late Future<List<StoreProduct>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _productsFuture = widget.productsRepository.listProducts();
    _account =
        widget.accountController ??
        AccountController(
          widget.commerceRepository is CommerceApi
              ? widget.commerceRepository as CommerceApi
              : CommerceApi(),
        );
    _account.addListener(_accountChanged);
    _account.initialize();
    _refreshCart();
  }

  void _accountChanged() {
    if (!mounted) return;
    final userId = _account.user?['id'] as int?;
    if (userId != _lastUserId) {
      _lastUserId = userId;
      _cart = null;
      _refreshCart();
    }
    setState(() {});
  }

  @override
  void dispose() {
    _account.removeListener(_accountChanged);
    if (widget.accountController == null) _account.dispose();
    super.dispose();
  }

  Future<void> _toggleFavorite(StoreProduct product) async {
    try {
      await _account.toggle(product);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(errorText(e))));
      }
    }
  }

  Future<void> _openProduct(StoreProduct product) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductDetailPage(
          productId: product.id,
          repository: widget.productsRepository,
          account: _account,
          onAdd: (p, q, v) async {
            await _addToBag(p, count: q, variant: v, propagate: true);
          },
          onBag: _openBag,
        ),
      ),
    );
    if (mounted) {
      _refreshCart();
      _reloadProducts();
    }
  }

  void _reloadProducts() {
    setState(() {
      _productsFuture = widget.productsRepository.listProducts();
    });
  }

  /// Devolve true quando a peça entrou na sacola.
  Future<bool> _addToBag(
    StoreProduct product, {
    int count = 1,
    ProductVariant? variant,
    bool propagate = false,
  }) async {
    if (_cartBusy) return false;
    if (product.hasVariants && variant == null) {
      // Peça com tamanho/cor: a escolha acontece na página do produto.
      await _openProduct(product);
      return false;
    }
    if (product.id <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Este produto é demonstrativo. Aguarde o catálogo da loja.',
          ),
        ),
      );
      return false;
    }
    setState(() => _cartBusy = true);
    try {
      final cart = await widget.commerceRepository.cart();
      final current = cart.items.where(
        (line) => line.productId == product.id && line.variantId == variant?.id,
      );
      final quantity = current.isEmpty ? count : current.first.quantity + count;
      final updated = await widget.commerceRepository.setQuantity(
        product.id,
        quantity,
        cart.version,
        variantId: variant?.id,
      );
      if (!mounted) return true;
      setState(() => _cart = updated);
      final name = variant == null ? product.name : '${product.name} (${variant.label})';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$name adicionado à sua sacola.')),
      );
      return true;
    } catch (e) {
      if (propagate) rethrow;
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(errorText(e))));
      }
      return false;
    } finally {
      if (mounted) setState(() => _cartBusy = false);
    }
  }

  /// "Comprar agora": coloca na sacola e já abre a sacola para finalizar.
  Future<void> _buyNow(StoreProduct product) async {
    if (await _addToBag(product) && mounted) await _openBag();
  }

  void _go(int page, {bool search = false}) => setState(() {
    _selectedNav = page;
    if (search) _searchRequest++;
  });

  /// Destinos do menu e do rodapé.
  void _navigate(String target) {
    switch (target) {
      case 'home':
        _go(0);
      case 'shop':
        _go(1);
      case 'favorites':
        _go(2);
      case 'account':
        _go(3);
      case 'orders':
        _openOrders();
      default:
        _openLegal(target);
    }
  }

  Future<void> _openLegal(String slug) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => LegalPage(account: _account, slug: slug),
    ),
  );

  int get _bagCount => _cart?.count ?? 0;

  Future<void> _refreshCart() async {
    try {
      final cart = await widget.commerceRepository.cart();
      if (mounted) setState(() => _cart = cart);
    } catch (_) {
      // The bag screen presents retry details when opened.
    }
  }

  Future<void> _openBag() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BagPage(
          repository: widget.commerceRepository,
          savedAddresses: _account.user == null ? null : _account.addresses,
          email: _account.user?['email'] as String?,
        ),
      ),
    );
    if (mounted) {
      _refreshCart();
      _reloadProducts();
    }
  }

  Future<void> _openOrders() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OrdersPage(repository: widget.commerceRepository),
      ),
    );
    if (mounted) {
      _refreshCart();
      _reloadProducts();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    key: _scaffold,
    backgroundColor: Lumen.background,
    appBar: StoreTopBar(
      bagCount: _bagCount,
      onHome: () => _go(0),
      onBag: _openBag,
      onMenu: () => _scaffold.currentState?.openEndDrawer(),
    ),
    endDrawer: StoreMenu(
      signedIn: _account.user != null,
      onSelect: (target) {
        Navigator.of(context).pop();
        _navigate(target);
      },
    ),
    body: SafeArea(
      top: false,
      child: StoreViewport(
        maxWidth: _selectedNav == 3 ? 640 : 1280,
        child: _selectedNav == 1
            ? CatalogPage(
                repository: widget.productsRepository,
                account: _account,
                onOpen: _openProduct,
                onAdd: _addToBag,
                onBuyNow: _buyNow,
                searchRequest: _searchRequest,
              )
            : _selectedNav == 2
            ? FavoritesPage(
                account: _account,
                onOpen: _openProduct,
                onAdd: _addToBag,
                onBuyNow: _buyNow,
                onExplore: () => _go(1),
              )
            : _selectedNav == 3
            ? ProfilePage(
                account: _account,
                onOrders: _openOrders,
                onCatalogChanged: _reloadProducts,
              )
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: HeroCarousel(onShop: () => _go(1)),
                  ),
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(22, 22, 22, 0),
                      child: TrustStrip(),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
                  SliverToBoxAdapter(child: _buildProductShowcase()),
                  const SliverToBoxAdapter(child: SizedBox(height: 28)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: OutlinedButton(
                        onPressed: () => _go(1),
                        child: const Text('VER TODO O CATÁLOGO'),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 48)),
                  SliverToBoxAdapter(
                    child: StoreFooter(onSelect: _navigate),
                  ),
                ],
              ),
      ),
    ),
    bottomNavigationBar: StoreBottomNav(
      selected: switch (_selectedNav) {
        0 => 0,
        1 => 1,
        _ => -1,
      },
      bagCount: _bagCount,
      onSelect: (index) {
        switch (index) {
          case 0:
            _go(0);
          case 1:
            _go(1);
          case 2:
            _go(1, search: true);
          default:
            _openBag();
        }
      },
    ),
  );

  Widget _buildProductShowcase() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 22),
    child: FutureBuilder<List<StoreProduct>>(
      future: _productsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingProductCard();
        }

        final products = snapshot.data ?? const [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (snapshot.hasError)
              _CatalogUnavailableNotice(onRetry: _reloadProducts),
            if (!snapshot.hasError && products.isEmpty)
              const Text(
                'Novidades em breve. Nosso catálogo está sendo preparado.',
              ),
            if (products.isNotEmpty) ...[
              ShowcaseHeader(
                label: 'Vitrine',
                title: 'Escolhidos da semana',
                count: products.length,
              ),
              const SizedBox(height: 24),
            ],
            ProductCollection(
              children: [
                for (final product in products)
                  ProductCard(
                    key: ValueKey('home-product-${product.id}'),
                    product: product,
                    favorite: _account.isFavorite(product.id),
                    onFavorite: () => _toggleFavorite(product),
                    onAdd: () => _addToBag(product),
                    onBuyNow: () => _buyNow(product),
                    onOpen: () => _openProduct(product),
                  ),
              ],
            ),
          ],
        );
      },
    ),
  );
}

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.favorite,
    required this.onFavorite,
    required this.onAdd,
    required this.onOpen,
    this.onBuyNow,
  });

  final StoreProduct product;
  final bool favorite;
  final VoidCallback onFavorite;
  final VoidCallback onAdd;
  final VoidCallback onOpen;
  final VoidCallback? onBuyNow;

  @override
  Widget build(BuildContext context) => ShopProductCard(
    product: product,
    favorite: favorite,
    onFavorite: onFavorite,
    onAdd: onAdd,
    onBuyNow: onBuyNow,
    onOpen: onOpen,
  );
}

class _LoadingProductCard extends StatelessWidget {
  const _LoadingProductCard();

  @override
  Widget build(BuildContext context) => Container(
    height: 400,
    decoration: Lumen.card(),
    child: const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
              color: LumenColors.gold,
              strokeWidth: 2,
            ),
          ),
          SizedBox(height: 14),
          Text(
            'Preparando a seleção Lumen...',
            style: TextStyle(color: LumenColors.muted, fontSize: 13),
          ),
        ],
      ),
    ),
  );
}

class _CatalogUnavailableNotice extends StatelessWidget {
  const _CatalogUnavailableNotice({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: DecoratedBox(
      decoration: Lumen.card(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        child: Row(
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: LumenColors.gold,
              size: 18,
            ),
            const SizedBox(width: 9),
            const Expanded(
              child: Text(
                'Não foi possível conectar ao catálogo.',
                style: TextStyle(color: Lumen.ink, fontSize: 12),
              ),
            ),
            TextButton(
              onPressed: onRetry,
              child: const Text(
                'TENTAR',
                style: TextStyle(fontSize: 10, letterSpacing: 1),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class FashionIllustration extends StatelessWidget {
  const FashionIllustration({super.key});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _DressPainter(), child: const SizedBox.expand());
}

class _DressPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final backdrop = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFEEE7DB), Color(0xFFD2B58D)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, backdrop);
    final glow = Paint()..color = Colors.white.withValues(alpha: .36);
    canvas.drawCircle(Offset(size.width * .76, size.height * .2), 70, glow);
    final dress = Paint()..color = const Color(0xFF92724D);
    final path = Path()
      ..moveTo(size.width * .48, 36)
      ..lineTo(size.width * .57, 36)
      ..lineTo(size.width * .60, 100)
      ..lineTo(size.width * .82, size.height - 16)
      ..quadraticBezierTo(
        size.width * .52,
        size.height + 9,
        size.width * .20,
        size.height - 16,
      )
      ..lineTo(size.width * .43, 100)
      ..close();
    canvas.drawPath(path, dress);
    final waist = Paint()..color = const Color(0xFF725536);
    canvas.drawRect(
      Rect.fromLTWH(size.width * .405, 98, size.width * .2, 7),
      waist,
    );
    final line = Paint()
      ..color = Colors.white.withValues(alpha: .45)
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(size.width * .49, 47),
      Offset(size.width * .50, size.height - 20),
      line,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LumenMark extends StatelessWidget {
  const LumenMark({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: size,
    width: size * 1.35,
    child: Stack(
      alignment: Alignment.center,
      children: [
        CustomPaint(size: Size(size * 1.35, size), painter: _MarkPainter()),
        Positioned(
          top: 0,
          child: Text(
            'L',
            style: TextStyle(
              fontFamily: Lumen.display,
              color: Lumen.ink,
              height: .88,
              fontSize: size * .99,
            ),
          ),
        ),
      ],
    ),
  );
}

class _MarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = LumenColors.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    final curve = Path()
      ..moveTo(size.width * .08, size.height * .68)
      ..cubicTo(
        size.width * .10,
        size.height * .42,
        size.width * .34,
        size.height * .56,
        size.width * .39,
        size.height * .69,
      )
      ..cubicTo(
        size.width * .65,
        size.height * .49,
        size.width * .79,
        size.height * .74,
        size.width * .90,
        size.height * .73,
      )
      ..cubicTo(
        size.width * .97,
        size.height * .73,
        size.width * .98,
        size.height * .64,
        size.width * .91,
        size.height * .61,
      );
    canvas.drawPath(curve, paint);
    final star = Paint()..color = LumenColors.gold;
    final center = Offset(size.width * .91, size.height * .28);
    final starPath = Path();
    for (var i = 0; i < 8; i++) {
      final radius = i.isEven ? 9.0 : 2.6;
      final angle = i * math.pi / 4 - math.pi / 2;
      final point =
          center + Offset(radius * math.cos(angle), radius * math.sin(angle));
      if (i == 0) {
        starPath.moveTo(point.dx, point.dy);
      } else {
        starPath.lineTo(point.dx, point.dy);
      }
    }
    canvas.drawPath(starPath..close(), star);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Marca da loja: nome em Bodoni e assinatura pequena entre traços.
class LumenWordmark extends StatelessWidget {
  const LumenWordmark({super.key, this.color = Lumen.ink});
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        'LUMEN',
        style: TextStyle(
          fontFamily: Lumen.display,
          color: color,
          fontSize: 30,
          height: 1,
          letterSpacing: 3,
        ),
      ),
      const SizedBox(height: 4),
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 16, height: .8, color: color.withValues(alpha: .5)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              'STORE',
              style: TextStyle(
                color: color,
                fontSize: 8,
                fontWeight: FontWeight.w600,
                letterSpacing: 3,
              ),
            ),
          ),
          Container(width: 16, height: .8, color: color.withValues(alpha: .5)),
        ],
      ),
    ],
  );
}
