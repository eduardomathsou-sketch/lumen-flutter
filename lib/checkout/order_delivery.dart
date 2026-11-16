import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'checkout_pages.dart' show errorText;
import 'commerce_api.dart';

String shortDate(DateTime date) {
  final local = date.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year}';
}

/// Linha do tempo da entrega de um pedido pago: preparação → enviado → entregue.
class DeliveryProgress extends StatelessWidget {
  const DeliveryProgress(this.order, {super.key});
  final StoreOrder order;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final steps = [
      ('Em preparação', 'Separando e embalando suas peças', null),
      ('Enviado', 'A caminho do seu endereço', order.shippedAt),
      ('Entregue', 'Chegou! Aproveite', order.deliveredAt),
    ];
    final current = order.deliveryStep;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Entrega', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            for (var i = 0; i < steps.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      i < current
                          ? Icons.check_circle
                          : i == current
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: i <= current ? scheme.primary : scheme.outline,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            steps[i].$1,
                            style: TextStyle(
                              fontWeight: i == current
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: i <= current ? null : scheme.outline,
                            ),
                          ),
                          Text(
                            steps[i].$3 == null
                                ? steps[i].$2
                                : '${steps[i].$2} · ${shortDate(steps[i].$3!)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            if (order.trackingCode != null) ...[
              const Divider(),
              Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      'Rastreio: ${order.trackingCode}',
                      key: const ValueKey('tracking-code'),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Copiar código de rastreio',
                    icon: const Icon(Icons.copy),
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: order.trackingCode!),
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Código copiado. Cole no site ou app dos Correios.',
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Devolução: só aparece depois da entrega e respeita os prazos que a API calcula.
class ReturnSection extends StatefulWidget {
  const ReturnSection({super.key, required this.order, required this.returns});
  final StoreOrder order;
  final OrderReturns returns;
  @override
  State<ReturnSection> createState() => _ReturnSectionState();
}

class _ReturnSectionState extends State<ReturnSection> {
  static const _labels = {
    'arrependimento': 'Me arrependi da compra',
    'defeito': 'A peça veio com defeito',
  };
  ReturnInfo? _info;
  String? _error;
  bool _busy = true;

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
      final info = await widget.returns.returnInfo(widget.order.id);
      if (mounted) setState(() => _info = info);
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _request() async {
    final deadlines = _info!.deadlines;
    final choice = await showDialog<(String, String)>(
      context: context,
      builder: (_) => _ReturnDialog(
        options: {
          for (final reason in _labels.keys)
            if (deadlines.containsKey(reason))
              reason: '${_labels[reason]} (até ${shortDate(deadlines[reason]!)})',
        },
      ),
    );
    if (choice == null || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final info = await widget.returns.requestReturn(
        widget.order.id,
        choice.$1,
        choice.$2,
      );
      if (!mounted) return;
      setState(() => _info = info);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solicitação enviada. Você recebe as instruções por e-mail.'),
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = _info;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Trocas e devoluções', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (_busy) const LinearProgressIndicator(),
            if (_error != null) ...[
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              TextButton(onPressed: _load, child: const Text('TENTAR NOVAMENTE')),
            ],
            if (info != null && info.request != null) ...[
              Text(info.requestStatusLabel!, key: const ValueKey('return-status')),
              if ((info.request!['admin_note'] as String? ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('Recado da loja: ${info.request!['admin_note']}'),
                ),
            ] else if (info != null && info.eligible) ...[
              const Text(
                'Você pode pedir a devolução por arrependimento em até 7 dias e por defeito em até 90 dias depois da entrega.',
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _busy ? null : _request,
                child: const Text('SOLICITAR DEVOLUÇÃO'),
              ),
            ] else if (info != null)
              const Text('O prazo para devolução deste pedido terminou.'),
          ],
        ),
      ),
    );
  }
}

class _ReturnDialog extends StatefulWidget {
  const _ReturnDialog({required this.options});
  final Map<String, String> options;
  @override
  State<_ReturnDialog> createState() => _ReturnDialogState();
}

class _ReturnDialogState extends State<_ReturnDialog> {
  String? _reason;
  final _details = TextEditingController();
  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Solicitar devolução'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Qual o motivo?'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in widget.options.entries)
                ChoiceChip(
                  key: ValueKey('return-${entry.key}'),
                  label: Text(entry.value),
                  selected: _reason == entry.key,
                  onSelected: (_) => setState(() => _reason = entry.key),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('return-details'),
            controller: _details,
            maxLength: 500,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Conte o que aconteceu (opcional)',
              border: OutlineInputBorder(),
            ),
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
        onPressed: _reason == null
            ? null
            : () => Navigator.of(context).pop((_reason!, _details.text.trim())),
        child: const Text('ENVIAR'),
      ),
    ],
  );
}
