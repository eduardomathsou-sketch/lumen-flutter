import 'package:flutter/material.dart';

import '../lumen_theme.dart';
import 'catalog_api.dart';
import 'store_pages.dart' show ProductVisual;

/// Cartão da vitrine: foto vertical com selos, nome forte, preço em Bodoni, atalho para a
/// sacola e "Comprar agora". Usado na home, na loja e nos favoritos.
class ShopProductCard extends StatelessWidget {
  const ShopProductCard({
    super.key,
    required this.product,
    required this.favorite,
    required this.onFavorite,
    required this.onAdd,
    required this.onOpen,
    this.onBuyNow,
    this.favoriteBusy = false,
  });

  final StoreProduct product;
  final bool favorite, favoriteBusy;
  final VoidCallback onFavorite, onAdd, onOpen;

  /// Adiciona e já leva para a sacola; sem ele, faz o mesmo que [onAdd].
  final VoidCallback? onBuyNow;

  @override
  Widget build(BuildContext context) {
    final available = product.availableStock > 0;
    final sizes = product.sizes;
    return DecoratedBox(
      decoration: Lumen.card(),
      child: ClipRRect(
        borderRadius: Lumen.radius,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                Semantics(
                  button: true,
                  label: 'Ver ${product.name}',
                  child: InkWell(
                    onTap: onOpen,
                    child: ProductVisual(product: product, aspectRatio: 3 / 4),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  right: 60,
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ShopPill(
                        text: product.badgeLabel ?? 'LUMEN',
                        icon: Icons.auto_awesome,
                      ),
                      if (product.hasDiscount)
                        ShopPill(
                          text: '-${product.discountPercent}%',
                          background: Lumen.sale,
                          foreground: Colors.white,
                          size: 10,
                        ),
                    ],
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    tooltip: favorite ? 'Remover favorito' : 'Favoritar produto',
                    onPressed: favoriteBusy ? null : onFavorite,
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xF2FFFFFF),
                    ),
                    icon: Icon(
                      favorite ? Icons.favorite : Icons.favorite_border,
                      color: favorite ? Lumen.sale : Lumen.ink,
                      size: 20,
                    ),
                  ),
                ),
                if (product.categoryName != null)
                  Positioned(
                    left: 12,
                    bottom: 12,
                    right: 64,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: ShopPill(text: product.categoryName!, caps: false),
                    ),
                  ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: IconButton.filled(
                    tooltip: 'Ver detalhes',
                    onPressed: onOpen,
                    style: IconButton.styleFrom(
                      backgroundColor: Lumen.ink,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.visibility_outlined, size: 20),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: LayoutBuilder(
                builder: (context, constraints) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    InkWell(
                      onTap: onOpen,
                      child: Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Lumen.ink,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Linha sempre presente: cartões lado a lado mantêm o botão alinhado.
                    Align(
                      alignment: Alignment.centerLeft,
                      child: !available
                          ? const Text(
                              'Esgotado',
                              style: TextStyle(
                                color: Lumen.sale,
                                fontWeight: FontWeight.w700,
                              ),
                            )
                          : Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                if (sizes.isEmpty) const Text(' '),
                                for (final size in sizes.take(5)) _SizeTag(size),
                                if (sizes.length > 5)
                                  Text(
                                    '+${sizes.length - 5}',
                                    style: const TextStyle(
                                      color: Lumen.muted,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.formattedCompareAt ?? ' ',
                                style: const TextStyle(
                                  color: Lumen.faint,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  product.formattedPrice,
                                  style: Lumen.displayStyle(
                                    constraints.maxWidth < 300 ? 30 : 36,
                                    weight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'à vista no PIX',
                                style: TextStyle(
                                  color: Lumen.muted,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Tooltip(
                          message: 'Adicionar à sacola',
                          child: IconButton.filled(
                            onPressed: available ? onAdd : null,
                            style: IconButton.styleFrom(
                              backgroundColor: Lumen.ink,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: const Color(0xFFE5E7EB),
                              fixedSize: const Size(48, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: Lumen.radius,
                              ),
                            ),
                            icon: const Icon(
                              Icons.shopping_cart_outlined,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: available ? (onBuyNow ?? onAdd) : null,
                      icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                      label: Text(available ? 'Comprar agora' : 'Esgotado'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SizeTag extends StatelessWidget {
  const _SizeTag(this.size);
  final String size;
  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 26),
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: const Color(0xFFE5E7EB)),
    ),
    child: Text(
      size,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Lumen.ink,
      ),
    ),
  );
}

/// Selo arredondado sobre a foto (selo, desconto, categoria).
class ShopPill extends StatelessWidget {
  const ShopPill({
    super.key,
    required this.text,
    this.icon,
    this.background = const Color(0xF2FFFFFF),
    this.foreground = Lumen.ink,
    this.size = 11,
    this.caps = true,
  });
  final String text;
  final IconData? icon;
  final Color background, foreground;
  final double size;
  final bool caps;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(999),
      boxShadow: const [
        BoxShadow(color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 2)),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 12, color: Lumen.gold),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Text(
            caps ? text.toUpperCase() : text,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: foreground,
              fontSize: size,
              fontWeight: caps ? FontWeight.w800 : FontWeight.w700,
              letterSpacing: caps ? .3 : 0,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Cabeçalho de seção: rótulo pequeno, título em Bodoni e contagem à direita.
class ShowcaseHeader extends StatelessWidget {
  const ShowcaseHeader({
    super.key,
    required this.label,
    required this.title,
    this.count,
  });
  final String label, title;
  final int? count;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(), style: Lumen.label),
            const SizedBox(height: 6),
            Text(title, style: Lumen.displayStyle(36)),
          ],
        ),
      ),
      if (count != null)
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 6),
          child: Text(
            count == 1 ? '1 produto' : '$count produtos',
            style: const TextStyle(
              color: Lumen.muted,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
    ],
  );
}

/// Faixa de confiança: só promessas que a loja cumpre.
class TrustStrip extends StatelessWidget {
  const TrustStrip({super.key});

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: Lumen.card(),
    child: const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Wrap(
        spacing: 22,
        runSpacing: 12,
        alignment: WrapAlignment.spaceAround,
        children: [
          _TrustItem(Icons.verified_user_outlined, 'Compra segura'),
          _TrustItem(Icons.pix, 'Pagamento por PIX'),
          _TrustItem(
            Icons.local_shipping_outlined,
            'Frete grátis a partir de 2 peças',
          ),
          _TrustItem(Icons.autorenew, 'Devolução em até 7 dias'),
        ],
      ),
    ),
  );
}

class _TrustItem extends StatelessWidget {
  const _TrustItem(this.icon, this.text);
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 18, color: Lumen.gold),
      const SizedBox(width: 8),
      Flexible(
        child: Text(
          text,
          style: const TextStyle(
            color: Lumen.ink,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ],
  );
}

/// Cartão de informação com ícone dourado (página da peça, garantias).
class InfoCard extends StatelessWidget {
  const InfoCard({super.key, required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: Lumen.card(),
    child: Row(
      children: [
        Icon(icon, size: 18, color: Lumen.gold),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Lumen.ink,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ],
    ),
  );
}
