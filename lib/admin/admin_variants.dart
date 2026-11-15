import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../checkout/checkout_pages.dart' show RetryNotice, errorText;
import 'admin_api.dart';

/// Tamanhos e cores de uma peça. Com variações ativas, a loja vende pelo estoque de cada uma.
class AdminVariantsPage extends StatefulWidget {
  const AdminVariantsPage({
    super.key,
    required this.repository,
    required this.productId,
    required this.productName,
  });
  final AdminVariantsRepository repository;
  final int productId;
  final String productName;
  @override
  State<AdminVariantsPage> createState() => _AdminVariantsPageState();
}

class _AdminVariantsPageState extends State<AdminVariantsPage> {
  List<AdminVariant> _items = [];
  bool _busy = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final items = await widget.repository.variants(widget.productId);
      if (mounted) setState(() => _items = items);
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit([AdminVariant? variant]) async {
    final data = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _VariantDialog(variant: variant),
    );
    if (data == null || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.repository.saveVariant(
        widget.productId,
        {...data, if (variant != null) 'version': variant.version},
        id: variant?.id,
      );
      if (mounted) await _load();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = errorText(e);
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _items.where((v) => v.active).fold(0, (sum, v) => sum + v.stock);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.productName.isEmpty
              ? 'Tamanhos e cores'
              : 'Tamanhos · ${widget.productName}',
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _busy ? null : () => _edit(),
        icon: const Icon(Icons.add),
        label: const Text('NOVO TAMANHO/COR'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                const Text(
                  'Com tamanhos ou cores ativos, a cliente precisa escolher um antes de comprar e a '
                  'reserva sai do estoque daquela opção. Para parar de vender uma opção, desative-a: '
                  'os pedidos antigos continuam com ela.',
                ),
                const SizedBox(height: 12),
                if (_busy) const LinearProgressIndicator(),
                if (_error != null) RetryNotice(_error!, () => _load()),
                if (_items.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('Estoque total à venda: $total unidades'),
                  ),
                if (!_busy && _error == null && _items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'Esta peça ainda não tem tamanhos: vende pelo estoque do produto.',
                    ),
                  ),
                for (final variant in _items)
                  Card(
                    child: ListTile(
                      title: Text(variant.label),
                      subtitle: Text(
                        variant.active
                            ? '${variant.stock} em estoque'
                            : 'Desativado · ${variant.stock} em estoque',
                      ),
                      trailing: const Icon(Icons.edit_outlined),
                      onTap: _busy ? null : () => _edit(variant),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VariantDialog extends StatefulWidget {
  const _VariantDialog({this.variant});
  final AdminVariant? variant;
  @override
  State<_VariantDialog> createState() => _VariantDialogState();
}

class _VariantDialogState extends State<_VariantDialog> {
  final _form = GlobalKey<FormState>();
  late final _size = TextEditingController(text: widget.variant?.size ?? '');
  late final _color = TextEditingController(text: widget.variant?.color ?? '');
  late final _stock = TextEditingController(
    text: '${widget.variant?.stock ?? 0}',
  );
  late bool _active = widget.variant?.active ?? true;

  @override
  void dispose() {
    _size.dispose();
    _color.dispose();
    _stock.dispose();
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    Navigator.of(context).pop({
      'size': _size.text.trim().toUpperCase(),
      'color': _color.text.trim(),
      'stock': int.parse(_stock.text),
      'is_active': _active,
    });
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.variant == null ? 'Novo tamanho/cor' : 'Editar ${widget.variant!.label}'),
    content: Form(
      key: _form,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              key: const ValueKey('variant-size'),
              controller: _size,
              maxLength: 20,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Tamanho', hintText: 'P, M, G, 38…'),
            ),
            TextFormField(
              key: const ValueKey('variant-color'),
              controller: _color,
              maxLength: 40,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Cor', hintText: 'Champagne'),
              validator: (v) => v!.trim().isEmpty && _size.text.trim().isEmpty
                  ? 'Informe o tamanho, a cor ou os dois.'
                  : null,
            ),
            TextFormField(
              key: const ValueKey('variant-stock'),
              controller: _stock,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Estoque'),
              validator: (v) {
                final n = int.tryParse(v!);
                return n == null || n > 1000000 ? 'De 0 a 1.000.000 unidades.' : null;
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _active,
              onChanged: (v) => setState(() => _active = v),
              title: const Text('À venda'),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('CANCELAR'),
      ),
      FilledButton(onPressed: _save, child: const Text('SALVAR')),
    ],
  );
}
