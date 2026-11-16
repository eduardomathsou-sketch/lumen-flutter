import 'package:flutter/material.dart';

import 'catalog_api.dart';
import 'store_pages.dart' show ProductVisual;

const _ink = Color(0xFF171717);
const _paper = Color(0xFFF7F2EA);
const _gold = Color(0xFFD9B66A);
const _muted = Color(0xFF756C62);
const _sale = Color(0xFFB23A3A);

/// Cartão da vitrine: foto grande com selos, preço em destaque e botão de compra.
/// Usado na home, no catálogo e nos favoritos, para a loja ter um só padrão.
class ShopProductCard extends StatelessWidget {
  const ShopProductCard({
    super.key,
    required this.product,
    required this.favorite,
    required this.onFavorite,
    required this.onAdd,
    required this.onOpen,
    this.favoriteBusy = false,
  });

  final StoreProduct product;
  final bool favorite, favoriteBusy;
  final VoidCallback onFavorite, onAdd, onOpen;

  @override
  Widget build(BuildContext context) {
    final available = product.availableStock > 0;
    final sizes = product.sizes;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _paper,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _gold.withValues(alpha: .6)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
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
                    child: ProductVisual(product: product),
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
                      if (product.badgeLabel != null)
                        ShopPill(
                          text: product.badgeLabel!,
                          icon: Icons.auto_awesome,
                        ),
                      if (product.hasDiscount)
                        ShopPill(
                          text: '-${product.discountPercent}%',
                          background: _sale,
                          foreground: Colors.white,
                        ),
                    ],
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: IconButton(
                    tooltip: favorite ? 'Remover favorito' : 'Favoritar produto',
                    onPressed: favoriteBusy ? null : onFavorite,
                    style: IconButton.styleFrom(
                      backgroundColor: _paper.withValues(alpha: .92),
                    ),
                    icon: Icon(
                      favorite ? Icons.favorite : Icons.favorite_border,
                      color: favorite ? const Color(0xFFAF4C55) : _ink,
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
                      child: ShopPill(text: product.categoryName!.toUpperCase()),
                    ),
                  ),
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: IconButton.filled(
                    tooltip: 'Ver detalhes',
                    onPressed: onOpen,
                    style: IconButton.styleFrom(
                      backgroundColor: _ink,
                      foregroundColor: _paper,
                    ),
                    icon: const Icon(Icons.visibility_outlined, size: 20),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  InkWell(
                    onTap: onOpen,
                    child: Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (!available || sizes.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      available ? 'Tamanhos: ${sizes.join(' · ')}' : 'Esgotado',
                      style: const TextStyle(color: _muted, fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 12),
                  if (product.hasDiscount)
                    Text(
                      product.formattedCompareAt!,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 13,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  Text(
                    product.formattedPrice,
                    style: const TextStyle(
                      fontFamily: 'Playfair',
                      color: _ink,
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      fontVariations: [FontVariation.weight(600)],
                      height: 1.15,
                    ),
                  ),
                  const Text(
                    'à vista no PIX',
                    style: TextStyle(color: _muted, fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  Tooltip(
                    message: 'Adicionar à sacola',
                    child: FilledButton.icon(
                      onPressed: available ? onAdd : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: _ink,
                        foregroundColor: _paper,
                        disabledBackgroundColor: const Color(0xFFD9D1C5),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                      label: Text(
                        available ? 'COMPRAR' : 'ESGOTADO',
                        style: const TextStyle(
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Selo arredondado sobre a foto (novidade, desconto, categoria).
class ShopPill extends StatelessWidget {
  const ShopPill({
    super.key,
    required this.text,
    this.icon,
    this.background = _paper,
    this.foreground = _ink,
  });
  final String text;
  final IconData? icon;
  final Color background, foreground;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [
        BoxShadow(color: Color(0x1F000000), blurRadius: 6, offset: Offset(0, 2)),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 12, color: _gold),
          const SizedBox(width: 5),
        ],
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: foreground,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: .8,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Cabeçalho de seção no estilo vitrine: rótulo dourado, título e contagem de peças.
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
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          color: _gold,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 2.1,
        ),
      ),
      const SizedBox(height: 6),
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Playfair',
                color: _paper,
                fontSize: 28,
                height: 1.1,
              ),
            ),
          ),
          if (count != null)
            Text(
              count == 1 ? '1 peça' : '$count peças',
              style: const TextStyle(color: Color(0xFFA7A097), fontSize: 13),
            ),
        ],
      ),
    ],
  );
}

/// Faixa de confiança abaixo do banner: só promessas que a loja cumpre.
class TrustStrip extends StatelessWidget {
  const TrustStrip({super.key});

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 18,
    runSpacing: 10,
    alignment: WrapAlignment.center,
    children: const [
      _TrustItem(Icons.verified_user_outlined, 'Compra segura'),
      _TrustItem(Icons.pix, 'Pagamento por PIX'),
      _TrustItem(Icons.local_shipping_outlined, 'Frete grátis a partir de 2 peças'),
      _TrustItem(Icons.autorenew, 'Devolução em até 7 dias'),
    ],
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
      Icon(icon, size: 16, color: _gold),
      const SizedBox(width: 6),
      Flexible(
        child: Text(
          text,
          style: const TextStyle(color: Color(0xFFA7A097), fontSize: 12),
        ),
      ),
    ],
  );
}
