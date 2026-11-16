import 'package:flutter/material.dart';

/// Keeps the scrollable content centered without constraining its height.
class StoreViewport extends StatelessWidget {
  const StoreViewport({super.key, required this.child, this.maxWidth = 1280});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: SizedBox(width: double.infinity, child: child),
    ),
  );
}

/// Natural-height cards accommodate long product names and larger text.
class ProductCollection extends StatelessWidget {
  const ProductCollection({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      // Vitrine: 1 coluna no celular, 2 no tablet e 3 no computador.
      final columns = width >= 960 ? 3 : width >= 600 ? 2 : 1;
      final cardWidth = (width - (columns - 1) * 24) / columns;
      return Wrap(
        spacing: 24,
        runSpacing: 24,
        children: [
          for (final child in children)
            SizedBox(width: cardWidth, child: child),
        ],
      );
    },
  );
}

class ProductDetailLayout extends StatelessWidget {
  const ProductDetailLayout({
    super.key,
    required this.image,
    required this.details,
  });

  final Widget image, details;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => constraints.maxWidth >= 760
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: image),
              const SizedBox(width: 40),
              Expanded(child: details),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [image, const SizedBox(height: 24), details],
          ),
  );
}
