import 'package:flutter/material.dart';

import '../lumen_theme.dart';

/// Banner principal da home: três chamadas que a cliente passa de lado,
/// com indicadores clicáveis. Sem troca automática (não distrai quem está lendo).
class HeroCarousel extends StatefulWidget {
  const HeroCarousel({super.key, required this.onShop});
  final VoidCallback onShop;

  @override
  State<HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<HeroCarousel> {
  final _pages = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _show(int page) => _pages.animateToPage(
    page,
    duration: const Duration(milliseconds: 380),
    curve: Curves.easeOutCubic,
  );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= 760;
      final slides = [
        _Slide(
          wide: wide,
          image: 'assets/images/collection-banner.png',
          label: 'Nova coleção',
          title: 'Vista a sua\nessência.',
          band: 'PEÇAS ESCOLHIDAS PARA ILUMINAR O SEU DIA',
          action: 'VER A COLEÇÃO',
          onAction: widget.onShop,
        ),
        _Slide(
          wide: wide,
          background: const Color(0xFFEFE9E1),
          label: 'Um presente para você',
          title: 'Frete grátis\na partir de 2 peças.',
          band: 'INCLUSIVE DO MESMO PRODUTO',
          action: 'ESCOLHER MEUS FAVORITOS',
          onAction: widget.onShop,
        ),
        _Slide(
          wide: wide,
          background: Lumen.ink,
          dark: true,
          label: 'Pagamento',
          title: 'PIX aprovado\nna hora.',
          band: 'SEM TAXA · COMPRA PROTEGIDA',
          action: 'COMPRAR AGORA',
          onAction: widget.onShop,
        ),
      ];
      return SizedBox(
        height: wide ? 440 : 400,
        child: Stack(
          children: [
            PageView(
              controller: _pages,
              onPageChanged: (page) => setState(() => _page = page),
              children: slides,
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < slides.length; i++)
                    Semantics(
                      button: true,
                      label: 'Ver banner ${i + 1}',
                      child: GestureDetector(
                        onTap: () => _show(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: i == _page ? 28 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _page ? Lumen.ink : const Color(0x66FFFFFF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0x33111111)),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _Slide extends StatelessWidget {
  const _Slide({
    required this.wide,
    required this.label,
    required this.title,
    required this.band,
    required this.action,
    required this.onAction,
    this.image,
    this.background = const Color(0xFFF3EEE7),
    this.dark = false,
  });
  final bool wide, dark;
  final String label, title, band, action;
  final VoidCallback onAction;
  final String? image;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final ink = dark ? Colors.white : Lumen.ink;
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: background),
        if (image != null)
          Image.asset(
            image!,
            fit: BoxFit.cover,
            alignment: wide ? Alignment.centerRight : const Alignment(.55, 0),
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        if (image != null)
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xF2F5F1EA), Color(0x99F5F1EA), Color(0x00F5F1EA)],
                stops: [0, .45, .8],
              ),
            ),
          ),
        Padding(
          padding: EdgeInsets.fromLTRB(wide ? 56 : 24, 28, 24, 44),
          // Com letra grande (acessibilidade) o bloco encolhe em vez de estourar.
          child: LayoutBuilder(
            builder: (context, box) => Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: box.maxWidth.clamp(0, 520).toDouble(),
                  child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: Lumen.label.copyWith(color: dark ? Lumen.gold : Lumen.text),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: Lumen.displayStyle(wide ? 54 : 40, color: ink),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                color: dark ? Lumen.gold : Lumen.ink,
                child: Text(
                  band,
                  style: TextStyle(
                    color: dark ? Lumen.ink : Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: dark ? Colors.white : Lumen.ink,
                  foregroundColor: dark ? Lumen.ink : Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                ),
                onPressed: onAction,
                child: Text(action),
              ),
            ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
