import 'package:flutter/material.dart';

import '../checkout/commerce_api.dart';

/// Estrelas só de leitura (nota inteira de 1 a 5).
class Stars extends StatelessWidget {
  const Stars(this.rating, {super.key, this.size = 16});
  final int rating;
  final double size;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 1; i <= 5; i++)
        Icon(
          i <= rating ? Icons.star : Icons.star_border,
          size: size,
          color: Theme.of(context).colorScheme.primary,
        ),
    ],
  );
}

/// Últimas avaliações da peça. Se a lista não carregar, a página segue sem ela.
class ProductReviews extends StatefulWidget {
  const ProductReviews({super.key, required this.productId, required this.load});
  final int productId;
  final Future<Json> Function(int productId) load;
  @override
  State<ProductReviews> createState() => _ProductReviewsState();
}

class _ProductReviewsState extends State<ProductReviews> {
  List<Json> _items = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final data = await widget.load(widget.productId);
      final items = (data['items'] as List? ?? []).cast<Json>();
      if (mounted) setState(() => _items = items);
    } catch (_) {
      // Avaliações são complemento: sem elas a compra continua normal.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AVALIAÇÕES',
            style: theme.textTheme.labelLarge?.copyWith(letterSpacing: 2),
          ),
          const SizedBox(height: 12),
          for (final review in _items)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Stars(review['rating'] as int? ?? 0),
                      const SizedBox(width: 8),
                      Text(
                        review['author'] as String? ?? 'Cliente Lumen',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  if ((review['comment'] as String? ?? '').isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(review['comment'] as String),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Pede nota (1–5) e comentário. Devolve null se a pessoa desistir.
Future<(int, String)?> askReview(BuildContext context, String productName) =>
    showDialog<(int, String)>(
      context: context,
      builder: (_) => _ReviewDialog(productName: productName),
    );

class _ReviewDialog extends StatefulWidget {
  const _ReviewDialog({required this.productName});
  final String productName;
  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  int _rating = 0;
  final _comment = TextEditingController();
  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('Avaliar ${widget.productName}'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  key: ValueKey('star-$i'),
                  tooltip: '$i de 5',
                  onPressed: () => setState(() => _rating = i),
                  icon: Icon(
                    i <= _rating ? Icons.star : Icons.star_border,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
            ],
          ),
          TextField(
            key: const ValueKey('review-comment'),
            controller: _comment,
            maxLength: 1000,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Conte como ficou (opcional)',
              border: OutlineInputBorder(),
            ),
          ),
          const Text(
            'Só o seu primeiro nome aparece junto da avaliação.',
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('CANCELAR'),
      ),
      FilledButton(
        onPressed: _rating == 0
            ? null
            : () => Navigator.of(context).pop((_rating, _comment.text.trim())),
        child: const Text('PUBLICAR'),
      ),
    ],
  );
}

/// No pedido entregue: um botão por peça para avaliar.
class ReviewItems extends StatefulWidget {
  const ReviewItems({super.key, required this.items, required this.writer});
  final List<Json> items;
  final ReviewWriter writer;
  @override
  State<ReviewItems> createState() => _ReviewItemsState();
}

class _ReviewItemsState extends State<ReviewItems> {
  final _done = <int>{};
  int? _busy;

  Future<void> _review(Json item) async {
    final productId = item['product_id'] as int;
    final name = item['name'] as String? ?? 'a peça';
    final answer = await askReview(context, name);
    if (answer == null || !mounted) return;
    setState(() => _busy = productId);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.writer.saveReview(productId, answer.$1, answer.$2);
      if (!mounted) return;
      setState(() => _done.add(productId));
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Obrigada! Sua avaliação foi publicada.')),
        );
    } catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              e is CommerceException
                  ? e.message
                  : 'Não foi possível publicar agora. Tente novamente.',
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final seen = <int>{};
    final products = [
      for (final item in widget.items)
        if (item['product_id'] is int && seen.add(item['product_id'] as int)) item,
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Avalie suas peças', style: Theme.of(context).textTheme.titleMedium),
            for (final item in products)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(item['name'] as String? ?? 'Peça'),
                trailing: TextButton(
                  key: ValueKey('review-${item['product_id']}'),
                  onPressed: _busy == null ? () => _review(item) : null,
                  child: Text(
                    _done.contains(item['product_id']) ? 'EDITAR' : 'AVALIAR',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
