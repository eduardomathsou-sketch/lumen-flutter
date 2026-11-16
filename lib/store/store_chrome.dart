import 'package:flutter/material.dart';

import '../lumen_theme.dart';
import '../main.dart' show LumenWordmark;

/// Barra do topo: marca à esquerda, sacola e menu à direita.
class StoreTopBar extends StatelessWidget implements PreferredSizeWidget {
  const StoreTopBar({
    super.key,
    required this.bagCount,
    required this.onHome,
    required this.onBag,
    required this.onMenu,
  });
  final int bagCount;
  final VoidCallback onHome, onBag, onMenu;

  @override
  Size get preferredSize => const Size.fromHeight(76);

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xF2FFFFFF),
    elevation: 0,
    child: SafeArea(
      bottom: false,
      child: Container(
        height: 76,
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Lumen.border, width: .8)),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Semantics(
                    button: true,
                    label: 'Ir para o início',
                    child: InkWell(
                      onTap: onHome,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: LumenWordmark(),
                      ),
                    ),
                  ),
                  const Spacer(),
                  _BagButton(count: bagCount, onTap: onBag),
                  IconButton(
                    tooltip: 'Abrir menu',
                    onPressed: onMenu,
                    icon: const Icon(Icons.menu, color: Lumen.ink),
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

class _BagButton extends StatelessWidget {
  const _BagButton({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Abrir sacola',
    onPressed: onTap,
    icon: Badge(
      isLabelVisible: count > 0,
      backgroundColor: Lumen.ink,
      label: Text('$count'),
      child: const Icon(Icons.shopping_cart_outlined, color: Lumen.ink),
    ),
  );
}

/// Menu lateral: atalhos da loja, da conta e das políticas.
class StoreMenu extends StatelessWidget {
  const StoreMenu({super.key, required this.signedIn, required this.onSelect});
  final bool signedIn;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) => Drawer(
    backgroundColor: Lumen.surface,
    shape: const RoundedRectangleBorder(),
    child: SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: LumenWordmark(),
            ),
          ),
          const Divider(),
          for (final (key, icon, label) in [
            ('home', Icons.home_outlined, 'Início'),
            ('shop', Icons.storefront_outlined, 'Loja'),
            ('favorites', Icons.favorite_border, 'Favoritos'),
            ('account', Icons.person_outline, signedIn ? 'Minha conta' : 'Entrar ou criar conta'),
            ('orders', Icons.receipt_long_outlined, 'Meus pedidos'),
          ])
            ListTile(
              leading: Icon(icon, color: Lumen.ink),
              title: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              onTap: () => onSelect(key),
            ),
          const Divider(),
          for (final (key, label) in const [
            ('returns', 'Trocas e devoluções'),
            ('terms', 'Termos de uso'),
            ('privacy', 'Política de privacidade'),
          ])
            ListTile(
              dense: true,
              title: Text(label, style: const TextStyle(color: Lumen.muted)),
              onTap: () => onSelect(key),
            ),
        ],
      ),
    ),
  );
}

/// Barra inferior flutuante: Início, Loja, Buscar e Sacola.
class StoreBottomNav extends StatelessWidget {
  const StoreBottomNav({
    super.key,
    required this.selected,
    required this.bagCount,
    required this.onSelect,
  });

  /// Índice destacado (-1 quando a página atual não é um dos atalhos).
  final int selected;
  final int bagCount;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xF2FFFFFF),
              borderRadius: Lumen.radius,
              border: Border.all(color: Lumen.border, width: .8),
              boxShadow: const [
                BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                for (final (index, icon, label) in const [
                  (0, Icons.home_outlined, 'Início'),
                  (1, Icons.shopping_bag_outlined, 'Loja'),
                  (2, Icons.search, 'Buscar'),
                  (3, Icons.shopping_cart_outlined, 'Sacola'),
                ])
                  Expanded(
                    child: _NavItem(
                      key: ValueKey('nav-$label'),
                      icon: icon,
                      label: label,
                      selected: selected == index,
                      badge: index == 3 ? bagCount : 0,
                      onTap: () => onSelect(index),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.badge,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : Lumen.muted;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? Lumen.ink : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Badge(
                  isLabelVisible: badge > 0,
                  backgroundColor: Lumen.gold,
                  label: Text('$badge'),
                  child: Icon(icon, size: 20, color: color),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  // A barra fica legível com letra grande sem empurrar a tela.
                  textScaler: MediaQuery.textScalerOf(
                    context,
                  ).clamp(maxScaleFactor: 1.4),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
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

/// Rodapé escuro com navegação, ajuda, pagamento e políticas.
class StoreFooter extends StatelessWidget {
  const StoreFooter({super.key, required this.onSelect});
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: Lumen.footer,
      border: Border(top: BorderSide(color: Color(0x4DCBA96B), width: .8)),
    ),
    padding: const EdgeInsets.fromLTRB(24, 40, 24, 110),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const LumenWordmark(color: Colors.white),
        const SizedBox(height: 14),
        const Text(
          'Moda feminina e beleza escolhidas com elegância, leveza e cuidado para você.',
          style: TextStyle(color: Color(0xA6FFFFFF), fontSize: 14, height: 1.6),
        ),
        const SizedBox(height: 28),
        Wrap(
          spacing: 48,
          runSpacing: 28,
          children: [
            _FooterColumn(
              title: 'Navegação',
              links: const [
                ('home', 'Início'),
                ('shop', 'Loja'),
                ('favorites', 'Favoritos'),
                ('account', 'Minha conta'),
              ],
              onSelect: onSelect,
            ),
            _FooterColumn(
              title: 'Ajuda',
              links: const [
                ('orders', 'Meus pedidos'),
                ('returns', 'Trocas e devoluções'),
              ],
              onSelect: onSelect,
            ),
            _FooterColumn(
              title: 'Legal',
              links: const [
                ('privacy', 'Privacidade'),
                ('terms', 'Termos e condições'),
              ],
              onSelect: onSelect,
            ),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FORMAS DE PAGAMENTO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.pix, color: Lumen.gold, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'PIX',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Aprovado na hora, sem taxa.',
                  style: TextStyle(color: Color(0x99FFFFFF), fontSize: 13),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 32),
        const Divider(color: Color(0x26FFFFFF)),
        const SizedBox(height: 14),
        Text(
          '© ${DateTime.now().year} Lumen. Todos os direitos reservados.',
          style: const TextStyle(color: Color(0x80FFFFFF), fontSize: 12),
        ),
      ],
    ),
  );
}

class _FooterColumn extends StatelessWidget {
  const _FooterColumn({
    required this.title,
    required this.links,
    required this.onSelect,
  });
  final String title;
  final List<(String, String)> links;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 10),
      for (final (key, label) in links)
        InkWell(
          onTap: () => onSelect(key),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Text(
              label,
              style: const TextStyle(color: Color(0xA6FFFFFF), fontSize: 14),
            ),
          ),
        ),
    ],
  );
}
