import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/permission_codes.dart';
import '../../../core/providers/auth_providers.dart';
import '../../theme/app_component_theme.dart';
import '../../theme/app_spacing.dart';
import 'theme_selector.dart';

class MasPage extends ConsumerWidget {
  const MasPage({super.key});

  static const List<_MasSection> _sections = <_MasSection>[
    _MasSection('OPERACIONES', <_MasItem>[
      _MasItem(
        'Compras',
        Icons.shopping_cart_outlined,
        '/compras',
        PermissionCodes.compras,
      ),
      _MasItem(
        'Movimientos',
        Icons.swap_vert,
        '/movimientos',
        PermissionCodes.movimientos,
      ),
      _MasItem(
        'Gastos',
        Icons.money_off_outlined,
        '/gastos',
        PermissionCodes.gastos,
      ),
    ]),
    _MasSection('CATALOGOS', <_MasItem>[
      _MasItem(
        'Categorias',
        Icons.category_outlined,
        '/categorias',
        PermissionCodes.categorias,
      ),
      _MasItem(
        'Proveedores',
        Icons.local_shipping_outlined,
        '/proveedores',
        PermissionCodes.proveedores,
      ),
      _MasItem(
        'Clientes',
        Icons.people_outline,
        '/clientes',
        PermissionCodes.clientes,
      ),
      _MasItem(
        'Precios',
        Icons.sell_outlined,
        '/gestion-precios',
        PermissionCodes.precios,
      ),
    ]),
    _MasSection('ADMINISTRACION', <_MasItem>[
      _MasItem(
        'Usuarios',
        Icons.people_alt_outlined,
        '/usuarios',
        PermissionCodes.usuarios,
      ),
      _MasItem(
        'Roles',
        Icons.admin_panel_settings_outlined,
        '/roles',
        PermissionCodes.roles,
      ),
    ]),
    _MasSection('SISTEMA', <_MasItem>[
      _MasItem('Logs', Icons.history, '/logs', PermissionCodes.logs),
      _MasItem(
        'Chat',
        Icons.chat_bubble_outline,
        '/chat',
        PermissionCodes.chat,
      ),
    ]),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Set<String> permissions = ref.watch(authNotifierProvider).permisos;
    final AppComponentTheme components =
        Theme.of(context).extension<AppComponentTheme>() ??
        AppComponentTheme.standard;
    return Scaffold(
      appBar: AppBar(title: const Text('Más')),
      body: ListView(
        padding: components.cardPadding,
        children: <Widget>[
          for (final _MasSection section in _sections)
            if (section.title != 'SISTEMA' &&
                section.items.any(
                  (item) => permissions.contains(item.permission),
                ))
              _MasSectionView(section: section, permissions: permissions),
          _SystemSection(
            components: components,
            onLogout: () => ref.read(authNotifierProvider.notifier).logout(),
          ),
        ],
      ),
    );
  }
}

class _MasSectionView extends StatelessWidget {
  const _MasSectionView({required this.section, required this.permissions});
  final _MasSection section;
  final Set<String> permissions;

  @override
  Widget build(BuildContext context) {
    final List<_MasItem> visibleItems = section.items
        .where((item) => permissions.contains(item.permission))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.space8),
          child: Text(
            section.title,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        ...visibleItems.map((item) => _MasTile(item: item)),
        const SizedBox(height: AppSpacing.space16),
      ],
    );
  }
}

class _MasTile extends StatelessWidget {
  const _MasTile({required this.item});
  final _MasItem item;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Abrir ${item.label}',
    child: ListTile(
      minVerticalPadding: AppSpacing.space8,
      leading: Icon(item.icon),
      title: Text(item.label),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.go(item.route),
    ),
  );
}

class _SystemSection extends StatelessWidget {
  const _SystemSection({required this.components, required this.onLogout});
  final AppComponentTheme components;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.space8),
        child: Text('SISTEMA', style: Theme.of(context).textTheme.labelLarge),
      ),
      const MasThemeSelector(),
      Semantics(
        button: true,
        label: 'Cerrar sesion',
        child: ListTile(
          contentPadding: components.cardPadding,
          leading: const Icon(Icons.logout),
          title: const Text('Cerrar sesion'),
          onTap: onLogout,
        ),
      ),
    ],
  );
}

class _MasSection {
  const _MasSection(this.title, this.items);
  final String title;
  final List<_MasItem> items;
}

class _MasItem {
  const _MasItem(this.label, this.icon, this.route, this.permission);
  final String label;
  final IconData icon;
  final String route;
  final String permission;
}
