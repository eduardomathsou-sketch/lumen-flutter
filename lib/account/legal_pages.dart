import 'package:flutter/material.dart';

import '../checkout/checkout_pages.dart';
import '../checkout/commerce_api.dart';
import 'account_controller.dart';

/// Documentos que a API entrega em `/legal/{slug}`.
const legalTitles = {
  'terms': 'Termos de Uso',
  'privacy': 'Política de Privacidade',
  'returns': 'Trocas e Devoluções',
};

/// Transforma o Markdown simples dos documentos (títulos, listas e tabelas)
/// em widgets. Nada de HTML: o texto do servidor nunca vira código na tela.
List<Widget> legalBlocks(BuildContext context, String markdown) {
  final text = Theme.of(context).textTheme;
  final blocks = <Widget>[];
  List<String>? header;
  for (final raw in markdown.split('\n')) {
    final line = raw.trimRight();
    if (line.isEmpty) continue;
    if (line.startsWith('|')) {
      final cells = line.split('|').map((cell) => cell.trim()).toList();
      cells.removeAt(0);
      if (cells.isNotEmpty && cells.last.isEmpty) cells.removeLast();
      if (cells.every((cell) => RegExp(r'^:?-+:?$').hasMatch(cell))) continue;
      if (header == null) {
        header = cells;
        continue;
      }
      final titles = header;
      blocks.add(
        Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < cells.length; i++) ...[
                  if (i < titles.length)
                    Text(titles[i].toUpperCase(), style: text.labelSmall),
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: i == cells.length - 1 ? 0 : 10,
                    ),
                    child: Text(
                      cells[i],
                      style: i == 0 ? text.titleSmall : text.bodyMedium,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
      continue;
    }
    header = null;
    if (line.startsWith('## ')) {
      blocks.add(
        Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 8),
          child: Text(line.substring(3), style: text.titleLarge),
        ),
      );
    } else if (line.startsWith('# ')) {
      blocks.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(line.substring(2), style: text.headlineSmall),
        ),
      );
    } else if (line.startsWith('- ')) {
      blocks.add(
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('•  '),
              Expanded(
                child: Text(
                  line.substring(2),
                  style: const TextStyle(height: 1.5),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      blocks.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(line, style: const TextStyle(height: 1.5)),
        ),
      );
    }
  }
  return blocks;
}

class LegalPage extends StatefulWidget {
  const LegalPage({super.key, required this.account, required this.slug});
  final AccountController account;
  final String slug;
  @override
  State<LegalPage> createState() => _LegalPageState();
}

class _LegalPageState extends State<LegalPage> {
  late Future<Json> _document;

  @override
  void initState() {
    super.initState();
    _document = widget.account.legalDocument(widget.slug);
  }

  void _retry() => setState(() {
    _document = widget.account.legalDocument(widget.slug);
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(legalTitles[widget.slug] ?? 'Documento')),
    body: SafeArea(
      child: FutureBuilder<Json>(
        future: _document,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: RetryNotice(
                  errorText(snapshot.error ?? 'Documento indisponível.'),
                  _retry,
                ),
              ),
            );
          }
          final data = snapshot.data!;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  ...legalBlocks(context, data['content'] as String),
                  const SizedBox(height: 24),
                  Text(
                    'Versão ${data['version']}',
                    style: const TextStyle(color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );
}
