import 'package:flutter/widgets.dart';

/// Rolagem para formulários. Diferente da ListView, monta todos os campos de uma vez:
/// a ListView desmonta o que sai da tela, e o Form só valida campos montados — um CPF
/// inválido lá em cima passaria sem aviso se a pessoa confirmasse lá embaixo.
class FormListView extends StatelessWidget {
  const FormListView({
    super.key,
    required this.children,
    this.padding,
    this.controller,
  });
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    controller: controller,
    padding: padding,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: children,
    ),
  );
}
